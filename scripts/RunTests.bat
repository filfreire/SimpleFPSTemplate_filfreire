:: reference from https://github.com/Floating-Island/ProjectR
:: "%ue4Location%\Engine\Binaries\Win64\UE4Editor-cmd.exe" "%workspace%\%projectFilename%" -nosplash -Unattended -nopause -nosound -NullRHI -nocontentbrowser -ExecCmds="Automation RunTests %testSuiteToRun%;quit" -TestExit="Automation Test Queue Empty" -ReportOutputPath="%workspace%\%testReportFolder%" -Log=%testsLogName%

set ueLocation=%~1
set projectLocation=%~2
set projectName=%~3
set testSuiteToRun=%~4
set testReportFolder=%~5
set testLogName=%~6
set UnrealEditorCmd=%~7


"%ueLocation%\Engine\Binaries\Win64\%UnrealEditorCmd%" "%projectLocation%\%projectName%" -nosplash -Unattended -nopause -nosound -NullRHI -nocontentbrowser -ExecCmds="Automation RunTests %testSuiteToRun%;quit" -TestExit="Automation Test Queue Empty" -ReportOutputPath="%projectLocation%\%testReportFolder%" -Log=%testLogName%
