local Config          = require("includes.lib.global_vars").Config
local Helpers         = require("includes.lib.helpers")
local bountyPedModels = require("includes.data.bounty_ped_models")
local bountyTargets   = {}
for _, model in ipairs(bountyPedModels) do
	bountyTargets[Util.Joaat(model)] = true
end

---@return integer?
local function GetBountyTargetFromScriptLocal()
	local maybeTarget
	if (Script.IsActive("net_fetch")) then
		maybeTarget = ScriptLocal("net_fetch", 4737):At(7):At(PLAYER.PLAYER_ID(), 74):At(62):ReadInt()
	elseif (Script.IsActive("fm_mission_controller")) then
		maybeTarget = ScriptLocal("fm_mission_controller", 14093):ReadInt()
	end

	if not (maybeTarget && ENTITY.DOES_ENTITY_EXIST(maybeTarget)) then
		return nil
	end

	if not (ENTITY.IS_ENTITY_A_PED(maybeTarget) && PED.IS_PED_HUMAN(maybeTarget) && ENTITY.IS_ENTITY_A_MISSION_ENTITY(maybeTarget)) then
		return nil
	end

	return maybeTarget
end

---@param ped integer
---@return boolean
local function DoesPedHaveBountyDecor(ped)
	if (not DECORATOR.DECOR_EXIST_ON(ped, "proc_bounty_target")) then
		return false
	end

	return DECORATOR.DECOR_GET_BOOL(ped, "proc_bounty_target") == true
end

---@return table<integer, integer>
local function TryGetAllBountyTargets()
	local maybeTarget = GetBountyTargetFromScriptLocal()
	if (maybeTarget) then
		return { maybeTarget }
	end

	local out = {}
	for _, ped in ipairs(Entities.GetAllPedsAsHandles()) do
		if not (PED.IS_PED_HUMAN(ped) && ENTITY.IS_ENTITY_A_MISSION_ENTITY(ped)) then
			continue
		end

		if (DoesPedHaveBountyDecor(ped) || bountyTargets[ENTITY.GET_ENTITY_MODEL(ped)]) then
			table.insert(out, ped)
		end
	end

	return out
end

return function()
	local cfg = Config.bounty_kidnapper

	cfg.Knockout = ImGui.Checkbox("Knockout", cfg.Knockout)
	Helpers.Tooltip("Knockout the target before bringing it.")

	cfg.Hogtie = ImGui.Checkbox("Hogtie", cfg.Hogtie)
	Helpers.Tooltip("Hogtie the target before bringing it. May not always succeed.")

	cfg.Kill = ImGui.Checkbox("Kill", cfg.Kill)
	Helpers.Tooltip("Bring the target dead.")

	if (ImGui.Button("Yoink Bounty Target")) then
		Script.RunInFiber(function()
			for i, ped in ipairs(TryGetAllBountyTargets()) do
				Helpers.BringEntity(ped, i, cfg)
				Script.Yield(120)
			end
		end)
	end

	Helpers.Tooltip(
		"Brings the bounty target to you.\n\n[Note]: Under certain circumstances the target may be invisible but you can still pick them up and deliver them.\nFor clue missions, it is recommended to inspect at least one clue before pressing this button."
	)

	ImGui.Spacing()

	if (ImGui.Button("Teleport To Bounty Target")) then
		Script.RunInFiber(function()
			local target = TryGetAllBountyTargets()[1]
			if (not target or not ENTITY.DOES_ENTITY_EXIST(target)) then
				log.warning("Could not find any bounty targets!")
				return
			end

			TASK.CLEAR_PED_TASKS_IMMEDIATELY(target, true, true)
			Script.Sleep(1000)
			Util.Teleport(PLAYER.PLAYER_PED_ID(), ENTITY.GET_ENTITY_COORDS(target, false, true), true)
		end)
	end
end
