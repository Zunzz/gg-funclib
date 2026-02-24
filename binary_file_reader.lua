BinaryFileReader = {}
BinaryFileReader.__index = BinaryFileReader

function BinaryFileReader:new(file)
    local self = setmetatable({}, BinaryFileReader)
    
    self.m_file = io.open(file, "rb")
    
    return self
end

function BinaryFileReader:readDataByOffset(offset, size)
    local current = self.m_file:seek()
    
    self.m_file:seek("set", offset)
    
    local data = self.m_file:read(size)
    
    self.m_file:seek("set", current)
    
    return data
end

function BinaryFileReader:readUInt8ByOffset(offset)
    local data = self:readDataByOffset(offset, 1)
    return string.unpack("I1", data)
end

function BinaryFileReader:readCStringByOffset(offset)
    local chars = {}
    local pos = offset

    while true do
        local byte = self:readUInt8ByOffset(pos)
        
        if byte == 0 then
            break
        end

        table.insert(chars, string.char(byte))
        
        pos = pos + 1
    end

    return table.concat(chars)
end

function BinaryFileReader:readUInt16ByOffset(offset)
    local data = self:readDataByOffset(offset, 2)
    return string.unpack("I2", data)
end

function BinaryFileReader:readUInt32ByOffset(offset)
    local data = self:readDataByOffset(offset, 4)
    return string.unpack("I4", data)
end

function BinaryFileReader:readUInt64ByOffset(offset)
    local data = self:readDataByOffset(offset, 8)
    return string.unpack("I8", data)
end

function BinaryFileReader:close()
    self.m_file:close()
end