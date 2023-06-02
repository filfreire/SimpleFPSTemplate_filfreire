set projectLocation=%~1
set packageFolder=%~2

powershell -Command "Compress-Archive -Path '%projectLocation%\%packageFolder%\*' -DestinationPath '%projectLocation%\%packageFolder%.zip'"
