local function resetPalette(periph)
    local mon
    if periph == "term" then
        mon = term
    else
        mon = assert(peripheral.wrap(periph), periph.." is not a valid peripheral")
    end

    for i = 0, 15 do
        mon.setPaletteColor(2^i, term.nativePaletteColor(2^i))
    end
end

local function main(periph, filename)
if not (periph and filename) then
    print("usage: peripheral filename\nOr peripheral reset")
    return
end

local mon
if periph == "term" then
    mon = term
else
    mon = assert(peripheral.wrap(periph), periph.." is not a valid peripheral")
    mon.setTextScale(0.5)
end
if filename == "reset" then
    resetPalette(periph)
    return
end
local imfile = filename
assert(fs.exists(imfile), imfile.." does not exist")
assert(not fs.isDir(imfile), imfile.." is a directory")
local im = assert(textutils.unserialize(io.open(imfile):read("*a")), imfile.." is not a valid BIMG file")

mon.clear()

local doLoop = true

while doLoop do
    doLoop = #im > 1 or im.animation or im.animated
    -- setup initial palette
    if im.palette then
    for k,v in pairs(im.palette) do
        mon.setPaletteColor(2^k, table.unpack(v))
    end
    end
    for _, frame in ipairs(im) do
    if frame.palette then
        for k,v in pairs(frame.palette) do
        mon.setPaletteColor(2^k, table.unpack(v))
        end
    end
    for yPos,v in pairs(frame) do
        if type(yPos) == "number" then
        mon.setCursorPos(1,yPos)
        mon.blit(table.unpack(v))
        end
    end
    local timer = os.startTimer(im.secondsPerFrame or 0.05)
    repeat
        local event = {os.pullEventRaw()}
        if event[1] == "terminate" then
        resetPalette(periph)
        return
        end
    until event[1] == "timer" and event[2] == timer
    end
end
end

main(...)