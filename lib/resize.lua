return function(image, factor, w, h)
    local out_x, out_y = 0, 0

    local output = {}

    for y = 1, h, factor do
        out_y = out_y + 1
        output[out_y] = {}
        out_x = 0
        for x = 1, w, factor do
        out_x = out_x + 1
        output[out_y][out_x] = image:get_pixel(x, y)
        end
    end

    output.width, output.height = out_x, out_y

    return setmetatable(output, nil)
end