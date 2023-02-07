![pngLua logo](/logo.png?raw=true)

Png decoder implementation designed to be used in the computercraft minecraft mod.
The main goal of this is to refactor and clean up the original library and make it nicer to use.

Usage
-----

To initialize a new png image:

    img = pngImage(<path to image>, newRowCallback)

so that would be
```lua
local pngImage = require("png")
local img      = pngImage("Example.png")
print(("pixel 1,1 has the colors r:%d g:%d b:%d"):format(table.unpack(img:get_pixel(1,1))))
```
    
The image will then be decoded. The available data from the image is as follows
```
img.width = 0
img.height = 0
img.depth = 0
img.colorType = 0

img:get_pixel(x, y)
```
Decoding the image is synchronous, and will take a long time for large images.

Support
-------

The supported colortypes are as follows:

-    Grayscale
-    Truecolor
-    Indexed
-    Greyscale/alpha
-    Truecolor/alpha

So far the module only supports 256 Colors in png-8, png-24 as well as png-32 files. and no ancillary chunks.

More than 256 colors might be supported (Bit-depths over 8) as long as they align with whole bytes. These have not been tested.

Multiple IDAT chunks of arbitrary lengths are supported, as well as all filters.

Errors
-------
So far no error-checking has been implemented. No crc32 checks are done.
