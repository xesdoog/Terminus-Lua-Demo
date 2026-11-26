return {
	---@class Config
	Config = {
		bounty_kidnapper = {
			Knockout = false,
			Hogtie   = false,
			Kill     = false
		},
		entity_grabber = {
			enabled      = false,
			max_distance = -1.0,
			entity_flags = 0x0,
			ped_options  = {
				Knockout = false,
				Hogtie   = false,
				Kill     = false
			},
		},
		syncshot = {
			enabled      = false,
			max_targets  = 5,
			max_distance = -1.0,
		}
	}
}
