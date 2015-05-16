local zlib = require("zlib")
require("mod_binary_reader")

local in_file = assert(arg[1], "no input")
local out_path = arg[2] or "."

local r = BinaryReader
r:open(in_file)

r:idstring("CR2W")

io.write("header: ")
for i = 1, 3 do
    io.write(r:hex32())
    io.write(" ")
end
io.write("\n\n")

-- 0x0010
print("id??", r:hex32() .. " " .. r:hex32())
print("size", r:uint32() .. "\\" .. r:uint32())
-- 0x0020
print("unkn", r:hex32())
print("06??", r:uint32())

-- modifiers for 'size': 1-1, 2-8, 3-8, 4-16, 5-24, 6-24
for i = 1, 10 do
    local offs = r:uint32()
    local size = r:uint32()
    local crc = r:hex32(1)
    io.write(string.format("%2d: %5d %4d %s\n", i, offs, size, crc))
end

r:close()
