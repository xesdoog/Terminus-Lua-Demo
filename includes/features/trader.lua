local TraderGlobal ---@type ScriptGlobal?
local TraderGlobal2 ---@type ScriptGlobal?
local inventoryList ---@type PlayerInventory?

---@param itemHash integer
---@param amount integer
local function SetTraderItemAmount(itemHash, amount)
	Script.RunInFiber(function()
		if (not inventoryList) then
			inventoryList = LocalPlayer.GetInventoryList(2)
		end

		local item = inventoryList:GetItem(itemHash)
		if (not item) then
			log.warning("Failed to get trader item from inventory list!")
			return
		end

		item:SetAmount(amount)
	end)
end

return function()
	if (not TraderGlobal) then
		TraderGlobal = ScriptGlobal(1144526):At(PLAYER.PLAYER_ID(), 83):At(74)
	end

	if (not TraderGlobal2) then
		TraderGlobal2 = ScriptGlobal(1901671):At(604)
	end

	local materials    = TraderGlobal:At(2):ReadInt()
	local goods        = TraderGlobal:At(3):ReadInt()
	local supplies     = TraderGlobal:At(5):ReadInt()
	local maxMaterials = TraderGlobal2:At(9):ReadInt() -- default 10k // DATABINDING_ADD_DATA_INT(Global_1144485.f_21, "TraderMaterialsMaximum", Global_1901671.f_604.f_9);
	local maxGoods     = TraderGlobal2:At(10):ReadInt() -- default 100 // DATABINDING_ADD_DATA_INT(Global_1144485.f_21, "TraderGoodsMaximum", Global_1901671.f_604.f_10);

	ImGui.Text("Materials")
	ImGui.SameLine()
	local progressBarSz = Vector2(ImGui.GetContentRegionAvail().x - 45, ImGui.GetFrameHeight())

	ImGui.ProgressBar(materials / maxMaterials, progressBarSz)
	ImGui.SameLine()
	ImGui.BeginDisabled(materials <= 0 || materials >= maxMaterials)
	if (ImGui.Button("Max##materials")) then
		SetTraderItemAmount(0x2DEFDE42, maxMaterials)
	end
	ImGui.EndDisabled()

	ImGui.Text("Supplies")
	ImGui.SameLine()
	ImGui.ProgressBar(supplies / 25, progressBarSz)
	ImGui.SameLine()
	ImGui.BeginDisabled(supplies <= 0 || supplies >= 25)
	if (ImGui.Button("Max##suplies")) then
		SetTraderItemAmount(0x3680CC24, 25)
	end
	ImGui.EndDisabled()

	ImGui.Text("Goods")
	ImGui.SameLine()
	ImGui.ProgressBar(goods / maxGoods, progressBarSz)
	ImGui.SameLine()
	ImGui.BeginDisabled(goods <= 0 || supplies >= maxGoods)
	if (ImGui.Button("Max##goods")) then
		SetTraderItemAmount(0xD42ABA4F, maxGoods)
	end
	ImGui.EndDisabled()

	ImGui.Spacing()
	ImGui.TextWrapped("[Note]: You must have at least 1 unit of an item in order to max it out.")

	-- ImGui.Spacing()
	-- ImGui.Separator()
	-- TraderGlobal2:At(11):WriteInt(ImGui.SliderInt("Production Time", TraderGlobal2:At(11):ReadInt(), 0, 60, "%d minutes"))
	-- TraderGlobal2:At(13):WriteInt(ImGui.SliderInt("Supplies Time", TraderGlobal2:At(13):ReadInt(), 0, 60, "%d minutes"))
end
