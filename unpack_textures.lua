local zlib = require("zlib")
require("mod_binary_reader")
require("mod_dds_header")

local in_file = assert(arg[1], "no input")
local out_path = arg[2] or "."

local r = BinaryReader
r:open(in_file)

r:jmp("end", -20)
local texture_num = r:uint32()
local block2_size = r:uint32()      -- names
local block1_size = r:uint32()      -- * 4 bytes
assert(1415070536 == r:uint32())    -- ???
assert(6 == r:uint32())             -- ???
-- EOF
print("textures: " .. texture_num .. "; filename buffer: " .. block2_size .. "; chunks: " .. block1_size)

local jmp = 20 + 12 + (texture_num * 52) + block2_size + (block1_size * 4)
r:jmp("end", -jmp)


local block1 = {}   -- relative offsets of packed chunks
io.write("read block1... ")
for i = 1, block1_size do
    local value = r:uint32()
    table.insert(block1, value)
end
io.write("OK\n")

io.write("read block2... ")
--local block2 = r:str(block2_size) -- filenames
local block2 = {}
local pos = r:pos()
for i = 1, texture_num do
    local idx = r:pos() - pos + 1
    local str = r:str()
    block2[idx] = str
end
io.write("OK\n")

io.write("read block3... ")
local block3 = {}   -- header
for i = 1, texture_num do
    t = {}
    t[1] = r:hex32()    -- crc??
    t[2] = r:uint32()   -- filename, start offset in block2
    t[3] = r:uint32()   -- * 4096 = start offset, first chunk
    t[4] = r:uint32()   -- packed size (all cunks)
    t[5] = r:uint32()   -- unpacked size
    t[6] = r:uint32()   -- bpp?
    t[7] = r:uint16()   -- width
    t[8] = r:uint16()   -- height
    t[9] = r:uint16()   -- mips
    t[10] = r:uint16()  -- 1/6/..., single, cubemaps, ...
    t[11] = r:uint32()  -- offset in block1, second packed chunk
    t[12] = r:uint32()  -- number left packed chunks
    t[13] = r:hex32()  -- zero???
    t[14] = r:hex32()  -- zero???
    t[15] = r:uint8()   -- 7-DXT1, 8-DXT5, 253-???
    t[16] = r:uint8()   -- 4/3 ???
    t[17] = r:uint16()
    table.insert(block3, t)
end
io.write("OK\n")

io.write("read block4... ")
for i = 1, 3 do
    local hex = r:hex32()
    io.write(hex)
    io.write(" ")
end
io.write("OK\n")


-- start unpack

local dds = DDSHeader

io.write("start unpacking...\n")
for i = 1, texture_num do
    local b = block3[i]

    local fmt = 0
    if     b[15] == 7 then fmt = 1      -- DXT1
    elseif b[15] == 8 then fmt = 4      -- DXT5
    elseif b[15] == 10 then fmt = 4     -- DXT5
    elseif b[15] == 253 then fmt = -1   -- skip 32 bit cubemap
    elseif b[15] == 0 then fmt = -1     -- skip 16 bit cubemap
    end

    if not (b[10] == 1 or b[10] == 6) then fmt = -1 end   -- skip arrays

    -- create dds header
    dds:new()

    local w
    local name = block2[b[2]+1]
    
    if fmt >= 0 then
        name = string.gsub(name, "\\", "#")
        print(i .. "/" .. texture_num .. ": " .. name)
            
        w = assert(io.open(out_path .. "\\" .. name .. ".(" .. i .. ").dds", "w+b"))
        
        -- width, height, mips, fmt, bpp, cubemap, depth, normal
        local header = dds:generate(b[7], b[8], b[9], fmt, b[6], b[10], nil, nil)
        w:write(header)
    else
        io.write("SKIP: " .. name .. "\n\n")
    end
    
    local function read_save_chunk(offset)
        r:seek(offset)
        local zsize = r:uint32()
        local size = r:uint32()
        local part = r:uint8()
        local buf = r:str(zsize)

        local stream = zlib.inflate()
        local data, eof, bytes_in, bytes_out = stream(buf)
        assert(true == eof, "ERROR: eof ~= true")
        assert(zsize == bytes_in, "ERROR: zsize = " .. zsize .." ~= ".. bytes_in)
        assert(size == bytes_out, "ERROR: size = " .. size .." ~= ".. bytes_out)

        -- append first mip
        if fmt >= 0 then
            w:write(data)
            io.write(".")
        end
    end

    -- append other mipmaps
    local start = b[3] * 4096
    read_save_chunk(start)
    for j = 1, b[12] do
        read_save_chunk(start + block1[b[11]+j])
    end

    if fmt >= 0 then
        w:close()
        io.write("OK\n")
    end
end


--[[
local stream = zlib.inflate()
local eof, bytes_in, bytes_out
data, eof, bytes_in, bytes_out = stream(data)
--]]

r:close()
