require("includes.api.extensions.__init__")
require("includes.modules.SimpleSerializer")
require("includes.modules.KeyManager")

local DrawTrader       = require("includes.features.trader")
local DrawBountyHunter = require("includes.features.bounty_hunter")
local DrawMisc         = require("includes.features.test")
local EntityGrabber    = require("includes.features.entity_grabber")
local SyncShot         = require("includes.features.syncshot")


local shouldDrawTestWindow = false
KeyManager:RegisterKeybind("F5", function()
	shouldDrawTestWindow = not shouldDrawTestWindow
end)

Gui.RegisterImGui(function()
	if (not Network.IsSessionStarted()) then
		ImGui.Text("Please join a freemode session")
		return
	end

	if (ImGui.BeginTabBar("##junkScript")) then
		if (ImGui.BeginTabItem("Bounty Kidnapper")) then
			DrawBountyHunter()
			ImGui.EndTabItem()
		end

		if (ImGui.BeginTabItem("Trader")) then
			DrawTrader()
			ImGui.EndTabItem()
		end

		if (ImGui.BeginTabItem("Extra")) then
			ImGui.SeparatorText("SyncShot")
			SyncShot:Draw()

			ImGui.Spacing()
			ImGui.SeparatorText("Entity Grabber")
			EntityGrabber:Draw()

			ImGui.EndTabItem()
		end

		ImGui.EndTabBar()
	end
end)

Gui.RegisterIndependentImGui(function()
	local shouldOverrideMouse = shouldDrawTestWindow or Gui.IsOpen()
	if (Gui.IsMouseOverridden() != shouldOverrideMouse) then
		Gui.OverrideMouse(shouldOverrideMouse)
	end

	if (shouldDrawTestWindow) then
		ImGui.SetNextWindowSize(Vector2(400, 400), ImGuiCond.Always)
		ImGui.Begin("##testLuaWindow", ImGuiWindowFlags.NoDecoration | ImGuiWindowFlags.NoSavedSettings)
		DrawMisc()
		ImGui.End()
	end
end)
