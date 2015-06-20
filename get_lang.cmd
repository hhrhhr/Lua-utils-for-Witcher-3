@echo off

set w3dir=f:\lalala\The Witcher 3 Wild Hunt
set outdir=g:\tmp\w3\lang



set languages=ru pl en de
if .%1==. goto begin
set languages=%1

:begin
for %%i in (%languages%) do (
    rem echo %%i
    set lang=%%i
    call :convert
)
pause
goto eof

:convert
for /l %%i in (0 1 16) do (
    if exist "%w3dir%\content\content%%i\%lang%.w3strings" (
        echo %lang% content%%i
        lua inspect_w3strings.lua "%w3dir%\content\content%%i\%lang%.w3strings" "%outdir%\content%%i_%lang%.txt"
        echo.
    )
)

for /l %%i in (0 1 16) do (
    if exist "%w3dir%\content\patch%%i\%lang%.w3strings" (
        echo %lang% patch%%i
        lua inspect_w3strings.lua "%w3dir%\content\patch%%i\%lang%.w3strings" "%outdir%\patch%%i_%lang%.txt"
        echo.
    )
)

for /l %%i in (0 1 16) do (
    if exist "%w3dir%\DLC\DLC%%i\content\%lang%.w3strings" (
        echo %lang% dlc%%i
        lua inspect_w3strings.lua "%w3dir%\DLC\DLC%%i\content\%lang%.w3strings" "%outdir%\dlc%%i_%lang%.txt"
        echo.
    )
)
goto eof

:usage
echo usage:
echo.
echo     get_lang.cmd (de/en/ru/etc)
echo.

:eof
