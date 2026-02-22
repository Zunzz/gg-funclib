local LuaType = {
    NIL = 0,
    BOOLEAN = 1,
    NUMBER = 3,
    STRING = 4
}

LuaPrototype = {}
LuaPrototype.__index = LuaPrototype

function LuaPrototype:new()
    local self = setmetatable({}, LuaPrototype)
    
    self.m_numParams = nil
    self.m_isVararg = nil
    self.m_code = nil
    self.m_constants = nil
    self.m_nestedFunctions = nil
    self.m_upValues = nil

    return self
end

function LuaPrototype:getNumParams()
    return self.m_numParams
end
    
function LuaPrototype:setNumParams(numParams)
    self.m_numParams = numParams
end

function LuaPrototype:getIsVararg()
    return self.m_isVararg
end
    
function LuaPrototype:setIsVararg(isVararg)
    self.m_isVararg = isVararg
end

function LuaPrototype:getCode()
    return self.m_code
end

function LuaPrototype:setCode(code)
    self.m_code = code
end

function LuaPrototype:getConstants()
    return self.m_constants
end

function LuaPrototype:setConstants(constants)
    self.m_constants = constants
end

function LuaPrototype:getNestedFunctions()
    return self.m_nestedFunctions
end

function LuaPrototype:setNestedFunctions(nestedFunctions)
    self.m_nestedFunctions = nestedFunctions
end

function LuaPrototype:getUpValues()
    return self.m_upValues
end

function LuaPrototype:setUpValues(upValues)
    self.m_upValues = upValues
end

LuaPrototypeParser = {}
LuaPrototypeParser.__index = LuaPrototypeParser

function LuaPrototypeParser:new(prototypeReader)
    local self = setmetatable({}, LuaPrototypeParser)
    
    self.m_prototypeReader = prototypeReader
    self.m_numParams = nil
    self.m_isVararg = nil
    self.m_code = nil
    self.m_constants = {}
    self.m_nestedFunctions = {}
    self.m_upValues = {}
    
    return self
end

local function parseConstants(self)
    local constantsCount = self.m_prototypeReader:readInt32()
    
    for i = 1, constantsCount do
        local constantType = self.m_prototypeReader:readInt8()
        if constantType == LuaType.NIL then
            self.m_constants[i] = nil
        elseif constantType == LuaType.BOOLEAN then
            self.m_constants[i] = self.m_prototypeReader:readUInt8() == 1
        elseif constantType == LuaType.NUMBER then
            self.m_constants[i] = self.m_prototypeReader:readNumber()
        elseif constantType == LuaType.STRING then
            self.m_constants[i] = self.m_prototypeReader:readStr()
        end
    end
end
    
local function parseNestedFunctions(self)
    local nestedFunctionsCount = self.m_prototypeReader:readInt32()
        
    for i = 1, nestedFunctionsCount do
        self.m_prototypeReader:addPosition(8)
        
        self.m_nestedFunctions[i] = LuaPrototypeParser:new(self.m_prototypeReader):parse()
    end
end    
    
local function parseUpvalues(self)
    local upvaluesCount = self.m_prototypeReader:readInt32()
        
    for i = 1, upvaluesCount do
        self.m_upValues[i] = {
            instack = self.m_prototypeReader:readUInt8() ~= 0,
            idx = self.m_prototypeReader:readUInt8()
        }
    end
end    
    
local function ignoreDebug(self)
    local strLen = self.m_prototypeReader:readInt32()
    self.m_prototypeReader:addPosition(strLen)
    
    local count = self.m_prototypeReader:readInt32()
    self.m_prototypeReader:addPosition(count * 4)
    
    count = self.m_prototypeReader:readInt32()
    
    for i = 1, count do
        local strLen = self.m_prototypeReader:readInt32()
        self.m_prototypeReader:addPosition(strLen + 8)
    end
    
    count = self.m_prototypeReader:readInt32()
    
    for i = 1, count do
        local strLen = self.m_prototypeReader:readInt32()
        self.m_prototypeReader:addPosition(strLen)
    end
end    
    
function LuaPrototypeParser:parse()
    self.m_numParams = self.m_prototypeReader:readUInt8()
    self.m_isVararg = self.m_prototypeReader:readUInt8()
    
    self.m_prototypeReader:addPosition(1)
    
    self.m_code = self.m_prototypeReader:readIntArray()
    
    parseConstants(self)
    parseNestedFunctions(self)
    parseUpvalues(self)
    
    ignoreDebug(self)
    
    local prototype = LuaPrototype:new()
    
    prototype:setNumParams(self.m_numParams)
    prototype:setIsVararg(self.m_isVararg)
    prototype:setCode(self.m_code)
    prototype:setConstants(self.m_constants)
    prototype:setNestedFunctions(self.m_nestedFunctions)
    prototype:setUpValues(self.m_upValues)
    
    return prototype
end

