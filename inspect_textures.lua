local zlib = require("zlib")
require("mod_binary_reader")

local in_file = assert(arg[1], "no input")
local out_path = arg[2] or "."

local r = BinaryReader
r:open(in_file)

r:jmp("end", -20)
local texture_num = r:uint32()
local block2_size = r:uint32()      -- names
local block1_size = r:uint32()      -- * 4 bytes
assert(1415070536 == r:uint32())    -- HCXT ???
assert(6 == r:uint32())             -- ???
-- EOF

io.write(string.format("textures: %d; filename buffer: %d; chunks: %d\n",
        texture_num, block2_size, block1_size))

local jmp = 20 + 12 + (texture_num * 52) + block2_size + (block1_size * 4)
r:jmp("end", -jmp)


local block1 = {}   -- relative offsets of packed chunks
for i = 1, block1_size do
    local value = r:uint32()
    table.insert(block1, value)
    --io.write(value)
    --io.write("\t")
end
--io.write("\n")


local block2 = {}   -- filenames
local pos = r:pos()
for i = 1, texture_num do
    local str = r:str()
    table.insert(block2, str)
--    io.write(string.format("%4d: %s\n", i, str))
end
--io.write("\n")
assert(pos + block2_size == r:pos())


local block3 = {}   -- header
for i = 1, texture_num do
    t = {}
    t[1] = r:hex32()    -- number (unique???)
    t[2] = r:uint32()   -- filename, start offset in block2
    t[3] = r:uint32()   -- * 4096 = start offset, first chunk
    t[4] = r:uint32()   -- packed size (all cunks)
    t[5] = r:uint32()   -- unpacked size
    t[6] = r:uint32()   -- bpp? always 16
    t[7] = r:uint16()   -- width
    t[8] = r:uint16()   -- height
    t[9] = r:uint16()   -- mips
    t[10] = r:uint16()  -- 1/6, cubemaps?
    t[11] = r:uint32()  -- offset in block1, second packed chunk
    t[12] = r:uint32()  -- number left packed chunks
    t[13] = r:hex32()   -- zero???
    t[14] = r:hex32()   -- zero???
    t[15] = r:uint8()   -- 7-DXT1, 8-DXT5, 253-???
    t[16] = r:uint8()   -- 4/3 ???
    t[17] = r:uint16()
    table.insert(block3, t)
    io.write(
        string.format("%4d, %s, %4d, %5d, %8d, %8d, %2d, %4d, %4d, %2d, %2d, %3d, %d, %s%s, %3d, %d, %d",
        i, table.unpack(t)))
    io.write("\n")
end

print()
r:hex32()
r:hex32()
r:uint32()

assert(texture_num == r:uint32())
io.write("\n")

r:close()
