--[[
*.w2am, *.w2em, *.xbm
--]]

local zlib = require("zlib")
require("mod_binary_reader")

local in_file = assert(arg[1], "no input")
local out_path = arg[2] or "."

local seek = arg[3] or 0

local r = BinaryReader
r:open(in_file)

r:seek(seek)
r:idstring("CR2W")

io.write("header: ")
for i = 1, 3 do
    io.write(r:hex32())
    io.write(" ")
end
io.write("\n\n")

-- 0x0010
print("id??", r:hex32() .. " " .. r:hex32())
print("size", r:uint32() .. "\\" .. r:uint32())
-- 0x0020
print("unkn", r:hex32())
print("06??", r:uint32())

-- modifiers for 'size': 1-1, 2-8, 3-8, 4-16, 5-24, 6-24
local h = {}
for i = 1, 10 do
    local offs = r:uint32()
    local size = r:uint32()
    local crc = r:hex32(1)
    --io.write(string.format("%2d: %5d %4d %s\n", i, offs, size, crc))
    table.insert(h, {offs, size, crc})
end
print()


local data = {}

local t = {}
local i = 0
while r:pos() < h[1][1] + h[1][2] do
    local str = r:str()
    table.insert(t, str)
    --print("", i, str)
    i = i + 1
end
table.insert(data, t)
print()

local b_size = {1, 2, 2, 4, 6, 6, 0, 0, 0, 0}
for i = 2, 10 do
    print(r:pos(), "block " .. i .. " start")
    local t = {}
    for j = 1, h[i][2] do
        local tt = {}
        for k = 1, b_size[i] do
            local v = r:uint32()
            table.insert(tt, v)
        end
        --print("", table.concat(tt, ", "))
        table.insert(t, tt)
    end
    table.insert(data, t)
    print()
end
print("--------------------------------------------------")


local function bit6()
    local result, shift, b = 0, 0, 0
    repeat
        b = r:uint8()
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


local Float
local Uint8
local Uint16
local Uint32
local Int16
local Int32
local String

local String_back

local CName
local Vector
local TagList
local Array
local CVariant

local IMaterial

local dumb1
local dumb2
local dumb3
local dumb4
local dumb5
local dumb52
local dumb53
local dumb54
local dumb55
local dumb56
local dumb57
local dumb58
local dumb59
local dumb6
local dumb7
local dumb8


local l = 0
local function tab(level)
    io.write(string.rep("\t", level or 0))
end
local function tab_p(level)
    return string.rep("\t", level or 0)
end

local function get2()
    io.write(r:pos() .. ": ")

    local typ = r:uint16()
    local size = r:uint32() - 4

    typ = data[1][typ+1]

    tab(l)
    io.write("(" .. typ .. ") ")

    local val
    if typ == "CName" then val = CName(size)
    elseif typ == "String" then val = String(size)
    elseif typ == "EActorImmortalityMode" then val = CName(size)
    elseif typ == "EAIAttitude" then val = CName(size)
    elseif typ == "EDoorQuestState" then val = CName(size)
    elseif typ == "array:2,0,CName" then val = dumb5(size)
    elseif typ == "Bool" then val = Uint8(size)
    elseif typ == "Color" then val = Vector(size)
    elseif typ == "Int32" then val = Int32(size)
    elseif typ == "Float" then val = Float(size)
    elseif typ == "array:2,0,EEffectType" then val = dumb4(size)
    elseif typ == "array:2,0,ErrandDetailsList" then val = Array(size)
    elseif typ == "GameTimeWrapper" then val = dumb7(size)
    elseif typ == "EFocusClueAttributeAction" then val = CName(size)
    else
        assert(false, "!!!" .. typ .. "!!!")
    end
    
    return true
end

local function get()
    io.write(r:pos() .. ": ")

    local var = r:uint16()
    if var == 0 then 
        tab(l)
        io.write("(EOB)")
        return false
    end
    local typ = r:uint16()
    local size = r:uint32() - 4

    var = data[1][var+1]
    typ = data[1][typ+1]

    tab(l)
    io.write("(" .. typ .. ") " .. var .. " = ")

    local val
    if     typ == "Float" then val = Float()
    elseif typ == "Uint8" then val = Uint8()
    elseif typ == "Uint16" then val = Uint16()
    elseif typ == "Uint32" then val = Uint32()
    elseif typ == "Int16" then val = Int16()
    elseif typ == "Int32" then val = Int32()
    elseif typ == "Bool" then val = Uint8()

    elseif typ == "soft:CEntityTemplate" then val = Uint16()
    elseif typ == "soft:CResource" then val = Uint16()
    elseif typ == "soft:CStoryScene" then val = Uint16()
    elseif typ == "soft:CCommunity" then val = Uint16()
    --elseif typ == "" then val = Uint16()
    --elseif typ == "" then val = Uint16()
    --elseif typ == "" then val = Uint16()
    --elseif typ == "" then val = Uint16()
    --elseif typ == "" then val = Uint16()

    elseif typ == "CVariant" then val = CVariant(size)

    elseif typ == "String" then val = String(size)
    elseif typ == "CName" then val = CName(size)
    elseif typ == "ECompareFunc" then val = CName(size)

    elseif typ == "ETextureCompression" then val = CName(size)
    elseif typ == "EMeshVertexType" then val = CName(size)
    elseif typ == "DeferredDataBuffer" then val = CName(size)
    elseif typ == "ECameraPlane" then val = CName(size)
    elseif typ == "EStorySceneOutputAction" then val = CName(size)
    elseif typ == "EQueryFact" then val = CName(size)
    elseif typ == "ECompareOp" then val = CName(size)
    elseif typ == "ELogicOperation" then val = CName(size)
    elseif typ == "EAreaName" then val = CName(size)

    --elseif typ == "" then val = CName(size)
    --elseif typ == "" then val = CName(size)
    --elseif typ == "" then val = CName(size)
    --elseif typ == "" then val = CName(size)

    elseif typ == "Vector" then val = Vector(size)
    elseif typ == "EulerAngles" then val = Vector(size)
    elseif typ == "Box" then val = Vector(size)
    elseif typ == "SMeshCookedData" then val = Vector(size)
    elseif typ == "CSStoryPhaseNames" then val = Vector(size)
    elseif typ == "CSLayerName" then val = Vector(size)
    --elseif typ == "" then val = Vector(size)
    --elseif typ == "" then val = Vector(size)
    --elseif typ == "" then val = Vector(size)
    --elseif typ == "" then val = Vector(size)
    --elseif typ == "" then val = Vector(size)
    --elseif typ == "" then val = Vector(size)
    --elseif typ == "" then val = Vector(size)

    elseif typ == "TagList" then val = TagList(size)
    elseif typ == "array:2,0,SEntityMapPinInfo" then val = Array(size)
    elseif typ == "array:2,0,SAreaMapPinInfo" then val = Array(size)
    elseif typ == "array:2,0,handle:CEntityTemplate" then val = dumb4(size)
    elseif typ == "array:2,0,handle:IMaterial" then val = dumb1(size)
    elseif typ == "handle:IMaterial" then val = dumb3(size)
    elseif typ == "array:2,0,SMeshChunkPacked" then val = Array(size)
    elseif typ == "array:46,0,Vector" then val = Array(size)
    elseif typ == "array:46,0,Float" then val = dumb1(size)
    elseif typ == "array:46,0,Uint8" then val = dumb2(size)
    elseif typ == "array:2,0,EntitySlot" then val = Array(size)
    elseif typ == "array:2,0,CStorySceneSectionVariantElementInfo" then val = Array(size)
    elseif typ == "array:2,0,StorySceneCameraDefinition" then val = Array(size)
    elseif typ == "array:2,0,SCachedConnections" then val = Array(size)
    elseif typ == "array:2,0,SBlockDesc" then val = Array(size)
    elseif typ == "array:2,0,QuestScriptParam" then val = Array(size)
    elseif typ == "array:2,0,CSTableEntry" then val = Array(size)
    elseif typ == "array:2,0,CSEntitiesEntry" then val = Array(size)
    elseif typ == "array:2,0,CSStoryPhaseEntry" then val = Array(size)
    elseif typ == "array:2,0,CSStoryPhaseTimetableEntry" then val = Array(size)
    elseif typ == "array:2,0,CSStoryPhaseTimetableACategoriesTimetableEntry" then val = Array(size)
    elseif typ == "array:2,0,CSStoryPhaseSpawnTimetableEntry" then val = Array(size)
    elseif typ == "array:2,0,CSStoryPhaseTimetableActionEntry" then val = Array(size)
    elseif typ == "array:2,0,CSStoryPhaseTimetableACategoriesEntry" then val = Array(size)
    --elseif typ == "" then val = Array(size)
    --elseif typ == "" then val = Array(size)
    --elseif typ == "" then val = Array(size)
    --elseif typ == "" then val = Array(size)
    --elseif typ == "" then val = Array(size)
    --elseif typ == "" then val = Array(size)

    elseif typ == "array:2,0,ptr:IGameplayDLCMounter" then val = dumb4(size)
        --elseif typ == "array:2,0,ptr:CBehaviorGraphPoseSlotNode" then val = dumb4(size)

    elseif typ == "ptr:CClipMap" then val = dumb4(size)
    elseif typ == "handle:C2dArray" then val = dumb4(size)
    elseif typ == "handle:CUmbraScene" then val = dumb4(size)
    elseif typ == "ptr:CPathLibWorld" then val = dumb4(size)
    elseif typ == "CWorldShadowConfig" then val = Vector(size)
    elseif typ == "SWorldEnvironmentParameters" then val = Vector(size)
    elseif typ == "handle:CBitmapTexture" then val = dumb4(size)
    elseif typ == "handle:CMesh" then val = dumb4(size)
    elseif typ == "handle:CMaterialInstance" then val = dumb4(size)
    elseif typ == "ptr:CFoliageScene" then val = dumb4(size)
    elseif typ == "ptr:CMergedWorldGeometry" then val = dumb4(size)
    elseif typ == "handle:CCookedExplorations" then val = dumb4(size)
    elseif typ == "handle:CWayPointsCollectionsSet" then val = dumb4(size)
    elseif typ == "ptr:CEntity" then val = dumb4(size)
    elseif typ == "array:2,0,ptr:CEntityTemplateParam" then val = dumb4(size)
    elseif typ == "handle:CSkeleton" then val = dumb4(size)
    elseif typ == "array:2,0,handle:CSkeletalAnimationSet" then val = dumb4(size)
    elseif typ == "array:2,0,ptr:CInventoryDefinitionEntry" then val = dumb4(size)
    elseif typ == "ptr:IInventoryInitializer" then val = dumb4(size)

    elseif typ == "EDrawableFlags" then val = dumb8(size)
    elseif typ == "ELightChannel" then val = dumb4(size)
    elseif typ == "array:2,0,ptr:CStorySceneControlPart" then val = dumb4(size)
    elseif typ == "array:2,0,ptr:CStorySceneSection" then val = dumb4(size)
    elseif typ == "array:2,0,ptr:CStorySceneActor" then val = dumb4(size)
    elseif typ == "ptr:CStorySceneLinkElement" then val = dumb4(size)

    elseif typ == "array:2,0,CStorySceneVoicetagMapping" then val = dumb7(size)

    elseif typ == "array:2,0,ptr:CStorySceneLinkElement" then val = dumb4(size)
    elseif typ == "array:2,0,ptr:CStorySceneSectionVariant" then val = dumb4(size)
    elseif typ == "array:2,0,ptr:CStorySceneElement" then val = dumb4(size)
    elseif typ == "ptr:IQuestCondition" then val = dumb4(size)
    elseif typ == "array:2,0,ptr:CStorySceneDialogsetInstance" then val = dumb4(size)
    elseif typ == "array:2,0,ptr:CStorySceneEventInfo" then val = dumb4(size)
    elseif typ == "ptr:CStorySceneChoice" then val = dumb4(size)
    elseif typ == "array:2,0,ptr:CStorySceneChoiceLine" then val = dumb4(size)
    elseif typ == "array:2,0,ptr:CStorySceneDialogsetSlot" then val = dumb4(size)
    elseif typ == "ptr:IStorySceneChoiceLineAction" then val = dumb4(size)
    elseif typ == "ptr:CQuestGraph" then val = dumb4(size)
    elseif typ == "array:2,0,ptr:CGraphBlock" then val = dumb4(size)
    elseif typ == "ptr:CQuestGraphBlock" then val = dumb4(size)
    elseif typ == "array:2,0,ptr:IQuestCondition" then val = dumb4(size)
    elseif typ == "ptr:IActorConditionType" then val = dumb4(size)
    elseif typ == "array:2,0,ptr:IQuestSpawnsetAction" then val = dumb4(size)

--    elseif typ == "" then val = dumb4(size)
--    elseif typ == "" then val = dumb4(size)
--    elseif typ == "" then val = dumb4(size)
--    elseif typ == "" then val = dumb4(size)

    elseif typ == "handle:C2dArray" then val = dumb4(size)
    elseif typ == "CGlobalLightingTrajectory" then val = Vector(size)
    elseif typ == "SSimpleCurve" then val = Vector(size)
    elseif typ == "array:142,0,SCurveDataEntry" then val = Array(size)
    elseif typ == "handle:CEnvironmentDefinition" then val = dumb4(size)
    elseif typ == "SGlobalSpeedTreeParameters" then val = Vector(size)
    elseif typ == "SWorldSkyboxParameters" then val = Vector(size)
    elseif typ == "SWorldRenderSettings" then val = Vector(size)
    elseif typ == "ApertureDofParams" then val = Vector(size)
    elseif typ == "CEventGeneratorCameraParams" then val = Vector(size)
--    elseif typ == "CWorldShadowConfig" then val = Vector(size)
--    elseif typ == "CWorldShadowConfig" then val = Vector(size)

    elseif typ == "array:2,0,CName" then val = dumb5(size)
    elseif typ == "array:2,0,Bool" then val = dumb52(size)
    elseif typ == "array:2,0,String" then val = dumb53(size)
    
    elseif typ == "EngineTransform" then val = dumb6(size)


    elseif typ == "array:2,0,Uint8" then val = skip(size)
    elseif typ == "array:2,0,SStreamedAttachment" then val = skip(size)
    elseif typ == "SharedDataBuffer" then val = skip(size)
    
    elseif typ == "CGUID" then val = dumb7(size)
    elseif typ == "array:2,0,CGUID" then val = dumb7(size)
    elseif typ == "GameTime" then val = Vector(size)
    --elseif typ == "" then val = dumb7(size)
    --elseif typ == "" then val = dumb7(size)
    --elseif typ == "" then val = dumb7(size)
    --elseif typ == "" then val = dumb7(size)
    --elseif typ == "" then val = dumb7(size)
    --elseif typ == "" then val = dumb7(size)
    --elseif typ == "" then val = dumb7(size)

    elseif typ == "array:2,0,SBehaviorGraphInstanceSlot" then val = skip(size)
--    elseif typ == "array:2,0,Uint8" then val = skip(size)
--    elseif typ == "array:2,0,Uint8" then val = skip(size)
--    elseif typ == "array:2,0,Uint8" then val = skip(size)

    elseif typ == "LocalizedString" then val = Hex32(size)
--    elseif typ == "array:2,0,Uint8" then val = Hex32(size)
--    elseif typ == "array:2,0,Uint8" then val = Hex32(size)
--    elseif typ == "array:2,0,Uint8" then val = Hex32(size)
--    elseif typ == "array:2,0,Uint8" then val = Hex32(size)

    elseif typ == "handle:CQuest" then val = String_back(size)
    elseif typ == "handle:CQuestPhase" then val = String_back(size)
    elseif typ == "handle:CJournalPath" then val = String_back(size)
    elseif typ == "handle:CCommunity" then val = String_back(size)
    --elseif typ == "" then val = String_back(size)
    --elseif typ == "" then val = String_back(size)
    --elseif typ == "" then val = String_back(size)
    --elseif typ == "" then val = String_back(size)

    else
        assert(false, "!!!" .. typ .. "!!!")
    end
    print()

    return true
end

function Float(size)
    local val = r:float()
    io.write(val)
end

function Uint8(size)
    local val = r:uint8()
    io.write(val)
end

function Uint16(size)
    local val = r:uint16()
    io.write(val)
end

function Uint32(size)
    local val = r:uint32()
    io.write(val)
end

function Int16(size)
    local val = r:sint16()
    io.write(val)
end

function Int32(size)
    local val = r:sint32()
    io.write(val)
end

function Hex32(size)
    local val = r:uint32()
    io.write(string.format("0x%08x", val))
end

function Vector(size)
    local stop = r:pos() + size
    local unk = r:uint8()
    print("{ // unk=" .. unk .. ", size=" .. size)
    l = l + 1
    while r:pos() < stop do
        get()
    end
    l = l - 1
    tab(l)
    io.write("}")
end

function CName(size)
    local val = r:uint16()
    val = data[1][val+1]
    io.write("\"" .. val .. "\"")
end

function String_back(size)
    local val = r:sint32()
    if val < 0 then
        val = #data[1] + val
        val = data[1][val+1]
    else
        val = "???(" .. val .. ")"
    end
    io.write("\"" .. val .. "\"")
end

function String(size)
    local len = r:uint8()

    assert(len >= 128)
    len = len - 128
    if len >= 64 then
        len = len - 64
        len = r:uint8() * 64 + len
    end

    val = r:str(len)
    io.write("\"" .. val .. "\"")
end

function TagList(size)
    local s = r:uint8()
    io.write("{\n")
    tab(l+1)
    for i = 1, s do
        CName()
        io.write(" ")
    end
    io.write("\n")
    tab(l)
    io.write("}")
end

function Array(size)
    local stop = r:pos() + size
    local arr = r:uint32()
    print("{ // arr=" .. arr .. ", size=" .. size)
    l = l + 1
    for i = 1, arr do
        local unk0 = r:uint8()
        tab(l)
        io.write("// unk=" .. unk0 .. "\n")
        while get() do end
        print()
    end
    l = l - 1
    io.write("}")
end

function CVariant(size)
    local stop = r:pos() + size
    l = l + 1
    print()
    while r:pos() < stop do
        get2()
    end
    l = l - 1
end

function dumb1(size)
    Uint32()
    io.write(", ")
    Uint32()
end

function dumb2(size)
    local stop = r:pos() + size
    while r:pos() < stop do
        Uint8()
        io.write(", ")
    end
end

function dumb3(size)
    Int32()
    io.write(", ")
    Uint16()
    io.write(", ")
    Int32()
    io.write(", ")
    Int32()
end

function dumb4(size)
    local stop = r:pos() + size
    while r:pos() < stop do
        Int32()
        io.write(", ")
    end
end

function dumb5(size)
    local stop = r:pos() + size
    Uint32()
    io.write("\n")
    l = l + 1
    while r:pos() < stop do
        tab(l)
        CName()
        io.write("\n")
    end
    l = l - 1
end

function dumb52(size)
    local stop = r:pos() + size
    Uint32()
    io.write("\n")
    l = l + 1
    while r:pos() < stop do
        tab(l)
        Uint8()
        io.write("\n")
    end
    l = l - 1
end

function dumb53(size)
    local stop = r:pos() + size
    Uint32()
    io.write("\n")
    l = l + 1
    while r:pos() < stop do
        tab(l)
        String()
        io.write("\n")
    end
    l = l - 1
end

function dumb6(size)
    local stop = r:pos() + size
    Uint8()
    io.write("\n")
    l = l + 1
    while r:pos() < stop do
        tab(l)
        Float()
        io.write(" ")
    end
    l = l - 1
end

function dumb7(size)
    local stop = r:pos() + size
    while r:pos() < stop do
        io.write(string.format("%02X", r:uint8()))
    end
end

function dumb8(size)
    local stop = r:pos() + size
    while r:pos() < stop do
        CName()
        io.write(", ")
    end
end

function dumb9(size)
    local stop = r:pos() + size
    while r:pos() < stop do
        Int16()
        io.write(", ")
    end
end

local skip_file = 1

function skip(size)
    local stop = r:pos() + size
    io.write("\n")
    l = l + 1
    tab(l)
    io.write("--[[ skip " .. size .. " bytes ]]")
    l = l - 1
    local w = assert(io.open("skip_file_" .. skip_file .. ".bin", "w+b"))
    w:write(r:str(size))
    w:close()
    skip_file = skip_file + 1
    assert(r:pos() == stop)
    --r:seek(stop)
end


--local stop = r:pos() + data[5][1][4]

local chunks = #data[5]

for i = 1, chunks do
    r:seek(data[5][i][4])
    print("\n\n-----------------------------------------------------------")
    r:uint8()   -- \x00
    while get() do end
end


print()

r:close()
