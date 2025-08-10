#include <dxgi1_6.h>
#include <numbers>
#include <spdlog/spdlog.h>
#include "NGX/NvNGX.h"
#include "XeSSFrameInterpolator.h"
#include "Util.h"

// Global configuration flags (similar to FSR 3 implementation)
bool g_EnableDebugOverlay = false;
bool g_EnableDebugTearLines = false;
bool g_EnableInterpolatedFramesOnly = false;

extern "C" void __declspec(dllexport) RefreshGlobalConfiguration()
{
    g_EnableDebugOverlay = Util::GetSetting(L"EnableDebugOverlay", false);
    g_EnableDebugTearLines = Util::GetSetting(L"EnableDebugTearLines", false);
    g_EnableInterpolatedFramesOnly = Util::GetSetting(L"EnableInterpolatedFramesOnly", false);
}

XeSSFrameInterpolator::XeSSFrameInterpolator(uint32_t OutputWidth, uint32_t OutputHeight)
    : m_SwapchainWidth(OutputWidth),
      m_SwapchainHeight(OutputHeight)
{
    RefreshGlobalConfiguration();
    spdlog::info("XeSS Frame Interpolator initialized for {}x{}", OutputWidth, OutputHeight);
}

XeSSFrameInterpolator::~XeSSFrameInterpolator()
{
    DestroyXeSSContext();
    DestroyXeLLContext();
    spdlog::info("XeSS Frame Interpolator destroyed");
}

bool XeSSFrameInterpolator::IsSupported(ID3D12Device* Device)
{
    if (!Device)
        return false;

    // Check if the device supports Shader Model 6.4 (required for XeSS-FG)
    D3D12_FEATURE_DATA_SHADER_MODEL shaderModel = { D3D_SHADER_MODEL_6_4 };
    HRESULT hr = Device->CheckFeatureSupport(D3D12_FEATURE_SHADER_MODEL, &shaderModel, sizeof(shaderModel));
    
    if (FAILED(hr) || shaderModel.HighestShaderModel < D3D_SHADER_MODEL_6_4)
    {
        spdlog::warn("Device does not support Shader Model 6.4, required for XeSS Frame Generation");
        return false;
    }

    // Check if the device supports DP4a instructions (required for XeSS-FG)
    D3D12_FEATURE_DATA_D3D12_OPTIONS options = {};
    hr = Device->CheckFeatureSupport(D3D12_FEATURE_D3D12_OPTIONS, &options, sizeof(options));
    
    if (FAILED(hr) || !options.Int64ShaderOps)
    {
        spdlog::warn("Device does not support Int64 shader operations, required for XeSS Frame Generation");
        return false;
    }

    // Check if XeSS DLLs are available
    HMODULE xessFgModule = LoadLibraryW(L"libxess_fg.dll");
    if (!xessFgModule)
    {
        spdlog::warn("XeSS Frame Generation DLL (libxess_fg.dll) not found");
        return false;
    }
    FreeLibrary(xessFgModule);

    HMODULE xellModule = LoadLibraryW(L"libxell.dll");
    if (!xellModule)
    {
        spdlog::warn("XeLL DLL (libxell.dll) not found");
        return false;
    }
    FreeLibrary(xellModule);

    spdlog::info("Device supports XeSS Frame Generation");
    return true;
}

xefg_swapchain_result_t XeSSFrameInterpolator::Dispatch(void* CommandList, NGXInstanceParameters* NGXParameters)
{
    if (!NGXParameters)
        return XEFG_SWAPCHAIN_RESULT_ERROR_INVALID_ARGUMENT;

    // Check if frame generation is enabled
    const bool enableInterpolation = NGXParameters->GetUIntOrDefault("DLSSG.EnableInterp", 0) != 0;
    
    if (!enableInterpolation)
        return XEFG_SWAPCHAIN_RESULT_SUCCESS;

    // Initialize if not already done
    if (!m_Initialized)
    {
        auto result = InitializeXeSSContext(NGXParameters);
        if (result != XEFG_SWAPCHAIN_RESULT_SUCCESS)
        {
            spdlog::error("Failed to initialize XeSS context: {}", result);
            return result;
        }
        m_Initialized = true;
    }

    // Get D3D12 resources
    if (!GetD3D12Resources(NGXParameters))
    {
        spdlog::error("Failed to get D3D12 resources from NGX parameters");
        return XEFG_SWAPCHAIN_RESULT_ERROR_INVALID_ARGUMENT;
    }

    // Query HDR luminance range
    QueryHDRLuminanceRange(NGXParameters);

    // Set present ID for frame tracking
    xefgSwapChainSetPresentId(m_XeSSSwapChain, m_PresentId);

    // Convert NGX parameters to XeSS resource data
    xefg_swapchain_d3d12_resource_data_t resourceData[XEFG_SWAPCHAIN_RES_COUNT] = {};
    
    if (!ConvertNGXParametersToXeSSResources(NGXParameters, resourceData))
    {
        spdlog::error("Failed to convert NGX parameters to XeSS resources");
        return XEFG_SWAPCHAIN_RESULT_ERROR_INVALID_ARGUMENT;
    }

    // Tag frame resources
    for (int i = 0; i < XEFG_SWAPCHAIN_RES_COUNT; ++i)
    {
        if (resourceData[i].pResource)
        {
            auto result = xefgSwapChainD3D12TagFrameResource(
                m_XeSSSwapChain,
                static_cast<ID3D12CommandList*>(CommandList),
                m_PresentId,
                &resourceData[i]
            );
            
            if (result != XEFG_SWAPCHAIN_RESULT_SUCCESS)
            {
                spdlog::warn("Failed to tag resource {}: {}", i, result);
            }
        }
    }

    // Build and set frame constants
    xefg_swapchain_frame_constant_data_t frameConstants = {};
    if (BuildFrameConstants(NGXParameters, &frameConstants))
    {
        auto result = xefgSwapChainTagFrameConstants(m_XeSSSwapChain, m_PresentId, &frameConstants);
        if (result != XEFG_SWAPCHAIN_RESULT_SUCCESS)
        {
            spdlog::warn("Failed to tag frame constants: {}", result);
        }
    }

    // Increment frame counters
    m_PresentId++;
    m_FrameId++;

    // Add XeLL markers for latency reduction
    if (m_XeLLContext)
    {
        xellAddMarkerData(m_XeLLContext, m_FrameId, XELL_PRESENT_START);
        xellAddMarkerData(m_XeLLContext, m_FrameId, XELL_PRESENT_END);
    }

    return XEFG_SWAPCHAIN_RESULT_SUCCESS;
}

xefg_swapchain_result_t XeSSFrameInterpolator::InitializeXeSSContext(NGXInstanceParameters* NGXParameters)
{
    if (!GetD3D12Resources(NGXParameters))
    {
        spdlog::error("Failed to get D3D12 resources for XeSS initialization");
        return XEFG_SWAPCHAIN_RESULT_ERROR_INVALID_ARGUMENT;
    }

    // Check if device supports XeSS Frame Generation
    if (!IsSupported(m_D3D12Device))
    {
        spdlog::error("Device does not support XeSS Frame Generation");
        return XEFG_SWAPCHAIN_RESULT_ERROR_UNSUPPORTED_DEVICE;
    }

    // Create XeSS Frame Generation context
    auto result = xefgSwapChainD3D12CreateContext(m_D3D12Device, &m_XeSSSwapChain);
    if (result != XEFG_SWAPCHAIN_RESULT_SUCCESS)
    {
        spdlog::error("Failed to create XeSS swap chain context: {}", result);
        return result;
    }

    // Setup logging callbacks
    SetupLoggingCallbacks();

    // Initialize XeLL context (required for XeSS-FG)
    if (InitializeXeLLContext() != XELL_RESULT_SUCCESS)
    {
        spdlog::warn("Failed to initialize XeLL context, but continuing with XeSS-FG");
    }

    // Link XeLL context to XeSS
    if (m_XeLLContext)
    {
        result = xefgSwapChainSetLatencyReduction(m_XeSSSwapChain, m_XeLLContext);
        if (result != XEFG_SWAPCHAIN_RESULT_SUCCESS)
        {
            spdlog::warn("Failed to link XeLL context to XeSS: {}", result);
        }
    }

    // Get XeSS properties
    xefg_swapchain_properties_t properties = {};
    result = xefgSwapChainGetProperties(m_XeSSSwapChain, &properties);
    if (result == XEFG_SWAPCHAIN_RESULT_SUCCESS)
    {
        spdlog::info("XeSS-FG properties: required descriptors={}, temp buffer heap={}MB, temp texture heap={}MB, max interpolations={}",
            properties.requiredDescriptorCount,
            properties.tempBufferHeapSize / (1024 * 1024),
            properties.tempTextureHeapSize / (1024 * 1024),
            properties.maxSupportedInterpolations);
    }

    // Initialize from swap chain
    xefg_swapchain_d3d12_init_params_t initParams = {};
    initParams.pApplicationSwapChain = m_OriginalSwapChain;
    initParams.initFlags = XEFG_SWAPCHAIN_INIT_FLAG_NONE;
    initParams.maxInterpolatedFrames = 1; // Must be 1 for XeSS-FG
    initParams.creationNodeMask = 0;
    initParams.visibleNodeMask = 0;
    initParams.pTempBufferHeap = nullptr; // Let XeSS manage memory
    initParams.pTempTextureHeap = nullptr; // Let XeSS manage memory
    initParams.pPipelineLibrary = nullptr;
    initParams.uiMode = XEFG_SWAPCHAIN_UI_MODE_AUTO;

    result = xefgSwapChainD3D12InitFromSwapChain(m_XeSSSwapChain, m_CommandQueue, &initParams);
    if (result != XEFG_SWAPCHAIN_RESULT_SUCCESS)
    {
        spdlog::error("Failed to initialize XeSS swap chain: {}", result);
        return result;
    }

    // Get proxy swap chain
    result = xefgSwapChainD3D12GetSwapChainPtr(m_XeSSSwapChain, IID_PPV_ARGS(&m_ProxySwapChain));
    if (result != XEFG_SWAPCHAIN_RESULT_SUCCESS)
    {
        spdlog::error("Failed to get XeSS proxy swap chain: {}", result);
        return result;
    }

    spdlog::info("XeSS Frame Generation context initialized successfully");
    return XEFG_SWAPCHAIN_RESULT_SUCCESS;
}

xell_result_t XeSSFrameInterpolator::InitializeXeLLContext()
{
    // Create XeLL context
    auto result = xellCreateContext(&m_XeLLContext);
    if (result != XELL_RESULT_SUCCESS)
    {
        spdlog::error("Failed to create XeLL context: {}", result);
        return result;
    }

    // Setup XeLL logging
    xellSetLoggingCallback(m_XeLLContext, XELL_LOGGING_LEVEL_INFO, XeLLLogCallback);

    // Configure XeLL for low latency mode
    xell_sleep_params_t sleepParams = {};
    sleepParams.bLowLatencyMode = 1;
    sleepParams.bLowLatencyBoost = 0;
    sleepParams.minimumIntervalUs = 0; // No FPS capping

    result = xellSetSleepMode(m_XeLLContext, &sleepParams);
    if (result != XELL_RESULT_SUCCESS)
    {
        spdlog::warn("Failed to set XeLL sleep mode: {}", result);
    }

    spdlog::info("XeLL context initialized successfully");
    return XELL_RESULT_SUCCESS;
}

void XeSSFrameInterpolator::SetupLoggingCallbacks()
{
    if (m_XeSSSwapChain)
    {
        xefgSwapChainSetLoggingCallback(
            m_XeSSSwapChain,
            XEFG_SWAPCHAIN_LOGGING_LEVEL_INFO,
            XeSSLogCallback,
            this
        );
    }
}

bool XeSSFrameInterpolator::ConvertNGXParametersToXeSSResources(
    NGXInstanceParameters* NGXParameters,
    xefg_swapchain_d3d12_resource_data_t* OutResourceData)
{
    if (!NGXParameters || !OutResourceData)
        return false;

    // Initialize all resources to null
    for (int i = 0; i < XEFG_SWAPCHAIN_RES_COUNT; ++i)
    {
        OutResourceData[i] = {};
        OutResourceData[i].type = static_cast<xefg_swapchain_resource_type_t>(i);
        OutResourceData[i].validity = XEFG_SWAPCHAIN_RV_UNTIL_NEXT_PRESENT;
        OutResourceData[i].resourceBase = { 0, 0 };
        OutResourceData[i].resourceSize = { m_SwapchainWidth, m_SwapchainHeight };
        OutResourceData[i].pResource = nullptr;
        OutResourceData[i].incomingState = D3D12_RESOURCE_STATE_COMMON;
    }

    // Load backbuffer (HUD-less color)
    ID3D12Resource* backbuffer = nullptr;
    if (NGXParameters->GetVoidPointer("DLSSG.Backbuffer", (void**)&backbuffer) == NGX_SUCCESS && backbuffer)
    {
        OutResourceData[XEFG_SWAPCHAIN_RES_HUDLESS_COLOR].pResource = backbuffer;
        OutResourceData[XEFG_SWAPCHAIN_RES_HUDLESS_COLOR].incomingState = D3D12_RESOURCE_STATE_PRESENT;
    }

    // Load depth buffer
    ID3D12Resource* depth = nullptr;
    if (NGXParameters->GetVoidPointer("DLSSG.Depth", (void**)&depth) == NGX_SUCCESS && depth)
    {
        OutResourceData[XEFG_SWAPCHAIN_RES_DEPTH].pResource = depth;
        OutResourceData[XEFG_SWAPCHAIN_RES_DEPTH].incomingState = D3D12_RESOURCE_STATE_DEPTH_READ;
    }

    // Load motion vectors
    ID3D12Resource* motionVectors = nullptr;
    if (NGXParameters->GetVoidPointer("DLSSG.MotionVectors", (void**)&motionVectors) == NGX_SUCCESS && motionVectors)
    {
        OutResourceData[XEFG_SWAPCHAIN_RES_MOTION_VECTOR].pResource = motionVectors;
        OutResourceData[XEFG_SWAPCHAIN_RES_MOTION_VECTOR].incomingState = D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE;
    }

    // Load UI texture (if available)
    ID3D12Resource* uiTexture = nullptr;
    if (NGXParameters->GetVoidPointer("DLSSG.UITexture", (void**)&uiTexture) == NGX_SUCCESS && uiTexture)
    {
        OutResourceData[XEFG_SWAPCHAIN_RES_UI].pResource = uiTexture;
        OutResourceData[XEFG_SWAPCHAIN_RES_UI].incomingState = D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE;
    }

    // Load backbuffer for UI composition
    if (backbuffer)
    {
        OutResourceData[XEFG_SWAPCHAIN_RES_BACKBUFFER].pResource = backbuffer;
        OutResourceData[XEFG_SWAPCHAIN_RES_BACKBUFFER].incomingState = D3D12_RESOURCE_STATE_PRESENT;
    }

    return true;
}

bool XeSSFrameInterpolator::BuildFrameConstants(
    NGXInstanceParameters* NGXParameters,
    xefg_swapchain_frame_constant_data_t* OutConstants)
{
    if (!NGXParameters || !OutConstants)
        return false;

    // Initialize frame constants
    memset(OutConstants, 0, sizeof(*OutConstants));

    // Get view matrix
    float* viewMatrix = nullptr;
    if (NGXParameters->GetVoidPointer("DLSSG.ViewMatrix", (void**)&viewMatrix) == NGX_SUCCESS && viewMatrix)
    {
        memcpy(OutConstants->viewMatrix, viewMatrix, sizeof(OutConstants->viewMatrix));
    }

    // Get projection matrix
    float* projMatrix = nullptr;
    if (NGXParameters->GetVoidPointer("DLSSG.ProjectionMatrix", (void**)&projMatrix) == NGX_SUCCESS && projMatrix)
    {
        memcpy(OutConstants->projectionMatrix, projMatrix, sizeof(OutConstants->projectionMatrix));
    }

    // Get jitter values
    OutConstants->jitterOffsetX = NGXParameters->GetFloatOrDefault("DLSSG.JitterX", 0.0f);
    OutConstants->jitterOffsetY = NGXParameters->GetFloatOrDefault("DLSSG.JitterY", 0.0f);

    // Get motion vector scale
    OutConstants->motionVectorScaleX = NGXParameters->GetFloatOrDefault("DLSSG.MotionVectorScaleX", 1.0f);
    OutConstants->motionVectorScaleY = NGXParameters->GetFloatOrDefault("DLSSG.MotionVectorScaleY", 1.0f);

    // Reset history flag
    OutConstants->resetHistory = NGXParameters->GetUIntOrDefault("DLSSG.ResetHistory", 0);

    // Frame render time (not available in NGX, set to 0)
    OutConstants->frameRenderTime = 0.0f;

    return true;
}

void XeSSFrameInterpolator::QueryHDRLuminanceRange(NGXInstanceParameters* NGXParameters)
{
    if (!NGXParameters || m_HDRLuminanceRangeSet)
        return;

    // Try to get HDR luminance range from NGX parameters
    float minLuminance = NGXParameters->GetFloatOrDefault("DLSSG.HDRMinLuminance", 0.0001f);
    float maxLuminance = NGXParameters->GetFloatOrDefault("DLSSG.HDRMaxLuminance", 1000.0f);

    if (minLuminance > 0.0f && maxLuminance > minLuminance)
    {
        m_HDRLuminanceRange[0] = minLuminance;
        m_HDRLuminanceRange[1] = maxLuminance;
        m_HDRLuminanceRangeSet = true;
        spdlog::info("HDR luminance range: {} - {}", minLuminance, maxLuminance);
    }
}

bool XeSSFrameInterpolator::GetD3D12Resources(NGXInstanceParameters* NGXParameters)
{
    if (!NGXParameters)
        return false;

    // Get D3D12 device
    if (!m_D3D12Device)
    {
        if (NGXParameters->GetVoidPointer("DLSSG.D3D12Device", (void**)&m_D3D12Device) != NGX_SUCCESS || !m_D3D12Device)
        {
            spdlog::error("Failed to get D3D12 device from NGX parameters");
            return false;
        }
    }

    // Get command queue
    if (!m_CommandQueue)
    {
        if (NGXParameters->GetVoidPointer("DLSSG.CommandQueue", (void**)&m_CommandQueue) != NGX_SUCCESS || !m_CommandQueue)
        {
            spdlog::error("Failed to get command queue from NGX parameters");
            return false;
        }
    }

    // Get original swap chain
    if (!m_OriginalSwapChain)
    {
        if (NGXParameters->GetVoidPointer("DLSSG.SwapChain", (void**)&m_OriginalSwapChain) != NGX_SUCCESS || !m_OriginalSwapChain)
        {
            spdlog::error("Failed to get swap chain from NGX parameters");
            return false;
        }
    }

    return true;
}

void XeSSFrameInterpolator::XeSSLogCallback(const char* message, xefg_swapchain_logging_level_t level, void* userData)
{
    switch (level)
    {
    case XEFG_SWAPCHAIN_LOGGING_LEVEL_DEBUG:
        spdlog::debug("[XeSS-FG] {}", message);
        break;
    case XEFG_SWAPCHAIN_LOGGING_LEVEL_INFO:
        spdlog::info("[XeSS-FG] {}", message);
        break;
    case XEFG_SWAPCHAIN_LOGGING_LEVEL_WARNING:
        spdlog::warn("[XeSS-FG] {}", message);
        break;
    case XEFG_SWAPCHAIN_LOGGING_LEVEL_ERROR:
        spdlog::error("[XeSS-FG] {}", message);
        break;
    }
}

void XeSSFrameInterpolator::XeLLLogCallback(const char* message, xell_logging_level_t level)
{
    switch (level)
    {
    case XELL_LOGGING_LEVEL_DEBUG:
        spdlog::debug("[XeLL] {}", message);
        break;
    case XELL_LOGGING_LEVEL_INFO:
        spdlog::info("[XeLL] {}", message);
        break;
    case XELL_LOGGING_LEVEL_WARNING:
        spdlog::warn("[XeLL] {}", message);
        break;
    case XELL_LOGGING_LEVEL_ERROR:
        spdlog::error("[XeLL] {}", message);
        break;
    }
}

void XeSSFrameInterpolator::DestroyXeSSContext()
{
    if (m_XeSSSwapChain)
    {
        xefgSwapChainDestroy(m_XeSSSwapChain);
        m_XeSSSwapChain = nullptr;
    }

    if (m_ProxySwapChain)
    {
        m_ProxySwapChain->Release();
        m_ProxySwapChain = nullptr;
    }

    m_Initialized = false;
}

void XeSSFrameInterpolator::DestroyXeLLContext()
{
    if (m_XeLLContext)
    {
        xellDestroyContext(m_XeLLContext);
        m_XeLLContext = nullptr;
    }
}