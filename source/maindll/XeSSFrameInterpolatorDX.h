#pragma once

#include <d3d12.h>
#include <memory>
#include "XeSSFrameInterpolator.h"

struct NGXInstanceParameters;

class XeSSFrameInterpolatorDX : public XeSSFrameInterpolator
{
private:
    ID3D12Device* m_D3D12Device = nullptr;

public:
    XeSSFrameInterpolatorDX(ID3D12Device* Device, uint32_t OutputWidth, uint32_t OutputHeight, NGXInstanceParameters* NGXParameters);
    XeSSFrameInterpolatorDX(const XeSSFrameInterpolatorDX&) = delete;
    XeSSFrameInterpolatorDX& operator=(const XeSSFrameInterpolatorDX&) = delete;
    ~XeSSFrameInterpolatorDX();

    // Main dispatch function for DirectX 12
    xefg_swapchain_result_t Dispatch(ID3D12GraphicsCommandList* CommandList, NGXInstanceParameters* NGXParameters);

protected:
    // Override to provide DirectX 12 specific initialization
    xefg_swapchain_result_t InitializeXeSSContext(NGXInstanceParameters* NGXParameters) override;
    
    // Get D3D12 device and command queue from NGX parameters
    bool GetD3D12Resources(NGXInstanceParameters* NGXParameters) override;

private:
    // Store D3D12 device reference
    void StoreD3D12Device(ID3D12Device* Device);
};