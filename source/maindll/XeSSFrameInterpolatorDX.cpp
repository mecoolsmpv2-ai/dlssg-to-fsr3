#include <d3d12.h>
#include <dxgi.h>
#include <spdlog/spdlog.h>
#include "XeSSFrameInterpolatorDX.h"
#include "NGX/NvNGX.h"

XeSSFrameInterpolatorDX::XeSSFrameInterpolatorDX(ID3D12Device* Device, uint32_t OutputWidth, uint32_t OutputHeight, NGXInstanceParameters* NGXParameters)
    : XeSSFrameInterpolator(OutputWidth, OutputHeight)
{
    StoreD3D12Device(Device);
    spdlog::info("XeSS Frame Interpolator DX12 initialized for {}x{}", OutputWidth, OutputHeight);
}

XeSSFrameInterpolatorDX::~XeSSFrameInterpolatorDX()
{
    if (m_D3D12Device)
    {
        m_D3D12Device->Release();
        m_D3D12Device = nullptr;
    }
    spdlog::info("XeSS Frame Interpolator DX12 destroyed");
}

xefg_swapchain_result_t XeSSFrameInterpolatorDX::Dispatch(ID3D12GraphicsCommandList* CommandList, NGXInstanceParameters* NGXParameters)
{
    if (!CommandList || !NGXParameters)
        return XEFG_SWAPCHAIN_RESULT_ERROR_INVALID_ARGUMENT;

    // Call the base class dispatch with the command list
    return XeSSFrameInterpolator::Dispatch(CommandList, NGXParameters);
}

xefg_swapchain_result_t XeSSFrameInterpolatorDX::InitializeXeSSContext(NGXInstanceParameters* NGXParameters)
{
    if (!m_D3D12Device)
    {
        spdlog::error("D3D12 device not available for XeSS initialization");
        return XEFG_SWAPCHAIN_RESULT_ERROR_INVALID_ARGUMENT;
    }

    // Check if device supports XeSS Frame Generation
    if (!IsSupported(m_D3D12Device))
    {
        spdlog::error("D3D12 device does not support XeSS Frame Generation");
        return XEFG_SWAPCHAIN_RESULT_ERROR_UNSUPPORTED_DEVICE;
    }

    // Get D3D12 resources from NGX parameters
    if (!GetD3D12Resources(NGXParameters))
    {
        spdlog::error("Failed to get D3D12 resources from NGX parameters");
        return XEFG_SWAPCHAIN_RESULT_ERROR_INVALID_ARGUMENT;
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

    spdlog::info("XeSS Frame Generation DX12 context initialized successfully");
    return XEFG_SWAPCHAIN_RESULT_SUCCESS;
}

bool XeSSFrameInterpolatorDX::GetD3D12Resources(NGXInstanceParameters* NGXParameters)
{
    if (!NGXParameters)
        return false;

    // Use the stored D3D12 device
    if (!m_D3D12Device)
    {
        spdlog::error("D3D12 device not available");
        return false;
    }

    // Get command queue from NGX parameters
    if (!m_CommandQueue)
    {
        if (NGXParameters->GetVoidPointer("DLSSG.CommandQueue", (void**)&m_CommandQueue) != NGX_SUCCESS || !m_CommandQueue)
        {
            spdlog::error("Failed to get command queue from NGX parameters");
            return false;
        }
    }

    // Get original swap chain from NGX parameters
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

void XeSSFrameInterpolatorDX::StoreD3D12Device(ID3D12Device* Device)
{
    if (Device)
    {
        m_D3D12Device = Device;
        m_D3D12Device->AddRef(); // Add reference to prevent premature release
    }
}