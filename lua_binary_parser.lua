--  Analyze the binary of a prototype of a Lua function.

function init_lua_binary_parser(lua_binary_reader)
    local lua_binary_parser = {
        lua_binary_reader = lua_binary_reader,
        constants = {},
        nested_functions = {},
        type = {
            NIL = 0,
            BOOLEAN = 1,
            NUMBER = 3,
            STRING = 4
        }
    }
    
    function lua_binary_parser:parse_header()
        self.numparams = self.lua_binary_reader:read_u8()
        self.is_vararg = self.lua_binary_reader:read_u8()
        self.lua_binary_reader:add_current_position(1)
    end
    
    function lua_binary_parser:parse_constants()
        local constants_count = self.lua_binary_reader:read_32()
        
        for i = 1, constants_count do
            local constant_type = self.lua_binary_reader:read_8()
            if constant_type == self.type.NIL then
                self.constants[i] = nil
            elseif constant_type == self.type.BOOLEAN then
                self.constants[i] = self.lua_binary_reader:read_u8() == 1
            elseif constant_type == self.type.NUMBER then
                self.constants[i] = self.lua_binary_reader:read_lua_number()
            elseif constant_type == self.type.STRING then
                self.constants[i] = self.lua_binary_reader:read_str()
            end
        end
    end
    
    function lua_binary_parser:parse_nested_functions()
        local nested_functions_count = self.lua_binary_reader:read_32()
        
        for i = 1, nested_functions_count do
            self.lua_binary_reader:add_current_position(8)
			self.lua_binary_parser.nested_functions[i] = init_lua_binary_parser(self.lua_binary_reader)
			self.lua_binary_parser.nested_functions[i]:parse()
        end
    end
    
    function lua_binary_parser:ignore_upvalues()
        local upvalues_count = self.lua_binary_reader:read_32()
        
        for i = 1, upvalues_count do
            self.lua_binary_reader:read_u8()
            self.lua_binary_reader:read_u8()
        end
    end
    
    function lua_binary_parser:ignore_debug()
        self.lua_binary_reader:read_str()
        self.lua_binary_reader:read_int_array()
		local count = self.lua_binary_reader:read_32()
		
		for i = 1, count do
		    self.lua_binary_reader:read_str()
		    self.lua_binary_reader:read_32()
		    self.lua_binary_reader:read_32()
        end

        count = self.lua_binary_reader:read_32()
        
        for i = 1, count do
            self.lua_binary_reader:read_str()
        end
    end

    function lua_binary_parser:parse()
        self:parse_header()
        self.code = self.lua_binary_reader:read_int_array()
        self:parse_constants()
        self:parse_nested_functions()
        self:ignore_upvalues()
        self:ignore_debug()
    end
    
    return lua_binary_parser
end