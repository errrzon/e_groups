local groups = {}
local ESX = nil
if Config.Framework == "esx" then
	ESX = exports["es_extended"]:getSharedObject()
end

-- FUNCTIONS

local function Notify(id, desc, type)
	TriggerClientEvent("ox_lib:notify", id, {
		title = 'Groups',
		description = desc,
		type = type,
		icon = "square",
		iconAnimation = "spin"
	})
end

local function isPlayerGroupOwner(source)
	if groups[source]?.groupOwner then
		return true
	end
	return false
end

local function isPlayerInGroup(id)
	for key, value in pairs(groups) do
		local playerCount = #value.players
		for i = 1, playerCount, 1 do
			if value.players[i].id == id then
				return true
			end
		end
	end
	return false
end

lib.addCommand('gr', { help = 'Manage your group!' }, function(source)
	local src = source
	local isOwner = isPlayerGroupOwner(src)
	local isInGroup = isPlayerInGroup(src)
	local players = nil
	if isOwner then
		players = groups[src].players
	end
	TriggerClientEvent("e_groups:client:createGroup:UI", source, isOwner, isInGroup, players)
end)

-- CREATES NEW GROUP
RegisterNetEvent("e_groups:server:CreateGroup", function()
	local src = source
	local isOwner = isPlayerGroupOwner(src)
	local isInGroup = isPlayerInGroup(src)
	if isOwner or isInGroup then
		Notify(src, "You already have a group!", "inform")
		return
	end
	if Config.Framework == 'esx' then
		local xPlayer = ESX.GetPlayerFromId(src)
		groups[src] = {
			groupOwner = src,
			players = {
				{
					name = xPlayer.getName(),
					id = src
				},
			},
			groupSize = 1,
			isLocked = false
		}
	elseif Config.Framework == 'qb' then
		local player = exports.qbx_core:GetPlayer(source)
		local name = ("%s %s"):format(player.PlayerData.charinfo.firstname, player.PlayerData.charinfo.lastname)
		groups[src] = {
			groupOwner = src,
			players = {
				{
					name = name,
					id = src
				},
			},
			groupSize = 1,
			isLocked = false
		}
	end
	Player(src).state.groups = { ownerid = src }
	TriggerClientEvent("e_groups:client:createGroup:UI", source, true, true, groups[src].players)
	Notify(src, "Succesfully created a group!", "inform")
end)

RegisterNetEvent("e_groups:server:RemoveGroup", function()
	local src = source
	if groups[src].isLocked then
		Notify(src, "This group is currently doing something.End task before removing group!", "inform")
		return
	end
	groups[src] = nil
	Notify(src, "Group removed!", "inform")
end)

RegisterNetEvent("e_groups:server:AddMember", function(targetId)
	local src = source
	if isPlayerGroupOwner(targetId) then
		Notify(src, "This player is already a owner of existing group!", "inform")
		return
	end
	if groups[src].isLocked then
		Notify(src, "This group is currently doing something.End task before inviting player!", "inform")
		return
	end
	if groups[src].groupSize >= 4 then
		Notify(src, "This group has already reached it's player limit!", "inform")
		return
	end
	if isPlayerInGroup(targetId) then
		Notify(src, "Player is already in some group", "inform")
		return
	end

	local xPlayer
	local name
	if Config.Framework == 'esx' then
		xPlayer = ESX.GetPlayerFromId(src)
		name = ESX.GetPlayerFromId(targetId).getName()
	elseif Config.Framework == 'qb' then
		xPlayer = exports.qbx_core:GetPlayer(targetId)
		name = ("%s %s"):format(xPlayer.PlayerData.charinfo.firstname, xPlayer.PlayerData.charinfo.lastname)
	end

	local accepted = lib.callback.await("e_groups:client:RequestMembership", targetId, xPlayer.getName())
	if accepted == "confirm" then
		local group = groups[src].players
		group[#group + 1] = {
			name = name,
			id = targetId
		}
		groups[src].groupSize += 1
		Notify(src, ("Player with id: %s joined your group!"):format(targetId), "inform")
		Notify(targetId, ("Joined id:%s group!"):format(src), "inform")
		Player(targetId).state.groups = { ownerid = src }
		return
	else
		Notify(src, ("Player with id: %s refused your invite!"):format(targetId), "inform")
	end
end)

RegisterNetEvent("e_groups:server:RemoveMember", function()
	local src = source
	if groups[src].isLocked then
		Notify(src, "This group is currently doing something. End task before removing player!", "inform")
	end
	local players = groups[src].players
	local whoToKick = lib.callback.await('e_groups:client:DecideWhoToKick', source, players)
	for i = 1, #players, 1 do
		if whoToKick == players[i].name then
			if players[i].id == src then
				Notify(src, "You can't kick yourself dumbass!", "inform")
				return
			end
			Notify(src, "Succesfuly removed player", "inform")
			Notify(players[i].id, "You got kick from the group", "inform")
			players[i] = nil
			groups[src].groupSize -= 1
			Player(players[i].id).state.groups = nil
		end
	end
end)

RegisterNetEvent("e_groups:server:LeaveGroup", function()
	local src = source
	local ownerid = Player(src).state.groups.ownerid
	local group = groups[ownerid].players
	for i = 1, #group, 1 do
		if group[i].id == src then
			if groups[src].isLocked then
				Notify(src, "This group is currently doing something.End task before leaving group!", "inform")
				return
			end
			Notify(src, "You left your current group!", "inform")
			Notify(ownerid, ("%s left your group!"):format(group[i].name), "inform")
			group[i] = nil
			Player(src).state.groups = nil
			groups[ownerid].groupSize -= 1
		end
	end
end)

lib.callback.register('e_groups:server:GetPlayerNames', function(source, tempPlayersIds)
	local tempTable = {}
	for i = 1, #tempPlayersIds, 1 do
		local xPlayer
		local name
		if Config.Framework == 'esx' then
			xPlayer = ESX.GetPlayerFromId(tempPlayersIds[i])
			name = xPlayer.getName()
		elseif Config.Framework == 'qb' then
			xPlayer = exports.qbx_core:GetPlayer(tempPlayersIds[i])
			name = ("%s %s"):format(xPlayer.PlayerData.charinfo.firstname, xPlayer.PlayerData.charinfo.lastname)
		end
		tempTable[#tempTable + 1] = name
	end
	return tempTable
end)

lib.callback.register('e_groups:server:getPlayerNames', function(source)
	local src = source
	local ownerid = Player(src).state.groups.ownerid
	return groups[ownerid].players
end)


RegisterNetEvent("e_groups:server:TriggerGroupEvent", function(id, eventName, ...)
	local src = id or source
	if not isPlayerGroupOwner(src) then return end
	local group = groups[src].players
	for _, value in ipairs(group) do
		TriggerClientEvent(eventName, value.id, ...)
	end
end)

-- handle player leaving server
AddEventHandler('playerDropped', function(reason)
	local src = source
	local group = groups[src]
	if isPlayerGroupOwner(src) then
		local playerCount = #group.players
		if playerCount == 1 then
			group[src] = nil
			return
		end
		if playerCount > 1 then
			local name
			for i = 1, playerCount, 1 do
				if group.players[i].id == src then
					if group.players[i + 1].id then
						group.groupOwner = group.players[i + 1].id
						name = group.players[i + 1].name
					elseif group.players[i - 1].id then
						group.groupOwner = group.players[i - 1].id
						name = group.players[i + 1].name
					end
					for _, value in ipairs(group) do
							Notify(value.id, ("%s left group!"):format(group.players[i].name))
							Notify(value.id, ("%s is new Owner!"):format(name))
					end
					group.players[i].id = nil
					group.groupSize -= 1
					return
				end
			end
		end
		return
	end
	if isPlayerInGroup(src) then
		for i = 1, #group.players, 1 do
			if group.players[i].id == src then
				group.players[i] = nil
				for _, value in ipairs(group) do
					Notify(value.id, ("%s left group!"):format(group.players[i].name))
				end
				return
			end
		end
	end
end)

-- USED FOR EXPORTS

lib.callback.register('e_groups:server:isPlayerOwnerOfGroup', function(source)
	return isPlayerGroupOwner(source)
end)

exports("getGroupOwner", function(id)
	for key, value in pairs(groups) do
		local playerCount = #value.players
		for i = 1, playerCount, 1 do
			if value.players[i].id == id then
				return value.groupOwner
			end
		end
	end
	return -1
end)
exports("getGroupPlayers", function(id)
	if not isPlayerGroupOwner(id) then return -1 end
	return groups[id].players
end)
exports("isGroupLocked", function(id)
	if not isPlayerGroupOwner(id) then return -1 end
	return groups[id].isLocked
end)
exports("setGroupLockedStatus", function(id, status)
	if not isPlayerGroupOwner(id) then return -1 end
	if type(status) == "boolean" then
		groups[id].isLocked = status
		return groups[id].isLocked
	end
end)
