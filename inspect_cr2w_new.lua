require("mod_binary_reader")
require("mod_cr2w_reader")

local in_file = assert(arg[1], "no input file")
local out_path = arg[2] or "."

local r = BinaryReader
r:open(in_file)

local c = CR2W
c.init(r)

c.read_header()

c.start_parse()


r:close()
