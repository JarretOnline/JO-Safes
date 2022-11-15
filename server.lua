local QBCore = exports['qb-core']:GetCoreObject()
local Safes = {}

for k,v in pairs(Config.Safes) do
    QBCore.Functions.CreateUseableItem(k, function(source, item)
        local Player = QBCore.Functions.GetPlayer(source)
        TriggerClientEvent('qb-safe:client:PlaceMode', source, v, k)
    end)
end

MySQL.ready(function()
    local safes = MySQL.query.await("SELECT * FROM safes")
    local safecount = 0

    for _, v in pairs(safes) do
        Safes[v.safeid] = {
            id = v.safeid,
            owner = v.owner,
            object = v.object,
            item = v.item,
            coords = json.decode(v.coords),
            cids = json.decode(v.cids)
        }

        safecount = safecount + 1
    end

    if safecount > 0 then
        print(safecount, ' safes have been loaded!')
    end
end)

local function IsACop(job)
    local isCop = false

    for i=1, #Config.PoliceJobs do
        if job == Config.PoliceJobs[i] then
            isCop = true
            break
        end
    end

    return isCop
end

local function CreateSafe(cid, object, coords, item)
    local safeid = MySQL.insert.await('INSERT INTO safes (owner, coords, object, item) VALUES (?, ?, ?, ?)', {
        cid,
        json.encode(coords),
        object,
        item
    })

    Safes[safeid] = {
        owner = cid,
        coords = coords,
        item = item,
        cids = {}
    }

    return safeid
end

QBCore.Functions.CreateCallback('qb-safe:server:GetSafes', function(source, cb)
    while Safes == nil do
        Citizen.Wait(100)
    end

    cb(Safes)
end)

QBCore.Functions.CreateCallback('qb-safe:server:GetSafeAccess', function(source, cb, safeid)
    local cids = Safes[safeid].cids
    local persons = {}

    cids[#cids+1] = Safes[safeid].owner

    for i=1, #cids do
        local Player = QBCore.Functions.GetPlayerByCitizenId(cids[i])

        if Player then
            persons[cids[i]] = ('%s %s'):format(Player.PlayerData.charinfo.firstname, Player.PlayerData.charinfo.lastname)
        else
            local name = MySQL.query.await("SELECT firstname, lastname FROM players WHERE citizenid = ?", {cids[i]})

            if name and name[1] then
                persons[cids[i]] = ('%s %s'):format(name[1].firstname, name[1].lastname)
            end
        end
    end

    cb(persons)
end)

RegisterNetEvent('qb-safe:server:CreateSafe', function(item, coords, heading)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Config.Safes[item] == nil then return end
    if Player == nil then return end

    if Player.Functions.RemoveItem(item, 1) then
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[item], 'remove')

        local safeCoords = vec4(coords.x, coords.y, coords.z, heading)
        local safeid = CreateSafe(Player.PlayerData.citizenid, Config.Safes[item], safeCoords, item)
        
        TriggerClientEvent('qb-safe:client:CreateSafe', -1, safeid, Config.Safes[item], safeCoords, Safes[safeid])
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        local queries = {}
        local defaultquery = 'UPDATE safes SET cids = :cids WHERE safeid = :safeid'
        
        for _, v in pairs(Safes) do
            queries[#queries+1] = {
                query = defaultquery,
                values = {
                    ['cids'] = json.encode(v.cids),
                    ['safeid'] = v.safeid
                }
            }
        end

        if #queries > 0 then
            MySQL.transaction(queries)
        end
    end
end)

RegisterNetEvent('qb-safe:server:AddAccessToSafe', function(target, safeid)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local Target = QBCore.Functions.GetPlayer(target)

    if Player == nil then return end
    if Target == nil then return end

    if Player.PlayerData.citizenid == Safes[safeid].owner then
        local count = #Safes[safeid].cids

        Safes[safeid].cids[count+1] = Target.PlayerData.citizenid
        TriggerClientEvent('QBCore:Notify', src, Lang:t('success.access_added', {name = ('%s %s'):format(Target.PlayerData.charinfo.firstname, Target.PlayerData.charinfo.lastname)}), 'success')
    end
end)

RegisterNetEvent('qb-safe:server:RemoveSafe', function(data)
    local src = source
    local safeid = data.safeid
    local Player = QBCore.Functions.GetPlayer(src)

    if Safes[safeid].owner == Player.PlayerData.citizenid then
        MySQL.query.await('DELETE FROM safes WHERE owner = ? AND safeid = ?', {
            Player.PlayerData.citizenid,
            safeid
        })

        Player.Functions.AddItem(Safes[safeid].item, 1)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Safes[safeid].item], 'add')
        Safes[safeid] = nil

        TriggerClientEvent('qb-safe:client:DeleteSafe', -1, safeid)
    end
end)

RegisterNetEvent('qb-safe:server:DisintegrateSafe', function(data)
    local src = source
    local safeid = data.safeid
    local Player = QBCore.Functions.GetPlayer(src)

    if IsACop(Player.PlayerData.job.name) then
        MySQL.query.await('DELETE FROM safes WHERE owner = ? AND safeid = ?', {
            Safes[safeid].owner,
            safeid
        })

        TriggerClientEvent('qb-safe:client:DeleteSafe', -1, safeid)
        TriggerClientEvent('QBCore:Notify', src, Lang:t('success.disintegrate_safe', {cid = Safes[safeid].owner}))

        Safes[safeid] = nil
    else
        TriggerClientEvent("QBCore:Notify", src, Lang:t('error.not_authorized'), 'error')
    end
end)

RegisterNetEvent('qb-safe:server:ChangeSafeCoords', function(id, pos)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local safeid = id
    local coords = pos

    MySQL.update('UPDATE safes SET coords = :coords WHERE owner = :owner AND safeid = :id', {
        ['coords'] = json.encode(coords),
        ['owner'] = Player.PlayerData.citizenid,
        ['id'] = Safes[safeid].id
    })

    Safes[safeid].coords = coords

    TriggerClientEvent('qb-safe:client:SyncSafeCoords', -1, safeid, Safes[safeid].object, Safes[safeid].coords)
end)