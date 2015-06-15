assert(_VERSION == "Lua 5.3")

BinaryReader = {
    f_handle = nil,
    f_size = 0
}

function BinaryReader:open(fullpath)
    self.f_handle = assert(io.open(fullpath, "rb"))
    self.f_size = self.f_handle:seek("end")
    assert(-1 ~= self.f_size, "your Lua doesn't support files larger than 2 Gb")
    self.f_handle:seek("set")
end

function BinaryReader:close()
    self.f_handle:close()
    self.f_handle = nil
    self.f_size = 0

end

function BinaryReader:pos()
   return self.f_handle:seek()
end

function BinaryReader:size()
    return self.f_size
end

function BinaryReader:seek(pos)
    return self.f_handle:seek("set", pos)
end

function BinaryReader:jmp(pos, off)
    return self.f_handle:seek(pos, off)
end

function BinaryReader:uint8()  -- unsigned byte
    local u8 = string.unpack("B", self.f_handle:read(1))
    return u8
end

function BinaryReader:sint8()  -- signed byte
    local s8 = string.unpack("b", self.f_handle:read(1))
    return s8
end

function BinaryReader:uint16(endian_big)  -- unsigned short
    local u16
    if endian_big then
        u16 = string.unpack(">H", self.f_handle:read(2))
    else
        u16 = string.unpack("<H", self.f_handle:read(2))
    end
    return u16
end

function BinaryReader:sint16(endian_big)  -- signed short
    local s16
    if endian_big then
        s16 = string.unpack(">h", self.f_handle:read(2))
    else
        s16 = string.unpack("<h", self.f_handle:read(2))
    end
    return s16
end

function BinaryReader:uint32(endian_big)  -- unsigned integer
    local u32
    if endian_big then
        u32 = string.unpack(">I", self.f_handle:read(4))
    else
        u32 = string.unpack("<I", self.f_handle:read(4))
    end
    return u32
end

function BinaryReader:sint32(endian_big)  -- signed integer
    local s32
    if endian_big then
        s32 =  string.unpack(">i", self.f_handle:read(4))
    else
        s32 =  string.unpack("<i", self.f_handle:read(4))
    end
    return s32
end

function BinaryReader:uint64(endian_big)  -- unsigned long long integer
    local u64
    if endian_big then
        u64 = string.unpack(">I8", self.f_handle:read(8))
    else
        u64 = string.unpack("<I8", self.f_handle:read(8))
    end
    return u64
end

function BinaryReader:sint64(endian_big)  -- signed long long integer
    local s64
    if endian_big then
        s64 = string.unpack(">i8", self.f_handle:read(8))
    else
        s64 = string.unpack("<i8", self.f_handle:read(8))
    end
end

function BinaryReader:hex32(inverse)  -- hex
    local b1, b2, b3, b4 = string.byte(self.f_handle:read(4), 1, 4)
    local h32
    if inverse then
        h32 = string.format("%02X%02X%02X%02X", b4, b3, b2, b1)
    else
        h32 = string.format("%02X%02X%02X%02X", b1, b2, b3, b4)
    end
    return h32
end

function BinaryReader:float(endian_big)  -- float
    local f
    if endian_big then
        f = string.unpack(">f", self.f_handle:read(4))
    else
        f = string.unpack("<f", self.f_handle:read(4))
    end
    return f
end

function BinaryReader:double(endian_big)
    local d
    if endian_big then
        d = string.unpack(">d", self.f_handle:read(4))
    else
        d = string.unpack("<d", self.f_handle:read(4))
    end
    return d
end

function BinaryReader:str(len) -- string
    local str = ""
    if len ~= nil then
        str = self.f_handle:read(len)
    else
        local chars = {}
        while true do
            local char = self.f_handle:read(1)
            if char == "\x00" then break end
            table.insert(chars, char)
        end
        str = table.concat(chars)
    end
    return str
end

function BinaryReader:idstring(str)
    local len = string.len(str)
    local tmp = self.f_handle:read(len)
    assert(str == tmp, "\n\nERROR: " .. tmp .. " != " .. str .. "\n")
end
