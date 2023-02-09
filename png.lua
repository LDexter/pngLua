package.path = "/pngLua/?.lua;" .. package.path
local canvas = require("lib/canvas")
local quill = require("lib/quill")

local factor = 2
local dirInput = "/pngLua/images/input/"
local dirOutput = "/pngLua/images/output/"

-- Make image directories
fs.makeDir(dirInput)
fs.makeDir(dirOutput)

-- Find all input pngs
local files = fs.list(dirInput)


-- Iterate inputs
for _, item in pairs(files) do
    -- Find pathing
    local pathInput = dirInput .. item
    local pathOutput = dirOutput .. item
    pathOutput = quill.replace(pathOutput, ".png", ".json")

    -- Convert and serialise
    local canv = canvas.render(pathInput, factor, pathOutput)
end

sleep(1)
term.clear()
sleep(1)
canvas.open(dirOutput .. "logo.json")
os.pullEvent("char")
