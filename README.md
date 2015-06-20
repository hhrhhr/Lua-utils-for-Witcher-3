# Lua-utils-for-Witcher-3

### requirements
* Lua 5.3 (http://www.lua.org/download.html) (with >2GB file support)
* lua-zlib (https://github.com/brimworks/lua-zlib)

### instructions ;)

#### inspect_cr2w.lua
    lua inspect_cr2w.lua path_to.cr2w [debug_level [offset]] [> output_file.lua]
* *debug_level*: 0 — no debug (default), 1 — show type of variables, 2 — add headers dump
* *offset*: default is 0
* *output_file.lua*: default output to ````stdout````.

generates Lua–compatible code with parsed values.

#### inspect_w3speech.lua
    lua inspect_w3speech.lua path_to.w3speech [output_dir [debug]]
retrieves a pair of .wav and cr2w files

#### inspect_w3strings.lua
    lua inspect_w3strings.lua path_to.w3.strings [output_file [debug]]
* *output_file* — default is *./strings_utf16le.txt*
* *debug* — enable headers dump

#### inspect_textures.lua
    lua inspect_textures.lua path_to_texture.cache
shows headers from *texture.cache*

#### unpack_textures.lua
    lua unpack_textures.lua path_to_texture.cache [output_dir [mips]]
* *output_dir*: default is "."
* *mips*: save all mips, else only first

unpacking textures and appending the necessary DDS-header. almost all *cubemaps* skipped due to uselessness (can be enabled by remove comment *-- skip tonns of envprobes*). All slashes in paths are replaced on "#", files are written to the same directory.

#### unpack_potato.lua
    lua unpack_potato.lua path_to_archive [output_dir]
only LZ compression is supported, the remaining files are copied as is.

#### mod_*.lua
modules/classes/libs
