#pragma once
#include <string>

namespace Util
{
#ifdef LINUX_BUILD
	const std::string& GetThisDllPath();
	bool GetSetting(const char* Key, bool DefaultValue);
	bool IsXeSSSupported();
	std::string GetGPUInfo();
#else
	const std::wstring& GetThisDllPath();
	bool GetSetting(const wchar_t* Key, bool DefaultValue);
#endif
	void InitializeLog();
}
