@echo off

set w3dir=f:\lalala\The Witcher 3 Wild Hunt
set outdir=g:\tmp\w3\map_img

set mask=tile*%%dx*%%d

for /r "%w3dir%" %%i in ("texture.*") do (
    lua unpack_textures_for_maps.lua "%%i" "%outdir%" "%mask%"
)
