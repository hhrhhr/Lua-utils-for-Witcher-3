assert(_VERSION == "Lua 5.3")

local zlib = require("zlib")
require("mod_binary_reader")

local in_file = assert(arg[1], "ERR: no input file")
local out_path = arg[2] or "."

local r = BinaryReader
r:open(in_file)

r:idstring("POTATO70")
assert(r:size() == r:uint32())

local size = r:uint32()
local header_sz = r:uint32()
local data_sz = r:uint32()
local tmp = r:str(8)


-- parse header

local file_num = header_sz // 320

local files = {}
for i = 1, file_num do
    local t = {}
    local pos = r:pos()
    t.name = r:str()
    r:seek(pos + 256)

    local unk0 = r:str(16)
    local unk1 = r:uint32(); assert(0 == unk1)
    t.size = r:uint32()
    t.zsize = r:uint32()
    t.offs  = r:uint32()
    local unk4 = r:uint32()
    local unk5 = r:uint32()
    local zero = r:str(16)  -- 00 00 00 ...
    local unk6 = r:uint32()
    t.pack = r:uint32()     -- 0 - not packed, 1 - zlib, 5 - LZ??

    --print(i, t.size, t.zsize, t.offs, t.pack, t.name)
    table.insert(files, t)
end


-- process dir tree

local dirs_tmp = {}
for i = 1, file_num do
    local t = {}
    for s in string.gmatch(files[i].name, "([^\\]+)") do
        table.insert(t, s)
    end
    table.remove(t)
    table.insert(dirs_tmp, table.concat(t, "\\"))
end
table.sort(dirs_tmp)

local dirs = {}
tmp = ""
for i = 1, file_num do
    local s = dirs_tmp[i]
    if tmp ~= s then
        table.insert(dirs, s)
        tmp = s
    end
end


-- mkdir

for k, v in ipairs(dirs) do
    --print(v)
    local cmd = "mkdir \"" .. out_path .. "\\" .. v .. "\" >nul 2>&1"
    --print(cmd)
    os.execute(cmd)
end


-- unpack

for i = 1, file_num do
    local f = files[i]
    r:seek(f.offs)
    local w = assert(io.open(out_path .. "\\" .. f.name, "w+b"))
    local data = r:str(f.zsize)
    if f.pack == 0 then
        -- just copy
    elseif f.pack == 1 then
        local stream = zlib.inflate()
        data, eof, bytes_in, bytes_out = stream(data)
        assert(f.zsize == bytes_in)
        assert(f.size == bytes_out)
    elseif f.pack == 5 then
        print("LZ?? chunk, copy as is: " .. f.name)
    else
        print("unknown chunk, copy as is" .. f.name)
    end
    w:write(data)
    w:close()
end

r:close()
