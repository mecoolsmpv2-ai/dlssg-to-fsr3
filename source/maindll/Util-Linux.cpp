#include <iostream>
#include <fstream>
#include <string>
#include <cstdlib>
#include <cstring>
#include <unistd.h>
#include <dlfcn.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <pwd.h>
#include <linux/limits.h>

#ifdef LINUX_BUILD
#include "Util.h"

namespace Util
{
    const std::string& GetThisDllPath()
    {
        const static std::string finalPath = [&]()
        {
            char path[PATH_MAX] = {};
            char result[PATH_MAX] = {};
            
            // Get the path of the current executable
            ssize_t len = readlink("/proc/self/exe", path, sizeof(path) - 1);
            if (len != -1) {
                path[len] = '\0';
                
                // Find the last directory separator
                char* lastSlash = strrchr(path, '/');
                if (lastSlash) {
                    *(lastSlash + 1) = '\0';
                    strcpy(result, path);
                }
            }
            
            return std::string(result);
        }();

        return finalPath;
    }

    void InitializeLog()
    {
        static bool once = []()
        {
            const auto fullPath = GetThisDllPath() + "dlssg_to_xess.log";
            std::cout << "[INFO] Initializing log to: " << fullPath << std::endl;
            return true;
        }();
    }

    bool GetSetting(const char* Key, bool DefaultValue)
    {
        // Check environment variable first
        std::string envKey = "DLSSGTOXESS_" + std::string(Key);
        const char* envValue = std::getenv(envKey.c_str());
        if (envValue) {
            return std::string(envValue) == "1";
        }

        // Check INI file
        const std::string iniPath = GetThisDllPath() + "dlssg_to_xess.ini";
        std::ifstream iniFile(iniPath);
        if (iniFile.is_open()) {
            std::string line;
            while (std::getline(iniFile, line)) {
                if (line.find("[Debug]") != std::string::npos) {
                    while (std::getline(iniFile, line)) {
                        if (line.find("=") != std::string::npos) {
                            size_t pos = line.find("=");
                            std::string key = line.substr(0, pos);
                            std::string value = line.substr(pos + 1);
                            
                            // Trim whitespace
                            key.erase(0, key.find_first_not_of(" \t"));
                            key.erase(key.find_last_not_of(" \t") + 1);
                            value.erase(0, value.find_first_not_of(" \t"));
                            value.erase(value.find_last_not_of(" \t") + 1);
                            
                            if (key == Key) {
                                return value == "1" || value == "true" || value == "True";
                            }
                        }
                    }
                }
            }
        }

        return DefaultValue;
    }

    // Linux-specific utility functions
    bool IsXeSSSupported()
    {
        // Check if XeSS libraries are available
        void* xessLib = dlopen("libxess_fg.so", RTLD_NOW);
        if (xessLib) {
            dlclose(xessLib);
            return true;
        }
        
        // Try Windows DLLs (for Wine compatibility)
        xessLib = dlopen("libxess_fg.dll", RTLD_NOW);
        if (xessLib) {
            dlclose(xessLib);
            return true;
        }
        
        return false;
    }

    std::string GetGPUInfo()
    {
        // Try to get GPU information from /proc
        std::ifstream gpuFile("/proc/driver/nvidia/gpus/0/information");
        if (gpuFile.is_open()) {
            std::string line;
            std::getline(gpuFile, line);
            return line;
        }
        
        // Try to get from lspci
        FILE* pipe = popen("lspci | grep -i vga", "r");
        if (pipe) {
            char buffer[256];
            std::string result;
            while (fgets(buffer, sizeof(buffer), pipe) != NULL) {
                result += buffer;
            }
            pclose(pipe);
            return result;
        }
        
        return "Unknown GPU";
    }
}

#else
// Windows version (original)
#include <spdlog/sinks/basic_file_sink.h>
#include <Windows.h>
#include "Util.h"

namespace Util
{
    const std::wstring& GetThisDllPath()
    {
        const static std::wstring finalPath = [&]()
        {
            wchar_t path[2048] = {};
            HMODULE thisModuleHandle = nullptr;

            GetModuleHandleExW(
                GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                reinterpret_cast<LPCWSTR>(&GetThisDllPath),
                &thisModuleHandle);

            if (GetModuleFileNameW(thisModuleHandle, path, std::size(path)))
            {
                // Chop off the file name
                for (auto i = static_cast<ptrdiff_t>(wcslen(path)) - 1; i > 0; i--)
                {
                    if (path[i] == L'\\' || path[i] == L'/')
                    {
                        path[i + 1] = 0;
                        break;
                    }
                }
            }

            return std::wstring(path);
        }();

        return finalPath;
    }

    void InitializeLog()
    {
        static bool once = []()
        {
            const auto fullPath = GetThisDllPath() + L"\\dlssg_to_xess.log";
            char convertedPath[2048] = {};

            if (wcstombs_s(nullptr, convertedPath, fullPath.c_str(), std::size(convertedPath)) == 0)
            {
                auto logger = spdlog::basic_logger_mt("file_logger", convertedPath, true);
                logger->set_level(spdlog::level::level_enum::trace);
                logger->set_pattern("[%H:%M:%S] [%l] %v"); // [HH:MM:SS] [Level] Message
                logger->flush_on(logger->level());
                spdlog::set_default_logger(std::move(logger));
            }

            return true;
        }();
    }

    bool GetSetting(const wchar_t *Key, bool DefaultValue)
    {
        wchar_t envKey[256];
        swprintf_s(envKey, L"DLSSGTOXESS_%s", Key);

        if (wchar_t v[2]; GetEnvironmentVariableW(envKey, v, std::size(v)) == 1)
            return v[0] == L'1';

        const static auto iniPath = GetThisDllPath() + L"\\dlssg_to_xess.ini";
        return GetPrivateProfileIntW(L"Debug", Key, DefaultValue, iniPath.c_str()) != 0;
    }
}
#endif