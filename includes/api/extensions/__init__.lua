-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


math.randomseed(os.time())

---@type table<table, table<integer, string>>
local EnumNamesCache = setmetatable({}, { __mode = "kv" })
local Chrono         = require("includes.modules.Chrono")
Bit                  = require("includes.modules.Bit") -- exposed globally sicne it's used all over the project.

for _, path in ipairs({
	"includes.api.extensions.std_math",
	"includes.api.extensions.std_string",
	"includes.api.extensions.std_table",

	"includes.api.extensions.api_pointer",

}) do require(path) end


_G.Time      = Chrono.Time
_G.Timer     = Chrono.Timer
_G.TimePoint = Chrono.TimePoint
_G.DateTime  = Chrono.DateTime
_G._F        = string.format
_G._J        = Util.Joaat
_G.yield     = Script.Yield
_G.sleep     = Script.Sleep


local type     = type
local tostring = tostring

--#region Global functions

-- A dummy function (no-operation).
function NOP() end

-- A switch-case construct without the closure overhead of `Switch`.
--
-- **Usage Example**:
--
--```Lua
-- local cases = {
--     [1] = function() return "one" end,
--     [2] = function() return "two" end,
--     default = "other"
-- }
-- local result = Match(value, cases)
--```
---@generic R1, R2, R3, R4, R5, R6, R7, R8, R9, R10
---@generic K: anyval
---@generic V
---@param case K
---@param cases table<K, ValueOrFunction<V>>
---@return V|R1, R2?, R3?, R4?, R5?, R6?, R7?, R8?, R9?, R10?
function Match(case, cases)
	local result = cases[case] or cases["default"]
	assert(result ~= nil, "No case matched and no default provided!")
	return (type(result) == "function") and result() or result
end

-- A switch-case construct. This is only beneficial if you have **A LOT** of `if` statements;
--
-- otherwise regular `if-elseif-else` chains or cached lookup tables are faster and create less overhead.
--
-- **[Note]**: Avoid calling this per-frame. This function creates a closure every time it's called and the reason
--
-- for this is that it allows for more flexible and dynamic case handling. Also looks fancier lol
--
-- Example:
--
--```Lua
-- local result = Switch(value) {
--     [1] = function() return "one" end,
--     [2] = function() return "two" end,
--     default = "default"
-- }
--```
--
-- If you want a version with less overhead, use `Match` instead:
--
--```Lua
-- local cases = {
--     [1] = function() return "one" end,
--     [2] = function() return "two" end,
--     default = "default"
-- }
-- local result = Match(value, cases)
--```
---@param case anyval
function Switch(case)
	return function(cases)
		return Match(case, cases)
	end
end

---@param e Enum
---@param index integer
function EnumToString(e, index)
	if (type(e) ~= "table") then
		return "Unknown"
	end

	local cache = EnumNamesCache[e]
	if (not cache) then
		cache = {}
		EnumNamesCache[e] = cache
	end

	local cachedName = cache[index]
	if (cachedName) then return cachedName end

	for k, v in pairs(e) do
		if (v == index) then
			local name = tostring(k)
			cache[index] = name
			return name
		end
	end

	cache[index] = "Unknown"
	return "Unknown"
end

--#endregion
