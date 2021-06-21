local multipart = require("multipart")
local split = require("coro-split")
local spawn = require("coro-spawn")
local pathjoin = require("pathjoin").pathJoin
local uv = require("uv")
local cwd = uv.cwd()

local function run(args, stdin)
    local child, err = spawn(pathjoin(cwd, "luajit"), {
    	args = args,
    	stdio = {true, true, true},
        cwd = pathjoin(cwd, "..")
    })

    if err then
        return nil, err
    end

    split(function()
        child.stdin.write(stdin)
    end, function()
        local parts = {}
        for data in child.stdout.read do
            parts[#parts + 1] = data
        end
        stdout = table.concat(parts)
    end, function()
        local parts = {}
        for data in child.stderr.read do
            parts[#parts + 1] = data
        end
        stderr = table.concat(parts)
    end, function()
        child.waitExit()
    end)

    print(stderr)

    return stdout
end

require('weblit-app')
    .bind({ host = "127.0.0.1", port = 8880 })

    .use(require('weblit-logger'))
    .use(require('weblit-auto-headers'))
    .use(require('weblit-etag-cache'))

    .use(require('weblit-static')("static"))

    .route({
        method = "POST",
        path = "/feed"
    }, function (req, res, go)
        res.code = 204
        res.body = ""

        local content = multipart(req.body, req.headers["content-type"]):get("content").value

        local stdin = {}

        if content:sub(-1) ~= "\n" then
            content = content .. "\n"
        end

        for line in content:gmatch("(.-)\n") do
            line = line:gsub("\r", "7")
            if #line > 1 then
                stdin[#stdin+1] = line
            end
        end

        stdin[#stdin+1] = "________________________________END\r\n"

        print(run({"feed.lua", "c.txt"}, table.concat(stdin, "\r\n")))
    end)

    .route({
        method = "POST",
        path = "/generate"
    }, function (req, res, go)
        local start = (req.body or ""):match("^ *(.-) *$")
        if #start < 2 then
            start = nil
        end

        res.code = 200
        res.body = run({"generate.lua", "c.txt", start})
    end)

    .start()
