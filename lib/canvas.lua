local canvas = {}

package.path = "/pngLua/?.lua;" .. package.path
local png_lua  = require("lib/png_lua")
local pixelbox = require("lib/pixelbox_lite").new(term.current()) -- https://github.com/9551-Dev/apis/blob/main/pixelbox_lite.lua
local resize = require("lib/resize")
local quill = require("lib/quill")

-- Set palette
local palette = {}
for i = 0, 15 do
    palette[2 ^ i] = { term.getPaletteColor(2 ^ i) }
end


-- Colour matches according to palette
local function find_closest_color(c)
    local n, result = 0, {}

    for k, v in pairs(palette) do
        n = n + 1
        result[n] = {
        dist = math.sqrt(
            (v[1] - c.r) ^ 2 +
            (v[2] - c.g) ^ 2 +
            (v[3] - c.b) ^ 2
        ), color = k,
        r = v[1], g = v[2], b = v[3]
        }
    end

    table.sort(result, function(a, b) return a.dist < b.dist end)

    local r = result[1]
    return r.color, r.r, r.g, r.b
end


-- Converts png
function canvas.convert(path, factor)
    -- Prepare and resize png
    local image = png_lua(path)
    image = resize(image, factor, image.width, image.height)

    -- Map image to palette
    for x = 1, image.width do
        for y = 1, image.height do
            pixelbox.CANVAS[y][x] = find_closest_color(image[y][x])
        end
    end

    return pixelbox.CANVAS
end


-- Saves already converted image
function canvas.save(canv, path)
    -- Serialise and write
    local canvJSON = textutils.serialiseJSON(canv)
    quill.scribe(path, "w", canvJSON)
end


-- Renders unconverted png with potential to save
function canvas.render(path, factor, save)
    -- Convert and render
    local canv = canvas.convert(path, factor)
    pixelbox:render()

    -- Potentially save
    if save then
        canvas.save(canv, save)
    end

    return canv
end


-- Opens already saved conversion
function canvas.open(path)
    -- Open and render
    local json = quill.scribe(path, "r")
    local canv = textutils.unserialiseJSON(json)
    pixelbox.CANVAS = canv
    pixelbox:render()
end


return canvas