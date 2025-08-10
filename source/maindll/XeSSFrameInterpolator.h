#pragma once

#include <d3d12.h>
#include <dxgi.h>
#include <dxgi1_5.h>
#include <memory>
#include <optional>
#include "NGX/NvNGX.h"

// XeSS Frame Generation includes
#include "xess_fg/xefg_swapchain.h"
#include "xess_fg/xefg_swapchain_d3d12.h"
#include "xell/xell.h"

struct NGXInstanceParameters;

class XeSSFrameInterpolator
{
private:
    // XeSS Frame Generation context
    xefg_swapchain_handle_t m_XeSSSwapChain = nullptr;
    
    // XeLL context for latency reduction (required for XeSS-FG)
    xell_context_handle_t m_XeLLContext = nullptr;
    
    // Proxy swap chain that replaces the application swap chain
    IDXGISwapChain4* m_ProxySwapChain = nullptr;
    
    // Original application swap chain
    IDXGISwapChain* m_OriginalSwapChain = nullptr;
    
    // D3D12 device and command queue
    ID3D12Device* m_D3D12Device = nullptr;
    ID3D12CommandQueue* m_CommandQueue = nullptr;
    
    // Frame tracking
    uint32_t m_PresentId = 0;
    uint32_t m_FrameId = 0;
    
    // Configuration
    const uint32_t m_SwapchainWidth;
    const uint32_t m_SwapchainHeight;
    
    // State
    bool m_Initialized = false;
    bool m_Enabled = true;
    
    // HDR configuration
    float m_HDRLuminanceRange[2] = { 0.0001f, 1000.0f };
    bool m_HDRLuminanceRangeSet = false;

public:
    XeSSFrameInterpolator(uint32_t OutputWidth, uint32_t OutputHeight);
    XeSSFrameInterpolator(const XeSSFrameInterpolator&) = delete;
    XeSSFrameInterpolator& operator=(const XeSSFrameInterpolator&) = delete;
    virtual ~XeSSFrameInterpolator();

    // Main dispatch function that replaces FSR 3 frame generation
    xefg_swapchain_result_t Dispatch(void* CommandList, NGXInstanceParameters* NGXParameters);
    
    // Get the proxy swap chain that should be used instead of the original
    IDXGISwapChain4* GetProxySwapChain() const { return m_ProxySwapChain; }
    
    // Check if XeSS Frame Generation is available and supported
    static bool IsSupported(ID3D12Device* Device);

protected:
    // Initialize XeSS Frame Generation context
    virtual xefg_swapchain_result_t InitializeXeSSContext(NGXInstanceParameters* NGXParameters);
    
    // Initialize XeLL context for latency reduction
    virtual xell_result_t InitializeXeLLContext();
    
    // Setup logging callbacks
    virtual void SetupLoggingCallbacks();
    
    // Convert NGX parameters to XeSS resource data
    virtual bool ConvertNGXParametersToXeSSResources(
        NGXInstanceParameters* NGXParameters,
        xefg_swapchain_d3d12_resource_data_t* OutResourceData);
    
    // Build frame constants from NGX parameters
    virtual bool BuildFrameConstants(
        NGXInstanceParameters* NGXParameters,
        xefg_swapchain_frame_constant_data_t* OutConstants);
    
    // Query HDR luminance range from NGX parameters
    virtual void QueryHDRLuminanceRange(NGXInstanceParameters* NGXParameters);
    
    // Get D3D12 device and command queue from NGX parameters
    virtual bool GetD3D12Resources(NGXInstanceParameters* NGXParameters);

private:
    // Logging callbacks
    static void XeSSLogCallback(const char* message, xefg_swapchain_logging_level_t level, void* userData);
    static void XeLLLogCallback(const char* message, xell_logging_level_t level);
    
    // Cleanup resources
    void DestroyXeSSContext();
    void DestroyXeLLContext();
};