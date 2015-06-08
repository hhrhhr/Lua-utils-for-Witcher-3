assert(_VERSION == "Lua 5.3")

CR2W = {}

local r = 0         -- file handle
local header = {}   -- header data
local DBG = 0       -- 0, 1, 2
local l = 0         -- tab level

function CR2W.init(file_handle, offset, debug)
    r = file_handle
    r:seek(offset or 0)
    DBG = debug or 0
end


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
                print("", table.concat(tt, ", "))
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

local function func(typ)
    for t1, t2 in string.gmatch(typ, "(%a+):(.+)") do
        if t1 == "array" then
            io.write("array {\n")
            for d1, d2, t3 in string.gmatch(t2, "(%d+),(%d+),(.+)") do
                func(t3)
            end
            io.write("}")
        elseif t1 == "ptr" then
            io.write(t2)
        elseif t1 == "handle" then
            io.write(t2)
        end
        io.write("\n")
        return
    end
    print(typ)
end

local function read_type_val(var, separator)
    local typ = r:uint16()
    local size = r:uint32() - 4

    typ = header[1][typ+1]
    var = header[1][var+1]

    if DBG > 0 then
        io.write("type = " .. typ .. ", size = " .. size .. "\n")
    end

    tab()
    io.write(var .. " = ")
    
    

    if string.sub(typ, 1, 6) == "array:" then
        for d1, d2, t2 in string.gmatch(typ, "array:(%d+),(%d+),(.+)") do
            CR2W.Array(size, d1, d2, t2)
        end
    elseif string.sub(typ, 1, 4) == "ptr:" then
        for t2 in string.gmatch(typ, "ptr:(.+)") do
            CR2W.ptr(t2)
        end
    elseif string.sub(typ, 1, 7) == "handle:" then
        for t2 in string.gmatch(typ, "handle:(.+)") do
            CR2W.handle(t2)
        end

    else
        if not (pcall(CR2W[typ], size)) then
            io.write("nil" .. (separator or ""))
            io.write("\t-- !!! skip " .. size .." bytes ")
            
            if DBG == 0 then
                io.write("(" .. typ .. ") ")
            end

            local pos = r:pos()
            local sz = size
            if sz > 12 then sz = 12 end
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

    io.write((separator or "") .. "\n")
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
    read_type_val(var, separator)
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

function CR2W.Float()
    local val = r:float()
    io.write(val)
end

function CR2W.String(size)
    local len = r:uint8()

    assert(len >= 128)
    len = len - 128
    if len >= 64 then
        len = len - 64
        len = r:uint8() * 64 + len
    end

    local val = r:str(len)
    io.write("\"" .. val .. "\"")
end

function CR2W.CName(size)
    local val = r:uint16()
    val = header[1][val+1]
    io.write("\"" .. val .. "\"")
end


function CR2W.Vector(size)
    local stop = r:pos() + size
    assert(0 == r:uint8())
    io.write("{\n")
    l = l + 1
    while r:pos() < stop do
        read_var(",")
    end
    l = l - 1
    tab()
    io.write("}")
end

function CR2W.EulerAngles(size)                 CR2W.Vector(size) end
function CR2W.CWorldShadowConfig(size)          CR2W.Vector(size) end
function CR2W.SWorldEnvironmentParameters(size) CR2W.Vector(size) end
function CR2W.CGlobalLightingTrajectory(size)   CR2W.Vector(size) end
function CR2W.SSimpleCurve(size)                CR2W.Vector(size) end
function CR2W.SGlobalSpeedTreeParameters(size)  CR2W.Vector(size) end
function CR2W.SWorldSkyboxParameters(size)      CR2W.Vector(size) end
function CR2W.SWorldRenderSettings(size)        CR2W.Vector(size) end
function CR2W.CGenericGrassMask(size)           CR2W.Vector(size) end
--function CR2W.(size) CR2W.Vector(size) end


function CR2W.ptr(t2)
    local val = r:sint32()
    io.write(val .. "\t-- ptr to chunk_" .. val)
end

function CR2W.handle(t2)
    local val = r:sint32()
    if val < 0 then
        local idx = val - #header[2]
        io.write("\"" .. header[1][-idx] .. "\"")
    else
        io.write(val .. "\t-- handle of chunk_" .. val)
    end
end

function CR2W.TagList(size)
    local count = r:uint8()
    io.write("{\n")
    l = l + 1
    tab()
    CR2W.CName(size)
    for i = 2, count do
        io.write(", ")
        CR2W.CName(size)
    end
    io.write("\n")
    l = l - 1
    tab()
    io.write("}")
end


function CR2W.Array(size, d1, d2, t2)
    local stop = r:pos() + size
    local count = r:uint32()
    io.write("{ -- " .. count .. " element[s] of '" .. t2 .. "'\n")
    l = l + 1
    for i = 1, count do
        tab()
        if t2 == "CName" then
            CR2W.CName(size)
            io.write(",\n")
        else
            assert(0 == r:uint8())
            io.write("[" .. i .. "] = {\n")
            l = l + 1
            while read_var(",") do end
            l = l - 1
            tab()
            io.write("},\n")
        end
    end
    l = l - 1
    tab()
    io.write("}")
end


-------------------------------------------------------------------------------


function CR2W.start_parse()
    local chunks = #header[5]
    for i = 1, chunks do
        r:seek(header[5][i][4])
        print("\n-- " .. r:pos() .. ": [[ chunk_" .. i .. " ]]\n")
        r:uint8()   -- \x00
        while read_var() do end
    end
end

--for k, v in pairs(_G) do
--    print(k, v)
--end

