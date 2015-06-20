local zlib = require("zlib")
require("mod_binary_reader")
require("mod_dds_header")

local WINDOWS = (package.config:sub(1,1) == "\\") or false
local SEPPERATOR = WINDOWS and "\\" or "/"

local in_file = assert(arg[1], "no input")
local out_path = arg[2] or "."
--local with_mips = arg[3] or false
local with_mips = false
local filter = arg[3] or ""


local r = BinaryReader
r:open(in_file)

r:jmp("end", -20)
local texture_num = r:uint32()
local block2_size = r:uint32()      -- names
local block1_size = r:uint32()      -- * 4 bytes
assert(1415070536 == r:uint32())    -- "HCXT"
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
    t[1] = r:hex32()    -- crc or id??
    t[2] = r:uint32()   -- filename, start offset in block2
    t[3] = r:uint32()   -- * 4096 = start offset, first chunk
    t[4] = r:uint32()   -- packed size (all cunks)
    t[5] = r:uint32()   -- unpacked size
    t[6] = r:uint32()   -- bpp? always 16
    t[7] = r:uint16()   -- width
    t[8] = r:uint16()   -- height
    t[9] = r:uint16()   -- mips
    t[10] = r:uint16()  -- 1/6/N, single, cubemaps, arrays
    t[11] = r:uint32()  -- offset in block1, second packed chunk
    t[12] = r:uint32()  -- the number of remaining packed chunks
    t[13] = r:hex32()   -- ????
    t[14] = r:hex32()   -- ????
    t[15] = r:uint8()   -- 0-????, 7-DXT1, 8-DXT5, 10-????, 13-DXT3, 14-ATI1, 15-????, 253-RGBA
    t[16] = r:uint8()   -- 3-cubemaps, 4-texture, 0-???
    t[17] = r:uint16()  -- 0/1 ???
    table.insert(block3, t)
end
io.write("OK\n")

io.write("read block4... ")
for i = 1, 3 do
    local hex = r:hex32()
    io.write(hex .. " ")
end
io.write("OK\n")


-- start unpack

local dds = DDSHeader

io.write("start unpacking...\n")
for i = 1, texture_num do
    local b = block3[i]

    local fmt = 0
    if     b[15] == 7   then fmt = 1    -- DXT1
    elseif b[15] == 8   then fmt = 4    -- DXT5
    elseif b[15] == 10  then fmt = 4    -- ??????
    elseif b[15] == 13  then fmt = 3    -- DXT3
    elseif b[15] == 14  then fmt = 6    -- ATI1
    elseif b[15] == 15  then fmt = 4    -- ??????
    elseif b[15] == 253 then fmt = 0    -- RGBA?
    elseif b[15] == 0   then fmt = 0    -- R4G4B4A4?
    else
        assert(false, fmt)
    end

    -- skip tonns of envprobes
    if b[10] == 6 and (b[15] == 253 or b[15] == 0) then fmt = -1 end

    -- use filter
    local name = block2[b[2]+1]
    local is_filter = string.find(name, filter)

    if is_filter == nil then goto skip end

    print(i .. "/" .. texture_num .. ": " .. name)

    -- skip unsupported or not needed files
    if fmt < 0 then
        io.write("SKIP\n")
        goto skip
    end

    -- make file path
    local fullpath = {}
    for s in string.gmatch(name, "([^\\]+)") do
        table.insert(fullpath, s)
    end
    table.remove(fullpath)

    -- mkdir
    local cmd
    if WINDOWS then
        local filepath = table.concat(fullpath, "\\")
        cmd = "mkdir \"" .. out_path .. "\\" .. filepath .. "\" >nul 2>&1"
    else
        local filepath = table.concat(fullpath, "/")
        cmd = "mkdir -p \"" .. out_path .. "/" .. filepath .. "\""
    end
    os.execute(cmd)

    -- check for cube
    local cubemap = (b[16] == 3 or b[16] == 0) and (b[10] == 6)

    local depth = 0
    -- mark as texture arrays
    if b[10] > 1 and b[16] == 4 then depth = b[10] end 

    -- skip mips unpacking
    if not with_mips then b[9] = 1 end

    -- TODO: check this
    if b[16] == 3 and b[15] == 253 then b[6] = 32 end   -- 32 bit
    --if b[16] == 0 and b[15] == 0 then b[6] = 16 end     -- 16 bit

    -- create dds header
    dds:new()
    -- width, height, mips, fmt, bpp, cubemap, depth, normal
    local header = dds:generate(b[7], b[8], b[9], fmt, b[6], cubemap, depth, nil)

--    local w = assert(io.open(out_path.."\\"..name .. ".("..i..").dds", "w+b"))
    name = WINDOWS and name or string.gsub(name, "\\", "/")
    local w = assert(io.open(out_path .. SEPPERATOR .. name .. ".dds", "w+b"))
    w:write(header)

    local function read_save_chunk(offset)
        r:seek(offset)
        local zsize = r:uint32()
        local size = r:uint32()
        local part = r:uint8()
        local buf = r:str(zsize)
        --print(offset .. " " .. part .. ": " .. zsize .. "->\t" .. size)

        local stream = zlib.inflate()
        local data, eof, bytes_in, bytes_out = stream(buf)
        assert(true == eof, "ERROR: eof ~= true")
        assert(zsize == bytes_in, "ERROR: zsize = " .. zsize .." ~= ".. bytes_in)
        assert(size == bytes_out, "ERROR: size = " .. size .." ~= ".. bytes_out)

        -- append first mip
        w:write(data)
        --io.write(".")
    end

    local start = b[3] * 4096
    read_save_chunk(start)

    if with_mips then
        for j = 1, b[12] do
            read_save_chunk(start + block1[b[11]+j])
        end
    end

    w:close()
    io.write("OK\n")

    ::skip::
end

r:close()
