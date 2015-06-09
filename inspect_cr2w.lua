require("mod_binary_reader")
require("mod_cr2w_reader")

local r = BinaryReader
local c = CR2W

local in_file = assert(arg[1], "no input file")
local out_path = arg[2] or "."

r:open(in_file)

c.init(r, 0, 2) -- file, offset, debug level
c.read_header()
c.start_parse()

r:close()
