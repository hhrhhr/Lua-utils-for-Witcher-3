require("mod_binary_reader")
require("mod_w3strings")

local in_file = assert(arg[1], "no input")
local out_file = arg[2] or "./strings_utf16le.txt"
local debug = arg[3] or false

local r = BinaryReader
r:open(in_file)

local function toutf16le(str)
    local s = string.gsub(str, "(.)", "%1\x00")
    return s
end

--[[
char magic[4];      // "RTSW"
uint version;        // 162
ushort key1;

uint6 count1;       // count of string
{
    uint str_id;     // ^key, unique
    uint offset;     // relative to start of utf[], must be multiple by 2
    uint strlen;     // number of UTF16 chars, without ending zeroes
} // * count1

uint6 count2;       
{
    char unk[4]     // global id? crc? hash?
    uint str_id      // ^key, same with first block
} // * count2

uint6 count3;       // count of UTF16 chars (2 byte)
{
    utf[count3 * 2] // \x00\x00 ended UTF16LE strings
}

ushort key2;    // key = key1 << 16 | key2
]]

r:idstring("RTSW")
r:idstring("\xA2\x00\x00\x00")  -- 162


local key1 = r:uint16()
r:seek(r:size() - 2)
local magic = r:uint16()
magic = key1 << 16 | magic
io.write(string.format("magic: 0x%08X ", magic))
magic = get_key(magic)
io.write(string.format("-> 0x%08X\n", magic))
r:seek(10)


local count1 = bit6(r)
print("block 1, count = " .. count1, count1 * 12 .. " bytes")

local t1 = {}
for i = 1, count1 do
    local str_id = r:uint32() ~ magic
    local offset = r:uint32()
    local strlen = r:uint32()
    table.insert(t1, {str_id = str_id, offset = offset, strlen = strlen})
end


local count2 = bit6(r)
print("block 2, count = " .. count2, count2 * 8 .. " bytes")

local t2 = {}
for i = 1, count2 do
    local unk1 = r:uint32()
    local str_id = r:uint32() ~ magic
    t2[str_id] = unk1
end


local count3 = bit6(r)
print("block 3, count = " .. count3, count3 * 2 .. " bytes")

local str_start = r:pos()

--------------------------------------------------------------------
if debug then
    --[[
    print("-- block 1 content ----------------")
    for i = 1, count1 do
        local t = t1[i]
        print(string.format("%d:\t0x%08X\t%d\t%d", i, t.str_id, t.offset, t.strlen))
    end
    --]]
    print("-- block 2 content ----------------")
    for i = 1, count2 do
        local t = t2[i]
        print(string.format("%d:\t0x%08X\t0x%08x", i, t.unk1, t.str_id))
    end
    print("-----------------------------------")
end
--------------------------------------------------------------------
print("sorting...")
table.sort(t1, function(a, b) return a.str_id < b.str_id end)
print("sorted")
--------------------------------------------------------------------
local w = assert(io.open(out_file, "w+b"))
w:write("\xFF\xFE")     -- UTF-16LE

for i = 1, count1 do
    local offset = t1[i].offset * 2 + str_start
    r:seek(offset)
    
    local strlen = t1[i].strlen
    local string_key = magic >> 8 & 0xffff  -- (unsigned short)
    
    w:write(toutf16le(string.format("0x%08x | ", t1[i].str_id)))
    local unk = t2[t1[i].str_id]
    if unk ~= nil then
        w:write(toutf16le(string.format("0x%08x | ", unk)))
    else
        w:write(toutf16le("           | "))
    end
    for j = 1, strlen do
        local b1 = (r:uint8())
        local b2 = (r:uint8())
        -- decode
        local char_key = ((strlen + 1) * string_key) & 0xffff        
        b1 = b1 ~ ((char_key >> 0) & 0xff)
        b2 = b2 ~ ((char_key >> 8) & 0xff)
        -- rotate left
        string_key = (string_key << 1 ) | (string_key >> 15)
        string_key = string_key & 0xffff
        
        w:write(string.char(b1, b2))
    end
    w:write("\n\0") -- unix like
end
w:close()
print("done")

r:seek(count3 * 2 + str_start)
local left = r:size() - r:pos() - 2
if left > 0 then
    print("!!! remains " .. left .. " bytes of unknown data !!!")
end

r:close()
