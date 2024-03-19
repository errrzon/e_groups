RegisterNetEvent("e_groups:client:createGroup:UI", function(isOwner, isInGroup, players)
	if isOwner then
		ShowGroupAsOwner(players)
		return
	end
	if not isOwner and isInGroup then
		ShowGroupAsMember()
		return
	end
	lib.registerContext({
		id = 'createGroup',
		title = 'Groups',
		options = {
			{
				title = 'Create New Group',
				description = 'Click to create new group!',
				icon = 'square',
				onSelect = function()
					TriggerServerEvent("e_groups:server:CreateGroup")
				end
			},
		}
	})
	lib.showContext('createGroup')
end)

local function createMultiSelectField(label, options)
	local formattedOptions = {}
	for i = 1, #options do
		formattedOptions[i] = { label = options[i], value = i }
	end
	return {
		type = 'select',
		label = label,
		options = formattedOptions,
		required = true
	}
end

function ShowGroupAsOwner(players)
	local string = ""
	-- CONCATENATING PLAYERS INTO ONE STRING TO DISPLAY IN MEMBERS DESCRIPTION
	for i = 1, #players, 1 do
		if i == #players then
			string = string .. players[i].name .. ""
		else
			string = string .. players[i].name .. ", "
		end
	end
	lib.registerContext({
		id = 'currentGroup',
		title = 'Groups',
		options = {
			{
				title = 'Members',
				description = string,
				icon = 'square',
			},
			{
				title = 'Add member',
				description = 'Click to add new member to group!',
				icon = 'square',
				onSelect = function()
					local closestPlayers = lib.getNearbyPlayers(GetEntityCoords(cache.ped), 15)
					if #closestPlayers == 0 then
						lib.notify({
							title = 'Groups',
							description = 'There is no one near you!',
							type = 'error',
							icon = "square",
							iconAnimation = "spin"
						})
						return
					end
					local tempPlayersId = {}
					for i = 1, #closestPlayers, 1 do
						tempPlayersId[#tempPlayersId + 1] = GetPlayerServerId(closestPlayers[i].id)
					end
					local options = lib.callback.await('e_groups:server:GetPlayerNames', false, tempPlayersId)
					local input = { lib.inputDialog('Select your options',
						{ createMultiSelectField('Choose one', options) }) }

					if not input then
						return
					end
					local playerId = tempPlayersId[input[1][1]]
					TriggerServerEvent("e_groups:server:AddMember", playerId)
				end
			},
			{
				title = 'Remove member',
				description = 'Click to remove member from your group!',
				icon = 'square',
				onSelect = function()
					TriggerServerEvent("e_groups:server:RemoveMember")
				end
			},
			{
				title = 'Remove Group',
				description = 'Click to remove your group!',
				icon = 'square',
				onSelect = function()
					TriggerServerEvent("e_groups:server:RemoveGroup")
				end
			},
		}
	})
	lib.showContext('currentGroup')
end

function ShowGroupAsMember()
	local players = lib.callback.await('e_groups:server:getPlayerNames', false)
	local string = ""
	-- CONCATENATING PLAYERS INTO ONE STRING TO DISPLAY IN MEMBERS DESCRIPTION
	for i = 1, #players, 1 do
		if i == #players then
			string = string .. players[i].name .. ""
		else
			string = string .. players[i].name .. ", "
		end
	end
	lib.registerContext({
		id = 'currentGroup',
		title = 'Groups',
		options = {
			{
				title = 'Members',
				description = string,
				icon = 'square',
			},
			{
				title = 'Leave group',
				description = 'Click to leave your current group!',
				icon = 'square',
				onSelect = function()
					TriggerServerEvent("e_groups:server:LeaveGroup")
				end
			},
		}
	})
	lib.showContext('currentGroup')
end

-- CALLBACKS

lib.callback.register('e_groups:client:RequestMembership', function(name)
	local alert = lib.alertDialog({
		header = 'Group Invitation!',
		content = ("Do you want to join : %s?"):format(name),
		centered = true,
		cancel = true
	})
	return alert
end)

lib.callback.register('e_groups:client:DecideWhoToKick', function(players)
	if #players <= 0 then return end
	local options = {}
	for i = 1, #players, 1 do
		options[#options + 1] = players[i].name
	end
	local input = { lib.inputDialog('Select your options',
		{ createMultiSelectField('Choose one', options) }) }

	if not input then
		return
	end
	return options[input[1][1]]
end)


exports("isGroupOwner", function()
	return lib.callback.await('e_groups:server:isPlayerOwnerOfGroup', false)
end)
