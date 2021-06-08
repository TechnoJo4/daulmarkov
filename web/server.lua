local markov = require("../chain")
local multipart = require("multipart")

local chain = markov("test.txt")

require('weblit-app')
    .bind({ host = "0.0.0.0", port = 8880 })

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

        local lines = {}

        if content:sub(-1) ~= "\n" then
            content = content .. "\n"
        end

        for line in content:gmatch("(.-)\n") do
            line = line:gsub("\r", "")
            if #line > 1 then
                chain.feed(line)
            end
        end
    end)

    .route({
        method = "POST",
        path = "/generate"
    }, function (req, res, go)
        local start = req.body:gsub("^ *(.-) *$")
        if #start < 2 then
            start = nil
        end

        res.code = 200
        res.body = chain.generate(start)
    end)

    .start()
