require("mod_binary_reader")
require("mod_w3strings")

local in_file = assert(arg[1], "\n\nno input\n")
local out_dir = arg[2] or "."
local debug = arg[3] or false

local r = BinaryReader
r:open(in_file)

--[[
char magic[4];          // "CPSW"
int version;            // 162
unsigned short key1;

bit6 count;
{
    uint id;            // ^key
    uint zero;
    uint wave_offset;   // absolute
    uint zero;          //
    uint wave_size;     //
    uint zero;          //
    uint cr2w_offset    // absolute
    uint zero;          //
    uint cr2w_size      //
    uint zero;          //
} // * count

unsigned shory key2; // key = key1 << 16 | key2
--]]

r:idstring("CPSW")
r:idstring("\xA2\x00\x00\x00")  -- 162

local key = r:uint16()
local count = bit6(r)

local h = {}
for i = 1, count do
    local t = {}
    t.id        = r:uint32(); assert(0 == r:uint32())
    t.wave_offs = r:uint32(); assert(0 == r:uint32())
    t.wave_size = r:uint32(); assert(0 == r:uint32())
    t.cr2w_offs = r:uint32(); assert(0 == r:uint32())
    t.cr2w_size = r:uint32(); assert(0 == r:uint32())
    table.insert(h, t)
end

key = key << 16 | r:uint16()
io.write(string.format("key: 0x%08X ", key))

local magic, lang = get_key(key)
io.write(string.format("-> magic: 0x%08X (%s)\n", magic, lang))

for i = 1, count do
    h[i].id = h[i].id ~ magic
end

io.write("sorting " .. count .. " items... ")
table.sort(h, function(a, b) return a.id < b.id end)
io.write("OK\n")

if debug then
    io.write("   #:         id   wave_off  wave_sz   cr2w_off  cr2w_sz\n")
    for i = 1, count do
        local t = h[i]
        io.write(string.format("%4d: 0x%08x %10d %8d %10d %8d\n", 
                i, t.id, t.wave_offs, t.wave_size, t.cr2w_offs, t.cr2w_size))
    end
end

for i = 1, count do
    local t = h[i]
    local name = string.format("%s/0x%08x.", out_dir, t.id)
    local w, data
    
    io.write("saving " .. name .. "(wav|cr2w) ... ")
    w = assert(io.open(name .. "wav", "w+b"))
    if t.wave_size > 0 then
        r:seek(t.wave_offs)
        local sz = r:uint32()
        assert(t.wave_size == sz + 12)
        data = r:str(sz)
        w:write(data)
    end
    w:close()
    
    w = assert(io.open(name .. "cr2w", "w+b"))
    if t.cr2w_size > 0 then
        r:seek(t.cr2w_offs)
        data = r:str(t.cr2w_size)
        w:write(data)
    end
    w:close()
    io.write("OK\n")
end

r:close()
