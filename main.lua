require("includes.simple_serializer"):Init()

local DrawTrader       = require("includes.features.trader")
local DrawBountyHunter = require("includes.features.bounty_hunter")
local DrawMisc         = require("includes.features.test")
local EntityGrabber    = require("includes.features.entity_grabber")

Menu.RegisterImGui(function()
	if (not Network.IsSessionStarted()) then
		ImGui.Text("Please join a freemode session")
		return
	end

	if (ImGui.BeginTabBar("##junkScript")) then
		if (ImGui.BeginTabItem("Bounty Kidnapper")) then
			DrawBountyHunter()
			ImGui.EndTabItem()
		end

		if (ImGui.BeginTabItem("Trader Test")) then
			DrawTrader()
			ImGui.EndTabItem()
		end

		if (ImGui.BeginTabItem("Entity Grabber")) then
			EntityGrabber:Draw()
			ImGui.EndTabItem()
		end

		-- if (ImGui.BeginTabItem("Misc")) then
		-- 	DrawMisc()
		-- 	ImGui.EndTabItem()
		-- end

		ImGui.EndTabBar()
	end
end)
