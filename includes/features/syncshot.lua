local Config        = require("includes.lib.global_vars").Config
local Helpers       = require("includes.lib.helpers")
local Set           = require("includes.api.classes.Set")
local IsPlaying     = Helpers.IsPlaying
local NATIVE_INPUTS = require("includes.data.native_inputs")


local INPUT_AIM         = NATIVE_INPUTS.INPUT_AIM
local INPUT_ATTACK      = NATIVE_INPUTS.INPUT_ATTACK
local INPUT_FRONTEND_LB = NATIVE_INPUTS.INPUT_FRONTEND_LB


---@class SyncShot
---@field private m_targets Set<integer>
---@field private m_is_shooting boolean
---@field private m_last_target_cleanup TimePoint
---@field private m_initialized boolean
local SyncShot   = { m_initialized = false }
SyncShot.__index = SyncShot

---@private
---@return SyncShot
function SyncShot:Init()
	if (self.m_initialized) then
		return self
	end

	self.m_targets             = Set()
	self.m_last_target_cleanup = TimePoint()
	self.m_is_shooting         = false
	self.m_initialized         = true

	Script.RunInFiber(function()
		while (true) do
			Script.Yield()
			if not (IsPlaying() && Config.syncshot.enabled) then
				continue
			end
			self:OnTick()
		end
	end)

	return self
end

function SyncShot:DrawTags()
	if (self.m_is_shooting || self.m_targets:IsEmpty()) then
		return
	end

	for ped in self.m_targets:Iter() do
		if (ENTITY.IS_ENTITY_DEAD(ped)) then
			continue
		end

		if (not ENTITY.IS_ENTITY_ON_SCREEN(ped)) then
			continue
		end

		local coords = PED.GET_PED_BONE_COORDS(ped, 21030, 0, 0, 0.0)
		GRAPHICS._DRAW_MARKER(
			0x50638AB9,
			coords.x, coords.y, coords.z + 0.5,
			0.0, 0.0, 0.0,
			0.0, 0.0, 0.0,
			0.12, 0.12, 0.12,
			255, 1, 1, 255,
			false,
			true,
			2,
			false,
			0,
			0,
			false
		)
	end
end

---@param target integer
function SyncShot:OnTargetTagged(target)
	if (self.m_targets:Contains(target)) then
		AUDIO.PLAY_SOUND_FRONTEND("Leaderboard_Hide", "MP_Leaderboard_Sounds", false, 0)
		self.m_targets:Pop(target)
		return
	end

	local cfg = Config.syncshot
	if (cfg.max_targets > 0 && self.m_targets:Size() >= cfg.max_targets) then
		AUDIO.PLAY_SOUND_FRONTEND("Idle_Kick_Message", "RDRO_Idle_Kick_Sounds", true, 0)
		log.warning("[SyncShot]: Maximum number of targets reached!")
	else
		AUDIO.PLAY_SOUND_FRONTEND("Leaderboard_Show", "MP_Leaderboard_Sounds", false, 0)
		self.m_targets:Push(target)
	end
end

function SyncShot:Cleanup()
	if (not self.m_last_target_cleanup:HasElapsed(2000)) then
		return
	end

	if (self.m_is_shooting || self.m_targets:IsEmpty()) then
		return
	end

	local trash = Set()
	for ped in self.m_targets:Iter() do
		if (not ENTITY.DOES_ENTITY_EXIST(ped) || ENTITY.IS_ENTITY_DEAD(ped)) then
			trash:Push(ped)
		end

		local pedCoords    = ENTITY.GET_ENTITY_COORDS(ped, false, true)
		local playerCoords = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), false, true)
		if (BUILTIN.VDIST(pedCoords.x, pedCoords.y, pedCoords.z, playerCoords.x, playerCoords.y, playerCoords.z) >= 200) then
			trash:Push(ped)
		end
	end

	for ped in trash:Iter() do
		self.m_targets:Pop(ped)
	end

	self.m_last_target_cleanup:Reset()
end

function SyncShot:OnTick()
	self:DrawTags()

	local playerPed = PLAYER.PLAYER_PED_ID()
	if (not WEAPON.IS_PED_ARMED(playerPed, 4)) then
		return
	end

	local _, entity = PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(PLAYER.PLAYER_ID(), 0)
	if (ENTITY.DOES_ENTITY_EXIST(entity) && ENTITY.IS_ENTITY_A_PED(entity) && not ENTITY.IS_ENTITY_DEAD(entity)) then
		if (PAD.IS_CONTROL_PRESSED(0, INPUT_AIM) && PAD.IS_CONTROL_JUST_RELEASED(0, INPUT_FRONTEND_LB)) then
			self:OnTargetTagged(entity)
		end
	end

	if (PAD.IS_CONTROL_JUST_RELEASED(0, INPUT_ATTACK) && self.m_targets:Size() > 0) then
		self.m_is_shooting = true

		for ped in self.m_targets:Iter() do
			if (ENTITY.DOES_ENTITY_EXIST(ped) && ENTITY.IS_ENTITY_A_PED(ped) && not ENTITY.IS_ENTITY_DEAD(ped)) then
				Helpers.ShootAtPed(ped,
					"weapon_repeater_evans",
					{ damage = 999, boneIndex = 21030, instigator = playerPed }
				)
				Script.Sleep(16)
			end
		end

		Script.Sleep(250)
		for ped in self.m_targets:Iter() do
			if not (ENTITY.IS_ENTITY_DEAD(ped) && PED.IS_PED_A_PLAYER(ped)) then
				ENTITY.SET_ENTITY_HEALTH(ped, 0, playerPed)
			end
		end

		self.m_targets:Clear()
		self.m_is_shooting = false
	end

	self:Cleanup()
end

function SyncShot:Draw()
	local cfg = Config.syncshot
	cfg.enabled = ImGui.Toggle("Enable Script##SyncShot", cfg.enabled)

	if (cfg.enabled) then
		Helpers.Tooltip(
			"Aim at peds and press [A] to tag them.\nAll tagged enemies will be shot in the head as soon as you fire your weapon."
		)

		cfg.max_targets = ImGui.SliderInt("Max Targets", cfg.max_targets, 0, 10)
		Helpers.Tooltip("Maximum number of targets. 0 means unlimited tags.")

		ImGui.BeginDisabled(self.m_targets:IsEmpty())
		if (ImGui.Button("Clear All Tags")) then
			Script.RunInFiber(function()
				self.m_is_shooting = true
				Script.Sleep(200)
				self.m_targets:Clear()
				self.m_is_shooting = false
			end)
		end
		ImGui.EndDisabled()
	end
end

return SyncShot:Init()
