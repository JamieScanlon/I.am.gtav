-------------------------------------------------------------------------------
-- Exports
-------------------------------------------------------------------------------

exports('getAttachedProp', function()
	return attachedPropRight
end)

exports('getAttachedPropRight', function()
	return attachedPropRight
end)

exports('getAttachedPropLeft', function()
	return attachedPropLeft
end)

exports('dropAllWeaponsWeapons', function()
	dropWeapons()
end)

-------------------------------------------------------------------------------
-- Register slash commands
-------------------------------------------------------------------------------

RegisterCommand('p', function(source, args, raw) 
	local item = args[1]
	local myProp = attachPropList[item]
	if myProp then
    	TriggerEvent("iam-props:attachPropRight",attachPropList[item]["model"], attachPropList[item]["bone"], attachPropList[item]["x"], attachPropList[item]["y"], attachPropList[item]["z"], attachPropList[item]["xR"], attachPropList[item]["yR"], attachPropList[item]["zR"], attachPropList[item]["vertexIndex"], attachPropList[item]["disableCollision"])
    end
end)
RegisterCommand('prop', function(source, args, raw) 
	local item = args[1]
	local myProp = attachPropList[item]
	if myProp then
    	TriggerEvent("iam-props:attachPropRight",attachPropList[item]["model"], attachPropList[item]["bone"], attachPropList[item]["x"], attachPropList[item]["y"], attachPropList[item]["z"], attachPropList[item]["xR"], attachPropList[item]["yR"], attachPropList[item]["zR"], attachPropList[item]["vertexIndex"], attachPropList[item]["disableCollision"])
    end
end)
RegisterCommand('pr', function(source, args, raw) 
	local item = args[1]
	local myProp = attachPropList[item]
	if myProp then
    	TriggerEvent("iam-props:attachPropRight",attachPropList[item]["model"], attachPropList[item]["bone"], attachPropList[item]["x"], attachPropList[item]["y"], attachPropList[item]["z"], attachPropList[item]["xR"], attachPropList[item]["yR"], attachPropList[item]["zR"], attachPropList[item]["vertexIndex"], attachPropList[item]["disableCollision"])
    end
end)
RegisterCommand('propright', function(source, args, raw) 
	local item = args[1]
	local myProp = attachPropList[item]
	if myProp then
    	TriggerEvent("iam-props:attachPropRight",attachPropList[item]["model"], attachPropList[item]["bone"], attachPropList[item]["x"], attachPropList[item]["y"], attachPropList[item]["z"], attachPropList[item]["xR"], attachPropList[item]["yR"], attachPropList[item]["zR"], attachPropList[item]["vertexIndex"], attachPropList[item]["disableCollision"])
    end
end)
RegisterCommand('pl', function(source, args, raw) 
	local item = args[1]
	local myProp = attachPropList[item]
	if myProp then
    	TriggerEvent("iam-props:attachPropLeft",attachPropList[item]["model"], attachPropList[item]["bone"], attachPropList[item]["x"], attachPropList[item]["y"], attachPropList[item]["z"], attachPropList[item]["xR"], attachPropList[item]["yR"], attachPropList[item]["zR"], attachPropList[item]["vertexIndex"], attachPropList[item]["disableCollision"])
    end
end)
RegisterCommand('propleft', function(source, args, raw) 
	local item = args[1]
	local myProp = attachPropList[item]
	if myProp then
    	TriggerEvent("iam-props:attachPropLeft",attachPropList[item]["model"], attachPropList[item]["bone"], attachPropList[item]["x"], attachPropList[item]["y"], attachPropList[item]["z"], attachPropList[item]["xR"], attachPropList[item]["yR"], attachPropList[item]["zR"], attachPropList[item]["vertexIndex"], attachPropList[item]["disableCollision"])
    end
end)

-------------------------------------------------------------------------------
-- Events
-------------------------------------------------------------------------------

RegisterNetEvent('iam-props:attachPropRight')
AddEventHandler('iam-props:attachPropRight', function(model, bone, x, y, z, xR, yR, zR, pVertexIndex, disableCollision)
	attachPropRight(model, bone, x, y, z, xR, yR, zR, pVertexIndex, disableCollision)
end)

RegisterNetEvent('iam-props:attachPropLeft')
AddEventHandler('iam-props:attachPropLeft', function(model, bone, x, y, z, xR, yR, zR)
	attachPropLeft(model, bone, x, y, z, xR, yR, zR)
end)

RegisterNetEvent('iam-props:attachPermanentProp')
AddEventHandler('iam-props:attachPermanentProp', function(model, bone, x, y, z, xR, yR, zR)
	attachPermanentProp(model, bone, x, y, z, xR, yR, zR)
end)

RegisterNetEvent('iam-props:destroyPropRight')
AddEventHandler('iam-props:destroyPropRight', function()
	removeAttachedPropRight()
end)

RegisterNetEvent('iam-props:destroyPropLeft')
AddEventHandler('iam-props:destroyPropLeft', function()
	removeAttachedPropLeft()
end)

RegisterNetEvent('iam-props:destroyPermanentProp')
AddEventHandler('iam-props:destroyPermanentProp', function()
	removeAttachedPermanentProp()
end)

-- Another way to call attachPropLeft with an object instead of individual params
RegisterNetEvent('iam-props:attachPropLeftObj')
AddEventHandler('iam-props:attachPropLeftObj', function(item)
	TriggerEvent("iam-props:attachPropLeft",attachPropList[item]["model"], attachPropList[item]["bone"], attachPropList[item]["x"], attachPropList[item]["y"], attachPropList[item]["z"], attachPropList[item]["xR"], attachPropList[item]["yR"], attachPropList[item]["zR"])
end)

-- Another way to call attachPropRight with an object instead of individual params
RegisterNetEvent('iam-props:attachPropRightObj')
AddEventHandler('iam-props:attachPropRightObj', function(item)
	TriggerEvent("iam-props:attachPropRight",attachPropList[item]["model"], attachPropList[item]["bone"], attachPropList[item]["x"], attachPropList[item]["y"], attachPropList[item]["z"], attachPropList[item]["xR"], attachPropList[item]["yR"], attachPropList[item]["zR"], attachPropList[item]["vertexIndex"], attachPropList[item]["disableCollision"])
end)

-- Another way to call attachPermanentProp with an object instead of individual params
RegisterNetEvent('iam-props:attachPermanentPropObj')
AddEventHandler('iam-props:attachPermanentPropObj', function(item)
	TriggerEvent("iam-props:attachPermanentProp",attachPropList[item]["model"], attachPropList[item]["bone"], attachPropList[item]["x"], attachPropList[item]["y"], attachPropList[item]["z"], attachPropList[item]["xR"], attachPropList[item]["yR"], attachPropList[item]["zR"])
end)

RegisterNetEvent('iam-props:animate:carryAndDrop');
AddEventHandler('iam-props:animate:carryAndDrop', function()
	animateCarryAndDrop()
end)

RegisterNetEvent('iam-props:removeCurrent');
AddEventHandler('iam-props:removeCurrent', function()
	removeAnythingAttached()
end)

RegisterNetEvent('iam-props:dropAllWeapons')
AddEventHandler('iam-props:dropAllWeapons', function()
	dropWeapons()
end)

RegisterNetEvent('iam-props:removeCarriedObject')
AddEventHandler('iam-props:removeCarriedObject', function()
	removeAttachedCarriedObject()
end)

RegisterNetEvent('ima-props:attachCarriedObject')
AddEventHandler('ima-props:attachCarriedObject', function(model, bone, x, y, z, xR, yR, zR)
	attachCarriedObject(model, bone, x, y, z, xR, yR, zR)
end)

-------------------------------------------------------------------------------
-- State / Constants
-------------------------------------------------------------------------------

local holding = "none"

local holdingPackage = false

attachedPropRight = 0
attachedPropLeft = 0
attachedPermanentProp = 0

carryingObject = false
carryObject = 0
objectType = 0
carryAnimType = 49
local canceled = false
local inVehicle = false
local lastObjectHealth = 0
local radollTimer = 0
local destroyByRagdoll = false

-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------

function removeAttachedPropRight()
	if DoesEntityExist(attachedPropRight) then
		DeleteEntity(attachedPropRight)
		attachedPropRight = 0
	end
end

function removeAttachedPropLeft()
	if DoesEntityExist(attachedPropLeft) then
		DeleteEntity(attachedPropLeft)
		attachedPropLeft = 0
	end
end

function removeAttachedPermanentProp()
	if DoesEntityExist(attachedPermanentProp) then
		DeleteEntity(attachedPermanentProp)
		attachedPermanentProp = 0
	end
end

function attachPropRight(model, bone, x, y, z, xR, yR, zR, pVertexIndex, disableCollision)
	removeAttachedPropRight()
	local attachModel = GetHashKey(model)
	boneNumber = bone
	SetCurrentPedWeapon(PlayerPedId(), noWeaponHash)
	local boneIndex = GetPedBoneIndex(PlayerPedId(), bone)
	RequestModel(attachModel)
	while not HasModelLoaded(attachModel) do
		Citizen.Wait(100)
	end
	attachedPropRight = CreateObject(attachModel, 1.0, 1.0, 1.0, 1, 1, 0)
	if disableCollision then
		SetEntityCollision(attachedPropRight, false, false)
	end
	SetModelAsNoLongerNeeded(attachModel)
	AttachEntityToEntity(attachedPropRight, PlayerPedId(), boneIndex, x, y, z, xR, yR, zR, 1, 1, 0, 0, pVertexIndex and pVertexIndex or 2, 1)

end

function attachPropLeft(model, bone, x, y, z, xR, yR, zR)
	removeAttachedPropLeft()
	local attachModelLeft = GetHashKey(model)
	boneNumber = bone
	SetCurrentPedWeapon(PlayerPedId(), noWeaponHash)
	local boneIndex = GetPedBoneIndex(PlayerPedId(), bone)
	RequestModel(attachModelLeft)
	while not HasModelLoaded(attachModelLeft) do
		Citizen.Wait(100)
	end
	attachedPropLeft = CreateObject(attachModelLeft, 1.0, 1.0, 1.0, 1, 1, 0)
	AttachEntityToEntity(attachedPropLeft, PlayerPedId(), boneIndex, x, y, z, xR, yR, zR, 1, 0, 0, 0, 2, 1)
end

function attachPermanentProp(model, bone, x, y, z, xR, yR, zR)

	if attachedPermanentProp ~= 0 then
		removeAttachedPermanentProp()
		return
	end

	holdingPackage = true
	local attachModel = GetHashKey(model)
	boneNumber = bone
	SetCurrentPedWeapon(PlayerPedId(), noWeaponHash)
	local boneIndex = GetPedBoneIndex(PlayerPedId(), bone)
	RequestModel(attachModel)
	while not HasModelLoaded(attachModel) do
		Citizen.Wait(100)
	end
	attachedPermanentProp = CreateObject(attachModel, 1.0, 1.0, 1.0, 1, 1, 0)
	AttachEntityToEntity(attachedPermanentProp, PlayerPedId(), boneIndex, x, y, z, xR, yR, zR, 1, 1, 0, 0, 2, 1)
end

function dropWeapons()
	if IsPedArmed(ped, 7) then
		SetCurrentPedWeapon(PlayerPedId(), noWeaponHash)
	end
	TriggerEvent("iam-props:destroyPermanentProp")
end

function removeAttachedCarriedObject()
	if DoesEntityExist(carryObject) then
		DeleteEntity(carryObject)
		carryObject = 0
	end
end

function attachCarriedObject(model, bone, x, y, z, xR, yR, zR)
	removeAttachedCarriedObject()
	local attachModel = GetHashKey(model)
	boneNumber = bone
	SetCurrentPedWeapon(PlayerPedId(), noWeaponHash)
	local boneIndex = GetPedBoneIndex(PlayerPedId(), bone)
	RequestModel(attachModel)
	while not HasModelLoaded(attachModel) do
		Citizen.Wait(100)
	end
	carryObject = CreateObject(attachModel, 1.0, 1.0, 1.0, 1, 1, 0)
	SetEntityCollision(carryObject, 0, 0)
	AttachEntityToEntity(carryObject, PlayerPedId(), boneIndex, x, y, z, xR, yR, zR, 1, 1, true, 0, 2, 1)
end

function animateCarryAndDrop()
	carryAnimType = 16
	carryingObject = true
	TriggerServerEvent("iam-props:carryStateChange", carryingObject)
	Citizen.Wait(5000)
	carryingObject = false
	TriggerServerEvent("iam-props:carryStateChange", carryingObject)
	carryAnimType = 49
end

function removeAnythingAttached()
	local playerped = PlayerPedId()
    local playerCoords = GetEntityCoords(playerped)
    local handle, ObjectFound = FindFirstObject()
    local success
    repeat
        local pos = GetEntityCoords(ObjectFound)
        local distance = #(playerCoords - pos)
		if distance < 1.0 then
			if IsEntityTouchingEntity(PlayerPedId(), ObjectFound) then
				DetachEntity(ObjectFound,false,false)
				DeleteObject(ObjectFound)
				DeleteEntity(ObjectFound)
			end

        end

        success, ObjectFound = FindNextObject(handle)
    until not success
	EndFindObject(handle)
	TriggerEvent("iam-props:animate:carry","none")
end

function setHidden(hide)
	if hide and holding ~= "none" then
		removeAttachedCarriedObject()
		carryingObject = false
		TriggerServerEvent("iam-props:carryStateChange", carryingObject)
		carryObject = 0
		objectType = 0
		carryAnimType = 49
	end

	if not hide and holding ~= "none" then
		local item = holding
		carryAnimType = 49
		carryingObject = true
		TriggerServerEvent("iam-props:carryStateChange", carryingObject)
		objectType = objectPassed
		TriggerEvent("ima-props:attachCarriedObject",attachPropList[item]["model"], attachPropList[item]["bone"], attachPropList[item]["x"], attachPropList[item]["y"], attachPropList[item]["z"], attachPropList[item]["xR"], attachPropList[item]["yR"], attachPropList[item]["zR"])
	end
end

-------------------------------------------------------------------------------
-- Game Loop
-------------------------------------------------------------------------------

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1)
		if carryingObject then
			RequestAnimDict('anim@heists@box_carry@')
			while not HasAnimDictLoaded("anim@heists@box_carry@") do
				Citizen.Wait(0)
				ClearPedTasksImmediately(PlayerPedId())
			end
			if not IsEntityPlayingAnim(PlayerPedId(), "anim@heists@box_carry@", "idle", 3) then
				TaskPlayAnim(PlayerPedId(), "anim@heists@box_carry@", "idle", 8.0, -8, -1, carryAnimType, 0, 0, 0, 0)
				canceled = false
			end
		else
			if IsEntityPlayingAnim(PlayerPedId(), "anim@heists@box_carry@", "idle", 3) and not canceled then
				if holding == "none" then
					ClearPedTasksImmediately(PlayerPedId())
					canceled = true
				else
					ClearPedSecondaryTask(PlayerPedId())
				end
			end
			Wait(1000)
		end
	end
end)

Citizen.CreateThread(function()
    while true do
        Wait(300)
		if holding ~= "none" then
			if inVehicle == nil then
				inVehicle = false
			end

			if IsPedGettingIntoAVehicle(PlayerPedId()) and attachPropList[holding].preventInVehicle then
				-- TODO: Need Some sort of error event
				ClearPedTasksImmediately(PlayerPedId())
			end

			if not inVehicle and IsPedInAnyVehicle(PlayerPedId(), true) then
				inVehicle = true
				if attachPropList[holding] ~= nil and attachPropList[holding].preventInVehicle then
					-- TODO: Need Some sort of error event
					ClearPedTasksImmediately(PlayerPedId())
				else
					setHidden(inVehicle)
				end
			end

			if inVehicle and not IsPedInAnyVehicle(PlayerPedId(), true) then
				inVehicle = false
				setHidden(inVehicle)
			end

			if attachPropList[holding] ~= nil and attachPropList[holding].preventRunning then
				if IsPedRunning(PlayerPedId()) or IsPedSprinting(PlayerPedId()) then
					SetPlayerControl(PlayerId(), 0, 0)
					Citizen.Wait(1000)
					SetPlayerControl(PlayerId(), 1, 1)
				end
			end

			if attachPropList[holding] ~= nil then
				local isColliding = HasEntityCollidedWithAnything(carryObject)

				if isColliding then
					local playerPed = PlayerPedId()
					local velocity = GetEntityVelocity(playerPed)
					local playerHealth = GetEntityHealth(playerPed)

					SetEntityHealth(playerPed, playerHealth - 5)
					SetEntityVelocity(PlayerPedId(), -velocity * 2)
				end
			end

		end

    end
end)

