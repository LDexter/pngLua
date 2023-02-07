local Stream = {}

setmetatable(Stream,{__call=function(methods,param)
    local self = {
        position = 1,
        data     = {}
    }

    local str = ""	
    if (param.inputF ~= nil) then
        local file = fs.open(param.inputF, "rb")
        str = file.readAll()
        file.close()
    end
    if (param.input ~= nil) then
        str = param.input
    end

    for i=1,#str do
        self.data[i] = str:byte(i, i)
    end

    return setmetatable(self,{__index=methods})
end})

function Stream:seek(amount)
    self.position = self.position + amount
end

function Stream:readByte()
    if self.position <= 0 then self:seek(1) return nil end
    local byte = self.data[self.position]
    self:seek(1)
    return byte
end

function Stream:readChar()
    if self.position <= 0 then self:seek(1) return nil end
    return string.char(self:readByte())
end

function Stream:readChars(num)
    if self.position <= 0 then self:seek(1) return nil end
    local str = ""
    local i = 1
    while i <= num do
        str = str .. self:readChar()
        i = i + 1
    end
    return str, i-1
end

function Stream:readInt(num)
    if self.position <= 0 then self:seek(1) return nil end

    num = num or 4

    local bytes, count = self:readBytes(num)

    return self:bytesToNum(bytes), count
end

function Stream:readBytes(num)
    if self.position <= 0 then self:seek(1) return nil end

    local tabl = {}
    local i = 1

    while i <= num do
        local curByte = self:readByte()
        if curByte == nil then break end

        tabl[i] = curByte
        i = i + 1
    end
    return tabl, i-1
end

function Stream:bytesToNum(bytes)
    local n = 0

    for _,v in ipairs(bytes) do
        n = n*256 + v
    end

    n = (n > 2147483647) and (n - 4294967296) or n

    return n
end

return Stream