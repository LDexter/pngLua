package.path = "/pngLua/?.lua;" .. package.path
local png_lua  = require("png")
local pixelbox = require("lib/pixelbox_lite").new(term.current()) -- https://github.com/9551-Dev/apis/blob/main/pixelbox_lite.lua

local image = png_lua("pngLua/test.png")

local palette = {}
for i=0,15 do
    palette[2^i] = {term.getPaletteColor(2^i)}
end

local function find_closest_color(c)
    local n,result = 0,{}

    for k,v in pairs(palette) do
        n=n+1
        result[n] = {
            dist=math.sqrt(
                (v[1]-c.r)^2 +
                (v[2]-c.g)^2 +
                (v[3]-c.b)^2
            ),  color=k,
            r=v[1],g=v[2],b=v[3]
        }
    end

    table.sort(result,function(a,b) return a.dist < b.dist end)

    local r = result[1]
    return r.color,r.r,r.g,r.b
end

for x=1,image.width do
    for y=1,image.height do
        pixelbox.CANVAS[y][x] = find_closest_color(image:get_pixel(x,y))
    end
end

pixelbox:render()

os.pullEvent("char")