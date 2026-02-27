SoParser = {}
SoParser.__index = SoParser

local SHT_STRTAB = 0x3
local SHT_HASH = 0x5
local SHT_DYNSYM = 0x0B
local SHT_GNU_HASH = 0x6FFFFFF6

local SHF_ALLOC = 0x2

function SoParser:new(binaryFileReader)
    local self = setmetatable({}, self)
    
    self._binaryFileReader = binaryFileReader
    self._e_shoff = nil
    self._e_shentsize = nil
    self._e_shnum = nil
    self._dynsym = nil
    self.m_dynstr = nil
    self.m_gnu_hash  = nil
    self.m_sysv_hash = nil
    self._offSize = nil
    self._maskSize = nil
    self.m_sysv = {}
    
    return self
end

function SoParser:_parseHeader()
end

function SoParser:_getSectionHeader(secHeaderOff)    
end

local function parseSectionHeaders(self)
    local cur = self._e_shoff

    for i = 0, self._e_shnum - 1 do
        local section = self:_getSectionHeader(cur)

        if section.sh_type == SHT_DYNSYM then
            self._dynsym = section
        elseif section.sh_type == SHT_STRTAB and 
            (section.sh_flags & SHF_ALLOC) ~= 0 then
            self.m_dynstr = section
        elseif section.sh_type == SHT_GNU_HASH then
            self.m_gnu_hash = section
        elseif section.sh_type == SHT_HASH then
            self.m_sysv_hash = section
        end
        
        if self._dynsym and self.m_dynstr and self.m_gnu_hash then
            break
        end

        cur = cur + self._e_shentsize
    end
end

local function parseSysVHash(self)
    self.m_sysv.nbucket = self._binaryFileReader:readUInt32ByOffset(self.m_sysv_hash.sh_offset)    
    self.m_sysv.nchain = self._binaryFileReader:readUInt32ByOffset(self.m_sysv_hash.sh_offset + 4)
    self.m_sysv.bucket_off = self.m_sysv_hash.sh_offset + 8
    self.m_sysv.chain_off = self.m_sysv.bucket_off + self.m_sysv.nbucket * 4
end


function SoParser:_getDynSym(index)
end

function SoParser:_getString(offset)
    return self._binaryFileReader:readCStringByOffset(self.m_dynstr.sh_offset + offset)
end

local function elfHash(name)
    local h = 0
    
    for i = 1, #name do
        h = (h << 4) + name:byte(i)
        
        local g = h & 0xF0000000
        
        if g ~= 0 then
            h = h ~ (g >> 24)
        end

        h = h & (~g)
    end

    return h & 0xFFFFFFFF
end

local function findSymbolSysV(self, name)
    local h = elfHash(name)
    local bucket = h % self.m_sysv.nbucket
    local idx = self._binaryFileReader:readUInt32ByOffset(self.m_sysv.bucket_off + bucket * 4)

    while idx ~= 0 do
        local sym = self:_getDynSym(idx)
        
        if sym and self:_getString(sym.st_name) == name then
            return sym.st_value
        end

        idx = self._binaryFileReader:readUInt32ByOffset(self.m_sysv.chain_off + idx * 4)
    end
end

function SoParser:_getWord(bloom_off, bloom_size, h)
end

local function gnuHash(name)
    local h = 5381
    
    for i = 1, #name do
        h = ((h * 33) + name:byte(i)) & 0xFFFFFFFF
    end

    return h
end


local function findSymbolGNU(self, name)
    local nbuckets = 
        self._binaryFileReader:readUInt32ByOffset(self.m_gnu_hash.sh_offset)
    local symoffset = 
        self._binaryFileReader:readUInt32ByOffset(self.m_gnu_hash.sh_offset + 4)
    local bloom_size = 
        self._binaryFileReader:readUInt32ByOffset(self.m_gnu_hash.sh_offset + 8)
    local bloom_shift = 
        self._binaryFileReader:readUInt32ByOffset(self.m_gnu_hash.sh_offset + 12)
    local bloom_off = self.m_gnu_hash.sh_offset + 16
    
    local bucket_off = bloom_off + bloom_size * self._offSize
    local chain_off = bucket_off + nbuckets * 4
    
    if bloom_size == 0 then return nil end
    
    local h = gnuHash(name)
    
    local word = self:_getWord(bloom_off, bloom_size, h)
    
    local mask =
        (1 << (h & self._maskSize)) |
        (1 << ((h >> bloom_shift) & self._maskSize))
    
    if (word & mask) ~= mask then
        return nil
    end
    
    local off = bucket_off + (h % nbuckets) * 4

    local bucket = self._binaryFileReader:readUInt32ByOffset(off)
    
    if bucket == 0 then return nil end

    local idx = bucket

    while true do
        off = chain_off + (idx - symoffset) * 4
        local hash = self._binaryFileReader:readUInt32ByOffset(off)
        
        if (hash & 0xFFFFFFFE) == (h & 0xFFFFFFFE) then
            local sym = self:_getDynSym(idx)
            if sym and self:_getString(sym.st_name) == name then
                return sym.st_value
            end
        end

        if (hash & 1) ~= 0 then
            break
        end

        idx = idx + 1
    end    
end

function SoParser:parse()
    self:_parseHeader()
    parseSectionHeaders(self)

    if not self.m_gnu_hash then
        parseSysVHash(self)
    end
end

function SoParser:findSymbol(name)
    if self.m_gnu_hash then
        return findSymbolGNU(self, name)
    end

    if self.m_sysv_hash then
        return findSymbolSysV(self, name)
    end

    return nil
end