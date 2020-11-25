@echo off
SETLOCAL EnableDelayedExpansion

rem In elevated case, the current directory is not where the batch file is.
rem Switch to where the script is first.
chdir /d "%~dp0"

copy /Y "AgentRemoval\AgentStop.bat" c:\ >NUL 2>&1
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
	del /f /q c:\AgentStop.bat
)

set TIMESTAMP=
for /F "tokens=1,2,3 delims=:. " %%a in ("%TIME%") do (
    set TIMESTAMP=%%a_%%b_%%c
)

echo WFBS Security Agent Unload Tool
echo WFBS Security Agent Unload Tool>> "Stop.%TIMESTAMP%.log" 2>>&1
type AgentRemoval\Version.txt
type AgentRemoval\Version.txt >> "Stop.%TIMESTAMP%.log" 2>>&1
echo Log file "Stop.%TIMESTAMP%.log" is created.
set AGENT_DISABLE_SVC=0
call AgentRemoval\AgentStop.bat >> "Stop.%TIMESTAMP%.log" 2>>&1

:EOF

 rem Built with WFBS 20.0.2128 
