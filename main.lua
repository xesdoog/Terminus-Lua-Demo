local bountyPedModels = require("includes.bounty_ped_models")
local bountyTargets = {}
for _, model in ipairs(bountyPedModels) do
	bountyTargets[Util.Joaat(model)] = true
end

-- local knockoutBtn = 0x2E
-- local WM_KEYUP = 0x0101
-- local WM_SYSKEYUP = 0x0105

local INPUT_AIM = 0xF84FA74F
local INPUT_SPRINT = 0x8FFC75D6
local INPUT_MELEE_ATTACK = 0xB2F377E8

local maxGoodsGlobal
local quickPickup = false
local hogtieGun = false
local buttonPressed = false
local lockMaxGoods = false

---@nodiscard
---@return boolean
local function IsPlaying()
	return Network.IsSessionStarted() && NETWORK.NETWORK_IS_GAME_IN_PROGRESS()
end

---@param text string
---@param ... any optional format args
local function Tooltip(text, ...)
	if (ImGui.IsItemHovered()) then
		ImGui.SetTooltip(text, ...)
	end
end

---@param entity integer
---@param attempts? integer
---@return boolean
local function TryTakeControlOf(entity, attempts)
	if not (entity and ENTITY.DOES_ENTITY_EXIST(entity)) then
		return false
	end

	attempts = attempts or 15
	local i = 0

	while (not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity) && i < attempts) do
		NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
		Script.Yield(100)
		i += 1
	end

	return NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity)
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

	local isPed = ENTITY.IS_ENTITY_A_PED(maybeTarget)
	local isMissionEntity = ENTITY.IS_ENTITY_A_MISSION_ENTITY(maybeTarget)
	if not (isPed && isMissionEntity) then
		return nil
	end

	return maybeTarget
end

---@param ped integer
---@return boolean
local function GetBountyTargetFromDecorator(ped)
	if (not DECORATOR.DECOR_EXIST_ON(ped, "proc_bounty_target")) then
		return false
	end

	return DECORATOR.DECOR_GET_BOOL(ped, "proc_bounty_target") == true
end

local function ShootBolasAtPed(ped)
	local playerPos = LocalPlayer:GetPed():GetPosition()
	local targetPos = ENTITY.GET_ENTITY_COORDS(ped, true, true)
	local hash = Util.Joaat("weapon_thrown_bolas")
	WEAPON._REQUEST_WEAPON_ASSET(hash, 31, false)
	MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(
		playerPos.x,
		playerPos.y,
		playerPos.z,
		targetPos.x,
		targetPos.y,
		targetPos.z,
		0,
		true,
		hash,
		0,
		false,
		false,
		-1082130432,
		false
	)
	WEAPON._REMOVE_WEAPON_ASSET(hash)
end

---@param ped integer
---@param attempts? integer
local function ForceHogtie(ped, attempts)
	attempts = attempts or 5
	local i = 0

	while (not PED.IS_PED_HOGTIED(ped) && not PED.IS_PED_BEING_HOGTIED(ped) && i < attempts) do
		TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped, true, true)
		TASK.CLEAR_PED_SECONDARY_TASK(ped)
		PED.SET_PED_TO_RAGDOLL(ped, 500, 1000, 0, false, true, 0)
		Script.Sleep(33)
		TASK.TASK_KNOCKED_OUT_AND_HOGTIED(ped, 0.0, 1)
		Script.Sleep(5000)
		i += 1
	end

	if (not PED.IS_PED_HOGTIED(ped)) then
		log.warning("Failed to hogtie ped! Attempting to shoot them with BOLAS")
		ShootBolasAtPed(ped)
	end
end

---@param ped integer
---@param offset number
---@return boolean
local function BringPedToFront(ped, offset)
	offset = offset or 1
	local coords = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
		PLAYER.PLAYER_PED_ID(),
		offset or 1,
		1,
		0
	)

	return Util.Teleport(ped, coords, false)
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

		if (GetBountyTargetFromDecorator(ped) || bountyTargets[ENTITY.GET_ENTITY_MODEL(ped)]) then
			table.insert(out, ped)
		end
	end

	return out
end

---@param target integer
---@param tpOffset? number
local function KidnapPed(target, tpOffset)
	if (not TryTakeControlOf(target)) then
		log.fwarning("Failed to take control of target ped. Kidnapping outcome may not end as expected.")
	end

	if (not PED.IS_PED_ON_FOOT(target)) then
		TASK.CLEAR_PED_TASKS_IMMEDIATELY(target, true, true)
		Script.Sleep(60)
	end

	if (not BringPedToFront(target, tpOffset or 1)) then
		log.warning("Task failed miserably!")
		return
	end

	ForceHogtie(target)
end

local function HogtieGun()
	if not (hogtieGun && WEAPON.IS_PED_ARMED(PLAYER.PLAYER_PED_ID(), 4)) then
		return
	end

	local isAiming, knockoutTarget = PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(PLAYER.PLAYER_ID(), 0)
	if not (isAiming && ENTITY.IS_ENTITY_A_PED(knockoutTarget) && PED.IS_PED_HUMAN(knockoutTarget)) then
		return
	end

	buttonPressed = PAD.IS_CONTROL_PRESSED(0, INPUT_AIM) && PAD.IS_CONTROL_JUST_RELEASED(0, INPUT_MELEE_ATTACK)
	if (buttonPressed && knockoutTarget != 0 && TryTakeControlOf(knockoutTarget)) then
		KidnapPed(knockoutTarget)
	end
end

Menu.RegisterImGui(function()
	if (not Network.IsSessionStarted()) then
		ImGui.Text("Please join a freemode session")
		return
	end

	-- quickPickup = ImGui.Checkbox("Quick Pickup", quickPickup)

	hogtieGun = ImGui.Checkbox("Hogtie Gun", hogtieGun)
	Tooltip("Aim at an NPC with any weapon and press [F] to bring them to you knocked out and hogtied.")

	ImGui.Spacing()
	ImGui.SeparatorText("Trader")
	lockMaxGoods = ImGui.Checkbox("Force Max Trader Goods", lockMaxGoods)

	ImGui.Spacing()
	ImGui.SeparatorText("Bounty Hunter")

	if (ImGui.Button("Kidnap Bounty Target")) then
		Script.RunInFiber(function()
			for _, ped in ipairs(TryGetAllBountyTargets()) do
				KidnapPed(ped)
				Script.Yield(100)
			end
		end)
	end
	Tooltip(
		"Brings the bounty target to you knocked out and hogtied.\n\n[Note]: Under certain circumstances, the target may be invisible but you can still pick them up and deliver them.")

	if (ImGui.Button("Teleport To Bounty Target")) then
		Script.RunInFiber(function()
			local target = TryGetAllBountyTargets()[1]
			if (not target or not ENTITY.DOES_ENTITY_EXIST(target)) then
				log.warning("Could not find any bounty targets!")
				return
			end

			TASK.CLEAR_PED_TASKS_IMMEDIATELY(target, true, true)
			Script.Sleep(1000)
			LocalPlayer:Teleport(ENTITY.GET_ENTITY_COORDS(target, false, true))
		end)
	end

	ImGui.Spacing()
	ImGui.SeparatorText("Debug")

	if (ImGui.Button("Get Running Tasks")) then
		Script.RunInFiber(function()
			local ped = PLAYER.PLAYER_PED_ID()
			local buff = {}
			local count = 0
			for i = 0, 0x2DF do
				if (TASK.GET_IS_TASK_ACTIVE(ped, i)) then
					table.insert(buff, i)
					count += 1
				end
			end

			if (count == 0) then
				log.info("We're not running any tasks.")
			else
				log.info(table.concat(buff, ", "))
			end
		end)
	end
end)

Script.RunInFiber(function()
	while (true) do
		Script.Yield()
		if (not IsPlaying()) then
			return
		end

		-- if (quickPickup && TASK.GET_IS_TASK_ACTIVE(playerPed, 631)) then
		-- 	PED.FORCE_PED_AI_AND_ANIMATION_UPDATE(playerPed, false, false)
		-- end

		HogtieGun()
	end
end)
