local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)			npcHandler:onCreatureAppear(cid)			end
function onCreatureDisappear(cid)		npcHandler:onCreatureDisappear(cid)			end
function onCreatureSay(cid, type, msg)		npcHandler:onCreatureSay(cid, type, msg)		end
function onThink()				npcHandler:onThink()					end

local choose = {}
local cancel = {}

function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end
	local player = Player(cid)

	if table.contains({"tasks", "task", "mission"}, msg:lower()) then
		local can = getTasksByPlayer(cid)
		if #can > 0 then
			local text = ""
			local sep = ", "
			table.sort(can, (function(a, b) return (a < b) end))
			local t = 0
			for _, id in ipairs(can) do
				t = t + 1
				if t == #can - 1 then
					sep = " and "
				elseif t == #can then
					sep = "."
				end
				text = text .. "{" .. (tasks[id].name or tasks[id].raceName) .. "}" .. sep
			end
			npcHandler:say("The current task" .. (#can > 1 and "s" or "") .. " that you can choose " .. (#can > 1 and "are" or "is") .. " " .. text, cid)
			npcHandler.topic[cid] = 0
		else
			npcHandler:say("I don't have any task for you right now.", cid)
		end
	elseif msg ~= "" and canStartTask(cid, msg) then
		if #getPlayerStartedTasks(cid) >= TaskConfig.tasksByPlayer then
			npcHandler:say("Sorry, but you already started " .. TaskConfig.tasksByPlayer .. " tasks.", cid)
			return true
		end
		local task = getTaskByName(msg)
		if task and player:getStorageValue(QUESTSTORAGE_BASE + task) > 0 then
			return false
		end
		npcHandler:say("In this task you must defeat " .. tasks[task].killsRequired .. " " .. tasks[task].raceName .. ". Are you sure that you want to start this task?", cid)
		choose[cid] = task
		npcHandler.topic[cid] = 1
	elseif msg:lower() == "yes" and npcHandler.topic[cid] == 1 then
		player:setStorageValue(QUESTSTORAGE_BASE + choose[cid], 1)
		npcHandler:say("Excellent! You can check the status of your task saying {report} to me.", cid)
		choose[cid] = nil
		npcHandler.topic[cid] = 0
	elseif msg:lower() == "report" then
		local started = getPlayerStartedTasks(cid)
		local finishedAtLeastOnce = false
		local finished = 0
		if started and #started > 0 then
			for _, id in ipairs(started) do
				if player:getStorageValue(KILLSSTORAGE_BASE + id) >= tasks[id].killsRequired then
					for _, reward in ipairs(tasks[id].rewards) do
						local deny = false
						if reward.storage then
							if player:getStorageValue(reward.storage[1]) >= reward.storage[2] then
								deny = true
							end
						end
						if table.contains({REWARD_MONEY, "money"}, reward.type:lower()) and not deny then
							player:addMoney(reward.value[1])
						elseif table.contains({REWARD_EXP, "exp", "experience"}, reward.type:lower()) and not deny then
							player:addExperience(reward.value[1])
							player:sendCancelMessage("You gained " .. reward.value[1] .. " experience points.")
						elseif table.contains({REWARD_ACHIEVEMENT, "achievement", "ach"}, reward.type:lower()) and not deny then
							player:addAchievement(reward.value[1], true)
						elseif table.contains({REWARD_STORAGE, "storage", "stor"}, reward.type:lower()) and not deny then
							player:setStorageValue(reward.value[1], reward.value[2])
						elseif table.contains({REWARD_POINT, "points", "point"}, reward.type:lower()) and not deny then
							player:setStorageValue(POINTSSTORAGE, player:getStorageValue(POINTSSTORAGE) + reward.value[1])
						elseif table.contains({REWARD_ITEM, "item", "items", "object"}, reward.type:lower()) and not deny then
							player:addItem(reward.value[1], reward.value[2])
						end

						if reward.storage then
							player:setStorageValue(reward.storage[1], reward.storage[2])
						end
					end

					if tasks[id].norepeatable then
						player:setStorageValue(QUESTSTORAGE_BASE + id, 2)
					else
						player:setStorageValue(QUESTSTORAGE_BASE + id, 0)
					end

					player:setStorageValue(KILLSSTORAGE_BASE + id, 0)

					if player:getStorageValue(REPEATSTORAGE_BASE + id) < 1 then
						player:setStorageValue(REPEATSTORAGE_BASE + id, 0)
					end
					player:setStorageValue(REPEATSTORAGE_BASE + id, player:getStorageValue(REPEATSTORAGE_BASE + id) + 1)
					finishedAtLeastOnce = true
					finished = finished + 1
				end
			end

			if not finishedAtLeastOnce then
				npcHandler:say("You haven't finished any task yet.", cid)
			else
				npcHandler:say("Awesome! you finished " .. (finished > 1 and "various" or "a") .. " task" .. (finished > 1 and "s" or "") .. ". Talk to me again if you want to start a task.", cid)
			end
		else
			npcHandler:say("You haven't started any task yet.", cid)
		end
	elseif msg:lower() == "started" then
		local started = getPlayerStartedTasks(cid)
		if started and #started > 0 then
			local text = ""
			local sep = ", "
			table.sort(started, (function(a, b) return (a < b) end))
			local t = 0
			for _, id in ipairs(started) do
				t = t + 1
				if t == #started - 1 then
					sep = " and "
				elseif t == #started then
					sep = "."
				end
				text = text .. "{" .. (tasks[id].name or tasks[id].raceName) .. "}" .. sep
			end

			npcHandler:say("The current task" .. (#started > 1 and "s" or "") .. " that you started " .. (#started > 1 and "are" or "is") .. " " .. text, cid)
		else
			npcHandler:say("You haven't started any task yet.", cid)
		end
	elseif msg:lower() == "cancel" then
		local started = getPlayerStartedTasks(cid)
		if started and #started > 0 then
			npcHandler:say("Canceling a task will make the count restart. Which task you want to cancel?", cid)
			npcHandler.topic[cid] = 2
		else
			npcHandler:say("You haven't started any task yet.", cid)
		end
	elseif getTaskByName(msg) and npcHandler.topic[cid] == 2 and table.contains(getPlayerStartedTasks(cid), getTaskByName(msg)) then
		local task = getTaskByName(msg)
		if player:getStorageValue(KILLSSTORAGE_BASE + task) > 0 then
			npcHandler:say("You currently killed " .. player:getStorageValue(KILLSSTORAGE_BASE + task) .. "/" .. tasks[task].killsRequired .. " " .. tasks[task].raceName .. ". Canceling this task will restart the count. Are you sure you want to cancel this task?", cid)
		else
			npcHandler:say("Are you sure you want to cancel this task?", cid)
		end
		npcHandler.topic[cid] = 3
		cancel[cid] = task
	elseif msg:lower() == "yes" and npcHandler.topic[cid] == 3 then
		player:setStorageValue(QUESTSTORAGE_BASE + cancel[cid], -1)
		player:setStorageValue(KILLSSTORAGE_BASE + cancel[cid], -1)
		npcHandler:say("You have canceled the task " .. (tasks[cancel[cid]].name or tasks[cancel[cid]].raceName) .. ".", cid)
		npcHandler.topic[cid] = 0
	elseif table.contains({"points", "rank"}, msg:lower()) then
		npcHandler:say("At this time, you have " .. player:getStorageValue(POINTSSTORAGE) .. " Paw & Fur points. You " .. (getPlayerRank(cid) == 5 and "are an Elite Hunter" or getPlayerRank(cid) == 4 and "are a Trophy Hunter" or getPlayerRank(cid) == 3 and "are a Big Game Hunter" or getPlayerRank(cid) == 2 and "are a Ranger" or getPlayerRank(cid) == 1 and "are a Huntsman" or "haven't been ranked yet") .. ".", cid)
		npcHandler.topic[cid] = 0
	end
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setMessage(MESSAGE_GREET, "Welcome to the 'Paw and Fur - Hunting Elite' |PLAYERNAME|. Feel free to do {tasks} for us or {report} a finished one.")
npcHandler:setMessage(MESSAGE_FAREWELL, "Happy hunting, old chap!")
npcHandler:addModule(FocusModule:new())
