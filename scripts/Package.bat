set ueLocation=%~1
set projectLocation=%~2
set projectName=%~3
set target=%~4
set packageFolder=%~5

"%ueLocation%\Engine\Build\BatchFiles\RunUAT.bat" BuildCookRun -project="%projectLocation%\%projectName%" -nop4 -utf8output -nocompileeditor -skipbuildeditor -cook -project="%projectLocation%\%projectName%" -target=%target% -platform=Win64 -installed -stage -archive -package -build -pak -iostore -compressed -archivedirectory="%projectLocation%\%packageFolder%" -clientconfig=Development -nocompile -nocompileuat

:: removed: -prereqs