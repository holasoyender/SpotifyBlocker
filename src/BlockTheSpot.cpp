#include "stdafx.h"

void __stdcall LoadAPI(LPVOID *destination, LPCSTR apiName)
{
	if (*destination)
		return;

	char path[MAX_PATH];
	wsprintf(path, ".\\chrome_elf_bak.dll");
	HMODULE hModule = GetModuleHandle(path);
	if (!hModule && !(hModule = LoadLibrary(path)))
		return;
	*destination = GetProcAddress(hModule, apiName);
}

#define API_EXPORT_ORIG(N)                                                                                         \
	static LPVOID _##N = NULL;                                                                                     \
	char S_##N[] = "" #N;                                                                                          \
	extern "C" __declspec(dllexport) __declspec(naked) void N##()                                                  \
	{                                                                                                              \
		__asm pushad __asm push offset S_##N __asm push offset _##N __asm call LoadAPI __asm popad __asm jmp[_##N] \
	}

API_EXPORT_ORIG(ClearReportsBetween_ExportThunk)
API_EXPORT_ORIG(CrashForException_ExportThunk)
API_EXPORT_ORIG(DisableHook)
API_EXPORT_ORIG(DrainLog)
API_EXPORT_ORIG(DumpHungProcessWithPtype_ExportThunk)
API_EXPORT_ORIG(DumpProcessWithoutCrash)
API_EXPORT_ORIG(GetApplyHookResult)
API_EXPORT_ORIG(GetBlockedModulesCount)
API_EXPORT_ORIG(GetCrashReports_ExportThunk)
API_EXPORT_ORIG(GetCrashpadDatabasePath_ExportThunk)
API_EXPORT_ORIG(GetHandleVerifier)
API_EXPORT_ORIG(GetInstallDetailsPayload)
API_EXPORT_ORIG(GetUniqueBlockedModulesCount)
API_EXPORT_ORIG(GetUserDataDirectoryThunk)
API_EXPORT_ORIG(InjectDumpForHungInput_ExportThunk)
API_EXPORT_ORIG(IsBrowserProcess)
API_EXPORT_ORIG(IsCrashReportingEnabledImpl)
API_EXPORT_ORIG(IsThirdPartyInitialized)
API_EXPORT_ORIG(RegisterLogNotification)
API_EXPORT_ORIG(RequestSingleCrashUpload_ExportThunk)
API_EXPORT_ORIG(SetCrashKeyValueImpl)
API_EXPORT_ORIG(SetMetricsClientId)
API_EXPORT_ORIG(SetUploadConsent_ExportThunk)
API_EXPORT_ORIG(SignalChromeElf)
API_EXPORT_ORIG(SignalInitializeCrashReporting)

#define API_COPY(M, N) \
	_##N = GetProcAddress(M, #N);