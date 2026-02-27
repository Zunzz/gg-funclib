require("so_parser")

SoParser64 = {}
SoParser64.__index = SoParser64

setmetatable(SoParser64, { __index = SoParser })

function SoParser64:new(binaryFileReader)
    local self = SoParser.new(self, binaryFileReader)
    
    self._offSize = 8
    self._maskSize = 63
    
    return self
end

function SoParser64:_parseHeader()
    self._e_shoff = self._binaryFileReader:readUInt64ByOffset(0x28)
    self._e_shentsize = self._binaryFileReader:readUInt16ByOffset(0x3A)
    self._e_shnum = self._binaryFileReader:readUInt16ByOffset(0x3C)
end

function SoParser64:_getSectionHeader(secHeaderOff)
    return {
        sh_type = self._binaryFileReader:readUInt32ByOffset(secHeaderOff + 0x04),
        sh_flags = self._binaryFileReader:readUInt64ByOffset(secHeaderOff + 0x8),
        sh_offset = self._binaryFileReader:readUInt64ByOffset(secHeaderOff + 0x18),
        sh_size = self._binaryFileReader:readUInt64ByOffset(secHeaderOff + 0x20),
    }
end

function SoParser64:_getDynSym(index)
    local off = self._dynsym.sh_offset + index * 24
    
    return {
        st_name  = self._binaryFileReader:readUInt32ByOffset(off),
        st_value = self._binaryFileReader:readUInt64ByOffset(off + 8),
    }
end

function SoParser64:_getWord(bloom_off, bloom_size, h)
    local off = bloom_off + ((h >> 6) % bloom_size) * 8
    return self._binaryFileReader:readUInt64ByOffset(off)
end
