
--[[
	==prototype achievements library==
	This is an initial prototype implementation in order to help effect a standard.
	This prototype will have no strong error checks and be small in scope. Any
	  wider-scope implementation of the standard will be separate.

	At the time of writing /Shared is slightly non-functional, so a temporary
	test folder is being used.

	== planned usage ==

	Import the library using `import "achievements"
	The library has now created a global variable named "achievements".
	I hate this approach, but it's a prototype and this is how the playdate
	  does things because y'all are crazy.

	The user now needs to configure the library. Make a config table as so:

		local achievementConfig = {
			-- Technically, any string. We need to spell it out explicitly
			--   instead of using metadata.bundleID so that it won't get 
			--   mangled by online sideloading. Plus, this way multi-pdx
			--   games or demos can share achievements.
			gameID = "com.yourcompany.yourgame",
			-- These are optional, and will be auto-filled with metadata
			--   values if not specified here. This is also for multi-pdx
			--   games.
			name = "My Awesome Game",
			author = "You, Inc",
			description = "The next evolution in cranking technology.",
			-- And finally, a table of achievements.
			achievements = {
				{
					id = "test_achievement",
					name = "Achievement Name",
					description = "Achievement Description",
					is_secret = false,
					icon = "filepath" -- to be iterated on
					[more to be determined]
				},
			}
		}

	This table makes up the top-level data structure being saved to the shared
	json file. The gameID field determines the name of the folder it will
	be written to, rather than bundleID, to keep things consistent.

	The only thing that is truly required is the gameID field, because this is
	  necessary for identification. Everything else can be left blank, and it
	  will be auto-filled or simply absent in the case of achievement data.

	The user passes the config table to the library like so:
		achievements.initialize(achievementConfig)
	This function finishes populating the configuration table with metadata
	  if necessary, merges the achievement data with the saved list of granted
	  achievements, creates the shared folder and .json file with the new data,
	  and iterates over the achievement data in order to copy images given to
	  the shared folder.

	In order to grant an achievement to the player, run `achievements.grant(id)`
	  If this is a valid achievement id, it will key the id to the current epoch
	  second in the achievement save data.
	In order to revoke an achievement, run `achievements.revoke(id)`
	  If this is a valid achievement id, it will remove the id from the save
	  data keys.
	
	To save achievement data, run `achievements.save()`. This will perfom a merge
	  with the configuration data and write it to the shared .json file. Run this
	  function alongside other game-save functions when the game exits. Of course,
	  unfortunately, achievements don't respect save slots.

	==details==
	The achievements file in the game's save directory is the prime authority on active achievements.
	It contains nothing more than a map of achievement IDs which have been earned by the player to when they were earned.
	This should make it extremely easy to manage, and prevents other games from directly messing with achievement data.
	The achievement files in the /Shared/Achievements/bundleID folder are regenerated at game load and when saving.
	They are to be generated by serializing `module.achievements` along with `module.localData` and copying any images (when we get to those).
--]]

print("Achievements library initializing...")

local local_achievement_file = "Achievements.json"

-- Right, we're gonna make this easier to change in the future.
-- Another note: changing the data directory to `/Shared/gameID`
--   rather than the previously penciled in `/Shared/Achievements/gameID`
local function get_achievement_folder_root_path(gameID)
	if type(gameID) ~= "string" then
		error("bad argument #1: expected string, got " .. type(gameID), 2)
	end
	local root = string.format("/Shared/%s/", gameID)
	return root
end
local function get_achievement_data_file_path(gameID)
	if type(gameID) ~= "string" then
		error("bad argument #1: expected string, got " .. type(gameID), 2)
	end
	local root = get_achievement_folder_root_path(gameID)
	return root .. "/Achievements.json"
end

-- local achievement_folder = root_folder .. playdate.metadata.bundleID .. "/"

local metadata <const> = playdate.metadata

---@diagnostic disable-next-line: lowercase-global
achievements = {
	version = "prototype 0.1"
}

local function load_data()
	local data = json.decodeFile(local_achievement_file)
	if not data then
		data = {}
	end
	achievements.localData = data
end

function achievements.save()
	json.encodeToFile(local_achievement_file, false, achievements.localData)
end

local function merge_and_export_data()
end
local function copy_images_to_data()
end

function achievements.initialize(configuration)
	if configuration.gameID == nil then
		error("gameID not configured", 2)
	elseif type(configuration.gameID) ~= "string" then
		error("gameID must be a string", 2)
	end
	for _, field in ipairs{"name", "author", "description"} do
		if configuration[field] == nil then
			configuration[field] = playdate.metadata[field]
		elseif type(configuration[field]) ~= "string" then
			error(field .. " must be a string", 2)
		end
	end
	configuration.version = metadata.version
	configuration.libversion = achievements.version
	achievements.configuration = configuration

	merge_and_export_data()
	copy_images_to_data()
end


--[[ Achievement Management Functions ]]--

achievements.getInfo = function(achievement_id)
	for _, achievement in ipairs(achievements.achievements) do
		if achievement.id == achievement_id then
			return achievement
		end
	end
	return false
end

achievements.grant = function(achievment_id, display_style)
	local info =  achievements.getInfo(achievment_id)
	if not info then
		error("attempt to grant unconfigured achevement '" .. achievment_id .. "'", 2)
	end
	achievements.localData[achievment_id] = ( playdate.getSecondsSinceEpoch() )
	-- Drawing to come later...
	
end

achievements.revoke = function(achievment_id)
	local info =  achievements.getInfo(achievment_id)
	if not info then
		error("attempt to revoke unconfigured achevement '" .. achievment_id .. "'", 2)
	end
	achievements.localData[achievment_id] = nil
end

--[[ External Game Functions ]]--

achievements.gamePlayed = function(game_id)
	return playdate.file.isdir(get_achievement_folder_root_path(game_id))
end

achievements.gameData = function(game_id)
	if not achievements.gamePlayed(game_id) then
		error("No game with ID '" .. game_id .. "' was found", 2)
	end
	return playdate.datastore.read(get_achievement_data_file_path(game_id))
end


return achievements