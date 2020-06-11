require("mod_binary_reader")
require("mod_w3strings")

local in_file = assert(arg[1], "no input")
local out_file = arg[2] or "./strings_utf8.txt"
local debug = arg[3] or false
local r

local function toutf16le(str)
    local s = string.gsub(str, "(.)", "%1\x00")
    return s
end

local function ReadValueEncodedS32()
    local op = r:uint8()
    local value = op & 0x3f
    if (op & 0x40) ~= 0 then
        local shift = 6
        local extra
        repeat
            if shift > 27 then
                error("shift > 27")
            end
            extra = r:uint8()
            value = value | ((extra & 0x7f) << shift)
            shift = shift + 7
        until (extra & 0x80) == 0
    end
    if (op & 0x80) ~= 0 then
        value = -value
    end
    return value
end

local function ReadEncodedString(is_buff)
    local length = ReadValueEncodedS32()
    local res, u
    if length < 0 then
        if is_buff then
            error("length < 0")
        end
        length = -length
        if length >= 0x10000 then
            error("length >= 0x10000")
        end
        res = r:str(length) -- 8-byte
        u = 8
    else
        if length >= 0x10000 then
            error("length >= 0x10000")
        end
        res = r:str(length * 2) -- 16-byte
        u = 16
    end
    return res, u
end


r = BinaryReader
r:open(in_file)

local w = assert(io.open(out_file, "w+b"))

local version = r:uint32()
local EncryptionKey = 0
if version >= 114 then
    EncryptionKey = (EncryptionKey | r:uint16()) << 16
end

local keyCount = ReadValueEncodedS32()
local Keys = {}
for i = 1, keyCount do
    local str, u = ReadEncodedString()
    local key = r:uint32()
    if 16 == u then
        local t = {}
        for i = 1, #str, 2 do
            local u1 = str:byte(i)
            local u2 = str:byte(i+1)
            local u16 = (u2 << 8) + u1
            table.insert(t, utf8.char(u16))
        end
        str = table.concat(t)
    end
    str = str:gsub("&", "&amp;")
    table.insert(Keys, {key, str})
end

if version >= 114 then
    local u16 = r:uint16()
    EncryptionKey = EncryptionKey | u16
end

local magic = get_key(EncryptionKey)

local fileStringsHash = 0
if version >= 200 then
    fileStringsHash = r:uint32()
    fileStringsHash = fileStringsHash ~ magic
end

local actualStringsHash = 0 -- u32
local stringCount = ReadValueEncodedS32()
local Texts = {}
for i = 1, stringCount do
    local key = r:uint32() ~ magic
    local buffer = ReadEncodedString(true)
    local out = {}
    local stringKey = (magic >> 8) & 0xffff -- u16
    local hash = 0 -- u32
    local buf_len = #buffer
    for j = 1, buf_len, 2 do
        local u1, u2 = string.byte(buffer, j, j+1)
        local u16 = (u2 << 8) + u1
        hash = (hash + u16) & 0xffffffff
        if version >= 200 then
            local charKey = ((buf_len / 2 + 1) * stringKey) & 0xffff -- u16
            u1 = u1 ~ (charKey & 0xff)
            u2 = u2 ~ ((charKey >> 8) & 0xff)
            u16 = (u16 ~ charKey) & 0xffff
            -- rotate left
            local l = (stringKey & 0x8000) >> 15
            stringKey = (stringKey << 1)
            stringKey = (stringKey + l) & 0xffff -- u16
        else
            error("string obfuscation for old strings files is untested")
        end
        table.insert(out, utf8.char(u16))
    end
    
    actualStringsHash = (actualStringsHash + hash) & 0xffffffff
    
    local text = table.concat(out)
    if 65434 == key and 83394453 == hash then
        -- fix corrupted strings
        text = text:sub(1, 52)
    end
    text = text:gsub("&", "&amp;")
    text = text:gsub("<", "&lt;")
    text = text:gsub(">", "&gt;")
    text = text:gsub("\x0b", "&#xB;")
    
    table.insert(Texts, {key, text})
end

if version >= 114 and version < 200 then
    fileStringsHash = r:uint32()
end

if version >= 114 and fileStringsHash ~= actualStringsHash then
    print(fileStringsHash .. "~=" .. actualStringsHash)
    print("hash for strings does not match !!!")
end


w:write("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n")
w:write(("<strings version=\"%d\" encryption_key=\"%d\" keyCount=\"%d\" stringCount=\"%d\">\n")
:format(version, EncryptionKey, keyCount, stringCount))

w:write("  <keys>\n")
for i = 1, #Keys do
    local k = Keys[i]
    local str = ("    <key id=\"%d\">%s</key>\n"):format(k[1] ~ magic, k[2])
    w:write(str)
end
w:write(("  </keys>\n"))

w:write("  <texts>\n")
for i = 1, #Texts do
    local k = Texts[i]
    local text = ("    <text id=\"%d\">%s</text>\n"):format(k[1], k[2])
    w:write(text)
end
w:write("  </texts>\n")

w:write("</strings>\n")

r:close()
w:close()
