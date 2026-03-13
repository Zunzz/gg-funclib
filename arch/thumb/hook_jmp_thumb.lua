require("hook_jmp")

HookJmpThumb = {}
HookJmpThumb.__index = HookJmpThumb

setmetatable(HookJmpThumb, { __index = HookJmp })

function HookJmpThumb:new(srcAddr, dstAddr)
    local self = HookJmp.new(self, Utils.clearBit0(srcAddr), dstAddr)
    return self
end

function HookJmpThumb:saveOriginalInstructions()
    local curAddr = self._srcAddr
   
    for i = 1, 6 do
        self._originalInstructions[i] = {
            address = curAddr,
            flags = gg.TYPE_WORD,
        }
        
        curAddr = curAddr + 2
    end
    
    self._originalInstructions =
        gg.getValues(self._originalInstructions)
end

function HookJmpThumb:emitJmp()
    local THUMB_LDR_PC_PC = 0xF000F8DF
    
    if Utils.isAling4(self._srcAddr) == false then
        table.insert(self._code, "~T nop")
    end
    
    table.insert(self._code, Utils.getLower16Bits(THUMB_LDR_PC_PC))
    table.insert(self._code, Utils.getUpper16Bits(THUMB_LDR_PC_PC))
    table.insert(self._code, Utils.getLower16Bits(self._dstAddr))
    table.insert(self._code, Utils.getUpper16Bits(self._dstAddr))
    
    local values = {}
    
    local curAddr = self._srcAddr
    
    for i = 1, #self._code do
        values[i] = {
            address = curAddr,
            flags = gg.TYPE_WORD,
            value = self._code[i]
        }
        
        curAddr = curAddr + 2
    end
    
    gg.setValues(values)
end