package.path = "pngLua/?.lua;" .. package.path
local canvas = require("lib/canvas")
local quill = require("lib/quill")

local factor = 4
local dirInput = "/DALL-CC/lib/pngLua/images/input/"
local dirOutput = "/DALL-CC/lib/pngLua/images/output/"


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
    local canv = canvas.render(pathInput, factor, pathOutput)

    -- Wait to preview render
    sleep(2)
    canvas.clear()
end


-- Opening 
canvas.open(dirOutput .. "logo.bimg")
sleep(10)
term.clear()
-- os.pullEvent("char")
