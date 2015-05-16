assert(_VERSION == "Lua 5.3")

BinaryReader = {
    f_handle = nil,
    f_size = 0
}

function BinaryReader:open(fullpath)
    self.f_handle = assert(io.open(fullpath, "rb"))
    self.f_size = self.f_handle:seek("end")
    assert(-1 == self.f_size, "your Lua doesn't support files larger than 2 Gb")
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
    return string.unpack("B", self.f_handle:read(1))
end

function BinaryReader:sint8()  -- signed byte
    return string.unpack("b", self.f_handle:read(1))
end

function BinaryReader:uint16(endian_big)  -- unsigned short
    if endian_big then
        return string.unpack(">H", self.f_handle:read(2))
    else
        return string.unpack("<H", self.f_handle:read(2))
    end
end

function BinaryReader:sint16(endian_big)  -- signed short
    if endian_big then
        return string.unpack(">h", self.f_handle:read(2))
    else
        return string.unpack("<h", self.f_handle:read(2))
    end
end

function BinaryReader:uint32(endian_big)  -- unsigned integer
    if endian_big then
        return string.unpack(">I", self.f_handle:read(4))
    else
        return string.unpack("<I", self.f_handle:read(4))
    end
end

function BinaryReader:sint32(endian_big)  -- signed integer
    if endian_big then
        return string.unpack(">i", self.f_handle:read(4))
    else
        return string.unpack("<i", self.f_handle:read(4))
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
    if endian_big then
        return string.unpack(">f", self.f_handle:read(4))
    else
        return string.unpack("<f", self.f_handle:read(4))
    end
end

function BinaryReader:double(endian_big)
    if endian_big then
        return string.unpack(">d", self.f_handle:read(4))
    else
        return string.unpack("<d", self.f_handle:read(4))
    end
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
    assert(str == tmp, "ERROR: " .. tmp .. " != " .. str)
end
