local args = {...}

local chain = require("chain")
local c = chain(args[1])
for line in io.lines() do
    if line == "________________________________END" then
        c.save()
        os.exit()
    end
    c.feed(line)
end
