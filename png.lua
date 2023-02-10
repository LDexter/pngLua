package.path = "/pngLua/?.lua;" .. package.path
local canvas = require("lib/canvas")
local quill = require("lib/quill")
local pixelbox = require("lib/pixelbox_lite").new(term.current()) -- https://github.com/9551-Dev/apis/blob/main/pixelbox_lite.lua

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
    pathOutput = quill.replace(pathOutput, ".png", ".bimg")

    -- Convert and serialise
    local image = canvas.render(pathInput, factor, pathOutput)

    -- Wait to preview render
    sleep(2)
    canvas.clear()
end


-- Opening 
canvas.open(dirOutput .. "logo.bimg")
sleep(2)
term.clear()
-- os.pullEvent("char")
