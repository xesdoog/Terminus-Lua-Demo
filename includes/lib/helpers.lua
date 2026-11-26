local Helpers = {}

---@param entity integer
---@param attempts? integer
---@return boolean
function Helpers.TryTakeControlOf(entity, attempts)
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

---@nodiscard
---@return boolean
function Helpers.IsPlaying()
	return Network.IsSessionStarted() && NETWORK.NETWORK_IS_GAME_IN_PROGRESS()
end

---@param text string
---@param ... any optional format args
function Helpers.Tooltip(text, ...)
	if (ImGui.IsItemHovered()) then
		ImGui.SetTooltip(text, ...)
	end
end

---@nodiscard
---@param n integer
---@param pos integer
---@return boolean
function Helpers.IsBitSet(n, pos)
	return ((n >> pos) & 1) != 0
end

---@param n integer
---@param pos integer
---@return integer
function Helpers.FlipBit(n, pos)
	return n ~ (1 << pos)
end

---@param ped integer
---@param weaponNameOrHash string|integer
---@param opts { boneIndex?: integer, damage?: integer, instigator?: integer, damage?: integer }?
function Helpers.ShootAtPed(ped, weaponNameOrHash, opts)
	opts = opts or {}
	local hash = type(weaponNameOrHash) == "string" ? Util.Joaat(weaponNameOrHash) : weaponNameOrHash
	if (not WEAPON.IS_WEAPON_VALID(hash)) then
		return
	end

	local playerPos = LocalPlayer:GetPed():GetPosition()
	local targetPos
	if (opts.boneIndex) then
		targetPos = Ped(ped):GetBonePosition(opts.boneIndex)
	else
		targetPos = ENTITY.GET_ENTITY_COORDS(ped, false, true)
	end

	WEAPON._REQUEST_WEAPON_ASSET(hash, 31, false)
	MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(
		playerPos.x,
		playerPos.y,
		playerPos.z,
		targetPos.x,
		targetPos.y,
		targetPos.z,
		opts.damage or 0,
		true,
		hash,
		opts.instigator or 0,
		false,
		false,
		-1082130432,
		false
	)
	WEAPON._REMOVE_WEAPON_ASSET(hash)
end

---@param entity integer
---@param offset? number
---@return boolean
function Helpers.BringEntityToPlayer(entity, offset)
	local coords = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
		PLAYER.PLAYER_PED_ID(),
		0.0,
		offset or 1.0,
		0.0
	)

	if (not Util.Teleport(entity, coords, false)) then
		return false
	end

	if (not ENTITY.IS_ENTITY_A_PED(entity)) then
		ENTITY.PLACE_ENTITY_ON_GROUND_PROPERLY(entity, true)
	end

	return true
end

---@param ped integer
---@param numAttempts? integer
function Helpers.TryForceHogtie(ped, numAttempts)
	if (ENTITY.IS_ENTITY_DEAD(ped)) then
		return
	end

	numAttempts = numAttempts or 5
	local i = 0

	TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped, true, true)
	TASK.CLEAR_PED_SECONDARY_TASK(ped)
	PED.SET_PED_TO_RAGDOLL(ped, 500, 1000, 0, false, true, 0)
	Script.Sleep(33)

	while (not PED.IS_PED_HOGTIED(ped) && not PED.IS_PED_BEING_HOGTIED(ped) && i < numAttempts) do
		TASK.TASK_KNOCKED_OUT_AND_HOGTIED(ped, 0.0, 1)
		Script.Sleep(2500)
		i += 1
	end

	if (not PED.IS_PED_HOGTIED(ped)) then
		log.warning("Failed to hogtie ped! Attempting to shoot them with BOLAS")
		Helpers.ShootAtPed(ped, "weapon_thrown_bolas")
	end
end

---@param entity integer
---@param tpOffset? number
---@param pedOptions? PedGrabOptions
function Helpers.BringEntity(entity, tpOffset, pedOptions)
	if (not Helpers.TryTakeControlOf(entity)) then
		log.fwarning("Failed to take control of target ped. Kidnapping outcome may not end as expected.")
	end

	if (not Helpers.BringEntityToPlayer(entity, tpOffset or 1)) then
		log.warning("Task failed miserably!")
		return
	end

	if (ENTITY.IS_ENTITY_A_PED(entity) && not PED.IS_PED_A_PLAYER(entity)) then
		if (not PED.IS_PED_ON_FOOT(entity)) then
			TASK.CLEAR_PED_TASKS_IMMEDIATELY(entity, true, true)
			Script.Sleep(60)
		end

		if (pedOptions?.Knockout) then
			TASK.TASK_KNOCKED_OUT(entity, 0.0, true)
			Script.Sleep(250)
		end

		if (pedOptions?.Hogtie) then
			Helpers.TryForceHogtie(entity)
		elseif (pedOptions?.Kill) then
			ENTITY.SET_ENTITY_HEALTH(entity, 0, 0)
		end
	end
end

---@param textureDict integer JOAAT
---@param texture integer JOAAT
---@param x float
---@param y float
---@param width float
---@param height float
---@param rotation float
---@param r integer
---@param g integer
---@param b integer
---@param a integer
---@param stereorize boolean
function Helpers.DrawTexture(textureDict, texture,x, y, width, height,rotation,r, g, b, a, stereorize)
    if (not TXD.HAS_STREAMED_TXD_LOADED(textureDict)) then
       TXD.REQUEST_STREAMED_TEXTURE_DICT(textureDict, false)
	   return
    end

	GRAPHICS.DRAW_SPRITE(textureDict, texture, 0.5, 0.5, width, height, rotation, r, g, b, a, stereorize)
end

---@param textureHash integer JOAAT
---@param pos Vector3
function Helpers.DrawMarker(textureHash, pos)
	GRAPHICS._DRAW_MARKER(0x94FDAE17, pos.x, pos.y, pos.z + 1.0, 0, 0, 0, 0, 0, 0, 1.0 , 1.0, 1.0, 250, 250, 100, 250, false, true, 2, false, 0, 0, true)
end

return Helpers
