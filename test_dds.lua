require("mod_dds_header")

local dds = DDSHeader
dds:new()

-- width, height, mips, fmt, bpp, cubemap, depth, normal
local data = dds:generate(512, 512, 9, 3, 16, 6, 0, false)

local w = assert(io.open("test_dds.bin", "w+b"))
w:write(data)
w:close()
