RANK_NONE = 0
RANK_HUNTSMAN = 1
RANK_RANGER = 2
RANK_BIGGAMEHUNTER = 3
RANK_TROPHYHUNTER = 4
RANK_ELITEHUNTER = 5

REWARD_MONEY = 1
REWARD_EXP = 2
REWARD_ACHIEVEMENT = 3
REWARD_STORAGE = 4
REWARD_POINT = 5
REWARD_ITEM = 6

QUESTSTORAGE_BASE = 1500
KILLSSTORAGE_BASE = 65000
REPEATSTORAGE_BASE = 48950
POINTSSTORAGE = 2500

TaskConfig = {
	repeatTimes = 3,
	tasksByPlayer = 3
}

tasks = {
	[1] = {
		killsRequired = 2, raceName = "Trolls", level = {6, 9999999}, premium = false,
		creatures = {"troll", "troll champion", "island troll", "swamp troll"},
		rewards = {{type = "exp", value = {200}},
				   {type = "storage", value = {35050, 1}},
				   {type = "item", value = {2195, 1}},
				   {type = "money", value = {200}}}
	},
	[2] = {
		killsRequired = 300, raceName = "Crocodiles", level = {6, 49}, premium = true,
		creatures = {"crocodile"},
		rewards = {{type = "exp", value = {800}},
				   {type = "achievement", value = {"Blood-Red Snapper"}},
				   {type = "storage", value = {35000, 1}},
				   {type = "points", value = {1}}}
	},
	[4] = {
		killsRequired = 6666, raceName = "Demons", level = {130, 9999}, rank = RANK_ELITEHUNTER, premium = true,
		creatures = {"demon"},
		rewards = {{type = "storage", value = {41300, 1}}} -- Storage that let's you to start Demon Oak
	},
	[5] = {
		killsRequired = 3000, raceName = "Pirates", level = {1, 9999}, storage = {12600, 1}, premium = true, -- Requires a storage (Gained on The Shattered Isles Quest)
		creatures = {"pirate ghost", "pirate marauder", "pirate cutthroad", "pirate buccaneer", "pirate corsair", "pirate skeleton"},
		rewards = {{type = "exp", value = {10000}},
				   {type = "money", value = {5000}},
				   {type = "storage", value = {35030, 1}}}
	},
	[6] = {killsRequired = 3000, raceName = "Pirates second task", level = {1, 9999}, storage = {REPEATSTORAGE_BASE + 5, 3}, norepeatable = true, premium = true, -- Requires a storage (Gained completing Raymond Striker's first task three times.) NOTE: The required storage to start this task is: base + first pirate task id (5)
		creatures = {"pirate ghost", "pirate marauder", "pirate cutthroad", "pirate buccaneer", "pirate corsair", "pirate skeleton"},
		rewards = {{type = "exp", value = {10000}},
				   {type = "money", value = {5000}},
				   {type = "storage", value = {35031, 1}}}
	},
}


function getPlayerRank(cid)
	local player = Player(cid)
	return (player:getStorageValue(POINTSSTORAGE) >= 100 and RANK_ELITEHUNTER or
	player:getStorageValue(POINTSSTORAGE) >= 70 and RANK_TROPHYHUNTER or
	player:getStorageValue(POINTSSTORAGE) >= 40 and RANK_BIGGAMEHUNTER or
	player:getStorageValue(POINTSSTORAGE) >= 20 and RANK_RANGER or
	player:getStorageValue(POINTSSTORAGE) >= 10 and RANK_HUNTSMAN or RANK_NONE)
end

function getTaskByName(name, table)
	local t = (table and table or tasks)
	for k, v in pairs(t) do
		if v.name then
			if v.name:lower() == name:lower() then
				return k
			end
		else
			if v.raceName:lower() == name:lower() then
				return k
			end
		end
	end
	return false
end

function getTasksByPlayer(cid)
	local canmake = {}
	local able = {}
	local player = Player(cid)
	for k, v in pairs(tasks) do
		if player:getStorageValue(QUESTSTORAGE_BASE + k) < 1 and player:getStorageValue(REPEATSTORAGE_BASE + k) < TaskConfig.repeatTimes then
			able[k] = true
			if player:getLevel() < v.level[1] or player:getLevel() > v.level[2] then
				able[k] = false
			end
			if v.storage and player:getStorageValue(v.storage[1]) < v.storage[2] then
				able[k] = false
			end

			if v.rank then
				if getPlayerRank(cid) < v.rank then
					able[k] = false
				end
			end

			if v.premium then
				if not player:isPremium() then
					able[k] = false
				end
			end

			if able[k] then
				table.insert(canmake, k)
			end
		end
	end
	return canmake
end


function canStartTask(cid, name, table)
	local v = ""
	local id = 0
	local t = (table and table or tasks)
	local player = Player(cid)
	for k, i in pairs(t) do
		if i.name then
			if i.name:lower() == name:lower() then
				v = i
				id = k
				break
			end
		else
			if i.raceName:lower() == name:lower() then
				v = i
				id = k
				break
			end
		end
	end
	if v == "" then
		return false
	end
	if player:getStorageValue(QUESTSTORAGE_BASE + id) > 0 then
		return false
	end
	if (player:getStorageValue(REPEATSTORAGE_BASE +  id) >= TaskConfig.repeatTimes) or (v.norepeatable and player:getStorageValue(REPEATSTORAGE_BASE +  id) > 0) then
		return false
	end
	if player:getLevel() >= v.level[1] and player:getLevel() <= v.level[2] then
		if v.premium then
			if player:isPremium() then
				if v.rank then
					if getPlayerRank(cid) >= v.rank then
						if v.storage then
							if player:getStorageValue(v.storage[1]) >= v.storage[2] then
								return true
							end
						else
							return true
						end
					end
				else
					return true
				end
			end
		else
			return true
		end
	end
	return false
end

function getPlayerStartedTasks(cid)
	local tmp = {}
	local player = Player(cid)
	for k, v in pairs(tasks) do
		if player:getStorageValue(QUESTSTORAGE_BASE + k) > 0 and player:getStorageValue(QUESTSTORAGE_BASE + k) < 2 then
			table.insert(tmp, k)
		end
	end
	return tmp
end

local KillingInTheNameOf = CreatureEvent("KillingInTheNameOf")

function KillingInTheNameOf.onKill(creature, target)
	if target:isPlayer() or target:getMaster() then
		return true
	end
	local player = Player(creature)
	local started = getPlayerStartedTasks(player:getId())

	if started and #started > 0 then
		for _, id in ipairs(started) do
			if table.contains(tasks[id].creatures, getCreatureName(target):lower()) then
				if player:getStorageValue(KILLSSTORAGE_BASE + id) < 0 then
					player:setStorageValue(KILLSSTORAGE_BASE + id, 0)
				end
				if player:getStorageValue(KILLSSTORAGE_BASE + id) < tasks[id].killsRequired then
					player:setStorageValue(KILLSSTORAGE_BASE + id, player:getStorageValue(KILLSSTORAGE_BASE + id) + 1)
					player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, player:getStorageValue(KILLSSTORAGE_BASE + id) .. "/" .. tasks[id].killsRequired .. " " .. tasks[id].raceName .. " already killed.")
				end
			end
		end
	end
	return true
end

KillingInTheNameOf:register()

local creatureevent = CreatureEvent("KillingInTheNameOfReg")

function creatureevent.onLogin(player)
	player:registerEvent("KillingInTheNameOf")
	return true
end

creatureevent:register()

function getPlayerStartedTasksName(cid)
	local tmp = ""
	local player = Player(cid)
	for k, v in pairs(tasks) do
		if player:getStorageValue(QUESTSTORAGE_BASE + k) > 0 and player:getStorageValue(QUESTSTORAGE_BASE + k) < 2 then
			if tmp ~= "" then
				tmp = tmp .. ", "
			end
			tmp = tmp .. v.raceName:lower()
		end
	end
	if tmp ~= "" then
		tmp = "You have started tasks " .. tmp .. ". Say: !task creature name"
	else
		tmp = "You have not started any tasks."
	end
	return tmp
end

local talkaction = TalkAction("!task")

function talkaction.onSay(player, words, param, type)
	param = param:lower()
	local cid = player:getId()
	if param == "" then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, getPlayerStartedTasksName(cid))
	elseif getTaskByName(param) and table.contains(getPlayerStartedTasks(cid), getTaskByName(param)) then
		local task = getTaskByName(param)
		if player:getStorageValue(KILLSSTORAGE_BASE + task) > 0 then
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, "You have currently killed " .. player:getStorageValue(KILLSSTORAGE_BASE + task) .. "/" .. tasks[task].killsRequired .. " " .. tasks[task].raceName .. ".")
		else
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, "You have not killed any " .. tasks[task].raceName .. " yet.")
		end
	else
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, "You have not started this task yet or this task does not exist. (" .. param .. ")")
	end
	return true
end

talk:separator(" ")
talkaction:register()
