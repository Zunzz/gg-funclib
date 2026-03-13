require("utils")

HookJmp = {}
HookJmp.__index = HookJmp

function HookJmp:new(srcAddr, dstAddr)
    local self = setmetatable({}, self)
    
    self._srcAddr = srcAddr
    self._dstAddr = dstAddr
    self._code = {}
    self._originalInstructions = {}
    
    return self
end

function HookJmp:getOriginalInstructions()
    return self._originalInstructions
end

function HookJmp:saveOriginalInstructions()
end

function HookJmp:emitJmp()
end

function HookJmp:restoreOriginalInstructions()
    gg.setValues(self._originalInstructions)
end

