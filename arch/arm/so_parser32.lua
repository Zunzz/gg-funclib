require("so_parser")

SoParser32 = {}
SoParser32.__index = SoParser32

setmetatable(SoParser32, { __index = SoParser })

function SoParser32:new(binaryFileReader)
    local self = SoParser.new(self, binaryFileReader)
    
    self._offSize = 4
    self._maskSize = 31
    
    return self
end

function SoParser32:_parseHeader()
    self._e_shoff = self._binaryFileReader:readUInt32ByOffset(0x20)
    self._e_shentsize = self._binaryFileReader:readUInt16ByOffset(0x2e)
    self._e_shnum = self._binaryFileReader:readUInt16ByOffset(0x30)
end

function SoParser32:_getSectionHeader(secHeaderOff)
    return {
        sh_type = self._binaryFileReader:readUInt32ByOffset(secHeaderOff + 0x4),
        sh_flags = self._binaryFileReader:readUInt32ByOffset(secHeaderOff + 0x8),
        sh_offset = self._binaryFileReader:readUInt32ByOffset(secHeaderOff + 0x10),
        sh_size = self._binaryFileReader:readUInt32ByOffset(secHeaderOff + 0x14),
    }
end

function SoParser32:_getDynSym(index)
    local off = self._dynsym.sh_offset + index * 16
    return {
        st_name = self._binaryFileReader:readUInt32ByOffset(off),
        st_value = self._binaryFileReader:readUInt32ByOffset(off + 4),
    }
end

function SoParser32:_getWord(bloom_off, bloom_size, h)
    local off = bloom_off + ((h >> 5) % bloom_size) * 4
    return self._binaryFileReader:readUInt32ByOffset(off)
end
