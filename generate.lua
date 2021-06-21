local args = {...}
math.randomseed(os.time())

local chain = require("chain")
local c = chain(args[1])
for i=1,10 do
    local str = c.generate(args[2])
    for i=1,#str do
        local c = str:sub(i, i)
        if c ~= "\0" and c ~= " " then
            str = str:sub(i)
            break
        end
    end
    str = str:gsub("7$", "")
    print(str)
    print()
end
