assert(_VERSION == "Lua 5.3")

-- DDS header       [19]
_fourcc  = 1;    _size    = 2;    _flags   = 3;    _height  = 4
_width   = 5;    _pitch   = 6;    _depth   = 7;    _mipmaps = 8
--_reserved
--  9 10 11 12
-- 13 14 15 16
-- 17 18 19
-- DDSPixelFormat   [32]
_psize   = 20;   _pflags  = 21;   _pfourcc = 22;   _pbpp    = 23
_prmask  = 24;   _pgmask  = 25;   _pbmask  = 26;   _pamask  = 27
-- DDSCaps          [16]
_caps1   = 28;   _caps2   = 29;   _caps3   = 30;   _caps4   = 31
--
_notused = 32
-- DDSHeader10      [20]
_dxgiFmt = 33;   _resDim  = 34;   _miscFlag = 35;  _arraySize   = 36
_reserved   = 37


local function MAKEFOURCC(fourcc)
    local a = string.byte(string.sub(fourcc, 1, 1))
    local b = string.byte(string.sub(fourcc, 2, 2))
    local c = string.byte(string.sub(fourcc, 3, 3))
    local d = string.byte(string.sub(fourcc, 4, 4))
    return a | (b << 8) | (c << 16) | (d << 24)
end

FOURCC_DDS  = MAKEFOURCC("DDS ")
FOURCC_DXT1 = MAKEFOURCC("DXT1")
FOURCC_DXT2 = MAKEFOURCC("DXT2")
FOURCC_DXT3 = MAKEFOURCC("DXT3")
FOURCC_DXT4 = MAKEFOURCC("DXT4")
FOURCC_DXT5 = MAKEFOURCC("DXT5")
FOURCC_RXGB = MAKEFOURCC("RXGB")
FOURCC_ATI1 = MAKEFOURCC("ATI1")
FOURCC_ATI2 = MAKEFOURCC("ATI2")
FOURCC_A2XY = MAKEFOURCC("A2XY")
FOURCC_DX10 = MAKEFOURCC("DX10")


Format_RGB      = 0
Format_RGBA     = Format_RGB
-- DX9 formats.
Format_DXT1     = 1
Format_DXT1a    = 2 -- DXT1 with binary alpha.
Format_DXT3     = 3
Format_DXT5     = 4
Format_DXT5n    = 5 -- Compressed HILO: R=1, G=y, B=0, A=x
-- DX10 formats.
Format_BC1      = Format_DXT1
Format_BC1a     = Format_DXT1a
Format_BC2      = Format_DXT3
Format_BC3      = Format_DXT5
Format_BC3n     = Format_DXT5n
Format_BC4      = 6 -- ATI1
Format_BC5      = 7 -- 3DC, ATI2

DDSD_CAPS           = 0x00000001
DDSD_HEIGHT         = 0x00000002
DDSD_WIDTH          = 0x00000004
DDSD_PITCH          = 0x00000008
DDSD_PIXELFORMAT    = 0x00001000
DDSD_MIPMAPCOUNT    = 0x00020000
DDSD_LINEARSIZE     = 0x00080000
DDSD_DEPTH          = 0x00800000

DDSCAPS_COMPLEX     = 0x00000008
DDSCAPS_TEXTURE     = 0x00001000
DDSCAPS2_VOLUME     = 0x00200000
DDSCAPS_MIPMAP      = 0x00400000
DDSCAPS2_CUBEMAP    = 0x00000200
DDSCAPS2_CUBEMAP_ALL_FACES = 0x0000FC00

DDPF_ALPHAPIXELS    = 0x00000001
DDPF_ALPHA          = 0x00000002
DDPF_FOURCC         = 0x00000004
DDPF_RGB            = 0x00000040
DDPF_NORMAL         = 0x80000000    -- Custom nv flag

-- enum DXGI_FORMAT
DXGI_FORMAT_UNKNOWN = 0
-- enum D3D10_RESOURCE_DIMENSION
D3D10_RESOURCE_DIMENSION_UNKNOWN    = 0
D3D10_RESOURCE_DIMENSION_BUFFER     = 1
D3D10_RESOURCE_DIMENSION_TEXTURE1D  = 2
D3D10_RESOURCE_DIMENSION_TEXTURE2D  = 3
D3D10_RESOURCE_DIMENSION_TEXTURE3D  = 4



-- init
DDSHeader = {}

function DDSHeader:new()
    self[_fourcc]   = FOURCC_DDS
    self[_size]     = 124
    self[_flags]    = DDSD_CAPS | DDSD_PIXELFORMAT
    self[_height]   = 0
    self[_width]    = 0
    self[_pitch]    = 0
    self[_depth]    = 0
    self[_mipmaps]  = 0
    
    for i = 9, 9+11 do
        self[i]     = 0
    end
    self[8+10]        = MAKEFOURCC("_LUA")
    self[8+11]        = MAKEFOURCC("_DDS")
    --
    self[_psize]    = 32
    self[_pflags]   = 0
    self[_pfourcc]  = 0
    self[_pbpp]     = 0
    self[_prmask]   = 0
    self[_pgmask]   = 0
    self[_pbmask]   = 0
    self[_pamask]   = 0
    --
    self[_caps1]    = DDSCAPS_TEXTURE
    self[_caps2]    = 0
    self[_caps3]    = 0
    self[_caps4]    = 0
    self[_notused]  = 0
    --
    self[_dxgiFmt]  = DXGI_FORMAT_UNKNOWN
    self[_resDim]   = D3D10_RESOURCE_DIMENSION_UNKNOWN
    self[_miscFlag] = 0
    self[_arraySize]= 0
    self[_reserved] = 0
end


function DDSHeader:set_width(num)
    self[_flags] = self[_flags] | DDSD_WIDTH
    self[_width] = num
end

function DDSHeader:set_height(num)
    self[_flags] = self[_flags] | DDSD_HEIGHT
    self[_height] = num
end

function DDSHeader:set_depth(num)
    self[_flags] = self[_flags] | DDSD_DEPTH
    self[_height] = num
end

function DDSHeader:set_mipmaps(num)
    if num == 0 or num == 1 then
        self[_flags] = self[_flags] & ~DDSD_MIPMAPCOUNT
        if self[_caps2] == 0 then
            self[_caps1] = DDSCAPS_TEXTURE
        else
            self[_caps1] = DDSCAPS_TEXTURE | DDSCAPS_COMPLEX
        end
    else
        self[_flags] = self[_flags] | DDSD_MIPMAPCOUNT
        self[_mipmaps] = num
        self[_caps1] = self[_caps1] | DDSCAPS_COMPLEX | DDSCAPS_MIPMAP
    end
end

function DDSHeader:set_cubemaps(num)
    if num == 6 then
        self[_caps1] = self[_caps1]| DDSCAPS_COMPLEX
        self[_caps2] = DDSCAPS2_CUBEMAP | DDSCAPS2_CUBEMAP_ALL_FACES
        self[_resDim] = D3D10_RESOURCE_DIMENSION_TEXTURE2D
        self[_arraySize] = 6
    elseif num == 1 then
        self[_resDim] = D3D10_RESOURCE_DIMENSION_TEXTURE2D
    else
        -- TODO: process texture arrays
        self[_resDim] = D3D10_RESOURCE_DIMENSION_TEXTURE2D
    end
end

function DDSHeader:set_linear(size)
    self[_flags] = self[_flags] & ~DDSD_PITCH
    self[_flags] = self[_flags] | DDSD_LINEARSIZE
    self[_pitch] = size
end

function DDSHeader:set_pitch(pitch)
    self[_flags] = self[_flags] & ~DDSD_LINEARSIZE
    self[_flags] = self[_flags] | DDSD_PITCH
    self[_pitch] = pitch
end

function DDSHeader:set_fourcc(fourcc)
    self[_pflags] = DDPF_FOURCC
    self[_pfourcc] = fourcc

    if self[_pfourcc] == FOURCC_ATI2 then
        self[_pbpp] = FOURCC_A2XY
    else
        self[_pbpp] = 0
    end

    self[_prmask] = 0
    self[_pgmask] = 0
    self[_pbmask] = 0
    self[_pamask] = 0
end

function DDSHeader:set_pixel_format(bpp, rmask, gmask, bmask, amask)
    rmask = rmask or 0
    gmask = gmask or 0
    bmask = bmask or 0
    amask = amask or 0

    assert((rmask & gmask) == 0)
    assert((rmask & bmask) == 0)
    assert((rmask & amask) == 0)
    assert((gmask & bmask) == 0)
    assert((gmask & amask) == 0)
    assert((bmask & amask) == 0)

    self[_pflags] = DDPF_RGB
    if amask ~= 0 then
        self[_pflags] = self[_pflags] | DDPF_ALPHAPIXELS
    end

    if bpp == 0 then
        local total = rmask | gmask | bmask | amask
        while total ~= 0 do
            bpp = bpp + 1
            total = total >> 1
        end
    end

    assert(bpp > 0 and bpp <= 32)

    -- align to 8
    if     bpp <= 8  then bpp = 8
    elseif bpp <= 16 then bpp = 16
    elseif bpp <= 24 then bpp = 24
    else                  bpp = 32
    end

    self[_pfourcc] = 0
    self[_pbpp] = bpp
    self[_prmask] = rmask
    self[_pgmask] = gmask
    self[_pbmask] = bmask
    self[_pamask] = amask
end

function DDSHeader:set_normal_flag(b)
    if b then
        self[_pflags] = self[_pflags] | DDPF_NORMAL
    else
        self[_pflags] = self[_pflags] & ~DDPF_NORMAL
    end
end

function DDSHeader:hasDX10Header()
    return self[_pfourcc] == FOURCC_DX10    -- This is according to AMD
    --return self[_pfourcc] == 0              -- This is according to MS
end


-------------------------------------------------------------------------------

local function computePitch(width, bpp)
    local pitch = width * ((bpp + 7) // 8)
    return ((pitch + 3) // 4 * 4)
end

local function blockSize(fmt)
    if (fmt == Format_DXT1 or fmt == Format_DXT1a) then
        return 8
    elseif (fmt == Format_DXT3) then
        return 16
    elseif (fmt == Format_DXT5 or fmt == Format_DXT5n) then
        return 16
    elseif (fmt == Format_BC4) then
        return 8
    elseif (fmt == Format_BC5) then
        return 16
    end
    return 0
end

local function computeImageSize(width, height, depth, bpp, fmt)
    if fmt == Format_RGBA then
        return depth * height * computePitch(width, bpp)
    else
        return ((width + 3) // 4 * ((height + 3) // 4) * blockSize(fmt))
    end
end

-------------------------------------------------------------------------------

function DDSHeader:generate(width, height, mips, fmt, bpp, cubemap, depth, normal)
    width   = width or 256
    height  = height or 256
    mips    = mips or 1
    fmt     = fmt or Format_DXT1
    bpp     = bpp or 16
    cubemap = cubemap or 1
    depth   = depth or 0
    normal  = normal or false
    
    self:set_width(width)
    self:set_height(height)
    self:set_mipmaps(mips)
    self:set_cubemaps(cubemap)
    if fmt == Format_RGBA then
        self:set_pitch(computePitch(width, bpp))
        self:set_pixel_format(bpp)  -- ...rmask, gmask, bmask, amask
    else
        self:set_linear(computeImageSize(width, height, depth, bpp, fmt))
        if     fmt == Format_DXT1 or fmt == Format_DXT1a then
            self:set_fourcc(FOURCC_DXT1)
            if normal then self:set_normal_flag(true) end
        elseif fmt == Format_DXT3 then
            self:set_fourcc(FOURCC_DXT3)
        elseif fmt == Format_DXT5 then
            self:set_fourcc(FOURCC_DXT5)
        elseif fmt == Format_DXT5n then
            self:set_fourcc(FOURCC_DXT5)
            if normal then self:set_normal_flag(true) end
        elseif fmt == Format_BC4 then
            self:set_fourcc(FOURCC_ATI1)
        elseif fmt == Format_DXT3 then
            self:set_fourcc(FOURCC_ATI2)
            if normal then self:set_normal_flag(true) end
        end
    end
    
    -- TODO: swapBytes()
    
    local header_size = 128 // 4
    if self:hasDX10Header() then
        header_size = 128 + 20 // 4
    end
    
    local data = {}

    for i = 1, header_size do
--        io.write(tostring(self[i]))
--        io.write("\t")
--        if (i % 4) == 0 then io.write("\n") end
        table.insert(data, string.pack("<L", self[i]))
    end
    return table.concat(data)
    
end
