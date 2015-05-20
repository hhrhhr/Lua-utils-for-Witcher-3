require("mod_binary_reader")

local in_file = assert(arg[1], "no input")
local out_path = arg[2] or "."

local r = BinaryReader
r:open(in_file)

--[[
char magic[4];      // "RTSW"
int version;        // 162??
unsigned char x1;   // x1, x2 and x3, x4 the same in all files of 
unsigned char x2;   // selected localization

uint6 count1;       // count of string
{
    int file_id;    // unique within the file
    int offset;     // relative to start of utf[], must be multiple by 2
    int str_len;    // -= 1 * 2, skip ending zeroes
} * num

uint6 count2;       
{
    char unk[4]     // global id? or to change the order of rows?
    int file_id     // same with first block
} * count2

uint6 count3;       // count of UTF16 chars (2 byte)
{
    utf[count3 * 2] // \x00\x00 ended UTF16LE strings
}

unsigned char x3;
unsigned char x4;
]]

r:idstring("RTSW")
r:idstring("\xA2\x00\x00\x00")  -- 162

local xor1 = r:uint8()
local xor2 = r:uint8()


local function bit6()
    local result, shift, b = 0, 0, 0
    repeat
        b = r:uint8()
        -- FIX
        if b == 128 then return 0 end
        local s = 6
        local mask = 255
        if b > 127 then
            mask = 127
            s = 7
        elseif b > 63 then
            mask = 63
        end
        result = result | ((b & mask) << shift)
        shift = shift + s
    until b < 64
    return result
end

--[[
local b1 = bit6(); io.write(b1 .. "*12\t-> ")
r:jmp("cur", b1 * 12)
print(r:pos())

local b2 = bit6(); io.write(b2 .. "*8\t-> ")
r:jmp("cur", b2 * 8)
print(r:pos())

local b3 = bit6(); io.write(b3 .. "*2\t-> ")
r:jmp("cur", b3 * 2)
print(r:pos())

local xor3 = r:uint8()
local xor4 = r:uint8()

print(xor1, xor2, xor3, xor4)

os.exit()
--]]


local count1 = bit6()
print(count1, count1 * 12)

local t1 = {}
for i = 1, count1 do
    local sid = r:uint32()
    local off = r:uint32()
    local len = r:uint32()
    table.insert(t1, {sid = sid, off = off, len = len})
    print(i, sid, off, len)
end
print()


local count2 = bit6()
print(count2, count2 * 8)

local t2 = {}
for i = 1, count2 do
    local unk1 = r:uint32()
    local sid = r:uint32()
    table.insert(t2, {unk1 = unk1, sid = sid})
    print(i, unk1, sid)
end
print()


local count3 = bit6()
print(count3, count3 * 2)

local w = assert(io.open(out_path .. "\\" .. "strings_utf16le.txt", "w+b"))
w:write("\xFF\xFE")     -- UTF-16LE

local start = r:pos()
for i = 1, count1 do
    r:seek(t1[i].off * 2 + start)
    for j = 1, t1[i].len, 2 do
        local b1 = (r:uint8())
        local b2 = (r:uint8())
        -- TODO:
        --b1 = decode(b1)
        --b2 = decode(b2)
        w:write(string.char(b1))
        w:write(string.char(b2))
    end
    w:write("\n\0")
end
print()

w:close()

r:seek(count3 * 2 + start)
local xor3 = r:uint8()
local xor4 = r:uint8()
print("keys??", xor1, xor2, xor3, xor4)

-- EOF
r:close()
