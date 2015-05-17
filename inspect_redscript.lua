require("mod_binary_reader")

local in_file = assert(arg[1], "no input")
local out_path = arg[2] or "."

local r = BinaryReader
r:open(in_file)


-- strings

r:jmp("end", -4)
local offs = r:uint32()
r:seek(offs)
local num = r:uint32()

for i = 1, num do
    local len = r:uint8()
    if len > 191 then
        len = r:uint8() * 64 + len - 192
    elseif len > 127 then
        len = len - 128
    else
        assert(true, r:pos())
    end
    local str = r:str(len)
    print(i, str)
end



r:close()