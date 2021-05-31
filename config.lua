local t = {}

t.N = 2
t.MINWORDS = 3
t.MAXCHARS = 1000

t.SEPARATORS = " \n\"\\:;/+~"
t.PREPROCESS_CHARS = "|*_`().,?!"

t.NEXT_SEP = function(str, i)
    return { str:match("()["..t.SEPARATORS.."]+()", i) }
end

t.PREPROCESS = function(str)
    return str:gsub("["..t.PREPROCESS_CHARS.."]+", ''):lower()
end

t.ALLOW = function(str)
    return not str:match("(http)")
end

return t
