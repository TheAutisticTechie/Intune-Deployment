@ECHO OFF
SETLOCAL EnableDelayedExpansion
rem: Description: Force removal tool for Security Agent

if "%INSTALL_RUNTIME_ROOT%" EQU "" (
	set INSTALL_RUNTIME_ROOT=%~dp0
) else (
	if not exist "%INSTALL_RUNTIME_ROOT%\helperUCInstallation.dll" (
		set INSTALL_RUNTIME_ROOT=%~dp0
	)
)


echo Security Agent Stopper Start [%DATE%][%TIME%]

echo Stop AMSP service
call :CHECKAMSPSERVICE
echo Check AMSP service result: %_RESULT%
if "%_RESULT%" EQU "1" (
    pushd "%INSTALL_RUNTIME_ROOT%"
    echo start /wait rundll32 "%INSTALL_RUNTIME_ROOT%\helperUCInstallation.dll",AMSP_PA_INST_RUNDLL32_Callback
    start /wait rundll32 "%INSTALL_RUNTIME_ROOT%\helperUCInstallation.dll",AMSP_PA_INST_RUNDLL32_Callback
    popd
)

echo Stop WFBS-SVC 6.1
echo Stop through StopClient.exe
"%INSTALL_RUNTIME_ROOT%\WFBS\StopClient.exe" /DISPLAY_CONSOLE /UNLOAD_CLIENT

echo Stop CSA 6.0 or earlier if it exists
if /I "%PROCESSOR_ARCHITECTURE%" EQU "AMD64" (
    echo Stop through svrSvcSetup_64x.exe
	"%INSTALL_RUNTIME_ROOT%\SvrSvcSetup_64x.exe" -stop_csa
) else (
echo Stop through svrSvcSetup.exe
"%INSTALL_RUNTIME_ROOT%\SvrSvcSetup.exe" -stop_csa
)


echo Kill WFBS-SVC running processes first for problems in versions 5.2 and before
call :KILLPROCESS HostedAgent.exe svcGenericHost.exe WFBSSUpdater.exe

echo Stop services
call :STOPSERVICE amsp tmlisten ntrtscan tmbmserver tmproxy tmpfw tmccsf svcGenericHost

if "%AGENT_DISABLE_SVC%" EQU "1" (
	echo Disable services
	call :DISABLESERVICE amsp tmlisten ntrtscan tmbmserver tmproxy tmpfw tmccsf svcGenericHost
)

echo Kill running processes
call :KILLPROCESS coreFrameworkHost.exe coreServiceShell.exe bspatch.exe uiWatchDog.exe uiSeAgnt.exe uiWinMgr.exe WSCStatusController.exe TmListen.exe WLauncher.exe
call :KILLPROCESS upgrade.exe TmUpgradeUI.exe
call :KILLPROCESS TmListen.exe NtRtScan.exe TmProxy.exe TmBmSrv.exe upgrade.exe xpupg.exe PccNTUpd.exe NtRmv.exe PccNtMon.exe TmPfw.exe
call :KILLPROCESS TMAS_OEMon.exe TMAS_WLMMon.exe tmccsf.exe bssattk.exe

echo Stop drivers
call :STOPSERVICE tmactmon tmevtmgr tmcomm vsapint tmfilter tmprefilter tmumh tmeevw tmusa

goto :EOF

:STOPSERVICE
set SERVICE_TO_STOP=%*
for %%p in (%SERVICE_TO_STOP%) do (
    echo net stop /y %%p
    net stop /y %%p
)
GOTO :EOF

:DISABLESERVICE
set SERVICE_TO_DISABLE=%*
for %%p in (%SERVICE_TO_DISABLE%) do (
    echo sc config %%p start= disabled
    sc config %%p start= disabled
)
GOTO :EOF

:KILLPROCESS
set IMAGENAME_TO_KILL=%*
for %%p in (%IMAGENAME_TO_KILL%) do (
    echo killing process: %%p
   
    for /F "tokens=2" %%t in ('TASKLIST /NH /FI "IMAGENAME eq %%p"' ) do (
        echo TASKKILL /F /PID %%t
        TASKKILL /F /PID %%t
    )
)
GOTO :EOF

:CHECKVCREDIST
set _RESULT=0
set PROD_CODE=
set CRT_VER=
set CRT_TYPE=
for /F "tokens=1" %%c in ('reg query HKEY_CLASSES_ROOT\Installer\UpgradeCodes\AA5D9C68C00F12943B2F6CA09FE28244 ^| find /I "REG_SZ"') do (
    set PROD_CODE=%%c
)
if not "%PROD_CODE%"=="" (
    for /F "tokens=2,3" %%u in ('reg query HKEY_CLASSES_ROOT\Installer\Products\%PROD_CODE% /v Version ^| find /I "REG_DWORD" ^| find /I ^"Version^"') do (
        set CRT_TYPE=%%u
        set CRT_VER=%%v
    )
)
if not "%PROD_CODE%"=="" (
    if "%CRT_TYPE%"=="REG_DWORD" (
        echo VC++ redistributrable version: %CRT_VER%
        if "%CRT_VER%" GEQ "0x800dc10" (
            set _RESULT=1
        )
    )
)
GOTO :EOF

:CHECKAMSPSERVICE
set _RESULT=0
set AMSP_STATUS=
for /f "tokens=4" %%a in ('sc query amsp ^| findstr /I "STATE"') do (
    set AMSP_STATUS=%%a
)
if not "%AMSP_STATUS%"=="" (
    if not "%AMSP_STATUS%"=="STOPPED" (
        set _RESULT=1
    )
)
GOTO :EOF

:EOF

 rem Built with WFBS 20.0.2128 
