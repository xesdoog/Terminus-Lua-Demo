local inventoryItemHash = 0

return function()
	ImGui.SeparatorText("Inventory")
	inventoryItemHash = ImGui.InputInt("Item Hash", inventoryItemHash, 0, 0)
	if (inventoryItemHash == 0) then
		return
	end

	if (ImGui.Button("Add Item Test")) then
		Script.RunInFiber(function()
			if (not ITEMDATABASE._ITEMDATABASE_IS_KEY_VALID(inventoryItemHash)) then
				print("Invalid item hash!")
				return
			end

			local invID  = INVENTORY._INVENTORY_GET_INVENTORY_ID_FROM_PED(PLAYER.PLAYER_PED_ID())
			local guid1  = Memory.Allocate(8 * 5)
			local unused = Memory.Allocate(8 * 5)
			if (not INVENTORY.INVENTORY_GET_GUID_FROM_ITEMID(
					invID,
					unused:GetAddress(),
					Util.Joaat("character"),
					Util.Joaat("slotid_none"),
					guid1:GetAddress())) then
				log.warning("Failed to get 1st GUID from item ID!")
				return
			end

			local slotHash = INVENTORY._GET_DEFAULT_ITEM_SLOT_INFO(inventoryItemHash, Util.Joaat("character"))
			if (slotHash == 0) then
				slotHash = Util.Joaat("slotid_satchel")
			end
			guid1:Add(8 * 4):WriteUint64(slotHash)

			local guid2 = Memory.Allocate(8 * 5)
			if (not INVENTORY.INVENTORY_GET_GUID_FROM_ITEMID(invID, guid1:GetAddress(), inventoryItemHash, slotHash, guid2:GetAddress())) then
				log.warning("Failed to get 2nd GUID from item ID!")
				return
			end

			if (not INVENTORY._INVENTORY_ADD_ITEM_WITH_GUID(
					invID,
					guid2:GetAddress(),
					guid1:GetAddress(),
					inventoryItemHash,
					slotHash,
					1,
					Util.Joaat("add_reason_default"))) then
				log.fwarning("Failed to add inventory item with hash '%d' and slot ID '%d'",
					inventoryItemHash,
					slotHash
				)
			end

			Memory.Free(unused)
			Memory.Free(guid1)
			Memory.Free(guid2)
		end)
	end
end
