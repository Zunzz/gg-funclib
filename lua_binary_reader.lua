function init_lua_binary_reader(binary)
    local lua_binary_reader = {
        binary = binary,
        current_position = 27
    }
    
    function lua_binary_reader:add_current_position(size)
        self.current_position = self.current_position + size
    end

    function lua_binary_reader:read_8()
        local integer8 = string.unpack("i1", self.binary, self.current_position)
        self.current_position = self.current_position + 1
        return integer8
    end
    
    function lua_binary_reader:read_u8()
        return self:read_8() & 0xff
    end
    
    function lua_binary_reader:read_32()
        local integer32 = string.unpack("i4", self.binary, self.current_position)
        self.current_position = self.current_position + 4
        return integer32
    end
    
    function lua_binary_reader:read_u32()
        return self:read_32() & 0xffffffff
    end
    
    function lua_binary_reader:read_lua_number()
        local lua_number = string.unpack("n", self.binary, self.current_position)
        self.current_position = self.current_position + 8
        return lua_number
    end
    
    function lua_binary_reader:read_str()
        local str_len = self:read_32()
        local str = self.binary:sub(self.current_position, self.current_position + str_len - 1)
        lua_binary_reader.current_position = self.current_position + str_len
        return str
    end
    
    function lua_binary_reader:read_int_array()
        local size = self:read_32()
        local int_array = {}
        
        for i = 1, size do
            int_array[i] = self:read_u32()
        end

        return int_array
    end

    return lua_binary_reader
end
