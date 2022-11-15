local QBCore = exports['qb-core']:GetCoreObject()

local Safes = {}
local safesLoaded = false
local placeMode = false
local placeModeObj = nil
local PlayerData = QBCore.Functions.GetPlayerData()
local crackingSafe = nil
local crackingSafeHash = nil

local function canAccessSafe(safeid)
    local canAccess = false
    local safeAccess = Safes[safeid].cids

    for i=1, #safeAccess do
        if PlayerData.citizenid == safeAccess[i] then
            canAccess = true
            break
        end
    end

    return canAccess
end

local function isSafeOwner(safeid)
    if Safes[safeid].owner == PlayerData.citizenid then
        return true
    end

    return false
end

local function IsACop()
    local isCop = false

    for i=1, #Config.PoliceJobs do
        if PlayerData.job.name == Config.PoliceJobs[i] then
            isCop = true
            break
        end
    end

    return isCop
end

local function canPickupSafe(objhash)
    local pickable = false

    if Config.Objects[objhash] ~= nil then
        if Config.Objects[objhash].pickable ~= nil then
            pickable = Config.Objects[objhash].pickable
        end
    end

    return pickable
end

local function CreateSafe(safeid, obj, coords)
    QBCore.Functions.LoadModel(obj)

    local object = CreateObject(GetHashKey(obj), coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(object, coords.w)
    FreezeEntityPosition(object, true)
    SetEntityAsMissionEntity(object, true)
    PlaceObjectOnGroundProperly(object)

    local safeData = Safes[safeid]
    local cids = {
        [safeData.owner] = true
    }

    exports['qb-target']:AddBoxZone("safe-"..safeid, vector3(coords.x, coords.y, coords.z), 2.0, 2.0, {
        name = "safe-"..safeid,
        heading = GetEntityHeading(object),
        debugPoly = false,
        minZ = coords.z - 1.0,
        maxZ = coords.z + 1.5,
    }, {
        options = {
            {
                type = "client",
                event = "qb-safe:client:openSafe",
                icon = "fa-solid fa-vault",
                label = "OPEN SAFE",
                safe = safeid,
                citizenid = cids
            },
            --[[
            {
                type = "client",
                event = "qb-safe:client:accessList",
                icon = "fa-solid fa-list",
                label = "Access List",
                safe = safeid,
                canInteract = function()
                    if Config.CanGiveAccess then
                        return isSafeOwner(safeid)
                    end

                    return false
                end
            },
            {
                type = "client",
                event = "qb-safe:client:crackSafe",
                icon = "fa-solid fa-user-ninja",
                label = "Crack Safe", 
                safe = safeid,
                canInteract = function()
                    if Config.SafeRobbable then
                        if not canAccessSafe(safeid) and not isSafeOwner(safeid) then
                            return true
                        end
                    end

                    return false
                end
            },
            ]]--
            {
                type = "client",
                event = "qb-safe:client:RemoveSafe",
                icon = "fa-solid fa-xmark",
                label = "REMOVE SAFE",
                safe = safeid,
                canInteract = function()
                    return isSafeOwner(safeid)
                end
            },
            {
                type = "client",
                event = "qb-safe:client:DisintegrateSafe",
                icon = "fa-solid fa-bomb",
                label = "DESTROY SAFE",
                safe = safeid,
                canInteract = function()
                    return IsACop() 
                end
            },
            {
                type = "client",
                event = "qb-safe:client:PickupSafe",
                icon = "fa-solid fa-people-carry-box",
                label = "PICKUP SAFE",
                safe = safeid,
                canInteract = function()
                    if canPickupSafe(GetHashKey(obj)) and isSafeOwner(safeid) then
                        return true
                    end

                    return false
                end,
            },
        },
        distance = 3.0
    })

    Safes[safeid].obj = object
    SetModelAsNoLongerNeeded(obj)
end

local function DeleteSafe(safeid)
    local safe = Safes[safeid]

    exports['qb-target']:RemoveZone('safe-'..safeid)
    DeleteObject(safe.obj)
    safe.obj = false
end

function LoadSafes()
    local p = promise.new()
    
    QBCore.Functions.TriggerCallback('qb-safe:server:GetSafes', function(safes)
        p:resolve(safes)
    end)

    Safes = Citizen.Await(p)
    safesLoaded = true
end

CreateThread(function()
    while true do
        local sleep = 2000

        if LocalPlayer.state.isLoggedIn and safesLoaded then
            local coords = GetEntityCoords(PlayerPedId())

            for safeid, safe in pairs(Safes) do
                local dist = #(coords - vec3(safe.coords.x, safe.coords.y, safe.coords.z))

                if dist <= 200 and not safe.obj then
                    CreateSafe(safeid, safe.object, safe.coords)
                elseif dist >= 200 and safe.obj then
                    DeleteSafe(safeid)
                end
            end
        end

        Wait(sleep)
    end
end)

RegisterNetEvent('qb-safe:client:CreateSafe', function(safeid, obj, coords, data)
    Safes[safeid] = data
    CreateSafe(safeid, obj, coords)
end)

RegisterNetEvent('qb-safe:client:SyncSafeCoords', function(safeid, obj, coords)
    DeleteSafe(safeid)
    CreateSafe(safeid, obj, coords)
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()

    LoadSafes()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        if LocalPlayer.state.isLoggedIn then
            Wait(2000)
            LoadSafes()
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for safeid, safe in pairs(Safes) do
            DeleteSafe(safeid)
        end

        if placeMode then
            if placeModeObj ~= nil then
                DeleteObject(placeModeObj)
            end

            exports['qb-core']:HideText()
        end
    end
end)

AddEventHandler('qb-safe:client:openSafe', function(data)
    local safeid = data.safe
    local storagelimit = Config.Objects[GetEntityModel(data.entity)] or Config.SafeStorage

    TriggerServerEvent("inventory:server:OpenInventory", "stash", 'Safe '..safeid, storagelimit)
    TriggerEvent("inventory:client:SetCurrentStash", 'Safe '..safeid)
end)

AddEventHandler('qb-safe:client:crackSafe', function(data)
    local safeid = data.safe
    crackingSafe = safeid
    crackingSafeHash = GetEntityModel(data.entity)
    TriggerEvent('SafeCracker:StartMinigame', {math.random(1, 300)})
end)

AddEventHandler('SafeCracker:EndMinigame', function(won)
    if crackingSafe ~= nil then
        if won then
            local storagelimit = Config.Objects[crackingSafeHash] or Config.SafeStorage

            TriggerServerEvent("inventory:server:OpenInventory", "stash", 'Safe '..crackingSafe, storagelimit)
            TriggerEvent("inventory:client:SetCurrentStash", 'Safe '..crackingSafe)
        else
            QBCore.Functions.Notify(Lang:t('error.failed'), 'error')
        end

        crackingSafe = nil
        crackingSafeHash = nil
    end
end)

AddEventHandler('qb-safe:client:RemoveSafe', function(data)
    local safeid = data.safe

    local menu = {
        {
            header = Lang:t('menu.removesafe_header'),
            txt = Lang:t('menu.removesafe_context'),
            isMenuHeader = true
        },
        {
            header = Lang:t('menu.yes'),
            params = {
                isServer = true,
                event = 'qb-safe:server:RemoveSafe',
                args = {
                    safeid = safeid
                }
            }
        },
        {
            header = Lang:t('menu.no')
        }
    }

    exports['qb-menu']:openMenu(menu)
end)

AddEventHandler('qb-safe:client:DisintegrateSafe', function(data)
    local safeid = data.safe

    local menu = {
        {
            header = Lang:t('menu.disintegrate_header'),
            isMenuHeader = true
        },
        {
            header = Lang:t('menu.yes'),
            params = {
                isServer = true,
                event = 'qb-safe:server:DisintegrateSafe',
                args = {
                    safeid = safeid
                }
            }
        },
        {
            header = Lang:t('menu.no')
        }
    }

    exports['qb-menu']:openMenu(menu)
end)

AddEventHandler('qb-safe:client:accessList', function(data)
    local safeid = data.safe
    local p = promise.new()

    QBCore.Functions.TriggerCallback('qb-safe:server:GetSafeAccess', function(persons)
        p:resolve(persons)
    end, safeid)

    local persons = Citizen.Await(p)

    if persons then
        local menu = {
            {
                header = Lang:t('menu.access_header'),
                txt = Lang:t('menu.access_context', {id = safeid, owner = persons[Safes[safeid].owner]}),
                isMenuHeader = true
            }
        }

        for cid, name in pairs(persons) do
            if cid ~= Safes[safeid].owner then
                menu[#menu+1] = {
                    header = name,
                    txt = Lang:t('menu.access_remove', {cid = cid}),
                }
            end
        end

        menu[#menu+1] = {
            header = Lang:t('menu.access_add'),
            params = {
                event = 'qb-safe:client:AddAccess',
                args = {
                    safeid = safeid
                }
            }
        }

        exports['qb-menu']:openMenu(menu)
    end
end)

AddEventHandler('qb-safe:client:AddAccess', function(data)
    local safeid = data.safeid

    local closestPlayer, closestDistance = QBCore.Functions.GetClosestPlayer()

    if closestPlayer ~= -1 and closestDistance < 2 then
        TriggerServerEvent('qb-safe:server:AddAccessToSafe', GetPlayerServerId(closestPlayer), safeid)
    else
        QBCore.Functions.Notify(Lang:t('error.player_nearby'), 'error')
    end
end)

AddEventHandler('qb-safe:client:PickupSafe', function(data)
    if not canPickupSafe(GetEntityModel(data.entity)) then return end

    local safeid = data.safe
    local safeobj = data.entity

    CreateThread(function()
        local ped = PlayerPedId()

        QBCore.Functions.RequestAnimDict('anim@amb@clubhouse@tutorial@bkr_tut_ig3@')
        QBCore.Functions.RequestAnimDict("anim@heists@box_carry@")
        QBCore.Functions.RequestAnimDict("mp_car_bomb")

        FreezeEntityPosition(ped,true)
        TaskPlayAnim(ped, "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", 'machinic_loop_mechandplayer', 2.0, 2.0, 1000, 0, 0, true, true, true)
        Wait(1200)

        AttachEntityToEntity(safeobj, ped, GetPedBoneIndex(ped, 57005), 0.0, 0.0, 0.0, 0.0, 20.0, 0.0, true, true, false, true, 1, true)

        FreezeEntityPosition(ped, false)
        FreezeEntityPosition(safeobj, false)

        QBCore.Functions.LoadAnimSet('anim_group_move_ballistic') 
        SetPedMovementClipset(ped, 'anim_group_move_ballistic', 0.2)

        TaskPlayAnim(ped, 'anim@heists@box_carry@', "walk", 8.0, -8, -1, 49, 0, 0, 0, 0)

        exports['qb-core']:DrawText('Press [E] to place down the safe.')

        while true do
            local sleep = 2	

            if IsControlJustReleased(0, 38) then      
                FreezeEntityPosition(ped, true)
                Wait(100)
                TaskPlayAnim(ped, "mp_car_bomb", "car_bomb_mechanic", 3.0, 3.0, -1, 2.0, 0, 0, 0, 0)
                Wait(3000)
                FreezeEntityPosition(ped, false)
                DetachEntity(safeobj, 1, 1)
                Wait(500)

                local heading = GetEntityHeading(ped)
                local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 1.0, 0.0)

                SetEntityCoords(safeobj, coords.x, coords.y, coords.z)
                SetEntityHeading(safeobj, heading)
                PlaceObjectOnGroundProperly(safeobj)
                SetEntityCollision(safeobj, true, true)

                ClearPedTasksImmediately(ped)
                ResetPedMovementClipset(ped)

                local saveCoords = vector4(GetEntityCoords(safeobj), GetEntityHeading(safeobj))

                TriggerServerEvent('qb-safe:server:ChangeSafeCoords', safeid, saveCoords)

                exports['qb-core']:HideText()

                break
            end
            
            Citizen.Wait(sleep)
        end
    end)
end)

RegisterNetEvent('qb-safe:client:DeleteSafe', function(safeid)
    DeleteSafe(safeid)
    Safes[safeid] = nil
end)

RegisterNetEvent('qb-safe:client:PlaceMode', function(object, item)
    if placeMode then
        QBCore.Functions.Notify(Lang:t('error.inmode'), 'error')
        return
    end

    local coords = GetEntityCoords(PlayerPedId())
    
    -- Load model --
    QBCore.Functions.LoadModel(object)

    -- Create object --
    placeMode = true
    placeModeObj = CreateObject(object, coords.x, coords.y, coords.z, false, false, false)
    exports['qb-core']:DrawText(Lang:t('info.placemode'), 'info')
    SetEntityAlpha(placeModeObj, 199, false)
    FreezeEntityPosition(placeModeObj, true)
    SetEntityNoCollisionEntity(PlayerPedId(), placeModeObj, false)

    CreateThread(function()
        local function ExitPlaceMode()
            placeMode = false
            DeleteObject(placeModeObj)
            exports['qb-core']:HideText()
        end

        while placeMode do
            local objCoords = GetEntityCoords(placeModeObj)
            local heading = GetEntityHeading(placeModeObj)
            local dist = #(coords - objCoords)

            -- Disable R key --
            DisableControlAction(0, 140, true)

            if dist >= 5 then
                ExitPlaceMode()
                QBCore.Functions.Notify(Lang:t('error.outbounds'), 'error')
                break
            end

            if IsControlPressed(0, 188) then -- ARROW UP
                SetEntityCoords(placeModeObj, objCoords.x, objCoords.y, objCoords.z + 0.05)
            end

            if IsControlPressed(0, 187) then -- ARROW DOWN
                SetEntityCoords(placeModeObj, objCoords.x, objCoords.y, objCoords.z - 0.05)
            end

            if IsControlPressed(0, 189) then -- ARROW LEFT
                SetEntityCoords(placeModeObj, objCoords.x - 0.05, objCoords.y, objCoords.z)
            end

            if IsControlPressed(0, 190) then -- ARROW LEFT
                SetEntityCoords(placeModeObj, objCoords.x + 0.05, objCoords.y, objCoords.z)
            end

            if IsControlPressed(0, 47) then
                PlaceObjectOnGroundProperly(placeModeObj)
            end

            if IsControlPressed(0, 201) then
                TriggerServerEvent('qb-safe:server:CreateSafe', item, objCoords, heading)
                ExitPlaceMode()
                break
            end

            if IsDisabledControlPressed(0, 140) then -- ROTATE
                SetEntityHeading(placeModeObj, heading + 1.0)
            end

            if IsControlPressed(0, 202) then -- CANCEL
                ExitPlaceMode()
                break
            end

            Wait(1)
        end
    end)
end)