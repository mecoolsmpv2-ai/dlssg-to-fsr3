#include <iostream>
#include "Util.h"

int main()
{
    std::cout << "=== XeSS Mod Linux Test ===" << std::endl;
    
    // Test utility functions
    Util::InitializeLog();
    
    std::cout << "DLL Path: " << Util::GetThisDllPath() << std::endl;
    
    // Test settings
    bool debugOverlay = Util::GetSetting("EnableDebugOverlay", false);
    std::cout << "Debug Overlay: " << (debugOverlay ? "Enabled" : "Disabled") << std::endl;
    
    // Test XeSS support
    bool xessSupported = Util::IsXeSSSupported();
    std::cout << "XeSS Support: " << (xessSupported ? "Available" : "Not Available") << std::endl;
    
    // Test GPU info
    std::string gpuInfo = Util::GetGPUInfo();
    std::cout << "GPU Info: " << gpuInfo << std::endl;
    
    std::cout << "=== Test Completed ===" << std::endl;
    return 0;
}