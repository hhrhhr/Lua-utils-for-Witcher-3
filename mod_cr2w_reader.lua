assert(_VERSION == "Lua 5.3")

CR2W = {}

local r = 0         -- file handle
local header = {}   -- header data
local DBG = 0       -- 0, 1, 2
local l = 1         -- tab level

function CR2W.init(file_handle, offset, debug)
    r = file_handle
    r:seek(offset or 0)
    DBG = debug or 0
end

--[[
block_1 - zero ended strings

block_2 - {
            start offset in block1 (strings),
            32-bit FNV_1a hash of string (with \x00)
}

block_3 - {
            start offset in block1 (name of handles???),
            filetype (69 - .xbm, 90 - .env, 41 - .csv, ...)
}

block_4 - {???}

block_5 - {
            ????,
            ????,
            size,
            offset,
            ????,
            CRC32
}
--]]

function CR2W.read_header()
    r:idstring("CR2W")

    if DBG > 0 then
        print("--[[")
        io.write("header: ")
        for i = 1, 3 do
            io.write(r:hex32() .. " ")
        end
        io.write("\n")

        -- 0x0010
        print("id??", r:hex32() .. " " .. r:hex32())
        print("size", r:uint32() .. "\\" .. r:uint32())
        -- 0x0020
        print("unk1", r:hex32())
        print("unk2", r:uint32() .. "")
    else
        r:jmp("cur", 36)
    end

-- modifiers for 'size': 1-1, 2-8, 3-8, 4-16, 5-24, 6-24
    local h = {}
    if DBG > 0 then
        io.write("\n id   off size      crc\n")
    end
    for i = 1, 10 do
        local offs = r:uint32()
        local size = r:uint32()
        local crc = r:hex32(1)
        table.insert(h, {offs, size, crc})
        if DBG > 0 then
            io.write(string.format("%2d: %5d %4d %s\n", i, offs, size, crc))
        end
    end

    header = {}

    if DBG > 0 then
        print("\n" .. r:pos() .. ":", "block 1 start")
    end
    local t = {}
    local i = 0
    local h2 = h[2][2]

    while r:pos() < h[1][1] + h[1][2] do
        local str = r:str()
        table.insert(t, str)
        if DBG > 1 then
            local ii = i
            if i >= h2 then ii = i - h2 end
            print("", ii, str)
        end
        i = i + 1
    end
    table.insert(header, t)

    --  1  2  3  4  5  6  7  8  9  10
    local b_size = {1, 2, 2, 4, 6, 6, 0, 0, 0, 0}
    for i = 2, 10 do
        if DBG > 0 then
            print(r:pos() .. ":", "block " .. i .. " start")
        end
        local t = {}
        for j = 1, h[i][2] do
            local tt = {}
            for k = 1, b_size[i] do
                local v = r:uint32()
                table.insert(tt, v)
            end
            table.insert(t, tt)
            if DBG > 1 then
                print("", j-1, table.concat(tt, ", "))
            end
        end
        table.insert(header, t)
    end
    if DBG > 0 then
        print("--]]")
    end
end


-------------------------------------------------------------------------------

local function tab()
    io.write(string.rep("    ", l))
end

local function read_value(typ, size, separator)
    local res, err = pcall(CR2W[typ])

    if res == true then
        io.write(separator or "")
    else
        io.write("nil" .. (separator or ""))
        io.write("\t-- !!! skip " .. size .." bytes ")

        if DBG == 0 then
            io.write("(" .. typ .. ") ")
        end

        local pos = r:pos()

        local sz = math.min(size, 12)
        for i = 1, sz do
            local b = r:uint8()
            io.write(string.format("%02X ", b))
        end
        if size > 12 then
            io.write("...")
        end

        io.stderr:write("ERR: unknown type '" .. typ .. "' at offset " .. pos .. "\n")
        -- skip this data
        local jmp = pos + size
        r:seek(jmp)
    end
end


local function parse_type(typ, separator)
    for t1, t2 in string.gmatch(typ, "(%a+):(.+)") do
        if t1 == "array" then
            for d1, d2, t3 in string.gmatch(t2, "(%d+),(%d+),(.+)") do
                CR2W.Array(d1, d2, t3)
            end
        elseif t1 == "ptr" then
            CR2W.ptr(separator)
        elseif t1 == "handle" then
            CR2W.handle(separator)
        else
            assert(false, "unknown type '" .. t1 .. "'")
        end
        return true
    end
    return false
end


local function read_type(var, separator)
    local typ = r:uint16()
    local size = r:uint32() - 4

    typ = header[1][typ+1]
    var = header[1][var+1]

    if DBG > 0 then
        io.write("type = '" .. typ .. "', size = " .. size .. "\n")
    end

    tab()
    io.write(var .. " = ")

    local res = parse_type(typ, separator)
    if not res then
        read_value(typ, size, separator)
    end

    io.write("\n")
end


local function read_var(separator)
    if DBG > 0 then
        tab()
        io.write("-- " .. r:pos() .. ": ")
    end

    local var = r:uint16()
    if var == 0 then 
        if DBG > 0 then
            io.write("EOB\n")
        end
        return false
    end

    read_type(var, separator)

    return true
end


-------------------------------------------------------------------------------

function CR2W.Bool()
    local val = r:uint8()
    val = val == 0 and "false" or "true"
    io.write(val)
end


function CR2W.Int8()
    local val = r:sint8()
    io.write(val)
end

function CR2W.Int16()
    local val = r:sint16()
    io.write(val)
end

function CR2W.Int32()
    local val = r:sint32()
    io.write(val)
end

function CR2W.Uint8()
    local val = r:uint8()
    io.write(val)
end

function CR2W.Uint16()
    local val = r:uint16()
    io.write(val)
end

function CR2W.Uint32()
    local val = r:uint32()
    io.write(val)
end

function CR2W.Uint64()
    local val = r:uint64()
    io.write(val)
end

function CR2W.Float()
    local val = r:float()
    io.write(val)
end

function CR2W.String()
    local len = r:uint8()

    assert(len >= 128)
    len = len - 128
    if len >= 64 then
        len = len - 64
        len = r:uint8() * 64 + len
    end

    local val = r:str(len)
    val = string.gsub(val, "\\", "/")
    io.write("\"" .. val .. "\"")
end

function CR2W.CName()
    local val = r:uint16()
    val = header[1][val+1]
    val = string.gsub(val, "\\", "/")
    io.write("\"" .. val .. "\"")
end

function CR2W.CGUID()
    io.write("\"")
    for i = 1, 4 do
        io.write(r:hex32())
    end
    io.write("\"")
end

function CR2W.Vector()
    --local stop = r:pos() + size
    assert(0 == r:uint8())
    io.write("{\n")
    l = l + 1
    --while r:pos() < stop do
    while read_var(",") do end
    --end
    l = l - 1
    tab()
    io.write("}")
end

function CR2W.EulerAngles()                 CR2W.Vector() end
function CR2W.CWorldShadowConfig()          CR2W.Vector() end
function CR2W.SWorldEnvironmentParameters() CR2W.Vector() end
function CR2W.CGlobalLightingTrajectory()   CR2W.Vector() end
function CR2W.SSimpleCurve()                CR2W.Vector() end
function CR2W.SGlobalSpeedTreeParameters()  CR2W.Vector() end
function CR2W.SWorldSkyboxParameters()      CR2W.Vector() end
function CR2W.SWorldRenderSettings()        CR2W.Vector() end
function CR2W.CGenericGrassMask()           CR2W.Vector() end
function CR2W.Box()                         CR2W.Vector() end
function CR2W.SMeshCookedData()             CR2W.Vector() end
function CR2W.Color()                       CR2W.Vector() end


function CR2W.DeferredDataBuffer()  CR2W.Int16() end

function CR2W.ELayerBuildTag()      CR2W.CName() end
function CR2W.ELayerType()          CR2W.CName() end
function CR2W.EMeshVertexType()     CR2W.CName() end
function CR2W.ETextureCompression() CR2W.CName() end

--function CR2W.() CR2W.() end



function CR2W.ptr(separator)
    local val = r:sint32()
    local sep = separator or ""
    io.write(val .. sep .. "\t-- ptr to chunk_" .. val)
end

function CR2W.handle(separator)
    local val = r:sint32()
    local sep = separator or ""
    if val < 0 then
        local idx = #header[2] - val
        val = header[1][idx]
        val = string.gsub(val, "\\", "/")
        io.write("\"" .. val .. "\"" .. sep)
    else
        io.write(val .. sep .. "\t-- handle of chunk_" .. val)
    end
end

function CR2W.TagList()
    local count = r:uint8()
    io.write("{\n")
    l = l + 1
    tab()
    CR2W.CName()
    for i = 2, count do
        io.write(", ")
        CR2W.CName()
    end
    io.write("\n")
    l = l - 1
    tab()
    io.write("}")
end

--function CR2W.Color()
--    for i = 1, 


function CR2W.Array(d1, d2, t2)
    local count = r:uint32()
    io.write("{ -- " .. count .. " element[s] of '" .. t2 .. "'\n")
    l = l + 1
    for i = 1, count do
        tab()
        local res = parse_type(t2, ",")
        if res then
            io.write("\n")
        else
            local res, err = pcall(CR2W[t2])
            if not res then
                assert(0 == r:uint8())
                io.write("[" .. i .. "] = {\n")
                l = l + 1
                while read_var(",") do end
                l = l - 1
                tab()
                io.write("},\n")
            end
        end
    end
    l = l - 1
    tab()
    io.write("},")
end


-------------------------------------------------------------------------------


function CR2W.start_parse()
    local chunks = #header[5]
    io.write("chunk = {}\t-- " .. chunks .. " element[s]\n")

    for i = 1, chunks do
        local offset = header[5][i][4]
        local size = header[5][i][3]

        r:seek(offset)
        io.write("chunk[" .. i .. "] = {\t-- ")
        if DBG > 0 then
            io.write(r:pos() .. ": ")
        end
        io.write(size)
        io.write(" bytes, chunk_" .. i .. "\n")

        r:uint8()   -- \x00
        while read_var(",") do end

        io.write("}\n")

        local left = size - (r:pos() - offset)
        if left ~= 0 then
            io.write("-- !!! left " .. left .. " of unreaded bytes !!!\n")
        end

        --goto skip

        if (header[5][i][1] & 0xffff) == 4 then
            io.write("unused[" .. i .. "] = {\n")
            local count = r:uint32()
            for j = 1, count do
                tab()
                io.write("-- " .. r:pos() .. ": ")
                local size = r:uint32()
                io.write(size .. " bytes, ")

                local var = r:uint16()
                var = header[1][var+1]

                local typ = r:uint16()
                typ = header[1][typ+1]

                io.write("type = '" .. typ .. "'\n")

                tab()
                io.write(var .. " = ")

                local res = parse_type(typ, ",")
                if not res then
                    --pcall(CR2W[typ])
                    read_value(typ, size-8, ",")
                end

                io.write("\n")
            end
            io.write("}\n")
        end

        ::skip::
    end
end
