@echo off

if .%1==. goto usage
set lang=%1

set w3dir=f:\lalala\The Witcher 3 Wild Hunt
set outdir=g:\tmp\w3\lang

set content=0 1 2 3 4 5 6 7 8 9 10 11 12
set patch=0
set dlc=1 2 3 4 5 7 8 13


for %%i in (%content%) do (
    echo content%%i
    lua inspect_w3strings.lua "%w3dir%\content\content%%i\%lang%.w3strings" "%outdir%\content%%i_%lang%.txt"
    echo.
)

for %%i in (%patch%) do (
    echo patch%%i
    lua inspect_w3strings.lua "%w3dir%\content\patch%%i\%lang%.w3strings" "%outdir%\patch%%i_%lang%.txt"
    echo.
)

for %%i in (%dlc%) do (
    echo dlc%%i
    lua inspect_w3strings.lua "%w3dir%\DLC\DLC%%i\content\%lang%.w3strings" "%outdir%\dlc%%i_%lang%.txt"
    echo.
)
goto eof

:usage
echo usage:
echo.
echo     get_lang.cmd (de/en/ru/etc)
echo.

:eof
pause
