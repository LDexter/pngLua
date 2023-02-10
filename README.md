![pngLua logo](/logo.png?raw=true)

Png decoder implementation designed to be used in the computercraft minecraft mod.
The main goal of this is to further increase UX for developers, add bimg format conversion, enable easy batch conversion, and _eventually_ build a command line interface around these tools for an alternative experience.

## Usage - Current Fork Additions

### Command Line Interface

Run png for full demo (unfinished, actual interface soon)

### Library Interface

Rendering images

```lua
-- Converts png
canvas.convert(path, factor)

-- Saves already converted image
canvas.save(image, path)

-- Renders unconverted png with potential to save
canvas.render(path, factor, save)

-- Opens already saved conversion
canvas.open(path)

-- Clears the canvas
canvas.clear(bg)
```

## Usage - Unchanged From 9551-Dev Fork

To initialize a new png image:

```lua
local img = pngImage(<path to image>, custom_stream_data, newRowCallback)
```

so that would be

```lua
local pngImage = require("png")
local img      = pngImage("Example.png")
print(("pixel 1,1 has the colors r:%d g:%d b:%d"):format(img:get_pixel(1,1):unpack()))
```

You can use custom_stream_data to directly pipe a string of bytes into the decoder like this

```lua
local img = pngImage(nil,{input="epic data string"},newRowCallback)
```

The decoded image provides these fields:

```
img.width = 0
img.height = 0
img.depth = 0
img.colorType = 0

img:get_pixel(x, y)
```

Decoding the image is synchronous, and will take a long time for large images.

## Support

The supported colortypes are as follows:

- Grayscale
- Truecolor
- Indexed
- Greyscale/alpha
- Truecolor/alpha

So far the module only supports 256 Colors in png-8, png-24 as well as png-32 files. and no ancillary chunks.

More than 256 colors might be supported (Bit-depths over 8) as long as they align with whole bytes. These have not been tested.

Multiple IDAT chunks of arbitrary lengths are supported, as well as all filters.

## Errors

So far no error-checking has been implemented. No crc32 checks are done.
