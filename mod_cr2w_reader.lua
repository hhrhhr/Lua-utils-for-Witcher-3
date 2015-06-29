assert(_VERSION == "Lua 5.3")

CR2W = {}
CR2W_type = {}
-- block_1: zero ended strings
local strings = {}  -- block_2: offset, FNV_1a hash
local handles = {}  -- block_3: offset, filetype
local block_4 = {}  -- block_4: ?, ?, ?, ?
local chunks  = {}  -- block_5: ?, ?, size, offset, ?, CRC32
local block_6 = {}  -- block_6: ???

local r = 0         -- file handle
local OFFSET = 0
local DBG = 0       -- 0, 1, 2
local l = 1         -- tab level


local function dbg(d, ...)
    if DBG >= d then
        io.write(...)
    end
end


function CR2W.init(file_handle, debug_level, offset)
    r = file_handle
    DBG = debug_level or 0
    OFFSET = offset
    r:seek(offset or 0)
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
        local s1 = r:uint32()
        local s2 = r:uint32()
        assert(s1 == s2, "\n\n" .. s1 .. " ~= " .. s2 .. "\n")
        print("size", s1)
        -- 0x0020
        print("unk1", r:hex32())
        print("unk2", r:uint32() .. "")
    else
        r:jmp("cur", 36)
    end

    local h = {}
    dbg(1, "\n id   off size      crc\n")
    for i = 1, 10 do
        local offs = r:uint32() + OFFSET
        local size = r:uint32()
        local crc = r:hex32(1)
        table.insert(h, {offs, size, crc})
        dbg(1, string.format("%2d: %5d %4d %s\n", i, offs, size, crc))
        if i > 6 and size > 0 then
            io.write("!!! size not zero, unknown data !!!")
        end
    end
    dbg(1, "--]]\n")


    -- parse strings ----------------------------------------------------------
    strings = {}

    local strbuf = h[1][1]
    local start = h[2][1]
    local count = h[2][2]
    r:seek(start)

    dbg(2, "--[[ " .. r:pos() .. ": strings buffer, " .. count .. " item[s]\n")
    for i = 1, count do
        local offs = r:uint32()
        local crc = r:uint32()

        local pos = r:pos()
        r:seek(strbuf + offs)
        local str = r:str()
        r:seek(pos)

        table.insert(strings, {str = str, crc = crc})
    end

    if DBG > 1 then
        for i = 1, count do
            io.write(string.format("[%4d] 0x%08X '%s'\n",
                    i, strings[i].crc, strings[i].str))
        end
    end
    dbg(2, "--]]\n")


    -- parse handles ----------------------------------------------------------
    handles = {}

    start = h[3][1]
    count = h[3][2]
    r:seek(start)

    dbg(2, "--[[ " .. r:pos() .. ": handles buffer, " .. count .. " items\n")
    for i = 1, count do
        local offs = r:uint32()
        local ftype = r:uint32()    -- file type

        local pos = r:pos()
        r:seek(strbuf + offs)
        local str = r:str()
        r:seek(pos)

        table.insert(handles, {str = str, ftype = ftype})
    end

    if DBG > 1 then
        for i = 1, count do
            io.write(string.format("[%4d] %3d '%s'\n",
                    i, handles[i].ftype, handles[i].str))
        end
    end
    dbg(2, "--]]\n")

    -- parse block_4 ----------------------------------------------------------
    block_4 = {}

    start = h[4][1]
    count = h[4][2]
    r:seek(start)

    dbg(2, "--[[ " .. r:pos() .. ": block_4, " .. count .. " item[s]\n")
    for i = 1, count do
        local t = {}
        for i = 1, 4 do
            local i32 = r:uint32()
            table.insert(t, i32)
        end
        table.insert(block_4, t)
    end

    if DBG > 1 then
        for i = 1, count do
            io.write(string.format("[%4d] %s\n",
                    i, table.concat(block_4[i], ", ")))
        end
    end
    dbg(2, "--]]\n")

    -- parse chunks -----------------------------------------------------------
    chunks = {}

    start = h[5][1]
    count = h[5][2]
    r:seek(start)

    dbg(2, "--[[ " .. r:pos() .. ": chunks, " .. count .. " item[s]\n")
    for i = 1, count do
        local t = {}
        t.u16_1 = r:uint16()
        t.u16_2 = r:uint16()
        t.u32_1 = r:uint32()
        t.size  = r:uint32()
        t.offs  = r:uint32() + OFFSET
        t.u32_2 = r:uint32()
        t.crc   = r:uint32()
        table.insert(chunks, t)
    end

    if DBG > 1 then
        for i = 1, count do
            local t = chunks[i]
            io.write(string.format("[%4d] %4d, 0x%04X, %4d, %8d, %8d, %4d, 0x%08X\n",
                    i, t.u16_1, t.u16_2, t.u32_1, t.size, t.offs, t.u32_2, t.crc 
                ))
        end
    end
    dbg(2, "--]]\n")

    -- parse block_6 ----------------------------------------------------------
    block_6 = {}

    start = h[6][1]
    count = h[6][2]
    r:seek(start)

    dbg(2, "--[[ " .. r:pos() .. ": block_6, " .. count .. " item[s]\n")
    for i = 1, count do
        local t = {}
        t.u32_1 = r:uint32()
        t.u32_2 = r:uint32()
        t.u32_3 = r:uint32()
        t.size1 = r:uint32()
        t.size2 = r:uint32()
        t.crc   = r:uint32()
        table.insert(block_6, t)
    end
    
    if DBG > 1 then
        for i = 1, count do
            local t = block_6[i]
            io.write(string.format("[%4d] %4d, %4d, %4d, %8d, %8d, 0x%08X\n",
                    i, t.u32_1, t.u32_2, t.u32_3, t.size1, t.size2, t.crc 
                ))
        end
    end
    dbg(2, "--]]\n")

    -- parse block_7-10 -------------------------------------------------------
    -- TODO:
end

-------------------------------------------------------------------------------

local function tab()
    io.write(string.rep("    ", l))
end

local function read_unknown_bytes(size, typ)
    local pos = r:pos()
    local sz = math.min(size, 64)
    local hex, str = {}, {}
    
    for i = 1, sz do
        local b = r:uint8()
        table.insert(hex, string.format("%02X", b))
        if b < 32 or b > 126 then b = 46 end
        table.insert(str, string.char(b))
    end
    
    local i = 1
    while i < sz do
        local j = math.min(i+15, sz)
        
        io.write(string.format("%08X: ", pos + i - 1))
        io.write(table.concat(hex, " ", i, j))
        local rep = 15 - sz + i
        if rep < 16 then
            io.write(string.rep("   ", rep))
        end
        io.write(" | ")
        io.write(table.concat(str, "", i, j))
        io.write("\n")
        
        i = i + 16
    end
    
    if size > 64 then io.write("...\n") end
    
    if typ then
        io.stderr:write("WARN: unknown type '" .. typ .. "' at offset " .. pos .. "\n")
    end

    -- skip this data
    local jmp = pos + size
    r:seek(jmp)
end


local function read_value(typ, size, separator)
    if pcall(CR2W_type[typ]) then
        io.write(separator or "")
    else
        io.write("nil" .. (separator or ""))
        io.write("\t--[[ !!! skip " .. size .." bytes ")

        if DBG == 0 then
            io.write("(" .. typ .. ") ")
        end
        io.write("\n")
        read_unknown_bytes(size, typ)
        io.write("--]]")
    end
end


local function parse_type(typ, separator)
    for t1, t2 in string.gmatch(typ, "(%a+):(.+)") do
        if t1 == "array" then
            for d1, d2, t3 in string.gmatch(t2, "(%d+),(%d+),(.+)") do
                CR2W_type.Array(d1, d2, t3, separator)
            end
        elseif t1 == "ptr" then
            CR2W_type.ptr(separator)
        elseif t1 == "handle" then
            CR2W_type.handle(separator)
        elseif t1 == "soft" then
            CR2W_type.Uint16()
            io.write(separator or "")
        else
            assert(false, "\n\nunknown type '" .. t1 .. "'\n")
        end
        return true
    end
    return false
end


local function read_type(var, separator)
    local typ = r:uint16()
    assert(0 ~= typ, "\n\n" .. r:pos()-2 ..": ERROR: type == 0\n")
    --[[ TODO:
    if typ == 0 then
    --]]

    local size = r:uint32() - 4

    typ = strings[typ+1].str
    var = strings[var+1].str

    dbg(1, "type = '" .. typ .. "', size = " .. size .. "\n")

    tab()
    
    -- workaround for spaces in variable names
    if string.find(var, " ") then
        var = "['" .. var .. "']"
    end
    
    io.write(var .. " = ")

    -- skip big data 
    if var == "flatCompiledData" then
        io.write("{},\t--[[ !!! skip " .. size .. " bytes (" .. typ .. ")\n")
        read_unknown_bytes(size)
        io.write("--]]")
    else
        if not parse_type(typ, separator) then
            read_value(typ, size, separator)
        end
    end

    io.write("\n")
    return true
end


local function read_var(separator)
    if DBG > 0 then
        tab()
        io.write("-- " .. r:pos() .. ": ")
    end

    local var = r:uint16()
    if var == 0 then
        dbg(1, "EOB\n")
        return false
    end

    return read_type(var, separator)
end


-- base types -----------------------------------------------------------------

function CR2W_type.Bool()
    local val = r:uint8()
    val = val == 0 and "false" or "true"
    io.write(val)
end

function CR2W_type.Int8()
    local val = r:sint8()
    io.write(val)
end

function CR2W_type.Int16()
    local val = r:sint16()
    io.write(val)
end

function CR2W_type.Int32()
    local val = r:sint32()
    io.write(val)
end

function CR2W_type.Uint8()
    local val = r:uint8()
    io.write(val)
end

function CR2W_type.Uint16()
    local val = r:uint16()
    io.write(val)
end

function CR2W_type.Uint32()
    local val = r:uint32()
    io.write(val)
end

function CR2W_type.Uint64()
    local val = r:uint64()
    io.write(val)
end

function CR2W_type.Float()
    local val = r:float()
    io.write(val)
end

function CR2W_type.String()
    local len = r:uint8()

    assert(len >= 128, "\n\n" .. r:pos()-1 .. ": ERROR: String lenght " .. len .. " >= 128\n")
    len = len - 128
    if len >= 64 then
        len = len - 64
        len = r:uint8() * 64 + len
    end

    local val = r:str(len)
    val = string.gsub(val, "\\", "/")
    io.write("\"" .. val .. "\"")
end

function CR2W_type.StringAnsi()
    local len = r:uint8()

    local val = r:str(len)
    val = string.sub(val, 1, len-1)     -- cut \x00
    val = string.gsub(val, "\\", "/")
    io.write("\"" .. val .. "\"")
end

function CR2W_type.CName()
    local val = r:uint16()
    val = strings[val+1].str
    val = string.gsub(val, "\\", "/")
    io.write("\"" .. val .. "\"")
end

function CR2W_type.Vector(idx)
    assert(0 == r:uint8(), "\n\n" .. r:pos()-1 ..": ERROR: first byte of Vector is not zero\n")
    if idx then
        io.write("[" .. idx .. "] = ")
    end
    io.write("{\n")
    l = l + 1
    while read_var(",") do end
    l = l - 1
    tab()
    io.write("}")
end

function CR2W_type.CVariant()
    local typ = r:uint16()
    local size = r:uint32() - 4

    typ = strings[typ+1].str

    dbg(1, "\t-- type = '" .. typ .. "', size = " .. size .. "\n")
    l = l + 1
    tab()
    if not parse_type(typ) then
        read_value(typ, size)
    end
    l = l - 1
end

-- other types ----------------------------------------------------------------

function CR2W_type.DeferredDataBuffer()         CR2W_type.Int16() end

local generator_Vector = {
    "ApertureDofParams", "Box", "Color", "EulerAngles", "Vector2",
    "CEventGeneratorCameraParams", "CGenericGrassMask", "CGlobalLightingTrajectory",
    "CWorldShadowConfig", "SAnimationBufferBitwiseCompressedData",
    "SAnimationBufferBitwiseCompressionSettings", "SAttachmentReplacements",
    "SDismembermentWoundDecal", "SDynamicDecalMaterialInfo", "SFoliageLODSetting",
    "SFlareParameters",
    "SGlobalSpeedTreeParameters", "SLensFlareGroupsParameters", "SLensFlareParameters",
    "SLightFlickering", "SMeshCookedData", "SMultiCurve", "SSimpleCurve",
    "SWorldEnvironmentParameters", "SWorldMotionBlurSettings", "SWorldRenderSettings",
    "SWorldSkyboxParameters"
}
for k, v in ipairs(generator_Vector) do
    CR2W_type[v] = function(i) CR2W_type.Vector(i) end
end

local generator_CName = {
    "EActorImmortalityMode", "EAIAttitude", "EAreaName", "ECameraPlane", "ECompareFunc",
    "ECompareOp", "ECurveBaseType", "ECurveRelativeMode", "ECurveType", "ECurveValueType",
    "EDoorQuestState", "EFocusModeVisibility",
    "EEnvColorGroup",
    "EInteractionPriority", "EPhantomShape", "EFocusClueAttributeAction",
    "ELayerBuildTag", "ELayerMergedContent", "ELayerType", "ELightChannel",
    "ELogicOperation", "EMeshVertexType",
    "EShowFlags", "eQuestType", "EQueryFact",
    "ERenderDynamicDecalProjection",
    "EStorySceneOutputAction", "ETextureCompression",
    "SAnimationBufferBitwiseCompressionPreset",
    "SAnimationBufferOrientationCompressionMethod",
}
for k, v in ipairs(generator_CName) do
    CR2W_type[v] = function() CR2W_type.CName() end
end

function CR2W_type.CGUID()
    io.write("\"")
    for i = 1, 4 do
        io.write(r:hex32())
    end
    io.write("\"")
end

function CR2W_type.TagList()
    local count = r:uint8()
    io.write("{\n")
    l = l + 1
    tab()
    CR2W_type.CName()
    for i = 2, count do
        io.write(", ")
        CR2W_type.CName()
    end
    io.write("\n")
    l = l - 1
    tab()
    io.write("}")
end

function CR2W_type.LocalizedString()
    local val = r:uint32()
    io.write(string.format("0x%08x", val))
end

function CR2W_type.CDateTime()
    --CR2W_type.Uint64()
    local t = r:uint32()
    t = (t << 32) + r:uint32()
    io.write(t)
end


local function Flags()
    io.write("{\n")
    l = l + 1
    tab()
    while true do
        local val = r:uint16()
        if val == 0 then break end
        val = strings[val+1].str
        io.write("\"" .. val .. "\", ")
    end
    io.write("\n")
    l = l - 1
    tab()
    io.write("}")
end

function CR2W_type.EDrawableFlags() Flags() end

-------------------------------------------------------------------------------

function CR2W_type.ptr(separator)
    local val = r:sint32()
    local sep = separator or ""
    io.write(val .. sep .. "\t-- ptr to chunk_" .. val)
end

function CR2W_type.handle(separator)
    local val = r:sint32()
    local sep = separator or ""
    if val < 0 then
        val = handles[-val].str
        val = string.gsub(val, "\\", "/")
        io.write("\"" .. val .. "\"" .. sep)
    else
        io.write(val .. sep .. "\t-- handle of chunk_" .. val)
    end
end

function CR2W_type.Array(d1, d2, t2, separator)
    local count = r:uint32()
    io.write("{ -- " .. count .. " element[s] of '" .. t2 .. "'\n")
    l = l + 1
    for i = 1, count do
        tab()
        if not parse_type(t2, ",") then
            if not pcall(CR2W_type[t2], i) then
                CR2W_type.Vector(i)
            end
            io.write(",")
        end
        io.write("\n")
    end
    l = l - 1
    tab()
    io.write("}")
    io.write(separator or "")
end


-------------------------------------------------------------------------------

local function unused_data1()
    io.write("unused[" .. i .. "] = {\n")

    local count = r:uint32()
    for j = 1, count do
        tab()
        io.write("-- " .. r:pos() .. ": ")

        local size = r:uint32()
        local var = r:uint16()
        local typ = r:uint16()

        var = strings[var+1].str
        typ = strings[typ+1].str

        io.write(size .. " bytes, ")
        io.write("type = '" .. typ .. "'\n")
        tab()
        io.write(var .. " = ")

        if not parse_type(typ, ",") then
            read_value(typ, size-8, ",")
        end
        io.write("\n")
    end
    io.write("}\n")
end


function CR2W.start_parse()
    local count = #chunks
    io.write("chunk = {}\t-- " .. count .. " element[s]\n")

    for i = 1, count do
        local offset = chunks[i].offs
        local size = chunks[i].size

        r:seek(offset)
        io.write("chunk[" .. i .. "] = {\t-- ")

        dbg(1, r:pos() .. ": ")

        io.write(size)
        io.write(" bytes, chunk_" .. i .. "\n")

        local zero = r:uint8()
        if zero == 0 then
            while read_var(",") do end
        else
            r:jmp("cur", -1)
        end

        io.write("}\n")

        local pos = r:pos()
        local left = size - (pos - offset)
        if left ~= 0 then
            io.write("--[[ " .. pos .. ": !!! left " .. left .. " unreaded bytes !!!\n")
            read_unknown_bytes(left)
            io.write("--]]\n")
        end
        io.write("\n")

        goto skip

        unused_data1()

        ::skip::
    end
end
