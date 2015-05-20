# Lua-utils-for-Witcher-3

### требования
* Lua 5.3 (http://www.lua.org/download.html)
* lua-zlib (https://github.com/brimworks/lua-zlib)
* Lua должна быть с поддержкой файлов больше 2 Гб (иначе часть игровых архивов будут недоступны)

### инструкции ;)

#### inspect_w3strings.lua
````
lua inspect_w3strings.lua path_to.w3.strings [output_dir]
````
попытка разбора локализации. результат записывается в файл ````strings_utf16le.txt````. локализации *ar|br|esMX* не зашифрованы, что может помочь в дальнейшем анализе.

#### inspect_textures.lua
````
lua inspect_textures.lua path_to_texture.cache
````
вывод заголовков из файла *texture.cache* для вдумчивого изучения в виде:
````
textures: 6; filename buffer: 337; chunks: 24

   1: environment\decorations\exterior\crystal\texture\crystal.xbm
   2: environment\decorations\exterior\crystal\texture\crystal_n.xbm
   -- skipped --

   1, 28561E39,    0,     0,      167,    21872, 16,  128,  128,  8,  1,   0, 2, 0000000000000000, 8, 4, 0
   2, D789DABD,   61,     1,      166,    21872, 16,  128,  128,  8,  1,   2, 2, 0000000000000000, 8, 4, 0
   -- skipped --
````
коментарии к названию столбцов см. в коде.

#### unpack_textures.lua
````
lua unpack_textures.lua path_to_texture.cache [output_dir]
````
распаковка текстур и дописывание к ним необходимого DDS-заголовка. пока что *texture arrays* (многослойные текстуры), куча мелких *enviroment cubemaps* и часть других картинок (в основном относящиеся к игровому журналу) пропускаются.
вывод примерно такой:
````
textures: 6; filename buffer: 337; chunks: 24
read block1... OK
read block2... OK
read block3... OK
read block4... A931DA96 753B2389 EE040000 OK
start unpacking...
1/6: environment#decorations#exterior#crystal#texture#crystal.xbm
...OK
2/6: environment#decorations#exterior#crystal#texture#crystal_n.xbm
...OK
3/6: fx#textures#explode#explode_smoke_10.xbm
.......OK
-- skipped --
````
точки в *.......OK* — сжатые чанки. все слеши в путях заменены на решетки, т. о. файлы падают в один каталог.

#### unpack_potato.lua
````
lua unpack_potato.lua path_to_archive [output_dir]
````
распаковка файлов с magic-ом ````POTATO70````, это почти все файлы ````\content?\bundles\*.bundle````.

#### mod_*.lua
просто модули/классы/библиотеки.
