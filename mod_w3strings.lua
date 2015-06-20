local keys = {
    [0x83496237] = {0x73946816, "pl"},
    [0x43975139] = {0x79321793, "en"},
    [0x75886138] = {0x42791159, "de"},
    [0x45931894] = {0x12375973, "it"},
    [0x23863176] = {0x75921975, "fr"},
    [0x24987354] = {0x21793217, "cz"},
    [0x18796651] = {0x42387566, "es"},
    [0x18632176] = {0x16875467, "zh"},
    [0x63481486] = {0x42386347, "ru"},
    [0x42378932] = {0x67823218, "hu"},
    [0x54834893] = {0x59825646, "jp"},
}

function get_key(key)
    if key == 0 then
        return 0, "cleartext"
    elseif keys[key] then
        return keys[key][1], keys[key][2]
    else
        assert(false, "\n\n!!! unknown key '" .. string.format("0x%08X", key) .. "' !!!\n")
    end

end

function bit6(reader)
    local result, shift, b, i = 0, 0, 0, 1
    repeat
        b = reader:uint8()
        if b == 128 then return 0 end
        local s = 6
        local mask = 255
        if b > 127 then
            mask = 127
            s = 7
        elseif b > 63 then
            if i == 1 then
                mask = 63
            end
        end
        result = result | ((b & mask) << shift)
        shift = shift + s
        i = i + 1
    until (b < 64) or (i == 3 and b < 128)
    return result
end
