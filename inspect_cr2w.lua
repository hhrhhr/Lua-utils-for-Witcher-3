require("mod_binary_reader")
require("mod_cr2w_reader")

local r = BinaryReader
local c = CR2W

local in_file = assert(arg[1], "\n\nno input file\n")
local debug_level = tonumber(arg[2]) or 0
local offset = tonumber(arg[3]) or 0

r:open(in_file)

c.init(r, debug_level, offset) -- file, offset, debug level
c.read_header()
c.start_parse()

r:close()
