@ECHO OFF
SETLOCAL EnableDelayedExpansion
rem: Description: Force removal tool for Security Agent

set INSTALL_RUNTIME_ROOT=%~dp0

rem: query installed folder from registry key
echo Finding Security Agent 7...
call :GETREGFOLDER "HKLM\Software\TrendMicro\Wofie\CurrentVersion" "Application Path"
set PRODUCT_ROOT=%_REGFOLDER%
if EXIST "%PRODUCT_ROOT%" (
	set PRODUCT_ROOT_7=!PRODUCT_ROOT!
)

if NOT EXIST "%PRODUCT_ROOT%" (
	echo Finding 32-bit common client...
	call :GETREGFOLDER "HKLM\Software\TrendMicro\PC-cillinNTCorp\CurrentVersion" "Application Path"
	set PRODUCT_ROOT=!_REGFOLDER!
	set PRODUCT_ROOT_6=!PRODUCT_ROOT!
)
if NOT EXIST "%PRODUCT_ROOT%" (
	echo Finding 64-bit common client...
	call :GETREGFOLDER "HKLM\Software\Wow6432Node\TrendMicro\PC-cillinNTCorp\CurrentVersion" "Application Path"
	set PRODUCT_ROOT=!_REGFOLDER!
	set PRODUCT_ROOT_6=!PRODUCT_ROOT!
)
if /I "%PROCESSOR_ARCHITECTURE%" EQU "AMD64" (
	echo Running in WOW6432 environment.
	if NOT EXIST "!PRODUCT_ROOT!" (
		set PRODUCT_ROOT=!ProgramFiles^(x86^)!\Trend Micro\Security Agent\
	)
	if NOT EXIST "!PRODUCT_ROOT_7!" (
		set PRODUCT_ROOT_7=!ProgramW6432!\Trend Micro\Security Agent\
	)
) else (
	echo Running in native environment.
	if NOT EXIST "!PRODUCT_ROOT!" (
		set PRODUCT_ROOT=!ProgramFiles!\Trend Micro\Security Agent\
	)
	if NOT EXIST "!PRODUCT_ROOT_7!" (
		set PRODUCT_ROOT_7=!ProgramFiles!\Trend Micro\Security Agent\
	)
)
if NOT EXIST "%PRODUCT_ROOT_6%" (
	if /I "!PROCESSOR_ARCHITECTURE!" EQU "AMD64" (
		set PRODUCT_ROOT_6=!ProgramFiles^(x86^)!\Trend Micro\Client Server Security Agent\
	) else (
		if /I "!PROCESSOR_ARCHITEW6432!" EQU "AMD64" (
			set PRODUCT_ROOT_6=!ProgramFiles^(x86^)!\Trend Micro\Client Server Security Agent\
		) else (
			set PRODUCT_ROOT_6=!ProgramFiles!\Trend Micro\Client Server Security Agent\
		)
	)
)

echo Security Agent installed at: %PRODUCT_ROOT%
echo Client-Server Security Agent installed at: %PRODUCT_ROOT_6%
echo Security Agent 7 installed at: %PRODUCT_ROOT_7%

echo Finding Anti-Malware Solution Platform...
call :GETREGFOLDER "HKLM\Software\TrendMicro\AMSP" InstallDir
set INSTALL_ROOT=%_REGFOLDER%
if NOT EXIST "%INSTALL_ROOT%AMSP" (
	call :GETFOLDER "!PRODUCT_ROOT!..\"
	set INSTALL_ROOT=!_RESULT!
)
if NOT EXIST "%INSTALL_ROOT%AMSP" (
	if /I "!PROCESSOR_ARCHITEW6432!" EQU "AMD64" (
		set INSTALL_ROOT=!ProgramW6432!\Trend Micro\
	) else (
		set INSTALL_ROOT=!ProgramFiles!\Trend Micro\
	)
)

echo AMSP installed at: %INSTALL_ROOT%AMSP


echo Security Agent Remover Start [%DATE%][%TIME%]

set AGENT_DISABLE_SVC=1
call :DECRYPT_BITLOCKER
call "%INSTALL_RUNTIME_ROOT%AgentStop.bat"

echo Delete services which need Local System Account Privileges
echo %INSTALL_RUNTIME_ROOT%
"%INSTALL_RUNTIME_ROOT%\WFBS\ServiceRemoveTool.exe" -install
"%INSTALL_RUNTIME_ROOT%\WFBS\ServiceRemoveTool.exe" -runonce

echo Remove AMSP, Communicator, Eagle Eye and AEGIS drivers
call :DELSERVICE amsp tmactmon tmevtmgr tmcomm 
call :DELSERVICE tmcomm tmlisten ntrtscan tmbmserver tmprefilter vsapint tmfilter tmumh
call :DELSERVICE tmproxy tmpfw 
call :DELSERVICE tmeevw tmusa 
call :DELSERVICE tmccsf
call :DELSERVICE acagentservice acdriverhelper acdriver
call :DELSERVICE svcGenericHost
call :DELSERVICE TmWSCSvc

echo Stop and Remove Firewall drivers
call :GETWINMAJORVER
if %WINMAJORVER% LEQ 5 (
	call :FINDNSCUTIL ncfg.exe
	if exist "!_RESULT!" (
	    call :GETFOLDER "!_RESULT!"
        echo "!_RESULT!ncfg.exe" -ur tm_cfw 
             "!_RESULT!ncfg.exe" -ur tm_cfw 
        echo "!_RESULT!ncfg.exe" -c
             "!_RESULT!ncfg.exe" -c
        echo "!_RESULT!ncfg.exe" -X1
             "!_RESULT!ncfg.exe" -X1
        echo "!_RESULT!ncfg.exe" -S
             "!_RESULT!ncfg.exe" -S
	)
) else (
	call :FINDNSCUTIL tmlwfins.exe
	if exist "!_RESULT!" (
	    call :GETFOLDER "!_RESULT!"
	    echo "!_RESULT!tmlwfins.exe" -u tmlwf
	         "!_RESULT!tmlwfins.exe" -u tmlwf
	)
	
	call :FINDNSCUTIL tmwfpins.exe
	if exist "!_RESULT!" (
	    call :GETFOLDER "!_RESULT!"
	    echo "!_RESULT!tmwfpins.exe" -u "!_RESULT!tmwfp.inf" 
	         "!_RESULT!tmwfpins.exe" -u "!_RESULT!tmwfp.inf" 
	)
)

echo Stop and Remove Proxy drivers
set TMTDI_REG=Software\TrendMicro\AMSP
call :FINDFILEBYNAME "%INSTALL_ROOT%AMSP\module\20004" tdiins.exe
if not exist "!_RESULT!" (
	call :FINDFILEBYNAME "%PRODUCT_ROOT%pfw_features" tdiins.exe
)
if not exist "!_RESULT!" (
	set TMTDI_REG=SOFTWARE\TrendMicro\NSC\TmProxy
	call :FINDFILEBYNAME "%PRODUCT_ROOT%" tdiins.exe
)
if exist "!_RESULT!" (
    call :GETFOLDER "!_RESULT!"
    echo "!_RESULT!tdiins.exe" -u "!_RESULT!tmtdi.inf" %TMTDI_REG% InfNameForTdi
         "!_RESULT!tdiins.exe" -u "!_RESULT!tmtdi.inf" %TMTDI_REG% InfNameForTdi
)

echo Force Remove Proxy drivers
if /I "%PROCESSOR_ARCHITECTURE%" EQU "AMD64" (
    set RSTRTMGR=%INSTALL_RUNTIME_ROOT%x64\RestartManager.exe
) else (
    if /I "%PROCESSOR_ARCHITEW6432%" EQU "AMD64" (
        set RSTRTMGR=%INSTALL_RUNTIME_ROOT%x64\RestartManager.exe
    ) else (
        set RSTRTMGR=%INSTALL_RUNTIME_ROOT%x86\RestartManager.exe
    )
)
echo Restart Manager "%RSTRTMGR%"
if exist "%RSTRTMGR%" (
    echo "%RSTRTMGR%" "%INSTALL_RUNTIME_ROOT%RemoveNSC.ini"
         "%RSTRTMGR%" "%INSTALL_RUNTIME_ROOT%RemoveNSC.ini"
)
call :REMOVE_BROWSER_PLUG_IN
call :REMOVE_SHELL_EXT
call :RMVTRENDPROTECT
call :REMOVE_WFBSS_UPDATER
call :REMOVE_DLP

echo Remove files
call :DELFOLDER "%INSTALL_ROOT%AMSP\"
call :DELFOLDER "%INSTALL_ROOT%UniClient\"
call :DELFOLDER "%PRODUCT_ROOT%..\BM"
call :DELFOLDER "%PRODUCT_ROOT%"
call :DELFOLDER "%PRODUCT_ROOT%..\WFBSSUpdater"
call :DELFOLDER "%WINDIR%\System32\tmumh\"
call :DELFOLDER "%WINDIR%\SysWOW64\tmumh\"
if EXIST "%PRODUCT_ROOT_6%" call :DELFOLDER "%PRODUCT_ROOT_6%"
if EXIST "%PRODUCT_ROOT_7%" call :DELFOLDER "%PRODUCT_ROOT_7%"

echo Remove Start Menu shortcuts
set _RESULT=%ALLUSERSPROFILE%\Start Menu\Programs\Trend Micro Worry-Free Business Security Agent
if exist "%_RESULT%" (
	call :DELFOLDER "%_RESULT%"
)
for /f "delims=" %%f in ('dir /b /s ^"!ALLUSERSPROFILE!^" ^| find /I ^"Business Security Agent^" ^| find /I /V ^".lnk^"') do (
	set _RESULT=%%f
)
if exist "%_RESULT%" (
	call :DELFOLDER "%_RESULT%"
)
for /f "delims=" %%f in ('dir /b /s ^"!ALLUSERSPROFILE!^" ^| find /I ^"Server Security Agent^" ^| find /I /V ^".lnk^"') do (
	set _RESULT=%%f
)
if exist "%_RESULT%" (
	call :DELFOLDER "%_RESULT%"
)
for /f "delims=" %%f in ('dir /b /s ^"!ALLUSERSPROFILE!^" ^| find /I ^"Security Agent^" ^| find /I /V ^".lnk^"') do (
	set _RESULT=%%f
)
if exist "%_RESULT%" (
	call :DELFOLDER "%_RESULT%"
)

echo Remove registry
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\TrendMicro\AMSP"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\TrendMicro\AMSP"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\TrendMicro\AMSP_INST"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\TrendMicro\AMSP_INST"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\TrendMicro\AMSPStatus"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\TrendMicro\AMSPStatus"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\TrendMicro\AMSPTest"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\TrendMicro\AMSPTest"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\TrendMicro\UniClient"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\TrendMicro\UniClient"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\TrendMicro\AEGIS"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\TrendMicro\AEGIS"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\TrendMicro\NSC"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\TrendMicro\NSC"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\TrendMicro\Wofie"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\TrendMicro\Wofie"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\TrendMicro\Vizor"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\TrendMicro\Vizor"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\TrendMicro\LoadHTTP"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\TrendMicro\LoadHTTP"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\TrendMicro\PC-cillinNTCorp"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\TrendMicro\PC-cillinNTCorp"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\TrendMicro\OfcWatchDog"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\TrendMicro\OfcWatchDog"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Wofie"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\HostedAgent"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\HostedAgent"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\OfficeScanNT"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\OfficeScanNT"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\TrendMicro\PC-cillin"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\TrendMicro\PC-cillin"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\TrendMicro\Osprey"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\TrendMicro\Osprey"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\TrendMicro\ClientStatus"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\TrendMicro\ClientStatus"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\TrendMicro\OEM"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\TrendMicro\OEM"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\TrendMicro\WFBSSUpdater"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\TrendMicro\WFBSSUpdater"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\TrendMicro\CPM"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\TrendMicro\CPM"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\Trendmicro\Endpoint Application Control Agent"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\tmumh"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\TrendMicro\ATTK"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\TrendMicro\ATTK"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\TrendMicro\housecall"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\TrendMicro\housecall"

echo Remove Windows Installer record of SA 10.0
"%INSTALL_RUNTIME_ROOT%msizap.exe" TW! {33BEF4B8-AFD3-4AF0-BD20-42F70A417266}
"%INSTALL_RUNTIME_ROOT%msizap.exe" TW! {1FF9FE5E-27A3-45F1-979B-85903EB3CFF1}

echo Remove Windows Installer record of SA 9.0
"%INSTALL_RUNTIME_ROOT%msizap.exe" TW! {C1F6E833-B25E-4C39-A026-D3253958B0D0}
"%INSTALL_RUNTIME_ROOT%msizap.exe" TW! {A38F51ED-D01A-4CE4-91EB-B824A00A8BDF}

echo Remove Windows Installer record of SA 8.0
"%INSTALL_RUNTIME_ROOT%msizap.exe" TW! {19D84BB4-35C9-4125-90AB-C2ADD0F9A8EC}
"%INSTALL_RUNTIME_ROOT%msizap.exe" TW! {8456195C-3BA3-45a4-A6A7-30AE7A62EADB}

echo Remove Windows Installer record of CSA 7.0
"%INSTALL_RUNTIME_ROOT%msizap.exe" TW! {0A07E717-BB5D-4B99-840B-6C5DED52B277}
rem call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{0A07E717-BB5D-4B99-840B-6C5DED52B277}"
rem call :DELREGISTRY "HKEY_CLASSES_ROOT\Installer\Features\717E70A0D5BB99B448B0C6D5DE252B77"
rem call :DELREGISTRY "HKEY_CLASSES_ROOT\Installer\Products\717E70A0D5BB99B448B0C6D5DE252B77"
rem call :DELREGISTRY "HKEY_CLASSES_ROOT\Installer\UpgradeCodes\8A88AE84D667B304CB368C99791A74A6"
echo Remove Windows Installer record of CSA 6.0 or earlier
"%INSTALL_RUNTIME_ROOT%msizap.exe" TW! {ECEA7878-2100-4525-915D-B09174E36971}

echo Remove Windows Installer record of WFBS-SVC
"%INSTALL_RUNTIME_ROOT%msizap.exe" TW! {BED0B8A2-2986-49F8-90D6-FA008D37A3D2}
rem MSIZAP misses Wow6432Node
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{BED0B8A2-2986-49F8-90D6-FA008D37A3D2}"

echo Cancel Ongoing Installation
"%INSTALL_RUNTIME_ROOT%msizap.exe" PS

echo Remove auto-startup programs
call :DELREGVALUE "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" "Trend Micro Client Framework"
call :DELREGVALUE "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" "OfficeScanNT Monitor"
call :DELREGVALUE "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" "OE"
call :DELREGVALUE "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run" "OfficeScanNT Monitor"
call :DELREGVALUE "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run" "OE"

echo Remove driver files
call :DELFILE %WINDIR%\system32\drivers\tmactmon.sys
call :DELFILE %WINDIR%\system32\drivers\tmevtmgr.sys
call :DELFILE %WINDIR%\system32\drivers\tmcomm.sys
call :DELFILE %WINDIR%\system32\drivers\tmeevw.sys
call :DELFILE %WINDIR%\system32\drivers\tmusa.sys
call :DELFILE %WINDIR%\system32\drivers\AcDriver.sys
call :DELFILE %WINDIR%\system32\drivers\AcDriverHelper.sys
call :DELFILE %WINDIR%\system32\drivers\tmumh.sys

echo remove INF and PNF files
"%INSTALL_RUNTIME_ROOT%\RemoveINF.exe"

call :RESTORE_WINDEFENDER_SETTING

if "%UNINST_LOG_PATH%" NEQ "" (
	if exist "%UNINST_LOG_PATH%" (
		copy /Y *.log "%UNINST_LOG_PATH%\"
		copy /Y AgentRemoval\*.log "%UNINST_LOG_PATH%\"
	)
)

rem end of the file!

goto :EOF


:REMOVE_SHELL_EXT
echo Stop and Un-register Shell Extensions
if exist "%INSTALL_ROOT%UniClient\UiFrmwrk\tmdshell.dll" (
    echo regsvr32 /u /s "%INSTALL_ROOT%UniClient\UiFrmwrk\tmdshell.dll"
         regsvr32 /u /s "%INSTALL_ROOT%UniClient\UiFrmwrk\tmdshell.dll"
    taskkill /F /IM explorer.exe >NUL 2>&1
    start explorer
)

if  "%PROCESSOR_ARCHITECTURE%" == "x86" (
    if exist "%PRODUCT_ROOT%TmdShell.dll" (
         echo regsvr32 /u /s "%PRODUCT_ROOT%TmdShell.dll"
         regsvr32 /u /s "%PRODUCT_ROOT%TmdShell.dll"
         taskkill /F /IM explorer.exe >NUL 2>&1
         start explorer
    )
) else (
    if exist "%PRODUCT_ROOT%TmdShell_64x.dll" (
         echo regsvr32 /u /s "%PRODUCT_ROOT%TmdShell_64x.dll"
         regsvr32 /u /s "%PRODUCT_ROOT%TmdShell_64x.dll"
         taskkill /F /IM explorer.exe >NUL 2>&1
         start explorer
    )
)

echo Remove shell extension
call :DELREGISTRY "HKEY_CLASSES_ROOT\*\shellex\ContextMenuHandlers\{48F45200-91E6-11CE-8A4F-0080C81A28D4}"
call :DELREGISTRY "HKEY_CLASSES_ROOT\CLSID\{48F45200-91E6-11CE-8A4F-0080C81A28D4}"
call :DELREGISTRY "HKEY_CLASSES_ROOT\DocShortcut\shellex\ContextMenuHandlers\{48F45200-91E6-11CE-8A4F-0080C81A28D4}"
call :DELREGISTRY "HKEY_CLASSES_ROOT\Folder\shellex\ContextMenuHandlers\{48F45200-91E6-11CE-8A4F-0080C81A28D4}"
call :DELREGISTRY "HKEY_CLASSES_ROOT\InternetShortcut\shellex\ContextMenuHandlers\{48F45200-91E6-11CE-8A4F-0080C81A28D4}"
call :DELREGISTRY "HKEY_CLASSES_ROOT\lnkfile\shellex\ContextMenuHandlers\{48F45200-91E6-11CE-8A4F-0080C81A28D4}"
call :DELREGISTRY "HKEY_CLASSES_ROOT\piffile\shellex\ContextMenuHandlers\{48F45200-91E6-11CE-8A4F-0080C81A28D4}"

call :DELREGISTRY "HKEY_CLASSES_ROOT\*\shellex\ContextMenuHandlers\OfficeScan NT"
call :DELREGISTRY "HKEY_CLASSES_ROOT\CLSID\{AF4F7471-FCFB-11d0-80B6-0080C838D5F9}"
call :DELREGISTRY "HKEY_CLASSES_ROOT\Directory\shellex\ContextMenuHandlers\OfficeScan NT"
call :DELREGISTRY "HKEY_CLASSES_ROOT\Drive\shellex\ContextMenuHandlers\OfficeScan NT"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\*\shellex\ContextMenuHandlers\OfficeScan NT"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{AF4F7471-FCFB-11d0-80B6-0080C838D5F9}"
call :DELREGISTRY "HKEY_CLASSES_ROOT\Directory\shellex\ContextMenuHandlers\OfficeScan NT"
call :DELREGISTRY "HKEY_CLASSES_ROOT\Drive\shellex\ContextMenuHandlers\OfficeScan NT"
GOTO :EOF

:GETREGFOLDER
set _REGFOLDER=
for /F "tokens=1,2 delims=:" %%a in ('REG QUERY %1 /v %2 ^|FINDSTR /I %2 2^>NUL') do (
    set DISK=%%a
    set FOLDER=%%b
    call :GETFOLDER "!DISK:~-1!:!FOLDER!\"
    set _REGFOLDER=!_RESULT!
)
GOTO :EOF


:FINDFILEBYNAME
set _FINDTHIS=%~f1
set _RESULT=
for /f "delims=" %%f in ('dir ^"!_FINDTHIS!^" /s /b ^| findstr /I %2') do (
    set _RESULT=%%f
)
GOTO :EOF

:GETFOLDER
set _RESULT=%~dp1
if "%_RESULT:~-1%" NEQ "\" set _RESULT=%_RESULT%\
GOTO :EOF

:DELSERVICE
set SERVICE_TO_DEL=%*
for %%p in (%SERVICE_TO_DEL%) do (
    echo sc delete %%p
    sc delete %%p
)
GOTO :EOF


:DISABLESERVICE
set SERVICE_TO_DISABLE=%*
for %%p in (%SERVICE_TO_DISABLE%) do (
    echo sc config %%p start= disabled
    sc config %%p start= disabled
)
GOTO :EOF

:STOPSERVICE
set SERVICE_TO_STOP=%*
for %%p in (%SERVICE_TO_STOP%) do (
    echo net stop /y %%p
    net stop /y %%p
)
GOTO :EOF

:DELFILE
    echo del /F /Q %*
         del /F /Q %*
GOTO :EOF

:DELFOLDER
set FOLDER_TO_DEL=%*
for %%p in (%FOLDER_TO_DEL%) do (
    echo RMDIR /S /Q %%p
    RMDIR /S /Q %%p
    if exist %%p (
        call :MOVEFOLDERTOTMP %%p
    )
)
GOTO :EOF

:DELREGVALUE
set REGISTRY_KEY=%1
set REGISTRY_VALUE=%2
echo REG DELETE %REGISTRY_KEY% /v %REGISTRY_VALUE% /f
REG DELETE %REGISTRY_KEY% /v %REGISTRY_VALUE% /f
GOTO :EOF

:DELREGISTRY
set REGISTRY_TO_DEL=%~1
echo Deleting registry key %REGISTRY_TO_DEL%
echo Windows Registry Editor Version 5.00>temp4del.reg
echo [-%REGISTRY_TO_DEL%]>>temp4del.reg
start /wait regedit /s temp4del.reg
del /f /q temp4del.reg
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

:MOVEFOLDERTOTMP
set FOLDER_TO_TMP=%~dp1
IF %FOLDER_TO_TMP:~-1%==\ set FOLDER_TO_TMP=%FOLDER_TO_TMP:~0,-1%
call :GETTEMPNAME
echo move "%FOLDER_TO_TMP%" "!_TMP_RESULT!"
move "%FOLDER_TO_TMP%" "!_TMP_RESULT!"
GOTO :EOF

:GETTEMPNAME
set _TMP_RESULT=%TMP%\RmvTool-%RANDOM%-%TIME:~6,5%
if exist "%_TMP_RESULT%" GOTO :GETTEMPNAME
GOTO :EOF

:SHOWHELP
echo AMSP UniClient Framework Removal Tool
echo.
echo Usage
echo RmvTool.bat INSTALL_RUNTIME_ROOT [DEFAULT_INSTALL_ROOT]
echo.
GOTO :EOF

:FINDNSCUTIL
set TMCFW_REG=Software\TrendMicro\AMSP
call :FINDFILEBYNAME "%INSTALL_ROOT%AMSP\module\20003" %1
if not exist "!_RESULT!" (
	call :FINDFILEBYNAME "%PRODUCT_ROOT%pfw_features" %1
)
if not exist "!_RESULT!" (
	set TMCFW_REG=Software\TrendMicro\NSC\PFW
	call :FINDFILEBYNAME "%PRODUCT_ROOT%" %1
)
if not exist "!_RESULT!" (
    if /I "%PROCESSOR_ARCHITECTURE%" EQU "AMD64" (
        call :FINDFILEBYNAME "%INSTALL_RUNTIME_ROOT%x64" %1        
    ) else (
        if /I "%PROCESSOR_ARCHITEW6432%" EQU "AMD64" (
            call :FINDFILEBYNAME "%INSTALL_RUNTIME_ROOT%x64" %1  
        ) else (
            call :FINDFILEBYNAME "%INSTALL_RUNTIME_ROOT%x86" %1          
        )
    )
)
GOTO :EOF

:REMOVE_DLP
echo Remove DLP
call :DELSERVICE dsasvc dlpnetfltr sakcd sakfile saknet
call :DELFILE %WINDIR%\system32\drivers\sakcd.sys
call :DELFILE %WINDIR%\system32\drivers\sakfile.sys
call :DELFILE %WINDIR%\system32\drivers\saknet.sys
call :DELFILE %WINDIR%\system32\drivers\dlpnetfltr.sys

GOTO :EOF

:REMOVE_BROWSER_PLUG_IN
echo Remove WR Browser Plug-ins

SET "ISX64=0"
if /I "%PROCESSOR_ARCHITECTURE%" EQU "AMD64" ( SET "ISX64=1" )
if /I "%PROCESSOR_ARCHITEW6432%" EQU "AMD64" ( SET "ISX64=1" )

if "%ISX64%" EQU "1" (
	IF EXIST "%PRODUCT_ROOT%TmExtIns.exe" ( "%PRODUCT_ROOT%TmExtIns.exe" -ue "%PRODUCT_ROOT:~0,-1%")
	IF EXIST "%PRODUCT_ROOT%TmExtIns32.exe" ( 
		"%PRODUCT_ROOT%TmExtIns32.exe" -ue "%PRODUCT_ROOT:~0,-1%"
		"%PRODUCT_ROOT%TmExtIns32.exe" -uf "%PRODUCT_ROOT%FirefoxExtension"
		"%PRODUCT_ROOT%TmExtIns32.exe" -uc "%PRODUCT_ROOT%tmNSCchromeExt.crx"
	)
) else (
	IF EXIST "%PRODUCT_ROOT%TmExtIns.exe" ( 
		"%PRODUCT_ROOT%TmExtIns.exe" -ue "%PRODUCT_ROOT:~0,-1%"
		"%PRODUCT_ROOT%TmExtIns.exe" -uf "%PRODUCT_ROOT%FirefoxExtension"
		"%PRODUCT_ROOT%TmExtIns.exe" -uc "%PRODUCT_ROOT%tmNSCchromeExt.crx"
	)
)

echo Remove BES Browser Plug-ins

if "%ISX64%" EQU "1" (
echo "64bit"
	call :DELREGVALUE "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Mozilla\Firefox\extensions" "tmbepff@trendmicro.com"
	call :DELREGVALUE "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Google\Chrome\Extensions\bmiabdepfhhiieiipmeecdmeljggmfee" "Path"
	call :DELREGVALUE "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Google\Chrome\Extensions\bmiabdepfhhiieiipmeecdmeljggmfee" "Version"
	call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Google\Chrome\Extensions\bmiabdepfhhiieiipmeecdmeljggmfee"
	regsvr32.exe /u /s "%PRODUCT_ROOT%CCSF\module\BES\TmBpIe64.dll"
	regsvr32.exe /u /s "%PRODUCT_ROOT%CCSF\module\BES\IE32\TmBpIe32.dll"
) else (
echo "32bit"
	regsvr32.exe /u /s "%PRODUCT_ROOT%CCSF\module\BES\TmBpIe32.dll"
)

call :DELREGVALUE "HKEY_LOCAL_MACHINE\SOFTWARE\Mozilla\Firefox\extensions" "tmbepff@trendmicro.com"
call :DELREGVALUE "HKEY_LOCAL_MACHINE\SOFTWARE\Google\Chrome\Extensions\bmiabdepfhhiieiipmeecdmeljggmfee" "Path"
call :DELREGVALUE "HKEY_LOCAL_MACHINE\SOFTWARE\Google\Chrome\Extensions\bmiabdepfhhiieiipmeecdmeljggmfee" "Version"
call :DELREGISTRY "HKEY_LOCAL_MACHINE\SOFTWARE\Google\Chrome\Extensions\bmiabdepfhhiieiipmeecdmeljggmfee"

GOTO :EOF

:GETWINMAJORVER
set WINMAJORVER=4
for /F "tokens=1 delims=." %%v in ('wmic os get version ^| findstr \.') do set WINMAJORVER=%%v
GOTO :EOF

:RMVTRENDPROTECT
echo Finding Trend Protect 1.X
if /I "%PROCESSOR_ARCHITECTURE%" EQU "AMD64" (
	reg query HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{D5462C8A-D08C-4163-8293-82F2E11A2760} /v "UninstallString" | findstr UninstallString > NUL 2>&1
) else (
		reg query HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{D5462C8A-D08C-4163-8293-82F2E11A2760} /v "UninstallString" | findstr UninstallString > NUL 2>&1
)
if NOT errorlevel 1 (
	echo Removing Trend Protect 1.X
	echo MsiExec.exe /X{D5462C8A-D08C-4163-8293-82F2E11A2760} /qn
	     MsiExec.exe /X{D5462C8A-D08C-4163-8293-82F2E11A2760} /qn
)
GOTO :EOF

:REMOVE_WFBSS_UPDATER
echo Removing WFBSSUpdater
IF EXIST "%PRODUCT_ROOT%..\WFBSSUpdater\WFBSSUpdater.exe" ( 
	"%PRODUCT_ROOT%..\WFBSSUpdater\WFBSSUpdater.exe" /uninstall
)
GOTO :EOF

:DECRYPT_BITLOCKER
echo Decrypt BitLocker
IF EXIST "%PRODUCT_ROOT%HostedAgent\HostedAgent.exe" ( 
	"%PRODUCT_ROOT%HostedAgent\HostedAgent.exe" -module "%PRODUCT_ROOT%HostedAgent\EncryptionManager.dll" -decrypt
)
GOTO :EOF

:RESTORE_WINDEFENDER_SETTING
echo Remove Reg value which disabled windows defender
call :DELREGVALUE "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender" "DisableAntiSpyware"
call :DELREGVALUE "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender" "DisableRoutinelyTakingAction"
GOTO :EOF

:EOF

rem ENDLOCAL

 rem Built with WFBS 20.0.2128 
