LuaPrototypeReader = {}
LuaPrototypeReader.__index = LuaPrototypeReader

function LuaPrototypeReader:new(binary)
    local self = setmetatable({}, LuaPrototypeReader)
    
    self.m_binary = binary
    self.m_position = 27
    
    return self
end

function LuaPrototypeReader:addPosition(size)
    self.m_position = self.m_position + size
end

function LuaPrototypeReader:readInt8()
    local int8 = string.unpack("i1", self.m_binary, self.m_position)
    
    self:addPosition(1)
    
    return int8
end

function LuaPrototypeReader:readUInt8()
    return self:readInt8() & 0xFF
end

function LuaPrototypeReader:readInt32()
    local int32 = string.unpack("i4", self.m_binary, self.m_position)
    
    self.m_position = self.m_position + 4
    
    return int32
end

function LuaPrototypeReader:readUInt32()
    return self:readInt32() & 0xFFFFFFFF
end

function LuaPrototypeReader:readNumber()
    local _number = string.unpack("n", self.m_binary, self.m_position)
    
    self.m_position = self.m_position + 8
    
    return _number
end

function LuaPrototypeReader:readStr()
    local strLen = self:readInt32()
    local str = self.m_binary:sub(self.m_position, self.m_position + strLen - 1)
    
    self.m_position = self.m_position + strLen

    return str
end

function LuaPrototypeReader:readIntArray()
    local size = self:readInt32()
    local intArray = {}
        
    for i = 1, size do
        intArray[i] = self:readUInt32()
    end

    return intArray
end