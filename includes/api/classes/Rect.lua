-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


--------------------------------------
-- Class: Rect
--------------------------------------
---@class Rect : Callable<Rect>
---@field public min Vector2
---@field public max Vector2
---@overload fun(min: Vector2, max: Vector2) : Rect
local Rect = require("includes.api.callable").Callable("Rect", {
	ctor = function(t, ...)
		return t:new(...)
	end
})

---@param min Vector2
---@param max Vector2
---@return Rect
function Rect:new(min, max)
	return setmetatable({ min = min, max = max }, self)
end

---@return float
function Rect:GetWidth()
	return self.max.x - self.min.x
end

---@return float
function Rect:GetHeight()
	return self.max.y - self.min.y
end

---@return Vector2
function Rect:GetSize()
	return Vector2(
		self.max.x - self.min.x,
		self.max.y - self.min.y
	)
end

---@return float
function Rect:GetArea()
	return (self.max.x - self.min.x) * (self.max.y - self.min.y)
end

---@return Vector2
function Rect:GetCenter()
	return Vector2(
		(self.min.x + self.max.x) * 0.5,
		(self.min.y + self.max.y) * 0.5
	)
end

---@param point Vector2
---@return boolean
function Rect:Contains(point)
	return
		point.x >= self.min.x and
		point.x <= self.max.x and
		point.y >= self.min.y and
		point.y <= self.max.y
end

---@param point Vector2
---@return Rect
function Rect:AddPoint(point)
	local min = Vector2(math.min(self.min.x, point.x), math.min(self.min.y, point.y))
	local max = Vector2(math.max(self.max.x, point.x), math.max(self.max.y, point.y))
	return Rect(min, max)
end

---@param other_rect Rect
---@return Rect
function Rect:Add(other_rect)
	local min = Vector2(math.min(self.min.x, other_rect.min.x), math.min(self.min.y, other_rect.min.y))
	local max = Vector2(math.max(self.max.x, other_rect.max.x), math.max(self.max.y, other_rect.max.y))
	return Rect(min, max)
end

---@param other Rect
---@return Rect
function Rect:__add(other)
	return self:Add(other)
end

return Rect
