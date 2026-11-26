-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local Range = require("includes.api.classes.Range")

-- Casts the pointer to an object.
--
-- **IMPORTANT:** You must only cast to objects that take a pointer parameter in their constructors otherwise this method will throw.
--
-- **Example Usage:**
--```lua
--print(memory.handle_to_ptr(self.get_ped()):add(0x10B8):as(CPedWeaponManager))
--```
---@generic T
---@param obj T
---@return T
function Pointer:As(obj)
	if (self:IsNull()) then
		error("Attempt to cast a null pointer")
	end

	local param_type = type(obj)
	if (param_type ~= "table") then
		error(_F("Invalid parameter #1: Expected class, got %s instead.", param_type))
	end

	local obj_name = obj.__type or obj.__name or tostring(obj)
	if (not obj.__ptr_ctor) then
		error(_F("Class '%s' constructor does not expect a pointer.", obj_name))
	end

	if (type(obj.new) == "function") then
		return obj.new(self)
	end

	if (type(obj.init) == "function") then
		return obj:init(self)
	end

	local __mt = getmetatable(obj)
	local call = __mt and __mt.__call or nil
	if (type(call) == "function") then
		return call(obj, self)
	end

	error(_F("Class '%s' has no valid pointer constructor", obj_name))
end

-- Writes a fixed-length string at the address.
---@param str string
---@param max_len integer
function Pointer:AtFixedString(str, max_len)
	str = str:sub(1, max_len - 1)
	local len = #str
	for i = 1, len do
		self:Add(i - 1):WriteUint8(str:byte(i))
	end

	self:Add(len):WriteUint8(0)

	for i = len + 1, max_len - 1 do
		self:Add(i):WriteUint8(0)
	end
end

-- Retrieves a 32-bit displacement value from the memory address, optionally adding an offset and adjustment.
--
-- **Example Usage:**
-- ```lua
-- displacement = pointer:get_disp32(offset, adjust)
-- ```
---@param offset? integer
---@param adjust? integer
---@return number -- imm32 displacement
function Pointer:GetDisp32(offset, adjust)
	if (self:IsNull()) then
		log.warning("Attempt to get imm32 displacement from a null pointer!")
		return 0
	end

	offset = offset or 0
	adjust = adjust or 0
	return self:Add(offset):ReadInt() + adjust
end

---@param size? number bytes, defaults to 16
function Pointer:Dump(size)
	if (self:IsNull()) then
		log.debug("Memory Dump<nullptr>")
		return
	end

	size = size or 0x10
	local result = {}
	for i = 0, size - 1 do
		table.insert(result, _F("%02X", self:Add(i):ReadUint8()))
	end

	log.fdebug(
		"Memory Dump<0x%X + 0x%X>: %s",
		self:GetAddress(),
		size,
		table.concat(result, " ")
	)
end

---@param size? number bytes, defauts to 16
function Pointer:MakePattern(size)
	if (self:IsNull()) then
		return ""
	end

	size        = size or 0x10
	local out   = {}
	local range = Range(0xC0, 0x100)

	for i = 0, size - 1 do
		local byte = self:Add(i):ReadUint8()
		out[#out + 1] = range:Contains(byte) and "??" or _F("%02X", byte)
	end

	return table.concat(out, " ")
end
