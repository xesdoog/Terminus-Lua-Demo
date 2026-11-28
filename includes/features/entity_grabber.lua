local NATIVE_INPUTS = require("includes.data.native_inputs")
local Config        = require("includes.lib.global_vars").Config
local Helpers       = require("includes.lib.helpers")
local IsBitSet      = Bit.IsBitSet
local FlipBit       = Bit.Flip
local IsPlaying     = Helpers.IsPlaying
local Tooltip       = Helpers.Tooltip


local INPUT_AIM = NATIVE_INPUTS.INPUT_AIM


---@enum eEntityGrabFlags
local eEntityGrabFlags = {
	Human   = 0,
	Animal  = 1,
	Object  = 2,
	Vehicle = 3,
	Alive   = 4
}

local EntityFlagsUiSetup = {
	{ bit = eEntityGrabFlags.Human,   label = "Include Humans", },
	{ bit = eEntityGrabFlags.Animal,  label = "Include Animals", },
	{ bit = eEntityGrabFlags.Object,  label = "Include Objects", },
	{ bit = eEntityGrabFlags.Vehicle, label = "Include Vehicles", },
	{ bit = eEntityGrabFlags.Alive,   label = "Ignore Dead Entities", },
}

---@class PedGrabOptions
local PedGrabOptions = {
	Knockout = false,
	Hogtie   = false,
	Kill     = false
}


---@class EntityGrabber
---@field private m_initialized boolean
local EntityGrabber   = { m_initialized = false }
EntityGrabber.__index = EntityGrabber ---@private

---@private
---@return EntityGrabber
function EntityGrabber:Init()
	if (self.m_initialized) then
		return self
	end

	self.m_initialized = true
	Script.RunInFiber(function()
		while (true) do
			Script.Yield()
			if (not IsPlaying()) then
				continue
			end
			self:OnTick()
		end
	end)

	return self
end

---@public
---@nodiscard
---@return boolean
function EntityGrabber:IsEnabled()
	return Config.entity_grabber.enabled
end

---@private
---@nodiscard
---@param target integer
---@return boolean
function EntityGrabber:ValidateTarget(target)
	if (target == 0 || not ENTITY.DOES_ENTITY_EXIST(target)) then
		return false
	end

	local config      = Config.entity_grabber
	local maxDistance = config.max_distance
	if (maxDistance > 0.0) then
		local entityPos = ENTITY.GET_ENTITY_COORDS(target, false, true)
		local playerPos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_ID(), false, true)
		if (playerPos:Distance(entityPos) > maxDistance) then
			return false
		end
	end

	local entityFlags = config.entity_flags
	if (IsBitSet(entityFlags, eEntityGrabFlags.Object) && ENTITY.IS_ENTITY_AN_OBJECT(target)) then
		return true
	end

	local doDeadCheck = IsBitSet(entityFlags, eEntityGrabFlags.Alive)
	if (IsBitSet(entityFlags, eEntityGrabFlags.Vehicle) && ENTITY.IS_ENTITY_A_VEHICLE(target)) then
		if (doDeadCheck && not VEHICLE.IS_VEHICLE_DRIVEABLE(target, true, true)) then
			return false
		end
		return true
	end

	if (ENTITY.IS_ENTITY_A_PED(target)) then
		if (doDeadCheck && ENTITY.IS_ENTITY_DEAD(target)) then
			return false
		end

		if (IsBitSet(entityFlags, eEntityGrabFlags.Animal) && ENTITY.GET_IS_ANIMAL(target)) then
			return true
		end

		if (IsBitSet(entityFlags, eEntityGrabFlags.Human) && PED.IS_PED_HUMAN(target)) then
			return true
		end
	end

	return false
end

---@private
function EntityGrabber:OnTick()
	local config = Config.entity_grabber
	if not (config.enabled && WEAPON.IS_PED_ARMED(PLAYER.PLAYER_PED_ID(), 4)) then
		return
	end

	local isAiming, entity = PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(PLAYER.PLAYER_ID(), 0)
	if not (isAiming && self:ValidateTarget(entity)) then
		return
	end

	local buttonPressed = PAD.IS_CONTROL_PRESSED(0, INPUT_AIM) && KeyManager:IsKeyJustReleased(config.hotkey)
	if (buttonPressed) then
		Helpers.BringEntity(entity, 1.14, config.ped_options)
	end
end

---@public
function EntityGrabber:Draw()
	local cfg   = Config.entity_grabber
	cfg.enabled = ImGui.Toggle("Enable Script##EntityGrabber", cfg.enabled)
	Tooltip("Aim at an entity with any firerarm and press [F] to bring them to you.")

	if (cfg.enabled) then
		local current = KeyManager:GetKeyByCode(cfg.hotkey)
		if (ImGui.BeginCombo("Hotkey##EntityGrabber", current ? current.name : string.format("0x%X", cfg.hotkey))) then
			for k, v in pairs(eVirtualKeyCodes) do
				local selected = v == cfg.hotkey
				if (ImGui.Selectable(k, selected)) then
					cfg.hotkey = v
				end

				if (selected && ImGui.SetItemDefaultFocus --[[missing from older builds]]) then
					ImGui.SetItemDefaultFocus()
				end
			end
			ImGui.EndCombo()
		end

		cfg.max_distance = ImGui.SliderFloat("Max Distance", cfg.max_distance, 0.0, 500.0)
		Tooltip(
			"Zero means infinite range as long as the entity can be targeted, which depends on your current weapon's range."
		)

		ImGui.SeparatorText("Entity Flags")
		for _, obj in pairs(EntityFlagsUiSetup) do
			local bit = obj.bit
			if select(2, ImGui.Checkbox(obj.label, IsBitSet(cfg.entity_flags, bit))) then
				cfg.entity_flags = FlipBit(cfg.entity_flags, bit)
			end
		end

		if (IsBitSet(cfg.entity_flags, eEntityGrabFlags.Animal) || IsBitSet(cfg.entity_flags, eEntityGrabFlags.Human)) then
			ImGui.SeparatorText("Ped Options")
			local pedConfig    = cfg.ped_options

			pedConfig.Knockout = ImGui.Checkbox("Knockout", pedConfig.Knockout)
			pedConfig.Hogtie   = ImGui.Checkbox("Hogtie", pedConfig.Hogtie)
			pedConfig.Kill     = ImGui.Checkbox("Kill", pedConfig.Kill)
		end
	end
end

return EntityGrabber:Init()
