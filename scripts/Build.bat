set ueLocation=%~1
set projectLocation=%~2
set projectName=%~3

"%ueLocation%\Engine\Build\BatchFiles\RunUAT.bat" BuildCookRun -project="%projectLocation%\%projectName%" -noP4 -platform=Win64 -clientconfig=Development -build
