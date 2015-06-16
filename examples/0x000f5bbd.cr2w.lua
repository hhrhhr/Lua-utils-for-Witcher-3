--[[
header: A2000000 00000000 001CF27D 
id??	48BEF303 66000E00
size	58464
unk1	E1639DD3
unk2	6

 id   off size      crc
 1:   160 1017 19C088B7
 2:  1177   56 7911454D
 3:     0    0 00000000
 4:  1625    1 ECBB4B55
 5:  1641    2 81CF81EF
 6:     0    0 00000000
 7:     0    0 00000000
 8:     0    0 00000000
 9:     0    0 00000000
10:     0    0 00000000
--]]
--[[ 1177: strings buffer, 56 item[s]
--]]
--[[ 0: handles buffer, 0 items
--]]
--[[ 1625: block_4, 1 item[s]
--]]
--[[ 1641: chunks, 2 item[s]
--]]
--[[ 0: block_6, 0 item[s]
--]]
chunk = {}	-- 2 element[s]
chunk[1] = {	-- 1689: 263 bytes, chunk_1
    -- 1690: type = 'CName', size = 2
    name = "vpea3_sq107_01006525",
    -- 1700: type = 'CDateTime', size = 8
    importFileTimeStamp = 9075324995207591553,
    -- 1716: type = 'String', size = 59
    ['Import file'] = "//cdprs-id574/w3_speech/en/lipsync/VPEA3_SQ107_01006525.re",
    -- 1783: type = 'SAnimationBufferBitwiseCompressionPreset', size = 2
    bitwiseCompressionPreset = "ABBCP_VeryHighQuality",
    -- 1793: type = 'SAnimationBufferBitwiseCompressionSettings', size = 109
    bitwiseCompressionSettings = {
        -- 1802: type = 'Float', size = 4
        translationTolerance = 0,
        -- 1814: type = 'Float', size = 4
        translationSkipFrameTolerance = 0,
        -- 1826: type = 'Float', size = 4
        orientationTolerance = 4.9999998736894e-005,
        -- 1838: type = 'SAnimationBufferOrientationCompressionMethod', size = 2
        orientationCompressionMethod = "ABOCM_PackIn64bitsW",
        -- 1848: type = 'Float', size = 4
        orientationSkipFrameTolerance = 9.9999997473788e-005,
        -- 1860: type = 'Float', size = 4
        scaleTolerance = 0.0010000000474975,
        -- 1872: type = 'Float', size = 4
        scaleSkipFrameTolerance = 0.0010000000474975,
        -- 1884: type = 'Float', size = 4
        trackTolerance = 0,
        -- 1896: type = 'Float', size = 4
        trackSkipFrameTolerance = 0.00050000002374873,
        -- 1908: EOB
    },
    -- 1910: type = 'ptr:IAnimationBuffer', size = 4
    animBuffer = 2,	-- ptr to chunk_2
    -- 1922: type = 'Float', size = 4
    framesPerSecond = 29.782529830933,
    -- 1934: type = 'Float', size = 4
    duration = 6.7824997901917,
    -- 1946: EOB
}
--[[ 1948: !!! left 4 unreaded bytes !!!
0000079C: 00 00 00 00                                     | ....
--]]

chunk[2] = {	-- 1952: 56512 bytes, chunk_2
    -- 1953: type = 'SAnimationBufferBitwiseCompressionPreset', size = 2
    compressionPreset = "ABBCP_VeryHighQuality",
    -- 1963: type = 'SAnimationBufferBitwiseCompressionSettings', size = 109
    compressionSettings = {
        -- 1972: type = 'Float', size = 4
        translationTolerance = 0,
        -- 1984: type = 'Float', size = 4
        translationSkipFrameTolerance = 0,
        -- 1996: type = 'Float', size = 4
        orientationTolerance = 4.9999998736894e-005,
        -- 2008: type = 'SAnimationBufferOrientationCompressionMethod', size = 2
        orientationCompressionMethod = "ABOCM_PackIn64bitsW",
        -- 2018: type = 'Float', size = 4
        orientationSkipFrameTolerance = 9.9999997473788e-005,
        -- 2030: type = 'Float', size = 4
        scaleTolerance = 0.0010000000474975,
        -- 2042: type = 'Float', size = 4
        scaleSkipFrameTolerance = 0.0010000000474975,
        -- 2054: type = 'Float', size = 4
        trackTolerance = 0,
        -- 2066: type = 'Float', size = 4
        trackSkipFrameTolerance = 0.00050000002374873,
        -- 2078: EOB
    },
    -- 2080: type = 'Uint32', size = 4
    sourceDataSize = 1461600,
    -- 2092: type = 'Uint32', size = 4
    version = 2,
    -- 2104: type = 'array:129,0,SAnimationBufferBitwiseCompressedBoneTrack', size = 340
    bones = { -- 2 element[s] of 'SAnimationBufferBitwiseCompressedBoneTrack'
        [1] = {
            -- 2117: type = 'SAnimationBufferBitwiseCompressedData', size = 34
            position = {
                -- 2126: type = 'Float', size = 4
                dt = 0.033576730638742,
                -- 2138: type = 'Int8', size = 1
                compression = 2,
                -- 2147: type = 'Uint16', size = 2
                numFrames = 1,
                -- 2157: EOB
            },
            -- 2159: type = 'SAnimationBufferBitwiseCompressedData', size = 49
            orientation = {
                -- 2168: type = 'Float', size = 4
                dt = 0.033576730638742,
                -- 2180: type = 'Uint16', size = 2
                numFrames = 1,
                -- 2190: type = 'Uint32', size = 4
                dataAddr = 6,
                -- 2202: type = 'Uint32', size = 4
                dataAddrFallback = 6,
                -- 2214: EOB
            },
            -- 2216: type = 'SAnimationBufferBitwiseCompressedData', size = 58
            scale = {
                -- 2225: type = 'Float', size = 4
                dt = 0.033576730638742,
                -- 2237: type = 'Int8', size = 1
                compression = 2,
                -- 2246: type = 'Uint16', size = 2
                numFrames = 1,
                -- 2256: type = 'Uint32', size = 4
                dataAddr = 14,
                -- 2268: type = 'Uint32', size = 4
                dataAddrFallback = 14,
                -- 2280: EOB
            },
            -- 2282: EOB
        },
        [2] = {
            -- 2285: type = 'SAnimationBufferBitwiseCompressedData', size = 34
            position = {
                -- 2294: type = 'Float', size = 4
                dt = 0.033576730638742,
                -- 2306: type = 'Int8', size = 1
                compression = 2,
                -- 2315: type = 'Uint16', size = 2
                numFrames = 1,
                -- 2325: EOB
            },
            -- 2327: type = 'SAnimationBufferBitwiseCompressedData', size = 49
            orientation = {
                -- 2336: type = 'Float', size = 4
                dt = 0.033576730638742,
                -- 2348: type = 'Uint16', size = 2
                numFrames = 1,
                -- 2358: type = 'Uint32', size = 4
                dataAddr = 6,
                -- 2370: type = 'Uint32', size = 4
                dataAddrFallback = 6,
                -- 2382: EOB
            },
            -- 2384: type = 'SAnimationBufferBitwiseCompressedData', size = 58
            scale = {
                -- 2393: type = 'Float', size = 4
                dt = 0.033576730638742,
                -- 2405: type = 'Int8', size = 1
                compression = 2,
                -- 2414: type = 'Uint16', size = 2
                numFrames = 1,
                -- 2424: type = 'Uint32', size = 4
                dataAddr = 20,
                -- 2436: type = 'Uint32', size = 4
                dataAddrFallback = 20,
                -- 2448: EOB
            },
            -- 2450: EOB
        },
    },
    -- 2452: type = 'array:129,0,SAnimationBufferBitwiseCompressedData', size = 5966
    tracks = { -- 148 element[s] of 'SAnimationBufferBitwiseCompressedData'
        [1] = {
            -- 2465: type = 'Float', size = 4
            dt = 0.033576730638742,
            -- 2477: type = 'Int8', size = 1
            compression = 2,
            -- 2486: type = 'Uint16', size = 2
            numFrames = 1,
            -- 2496: EOB
        },
        [2] = {
            -- 2499: type = 'Float', size = 4
            dt = 0.033576730638742,
            -- 2511: type = 'Uint16', size = 2
            numFrames = 203,
            -- 2521: type = 'Uint32', size = 4
            dataAddr = 26,
            -- 2533: type = 'Uint32', size = 4
            dataAddrFallback = 26,
            -- 2545: EOB
        },
--
-- cutted 145 elements
--
        [148] = {
            -- 8378: type = 'Float', size = 4
            dt = 0.033576730638742,
            -- 8390: type = 'Uint16', size = 2
            numFrames = 203,
            -- 8400: type = 'Uint32', size = 4
            dataAddr = 49154,
            -- 8412: type = 'Uint32', size = 4
            dataAddrFallback = 49154,
            -- 8424: EOB
        },
    },
    -- 8426: type = 'array:129,0,Int8', size = 49970
    data = { -- 49966 element[s] of 'Int8'
--
-- cutted 49966 elements
--
    },
    -- 58404: type = 'DeferredDataBuffer', size = 2
    deferredData = 0,
    -- 58414: type = 'Float', size = 4
    duration = 6.7824997901917,
    -- 58426: type = 'Uint32', size = 4
    numFrames = 203,
    -- 58438: type = 'Float', size = 4
    dt = 0.033576730638742,
    -- 58450: type = 'Uint32', size = 4
    nonStreamableBones = 2,
    -- 58462: EOB
}

