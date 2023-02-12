-- package.path = "/pngLua/?.lua;" .. package.path
local canvas = require("lib/canvas")
local quill = require("lib/quill")

-- Directories
local dirInput = "pngLua/images/input/"
local dirOutput = "pngLua/images/output/"


-- Make image directories and paths
if not fs.exists("pngLua/images") then
    fs.makeDir(dirInput)
    fs.makeDir(dirOutput)
    fs.copy("pngLua/test.png", dirInput .. "test.png")
    fs.copy("pngLua/logo.png", dirInput .. "logo.png")
end


-- Find all input pngs
local inputs = fs.list(dirInput)


-- Iterate inputs
print("Converting and rendering with pixelbox...\nPress any key to render next image.")
sleep(2)
for _, item in pairs(inputs) do
    -- Find pathing
    local pathInput = dirInput .. item
    local pathOutput = dirOutput .. item
    pathOutput = quill.replace(pathOutput, ".png", ".bimg")
    
    -- Convert and serialise
    local canv = canvas.render(pathInput, pathOutput)
    
    -- Wait to preview render
    os.pullEvent("char")
    canvas.clear()
end


-- Find all output pngs
local outputs = fs.list(dirOutput)


-- Iterate outputs
print("Opening and rendering with bimg draw...")
sleep(2)
for _, item in pairs(outputs) do
    -- Opening images
    canvas.open(dirOutput .. item)
    os.pullEvent("char")
    term.clear()
end


-- Finished rendering
term.clear()