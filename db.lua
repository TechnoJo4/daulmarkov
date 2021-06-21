local mod = {}
local serialize, deserialize

local ffi = require("ffi")
local bor, band = bit.bor, bit.band
local shl, shr = bit.lshift, bit.rshift
local char, byte = string.char, string.byte

-- types for number conversion
local double_t = ffi.typeof("double[1]")
local double_p = ffi.typeof("const double*")


local writers = {
    ["nil"] = function() return char(0) end, -- 0
    ["string"] = function(val) -- 1
        local len = #val
        local b1, b2 = shr(len, 8), band(len, 0xFF)
        return char(1, b1, b2)..val
    end,
    ["number"] = function(val) -- 2
        local ptr = ffi.new("double[1]", { val })
        return char(2)..ffi.string(ptr, 8)
    end,
    ["table"] = function(val) -- 3
        local ser = serialize(val)
        local len = #ser
        if len <= 0xFFFF then
            local b1, b2 = shr(len, 8), band(len, 0xFF)
            return char(3, b1, b2)..ser
        else
            local b1, b2, b3, b4 =
                    band(shr(len, 24), 0xFF),
                    band(shr(len, 16), 0xFF),
                    band(shr(len, 8), 0xFF),
                    band(len, 0xFF)
            return char(6, b1, b2, b3, b4)..ser
        end
    end,
    ["boolean"] = function(val) -- 4 -> true, 5 -> false
        return val and char(4) or char(5)
    end
}

local parsers = {
    [0] = function(_, i) return nil, i+1 end, -- nil
    [1] = function(b, i) -- string
        local b1, b2 = b:byte(i, i+1)
        local len = bor(shl(b1, 8), b2)
        if len == 0 then return "", i+2 end
        return b:sub(i+2, i+1+len), i+len+2
    end,
    [2] = function(b, i) -- number
        return ffi.cast(double_p, b:sub(i,i+7))[0], i+8
    end,
    [3] = function(b, i) -- table with 16-bit size
        local b1, b2 = b:byte(i, i+1)
        if not b2 then p(b, i) end
        local len = bor(shl(b1, 8), b2)
        if len == 0 then return {}, i+2 end
        return deserialize(b:sub(i+2,i+1+len)), i+2+len
    end,
    [4] = function(_, i) return true, i+1 end, -- true
    [5] = function(_, i) return false, i+1 end, -- false
    [6] = function(b, i) -- table with 32-bit size
        local b1, b2, b3, b4 = b:byte(i, i+3)
        local len = bor(shl(b1, 24), bor(shl(b2, 16), bor(shl(b3, 8), b4)))
        return deserialize(b:sub(i+4,i+3+len)), i+4+len
    end,
}

function serialize(val, ret_tbl)
    if type(val) ~= "table" then val = { val } end
    local function _err(val)
        error(("Cannot serialize value of type %q"):format(type(val)))
    end

    local tbl, i = {}, 1
    for k,v in pairs(val) do
        tbl[i]   = (writers[type(k)] or _err)(k)
        tbl[i+1] = (writers[type(v)] or _err)(v)
        i = i + 2
    end

    return ret_tbl and tbl or table.concat(tbl)
end

function deserialize(str)
    local key
    local tbl, i = {}, 1
    while i < #str do
        local v
        local t = byte(str, i, i)
        v, i = parsers[t](str, i+1)
        if key then
            tbl[key] = v
            key = nil
        else key = v end
    end
    return tbl
end

mod.serialize = serialize
mod.deserialize = deserialize

return mod
