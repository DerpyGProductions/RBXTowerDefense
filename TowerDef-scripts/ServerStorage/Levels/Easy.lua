--[[
    Easy (ModuleScript)
    Path: ServerStorage → Levels
    Parent: Levels
    Exported: 2026-09-29 15:57:28
]]
local Easy = {
	
	Map = workspace.Map,
	
	Paths = {
		[1] = workspace.Map.Nodes.Path1,
		[2] = workspace.Map.Nodes.Path2
	},
	
	Waves = {
		[1] = {

			Enemies = {
				["Slime King"] = 1,
				["Slime"] = 5,
			},

			["Delay"] = 0.5,
			["Lane"] = "All" --reserved for multi All - Enemies spawn at the same time (enemy count x2), 
							 --    				  Alternate - Enemies spawn in alternate lanes (keep enemy count)
							 --					  [waypointIndex] - Enemies only spawn at desired lane
		},

		[2] = {
			Enemies = {
				["Slime"] = 8,
			},

			["Delay"] = 0.5,
			["Lane"] = "All"
		},

		[3] = {
			Enemies = {
				
				["Slime"] = 16,
			},

			["Delay"] = 0.5,
			["Lane"] = "All"
		},

		[4] = {
			Enemies = {
				["Slime"] = 20,
			},

			["Delay"] = 0.5,
			["Lane"] = "All"
		},

		[5] = {
			Enemies = {
				["Slime Summon"] = 8,
				["Slime"] = 30,
			},

			["Delay"] = 0.5,
			["Lane"] = "All"
		},


		[6] = {
			Enemies = {
				["Slime Summon"] = 10,
				["Slime"] = 30,
				
			},

			["Delay"] = 0.5,
			["Lane"] = "All"
		},


		[7] = {
			Enemies = {
				["Slime Summon"] = 15,
				["Slime"] = 30,
			},

			["Delay"] = 0.5,
			["Lane"] = "All"
		},

		[8] = {
			Enemies = {
				["Slime Summon"] = 15,
				["Slime"] = 30,
			},

			["Delay"] = 0.5,
			["Lane"] = "All"
		},
		[9] = {
			Enemies = {
				["Slime Summon"] = 15,
				["Slime"] = 30,
			},

			["Delay"] = 0.5,
			["Lane"] = "All"
		},

		[10] = {
			Enemies = {
				["Slime King"] = 1,
			},

			["Delay"] = 10,
			["Lane"] = "All"
		},

		[11] = {
			Enemies = {
				["Slime"] = 30,
				["Slime Summon"] = 15,
			},

			["Delay"] = 0.5,
			["Lane"] = "All"
		},
		[12] = {
			Enemies = {
				["Slime"] = 30,
			},

			["Delay"] = 0.5,
			["Lane"] = "All"
		},


		[13] = {
			Enemies = {
				["Slime"] = 30,
			},

			["Delay"] = 0.5,
			["Lane"] = "All"
		},
		
		[14] = {
			Enemies = {
				["Slime"] = 30,
			},

			["Delay"] = 0.5,
			["Lane"] = "All"
		},
		
		[15] = {
			Enemies = {
				["Slime"] = 30,
				["Slime King"] = 1,
			},

			["Delay"] = 0.5,
			["Lane"] = "All"
		},
		
		[16] = {
			Enemies = {
				["Slime"] = 35,
			},

			["Delay"] = 0.5,
			["Lane"] = "All"
		},
		
		[17] = {
			Enemies = {
				["Slime"] = 35,
			},

			["Delay"] = 0.5,
			["Lane"] = "All"
		},
		
		[18] = {
			Enemies = {
				["Slime"] = 35,
			},

			["Delay"] = 0.5,
			["Lane"] = "All"
		},
		
		[19] = {
			Enemies = {
				["Slime"] = 35,
			},

			["Delay"] = 0.5,
			["Lane"] = "All"
		},
		
		[20] = {
			Enemies = {
				["Slime"] = 35,
				["Slime King"] = 3,
			},

			["Delay"] = 0.5,
			["Lane"] = "All"
		},


		[21] = {
			Enemies = {
				["Slime"] = 40,
				["Slime King"] = 1,
			},

			["Delay"] = 0.5,
			["Lane"] = "All"
		},
		
		[22] = {
			Enemies = {
				["Slime"] = 45,
				["Slime King"] = 1,
			},

			["Delay"] = 0.5,
			["Lane"] = "All"
		},
		
		[23] = {
			Enemies = {
				["Slime"] = 45,
				["Slime King"] = 1,
			},

			["Delay"] = 0.5,
			["Lane"] = "All"
		},
		
		[24] = {
			Enemies = {
				["Slime"] = 45,
				["Slime King"] = 2,
			},

			["Delay"] = 0.5,
			["Lane"] = "All"
		},
		
		[25] = {
			Enemies = {
				["Slime King"] = 7,
				["Slime"] = 40,
			},

			["Delay"] = 0.5,
			["Lane"] = "All"
		},
	}
	
	
	
}

return Easy
