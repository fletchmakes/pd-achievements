
-- TODO Note: Writing files to/reading files from /Shared isn't working. Start with the basics.

--[[
	==prototype achievements library==
	This is still just an experiment to satisfy my own curiosity and lay some groundwork.
	The /Shared folder is still experimental and details may change in the future,
	  so filepaths are currently being written as if they were constants.

	==usage==
	Still working on this, here's what I have so far:
	Achievement data for a game is coded in by defining the `module.achivements` table.
	This should be checked during a manual initialization step.
	Current data format is as follows:
		module.achievements = {
			{
				id = "test_achievement", -- any unique string
				name = "Achievement Name",
				description = "Achievement Description",
				is_secret = false,
				icon = "filepath" -- to be iterated on
				[more to be determined]
			},
			[...]
		}
	No validation is currently being performed.
	The library should then be initialized using `module.ready()`.

	==details==
	The achievements file in the game's save directory is the prime authority on active achievements.
	It contains nothing more than a map of achievement IDs which have been earned by the player to when they were earned.
	This should make it extremely easy to manage, and prevents other games from directly messing with achievement data.
	The achievement files in the /Shared/Achievements/bundleID folder are regenerated at game load and when saving.
	They are to be generated by serializing `module.achievements` along with `module.localData` and copying any images (when we get to those).
--]]

print("Achievements library initializing...")

local root_folder = "/Shared/Achievements/"
local achievement_folder = root_folder .. playdate.metadata.bundleID .. "/"
local datafile_name = "info.json"
local local_achievement_file = "Achievements.json"

-- If we wanted to ensure the game's "marker" folder was created on first run even if the developer
--   only imports the file, this is where it would go. But file.mkdir isn't working for me. -D

local module = {}

module.achievements = {}

local function load_data()
	local data = json.decodeFile(local_achievement_file)
	if not data then
		data = {}
	end
	module.localData = data
end

local function save_data()
	json.encodeToFile(local_achievement_file, false, module.localData)
end

--[[ Final Initialization Function ]]--
module.ready = function()

	load_data()
end

--[[ Achievement Management Functions ]]--

module.getInfo = function(achievement_id)
	for _, achievement in ipairs(module.achievements) do
		if achievement.id == achievement_id then
			return achievement
		end
	end
	return false
end

module.grant = function(achievment_id, display_style)
	local info =  module.getInfo(achievment_id)
	if not info then
		error("attempt to grant unconfigured achevement '" .. achievment_id .. "'", 2)
	end
	module.localData[achievment_id] = ( playdate.getSecondsSinceEpoch() )
	save_data()
	-- Drawing to come later...
	
end

module.revoke = function(achievment_id)
	local info =  module.getInfo(achievment_id)
	if not info then
		error("attempt to revoke unconfigured achevement '" .. achievment_id .. "'", 2)
	end
	module.localData[achievment_id] = nil
	save_data()
end

--[[ External Game Functions ]]--

module.gamePlayed = function(game_id)
	return playdate.file.isdir(root_folder .. game_id)
end

module.gameData = function(game_id)
	if not module.gamePlayed(game_id) then
		error("No game with ID '" .. game_id .. "' was found", 2)
	end
	return playdate.datastore.read(root_folder .. game_id .. datafile_name)
end


return module