local bimg = {}

local function get_default()
  local defaults = {}

  defaults[0] = { term.nativePaletteColor(0) }
  for i = 0, 15 do
    if i ~= 0 then
      defaults[i] = { term.nativePaletteColor(2^i) }
    end
  end

  return defaults
end

local function draw_frame(frame, target)
  local palette = frame.palette or {}
  for i, v in ipairs(palette) do
    target.setPaletteColor(2 ^ i, unpack(v))
  end
  for i, v in ipairs(frame) do
    target.setCursorPos(1, i)
    target.blit(v[1], v[2], v[3])
  end
end

local function draw(image, target, x, y)
  target = target or term

  x = x or 1
  y = y or 1
  local frame_data = image
  local palette = image.palette or get_default()

  for color, tbl in pairs(palette) do
    target.setPaletteColor(2 ^ color, unpack(tbl))
  end

  if image.animated then
    local delay = 0
    for i, v in ipairs(frame_data) do
      draw_frame(v, target)
      sleep(delay)
    end
  else
    draw_frame(frame_data[1], target)
  end
  target.setCursorPos(x, y)
end

function bimg.load_url(urls, delay)
  local content = {}

  for i, v in ipairs(urls) do
    local req = http.get(v, {}, true)

    while true do
      local byte = req.read()
      if not byte or byte == -1 then break end
      content[#content + 1] = byte
    end

    req.close()

  end

  content = string.char(unpack(content))

  local out = textutils.unserialize(content)

  function out:draw(target)
    draw(self, target)
  end

  return out
end

function bimg.load(filename, delay)
  local f = fs.open(filename, "rb")
  local content = {}

  while true do
    local byte = f.read()
    if not byte then break end
    content[#content + 1] = byte
  end

  f.close()

  content = string.char(unpack(content))

  local out = textutils.unserialise(content)

  function out:draw(target)
    draw(self, target)
  end

  return out
end

return bimg

