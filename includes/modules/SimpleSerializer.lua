local json 	 = require("includes.thirdparty.json.json")()
local Config = require("includes.lib.global_vars").Config


---@class SimpleSerializer<T>
---@field private m_initialized boolean
---@field private m_path Path
local SimpleSerializer 	 = {}
SimpleSerializer.__index = SimpleSerializer

---@return SimpleSerializer<Config>
function SimpleSerializer:Init()
	if (self.m_initialized) then
		return self
	end

	local configDir = Path("./config")
	if (not configDir:Exists()) then
		configDir:MakeDir()
	end

	self.m_path = configDir / "settings.json"
	if (self.m_path:Exists()) then
		local saved = self:Load()
		if (next(saved) != nil) then
			for k, v in pairs(saved) do
				Config[k] = v
			end
		end
	else
		self:Save()
	end

	Script.RunInFiber(function()
		while (true) do
			Script.Yield(5000)
			self:Save()
		end
	end)

	self.m_initialized = true
	return self
end

---@return Config
function SimpleSerializer:Load()
	if (not self.m_path:Exists()) then
		return {}
	end

	local f, e = self.m_path:Open("r")
	if (not f) then
		log.ferror("Failed to opend path: '%s': %s", self.m_path, e)
		return {}
	end

	local out = json:decode(f:read("*a")) ---@cast out table?
	f:close()

	return out ?? {}
end

function SimpleSerializer:Save()
	local f, e = self.m_path:Open("w")
	if (not f) then
		log.ferror("Failed to opend path: '%s': %s", self.m_path, e)
		return
	end

	f:write(json:encode(Config, nil, { pretty = true, indent = "  " }))
	f:flush()
	f:close()
end

return SimpleSerializer
