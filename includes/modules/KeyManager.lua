-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@diagnostic disable: lowercase-global
local ffi = require("ffi"); ffi.cdef [[ short GetKeyState(int vKey); ]]

local user32 = ffi.load("user32")
_GetKeyState = user32.GetKeyState


--#region defs

---@enum eControlType
eControlType     = {
	KEYBOARD   = 0x0,
	CONTROLLER = 0x1
}

---@enum eVirtualKeyCodes
eVirtualKeyCodes = { -- https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes
	DIGIT_0                = 0x30,
	DIGIT_1                = 0x31,
	DIGIT_2                = 0x32,
	DIGIT_3                = 0x33,
	DIGIT_4                = 0x34,
	DIGIT_5                = 0x35,
	DIGIT_6                = 0x36,
	DIGIT_7                = 0x37,
	DIGIT_8                = 0x38,
	DIGIT_9                = 0x39,
	A                      = 0x41,
	ADD                    = 0x6B,

	-- This is disabled because KeyManager never sees the KEYUP event after alt-tabbing so this key gets stuck on KEYDOWN until you press and release it again.
	-- Since this is a feature keybinding system not a raw input debugger, having it in the first place is counter-intuitive because it's a modifier key
	-- often used for window focus switching and it's reserved by the game as the default character switch key. Imagine assigning it to a "suicide" command then alt-tabbing
	-- during a heist or mission. Now that is simply stupid.
	-- ALT                    = 0x12,

	APPS                   = 0x5D,
	B                      = 0x42,
	BACKSPACE              = 0x8,
	C                      = 0x43,
	CAPSLOCK               = 0x14,
	CLEAR                  = 0xC,
	CTRL                   = 0x11,
	D                      = 0x44,
	DECIMAL                = 0x6E,
	DEL                    = 0x2E,
	DIVIDE                 = 0x6F,
	DOWN                   = 0x28,
	E                      = 0x45,
	END                    = 0x23,
	ENTER                  = 0xD,
	ESC                    = 0x1B,
	EXECUTE                = 0x2B,
	F                      = 0x46,
	F1                     = 0x70,
	F10                    = 0x79,
	F11                    = 0x7A,
	F12                    = 0x7B,
	F13                    = 0x7C,
	F14                    = 0x7D,
	F15                    = 0x7E,
	F16                    = 0x7F,
	F17                    = 0x80,
	F18                    = 0x81,
	F19                    = 0x82,
	F2                     = 0x71,
	F20                    = 0x83,
	F21                    = 0x84,
	F22                    = 0x85,
	F23                    = 0x86,
	F24                    = 0x87,
	F3                     = 0x72,
	F4                     = 0x73,
	F5                     = 0x74,
	F6                     = 0x75,
	F7                     = 0x76,
	F8                     = 0x77,
	F9                     = 0x78,
	G                      = 0x47,
	H                      = 0x48,
	HELP                   = 0x2F,
	HOME                   = 0x24,
	I                      = 0x49,
	INSERT                 = 0x2D,
	J                      = 0x4A,
	K                      = 0x4B,
	L                      = 0x4C,
	LALT                   = 0xA4,
	LCONTROL               = 0xA2,
	LEFT                   = 0x25,
	LSHIFT                 = 0xA0,
	LWIN                   = 0x5B,
	M                      = 0x4D,
	MOUSE4                 = 0x10020,
	MOUSE5                 = 0x20040,
	MULTIPLY               = 0x6A,
	N                      = 0x4E,
	NUMLOCK                = 0x90,
	NUMPAD0                = 0x60,
	NUMPAD1                = 0x61,
	NUMPAD2                = 0x62,
	NUMPAD3                = 0x63,
	NUMPAD4                = 0x64,
	NUMPAD5                = 0x65,
	NUMPAD6                = 0x66,
	NUMPAD7                = 0x67,
	NUMPAD8                = 0x68,
	NUMPAD9                = 0x69,
	O                      = 0x4F,
	P                      = 0x50,
	PAGEDOWN               = 0x22,
	PAGEUP                 = 0x21,
	PAUSE                  = 0x13,
	PRINT                  = 0x2A,
	PRINTSCREEN            = 0x2C,
	Q                      = 0x51,
	R                      = 0x52,
	RALT                   = 0xA5,
	RCONTROL               = 0xA3,
	RIGHT                  = 0x27,
	RSHIFT                 = 0xA1,
	RWIN                   = 0x5C,
	S                      = 0x53,
	SCROLLLOCK             = 0x91,
	SELECT                 = 0x29,
	SEPARATOR              = 0x6C,
	SHIFT                  = 0x10,
	SPACEBAR               = 0x20,
	SUBTRACT               = 0x6D,
	Sleep                  = 0x5F,
	T                      = 0x54,
	TAB                    = 0x9,
	U                      = 0x55,
	UP                     = 0x26,
	V                      = 0x56,
	VK_ATTN                = 0xF6,
	VK_BROWSER_BACK        = 0xA6,
	VK_BROWSER_FAVORITES   = 0xAB,
	VK_BROWSER_FORWARD     = 0xA7,
	VK_BROWSER_HOME        = 0xAC,
	VK_BROWSER_REFRESH     = 0xA8,
	VK_BROWSER_SEARCH      = 0xAA,
	VK_BROWSER_STOP        = 0xA9,
	VK_CRSEL               = 0xF7,
	VK_EREOF               = 0xF9,
	VK_EXSEL               = 0xF8,
	VK_LBUTTON             = 0x1,
	VK_RBUTTON             = 0x2,
	VK_LAUNCH_APP1         = 0xB6,
	VK_LAUNCH_APP2         = 0xB7,
	VK_LAUNCH_MAIL         = 0xB4,
	VK_LAUNCH_MEDIA_SELECT = 0xB5,
	VK_MEDIA_NEXT_TRACK    = 0xB0,
	VK_MEDIA_PLAY_PAUSE    = 0xB3,
	VK_MEDIA_PREV_TRACK    = 0xB1,
	VK_MEDIA_STOP          = 0xB2,
	VK_OEM_1               = 0xBA,
	VK_OEM_102             = 0xE2,
	VK_OEM_2               = 0xBF,
	VK_OEM_3               = 0xC0,
	VK_OEM_4               = 0xDB,
	VK_OEM_5               = 0xDC,
	VK_OEM_6               = 0xDD,
	VK_OEM_7               = 0xDE,
	VK_OEM_8               = 0xDF,
	VK_OEM_CLEAR           = 0xFE,
	VK_OEM_COMMA           = 0xBC,
	VK_OEM_MINUS           = 0xBD,
	VK_OEM_PERIOD          = 0xBE,
	VK_OEM_PLUS            = 0xBB,
	VK_OEM_SPEC_1          = 0xE1,
	VK_OEM_SPEC_10         = 0xF4,
	VK_OEM_SPEC_11         = 0xF5,
	VK_OEM_SPEC_2          = 0xE3,
	VK_OEM_SPEC_3          = 0xE4,
	VK_OEM_SPEC_4          = 0xE6,
	VK_OEM_SPEC_5          = 0xE9,
	VK_OEM_SPEC_6          = 0xF0,
	VK_OEM_SPEC_7          = 0xF1,
	VK_OEM_SPEC_8          = 0xF2,
	VK_OEM_SPEC_9          = 0xF3,
	VK_PA1                 = 0xFD,
	VK_PACKET              = 0xE7,
	VK_PLAY                = 0xFA,
	VK_PROCESSKEY          = 0xE5,
	VK_VOLUME_DOWN         = 0xAE,
	VK_VOLUME_MUTE         = 0xAD,
	VK_VOLUME_UP           = 0xAF,
	VK_ZOOM                = 0xFB,
	W                      = 0x57,
	X                      = 0x58,
	Y                      = 0x59,
	Z                      = 0x5A,
}

--#endregion


--#region Key

--------------------------------------
-- Class: Key
--------------------------------------
---@ignore
---@class VirtualKey
---@field public code integer https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes
---@field public name string The key's name
---@field private m_state boolean
---@field private m_prev_state boolean
---@field private m_just_pressed boolean
---@field private m_just_released boolean
local VirtualKey   = {}
VirtualKey.__index = VirtualKey

---@param code integer
---@param name string
function VirtualKey.new(code, name)
	return setmetatable({
		code            = code,
		name            = name,
		m_state         = false,
		m_prev_state    = false,
		m_just_pressed  = false,
		m_just_released = false,
	}, VirtualKey)
end

function VirtualKey:UpdateState()
	self.m_prev_state    = self.m_state or false
	self.m_state         = (_GetKeyState(self.code) & 0x8000) != 0
	self.m_just_pressed  = self.m_state == true && self.m_prev_state == false
	self.m_just_released = self.m_state == false && self.m_prev_state == true
end

---@return boolean
function VirtualKey:IsPressed()
	return self.m_state == true
end

---@return boolean
function VirtualKey:IsJustPressed()
	return self.m_just_pressed == true
end

---@return boolean
function VirtualKey:IsReleased()
	return self.m_state == false
end

---@return boolean
function VirtualKey:IsJustReleased()
	return self.m_just_released == true
end

--#endregion


--#region KeyManager

--------------------------------------
-- Class: KeyManager
--------------------------------------
---@class KeyManager
---@field private m_virtual_keys VirtualKey[]
---@field private m_vk_map_by_code table<eVirtualKeyCodes, VirtualKey>
---@field private m_vk_map_by_name table<string, VirtualKey>
---@field private m_registered_keybinds table<VirtualKey, { callback: function, looped: boolean }>
---@field private m_in_frame boolean
---@field private m_initialized boolean
---@overload fun(): KeyManager
local KeyManager   = {}
KeyManager.__index = KeyManager

---@private
---@return KeyManager
function KeyManager:Init()
	if (self.m_initialized) then return self end
	if (_G.KeyManager) then return _G.KeyManager end

	self.m_virtual_keys        = {}
	self.m_vk_map_by_code      = {}
	self.m_vk_map_by_name      = {}
	self.m_registered_keybinds = {}

	for name, code in pairs(eVirtualKeyCodes) do
		local key = VirtualKey.new(code, name)
		table.insert(self.m_virtual_keys, key)
		self.m_vk_map_by_code[code] = key
		self.m_vk_map_by_name[name] = key
	end

	Script.RunInFiber(function() self:OnTick() end)

	self.m_initialized = true
	_G.KeyManager      = self
	return self
end

---@param code eVirtualKeyCodes
---@return VirtualKey?
function KeyManager:GetKeyByCode(code)
	if (not code) then
		return
	end

	return self.m_vk_map_by_code[code]
end

---@param name string
---@return VirtualKey?
function KeyManager:GetKeyByName(name)
	if (not name) then
		return
	end

	return self.m_vk_map_by_name[name:upper()]
end

---@param key eVirtualKeyCodes|string
function KeyManager:GetVirtualKey(key)
	if (type(key) == "number") then
		return self:GetKeyByCode(key)
	elseif (type(key) == "string") then
		return self:GetKeyByName(key)
	end
end

---@return eControlType
function KeyManager:GetCurrentControlType()
	return PAD.IS_USING_KEYBOARD_AND_MOUSE(0) and eControlType.KEYBOARD or eControlType.CONTROLLER
end

---@param key eVirtualKeyCodes|string
---@return boolean
function KeyManager:IsKeyPressed(key)
	local _key = self:GetVirtualKey(key)
	return _key and _key:IsPressed() or false
end

---@param key eVirtualKeyCodes|string
---@return boolean
function KeyManager:IsKeyJustPressed(key)
	local _key = self:GetVirtualKey(key)
	return _key and _key:IsJustPressed() or false
end

---@param key eVirtualKeyCodes|string
---@return boolean
function KeyManager:IsKeyReleased(key)
	return not self:IsKeyPressed(key)
end

---@param key eVirtualKeyCodes|string
---@return boolean
function KeyManager:IsKeyJustReleased(key)
	local _key = self:GetVirtualKey(key)
	return _key and _key:IsJustPressed() or false
end

---@return boolean, eVirtualKeyCodes? keyCode, string? keyName
function KeyManager:IsAnyKeyPressed()
	for _, key in ipairs(self.m_virtual_keys) do
		if (key:IsPressed()) then
			return true, key.code, key.name
		end
	end
	return false
end

---@return boolean, eVirtualKeyCodes? keyCode, string? keyName
function KeyManager:IsAnyKeyJustPressed()
	for _, key in ipairs(self.m_virtual_keys) do
		if (key:IsJustPressed()) then
			return true, key.code, key.name
		end
	end
	return false
end

---@return boolean, eVirtualKeyCodes? keyCode, string? keyName
function KeyManager:IsAnyKeyJustReleased()
	for _, key in ipairs(self.m_virtual_keys) do
		if (key:IsJustReleased()) then
			return true, key.code, key.name
		end
	end
	return false
end

---@param key string|integer
---@param callback function
---@param looped? boolean
function KeyManager:RegisterKeybind(key, callback, looped)
	local vKey = self:GetVirtualKey(key)
	if (not vKey) then
		log.fwarning("[KeyManager]: Failed to register keybind! Unknown key '%s'", key)
		return
	end

	self.m_registered_keybinds[vKey] = { callback = callback, looped = looped or false }
end

---@private
function KeyManager:OnTick()
	while (true) do
		Script.Yield(0)

		for _, key in ipairs(self.m_virtual_keys) do
			key:UpdateState()
		end

		for vKey, data in pairs(self.m_registered_keybinds) do
			local trigger = data.looped and vKey:IsPressed() or vKey:IsJustReleased()
			if (trigger) then
				data.callback()
			end
		end
	end
end

--#endregion

return KeyManager:Init()
