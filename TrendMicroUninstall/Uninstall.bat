@echo off
SETLOCAL EnableDelayedExpansion

rem In elevated case, the current directory is not where the batch file is.
rem Switch to where the script is first.
chdir /d "%~dp0"

copy /Y "AgentRemoval\AgentRemoval.bat" c:\ >NUL 2>&1
if ERRORLEVEL 1 (
	echo --------------------------------------------------------
	echo --------------------------------------------------------
	echo --------------------------------------------------------
	echo Please run this script with Administrator privilege!!
	echo --------------------------------------------------------
	echo --------------------------------------------------------
	echo --------------------------------------------------------
	pause
	goto :EOF
) else (
	del /f /q c:\AgentRemoval.bat
)

echo "%~dp0">> "CheckPath.tmp"
findstr /r /c:"[()]" CheckPath.tmp >>"CheckPath.tmp"
if NOT ERRORLEVEL 1 (
    echo --------------------------------------------------------
    echo --------------------------------------------------------
    echo --------------------------------------------------------
    echo Please move these script files to a path name without 
    echo "^(" and "^)" characters!!
    echo --------------------------------------------------------
    echo --------------------------------------------------------	
    pause
    del /f /q CheckPath.tmp
    	goto :EOF
) else (  
    del /f /q CheckPath.tmp 
)

set TIMESTAMP=
for /F "tokens=1,2,3 delims=:. " %%a in ("%TIME%") do (
    set TIMESTAMP=%%a_%%b_%%c
)
set UNINST_LOG_PATH=%WINDIR%\Temp\WFBS_Debug\Uninstall_%TIMESTAMP%
mkdir "%UNINST_LOG_PATH%" >NUL 2>&1
regedit /e "%UNINST_LOG_PATH%\TrendMicro.reg" HKEY_LOCAL_MACHINE\Software\TrendMicro
sc query amsp     > "%UNINST_LOG_PATH%\ServiceStatus.log"
sc query tmlisten >> "%UNINST_LOG_PATH%\ServiceStatus.log"
sc query ntrtscan >> "%UNINST_LOG_PATH%\ServiceStatus.log"
sc query tmcomm   >> "%UNINST_LOG_PATH%\ServiceStatus.log"
sc query tmactmon >> "%UNINST_LOG_PATH%\ServiceStatus.log"
sc query tmevtmgr >> "%UNINST_LOG_PATH%\ServiceStatus.log"

echo WFBS Security Agent Uninstall Tool
echo WFBS Security Agent Uninstall Tool>> "Uninstall.%TIMESTAMP%.log" 2>>&1
type AgentRemoval\Version.txt
type AgentRemoval\Version.txt >> "Uninstall.%TIMESTAMP%.log" 2>>&1
echo Log file "Uninstall.%TIMESTAMP%.log" is created.
call AgentRemoval\AgentRemoval.bat >> "Uninstall.%TIMESTAMP%.log" 2>>&1

echo AgentRemoval eixt
echo set DESKTOP=%HOMEDRIVE%%HOMEPATH%\Desktop
set DESKTOP=%HOMEDRIVE%%HOMEPATH%\Desktop

for /F "tokens=2 delims=:" %%d in ('REG QUERY "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Desktop" ^|FINDSTR /I "Desktop" 2^>NUL') do (
	set DESKTOP=%HOMEDRIVE%%%d
)

echo set PATH=%~dp0AgentRemoval\zip;%PATH%
set PATH=%~dp0AgentRemoval\zip;%PATH%
pushd "%WINDIR%\Temp\WFBS_Debug"
zip.exe -rq ..\WFBS_Debug_%TIMESTAMP%.zip *.*
move ..\WFBS_Debug_%TIMESTAMP%.zip "%DESKTOP%\"
popd

echo if exist "%DESKTOP%\WFBS_Debug_%TIMESTAMP%.zip"

if exist "%DESKTOP%\WFBS_Debug_%TIMESTAMP%.zip" (
	cls
	rem explorer /select,"%DESKTOP%\WFBS_Debug_%TIMESTAMP%.zip"
	cmd.exe /V:ON /C AgentRemoval\generate_label.bat AgentRemoval\msg_log_collected.txt
	pause
)

cls
echo cmd.exe /V:ON /C AgentRemoval\generate_label.bat AgentRemoval\msg_uninstall_end.txt

cmd.exe /V:ON /C AgentRemoval\generate_label.bat AgentRemoval\msg_uninstall_end.txt
set /P REBOOT_NOW=Do you want to reboot now? (Y/N)

if /I "%REBOOT_NOW%" EQU "Y" shutdown -r -t 5 -c "Rebooting now."

:EOF
 rem Built with WFBS 20.0.2128 
