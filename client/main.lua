local QBCore = exports['qb-core']:GetCoreObject()
local UseTarget = GetConvar('UseTarget', 'false') == 'true'
local InApartment = false
local ClosestHouse = nil
local CurrentApartment = nil
local IsOwned = false
local CurrentDoorBell = 0
local CurrentOffset = 0
local HouseObj = {}
local POIOffsets = nil
local RangDoorbell = nil

-- target variables
local InApartmentTargets = {}

-- polyzone variables
local IsInsideEntranceZone = false
local IsInsideExitZone = false
local IsInsideStashZone = false
local IsInsideOutfitsZone = false
local IsInsideLogoutZone = false

-- ox_inventory compatibility
local ox_inventory = nil
if GetResourceState('ox_inventory') ~= 'missing' then
    ox_inventory = exports.ox_inventory
end 

-- polyzone integration

local function OpenEntranceMenu()
    local headerMenu = {}

    if IsOwned then
        headerMenu[#headerMenu + 1] = {
            header = Lang:t('text.enter'),
            params = {
                event = 'apartments:client:EnterApartment',
                args = {}
            }
        }
    elseif not IsOwned then
        headerMenu[#headerMenu + 1] = {
            header = Lang:t('text.move_here'),
            params = {
                event = 'apartments:client:UpdateApartment',
                args = {}
            }
        }
    end

    headerMenu[#headerMenu + 1] = {
        header = Lang:t('text.ring_doorbell'),
        params = {
            event = 'apartments:client:DoorbellMenu',
            args = {}
        }
    }

    headerMenu[#headerMenu + 1] = {
        header = Lang:t('text.close_menu'),
        txt = '',
        params = {
            event = 'qb-menu:client:closeMenu'
        }
    }

    exports['qb-menu']:openMenu(headerMenu)
end

local function OpenExitMenu()
    local headerMenu = {}

    headerMenu[#headerMenu + 1] = {
        header = Lang:t('text.open_door'),
        params = {
            event = 'apartments:client:OpenDoor',
            args = {}
        }
    }

    headerMenu[#headerMenu + 1] = {
        header = Lang:t('text.leave'),
        params = {
            event = 'apartments:client:LeaveApartment',
            args = {}
        }
    }

    headerMenu[#headerMenu + 1] = {
        header = Lang:t('text.close_menu'),
        txt = '',
        params = {
            event = 'qb-menu:client:closeMenu'
        }
    }

    exports['qb-menu']:openMenu(headerMenu)
end

-- exterior entrance (polyzone)

local function RegisterApartmentEntranceZone(apartmentID, apartmentData)
    local coords = apartmentData.coords['enter']
    local boxName = 'apartmentEntrance_' .. apartmentID
    local boxData = apartmentData.polyzoneBoxData

    if boxData.created then
        return
    end

    local zone = BoxZone:Create(coords, boxData.length, boxData.width, {
        name = boxName,
        heading = 340.0,
        minZ = coords.z - 1.0,
        maxZ = coords.z + 5.0,
        debugPoly = false
    })

    zone:onPlayerInOut(function(isPointInside)
        if isPointInside and not InApartment then
            exports['qb-core']:DrawText(Lang:t('text.options'), 'left')
        else
            exports['qb-core']:HideText()
        end
        IsInsideEntranceZone = isPointInside
    end)

    boxData.created = true
    boxData.zone = zone
end

-- exterior entrance (target)

local function RegisterApartmentEntranceTarget(apartmentID, apartmentData)
    local coords = apartmentData.coords['enter']
    local boxName = 'apartmentEntrance_' .. apartmentID
    local boxData = apartmentData.polyzoneBoxData

    if boxData.created then
        return
    end

    local options = {}
    if apartmentID == ClosestHouse and IsOwned then
        options = {
            {
                type = 'client',
                event = 'apartments:client:EnterApartment',
                icon = 'fas fa-door-open',
                label = Lang:t('text.enter'),
            },
        }
    else
        options = {
            {
                type = 'client',
                event = 'apartments:client:UpdateApartment',
                icon = 'fas fa-hotel',
                label = Lang:t('text.move_here'),
            }
        }
    end
    options[#options + 1] = {
        type = 'client',
        event = 'apartments:client:DoorbellMenu',
        icon = 'fas fa-concierge-bell',
        label = Lang:t('text.ring_doorbell'),
    }

    exports['ox_target']:addBoxZone({
        coords = coords, -- Posições x, y, z
        size = vec3(boxData.length, boxData.width, boxData.maxZ - boxData.minZ), -- Tamanho da caixa
        rotation = boxData.heading, -- Direção
        debug = boxData.debug, -- Para mostrar a caixa no mapa para debug (opcional)
        minZ = boxData.minZ, -- Z mínimo
        maxZ = boxData.maxZ, -- Z máximo
        options = options, -- Opções de interação
        distance = boxData.distance, -- Distância de interação
        name = boxName -- Nome da zona
    })
    

    boxData.created = true
end

-- interior interactable points (polyzone)

local function RegisterInApartmentZone(targetKey, coords, heading, text)
    if not InApartment then
        return
    end

    if InApartmentTargets[targetKey] and InApartmentTargets[targetKey].created then
        return
    end

    Wait(1500)

    local boxName = 'inApartmentTarget_' .. targetKey

    local zone = BoxZone:Create(coords, 1.5, 1.5, {
        name = boxName,
        heading = heading,
        minZ = coords.z - 1.0,
        maxZ = coords.z + 5.0,
        debugPoly = false
    })

    zone:onPlayerInOut(function(isPointInside)
        if isPointInside and text then
            exports['qb-core']:DrawText(text, 'left')
        else
            exports['qb-core']:HideText()
        end

        if targetKey == 'entrancePos' then
            IsInsideExitZone = isPointInside
        end

        if targetKey == 'stashPos' then
            IsInsideStashZone = isPointInside
        end

        if targetKey == 'outfitsPos' then
            IsInsideOutfitsZone = isPointInside
        end

        if targetKey == 'logoutPos' then
            IsInsideLogoutZone = isPointInside
        end
    end)

    InApartmentTargets[targetKey] = InApartmentTargets[targetKey] or {}
    InApartmentTargets[targetKey].created = true
    InApartmentTargets[targetKey].zone = zone
end

-- interior interactable points (target)

-- First, ensure we're properly storing targets when creating them
local function RegisterInApartmentTarget(id, coords, heading, options)
    if UseTarget then
        local targetId = 'inApartmentTarget_' .. id
        InApartmentTargets[id] = {
            id = targetId,
            type = 'target'
        }
        exports['ox_target']:addBoxZone(targetId, coords, 1.5, 1.5, {
            name = targetId,
            heading = heading,
            debugPoly = false,
            minZ = coords.z - 1.0,
            maxZ = coords.z + 1.0
        }, options)
    else
        -- For non-target version
        InApartmentTargets[id] = {
            type = 'zone',
            zone = lib.zones.box({
                coords = coords,
                size = vec3(2, 2, 2),
                rotation = heading,
                debug = false,
                onEnter = function()
                    -- Your zone enter logic
                end,
                onExit = function()
                    -- Your zone exit logic
                end
            })
        }
    end
end

-- shared

local function SetApartmentsEntranceTargets()
    if Apartments.Locations and next(Apartments.Locations) then
        for id, apartment in pairs(Apartments.Locations) do
            if apartment and apartment.coords and apartment.coords['enter'] then
                if UseTarget then
                    RegisterApartmentEntranceTarget(id, apartment)
                else
                    RegisterApartmentEntranceZone(id, apartment)
                end
            end
        end
    end
end

local InApartmentTargets = {} -- Make sure this is declared at the file scope (outside any function)

local function SetInApartmentTargets()
    -- If we're not in an apartment, don't do anything
    if not InApartment then
        return
    end
    
    if not POIOffsets then
        return
    end

    -- If we already have targets set up, don't create them again
    if InApartmentTargets and next(InApartmentTargets) then
        return
    end

    local entrancePos = vector3(Apartments.Locations[ClosestHouse].coords.enter.x + POIOffsets.exit.x, Apartments.Locations[ClosestHouse].coords.enter.y + POIOffsets.exit.y, Apartments.Locations[ClosestHouse].coords.enter.z - CurrentOffset + POIOffsets.exit.z)
    local stashPos = vector3(Apartments.Locations[ClosestHouse].coords.enter.x - POIOffsets.stash.x, Apartments.Locations[ClosestHouse].coords.enter.y - POIOffsets.stash.y, Apartments.Locations[ClosestHouse].coords.enter.z - CurrentOffset + POIOffsets.stash.z)
    local outfitsPos = vector3(Apartments.Locations[ClosestHouse].coords.enter.x - POIOffsets.clothes.x, Apartments.Locations[ClosestHouse].coords.enter.y - POIOffsets.clothes.y, Apartments.Locations[ClosestHouse].coords.enter.z - CurrentOffset + POIOffsets.clothes.z)
    local logoutPos = vector3(Apartments.Locations[ClosestHouse].coords.enter.x - POIOffsets.logout.x, Apartments.Locations[ClosestHouse].coords.enter.y + POIOffsets.logout.y, Apartments.Locations[ClosestHouse].coords.enter.z - CurrentOffset + POIOffsets.logout.z)

    if UseTarget then
        -- Store the target reference when creating it
        InApartmentTargets['entrancePos'] = exports['ox_target']:addBoxZone({
            coords = entrancePos,
            size = vec3(1.5, 1.5, 1.5),
            rotation = 0,
            debug = false,
            options = {
                {
                    type = 'client',
                    event = 'apartments:client:OpenDoor',
                    icon = 'fas fa-door-open',
                    label = Lang:t('text.open_door'),
                },
                {
                    type = 'client',
                    event = 'apartments:client:LeaveApartment',
                    icon = 'fas fa-door-open',
                    label = Lang:t('text.leave'),
                },
            }
        })

        InApartmentTargets['stashPos'] = exports['ox_target']:addBoxZone({
            coords = stashPos,
            size = vec3(1.5, 1.5, 1.5),
            rotation = 0,
            debug = false,
            options = {
                {
                    type = 'client',
                    event = 'apartments:client:OpenStash',
                    icon = 'fas fa-box-open',
                    label = Lang:t('text.open_stash'),
                }
            }
        })

        InApartmentTargets['outfitsPos'] = exports['ox_target']:addBoxZone({
            coords = outfitsPos,
            size = vec3(1.5, 1.5, 1.5),
            rotation = 0,
            debug = false,
            options = {
                {
                    type = 'client',
                    event = 'apartments:client:ChangeOutfit',
                    icon = 'fas fa-tshirt',
                    label = Lang:t('text.change_outfit'),
                }
            }
        })

        InApartmentTargets['logoutPos'] = exports['ox_target']:addBoxZone({
            coords = logoutPos,
            size = vec3(1.5, 1.5, 1.5),
            rotation = 0,
            debug = false,
            options = {
                {
                    type = 'client',
                    event = 'apartments:client:Logout',
                    icon = 'fas fa-sign-out-alt',
                    label = Lang:t('text.logout'),
                }
            }
        })
    else
        -- For non-target version
        InApartmentTargets['stashPos'] = lib.zones.box({
            coords = stashPos,
            size = vec3(2, 2, 2),
            rotation = 0,
            debug = false,
            text = '[E] ' .. Lang:t('text.open_stash')
        })

        InApartmentTargets['outfitsPos'] = lib.zones.box({
            coords = outfitsPos,
            size = vec3(2, 2, 2),
            rotation = 0,
            debug = false,
            text = '[E] ' .. Lang:t('text.change_outfit')
        })

        InApartmentTargets['logoutPos'] = lib.zones.box({
            coords = logoutPos,
            size = vec3(2, 2, 2),
            rotation = 0,
            debug = false,
            text = '[E] ' .. Lang:t('text.logout')
        })

        InApartmentTargets['entrancePos'] = lib.zones.box({
            coords = entrancePos,
            size = vec3(2, 2, 2),
            rotation = 0,
            debug = false,
            text = Lang:t('text.options')
        })
    end
end



local function DeleteApartmentsEntranceTargets()
    if Apartments.Locations and next(Apartments.Locations) then
        for id, apartment in pairs(Apartments.Locations) do
            if UseTarget then
                exports['ox_target']:removeZone('apartmentEntrance_' .. id)
            else
                if apartment.polyzoneBoxData.zone then
                    apartment.polyzoneBoxData.zone:destroy()
                    apartment.polyzoneBoxData.zone = nil
                end
            end
            apartment.polyzoneBoxData.created = false
        end
    end
end

local function DeleteInApartmentTargets()
    IsInsideExitZone = false
    IsInsideStashZone = false
    IsInsideOutfitsZone = false
    IsInsideLogoutZone = false

    if InApartmentTargets and next(InApartmentTargets) then
        for id, target in pairs(InApartmentTargets) do
            if UseTarget then
                exports['ox_target']:removeZone(target) -- Remove the target using the stored reference
            else
                target:remove() -- Remove the zone
            end
        end
    end
    InApartmentTargets = {} -- Clear the table
end


-- utility functions

local function loadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Wait(5)
    end
end

local function openHouseAnim()
    loadAnimDict('anim@heists@keycard@')
    TaskPlayAnim(PlayerPedId(), 'anim@heists@keycard@', 'exit', 5.0, 1.0, -1, 16, 0, 0, 0, 0)
    Wait(400)
    ClearPedTasks(PlayerPedId())
end

local function EnterApartment(house, apartmentId, new)
    TriggerServerEvent('InteractSound_SV:PlayOnSource', 'houses_door_open', 0.1)
    openHouseAnim()
    Wait(250)
    QBCore.Functions.TriggerCallback('apartments:GetApartmentOffset', function(offset)
        if offset == nil or offset == 0 then
            QBCore.Functions.TriggerCallback('apartments:GetApartmentOffsetNewOffset', function(newoffset)
                if newoffset > 230 then
                    newoffset = 210
                end
                CurrentOffset = newoffset
                TriggerServerEvent('apartments:server:AddObject', apartmentId, house, CurrentOffset)
                local coords = { x = Apartments.Locations[house].coords.enter.x, y = Apartments.Locations[house].coords.enter.y, z = Apartments.Locations[house].coords.enter.z - CurrentOffset }
                local data = exports['qb-interior']:CreateApartmentFurnished(coords)
                Wait(100)
                HouseObj = data[1]
                POIOffsets = data[2]
                InApartment = true
                CurrentApartment = apartmentId
                ClosestHouse = house
                RangDoorbell = nil
                Wait(500)
                TriggerEvent('qb-weathersync:client:EnableSync')
                Wait(100)
                TriggerServerEvent('qb-apartments:server:SetInsideMeta', house, apartmentId, true, false)
                TriggerServerEvent('InteractSound_SV:PlayOnSource', 'houses_door_close', 0.1)
                TriggerServerEvent('apartments:server:setCurrentApartment', CurrentApartment)
            end, house)
        else
            if offset > 230 then
                offset = 210
            end
            CurrentOffset = offset
            TriggerServerEvent('InteractSound_SV:PlayOnSource', 'houses_door_open', 0.1)
            TriggerServerEvent('apartments:server:AddObject', apartmentId, house, CurrentOffset)
            local coords = { x = Apartments.Locations[ClosestHouse].coords.enter.x, y = Apartments.Locations[ClosestHouse].coords.enter.y, z = Apartments.Locations[ClosestHouse].coords.enter.z - CurrentOffset }
            local data = exports['qb-interior']:CreateApartmentFurnished(coords)
            Wait(100)
            HouseObj = data[1]
            POIOffsets = data[2]
            InApartment = true
            CurrentApartment = apartmentId
            Wait(500)
            TriggerEvent('qb-weathersync:client:DisableSync')
            Wait(100)
            TriggerServerEvent('qb-apartments:server:SetInsideMeta', house, apartmentId, true, true)
            TriggerServerEvent('InteractSound_SV:PlayOnSource', 'houses_door_close', 0.1)
            TriggerServerEvent('apartments:server:setCurrentApartment', CurrentApartment)
        end

        if new ~= nil then
            if new then
                TriggerEvent('qb-interior:client:SetNewState', true)
            else
                TriggerEvent('qb-interior:client:SetNewState', false)
            end
        else
            TriggerEvent('qb-interior:client:SetNewState', false)
        end
    end, apartmentId)
end

local function LeaveApartment(house)
    TriggerServerEvent('InteractSound_SV:PlayOnSource', 'houses_door_open', 0.1)
    openHouseAnim()
    TriggerServerEvent('qb-apartments:returnBucket')
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(10) end
    exports['qb-interior']:DespawnInterior(HouseObj, function()
        TriggerEvent('qb-weathersync:client:EnableSync')
        SetEntityCoords(PlayerPedId(), Apartments.Locations[house].coords.enter.x, Apartments.Locations[house].coords.enter.y, Apartments.Locations[house].coords.enter.z)
        SetEntityHeading(PlayerPedId(), Apartments.Locations[house].coords.enter.w)
        Wait(1000)
        TriggerServerEvent('apartments:server:RemoveObject', CurrentApartment, house)
        TriggerServerEvent('qb-apartments:server:SetInsideMeta', CurrentApartment, false)
        CurrentApartment = nil
        InApartment = false
        CurrentOffset = 0
        DoScreenFadeIn(1000)
        TriggerServerEvent('InteractSound_SV:PlayOnSource', 'houses_door_close', 0.1)
        TriggerServerEvent('apartments:server:setCurrentApartment', nil)

        DeleteInApartmentTargets()
        DeleteApartmentsEntranceTargets()
    end)
end

local function SetClosestApartment()
    local pos = GetEntityCoords(PlayerPedId())
    local current = nil
    local dist = 100
    for id, _ in pairs(Apartments.Locations) do
        local distcheck = #(pos - vector3(Apartments.Locations[id].coords.enter.x, Apartments.Locations[id].coords.enter.y, Apartments.Locations[id].coords.enter.z))
        if distcheck < dist then
            current = id
        end
    end
    if current ~= ClosestHouse and LocalPlayer.state.isLoggedIn and not InApartment then
        ClosestHouse = current
        QBCore.Functions.TriggerCallback('apartments:IsOwner', function(result)
            IsOwned = result
            DeleteApartmentsEntranceTargets()
            -- Remove this line: DeleteInApartmentTargets()
        end, ClosestHouse)
    end
end


function MenuOwners()
    QBCore.Functions.TriggerCallback('apartments:GetAvailableApartments', function(apartments)
        if next(apartments) == nil then
            QBCore.Functions.Notify(Lang:t('error.nobody_home'), 'error', 3500)
            CloseMenuFull()
        else
            local apartmentMenu = {
                {
                    header = Lang:t('text.tennants'),
                    isMenuHeader = true
                }
            }

            for k, v in pairs(apartments) do
                apartmentMenu[#apartmentMenu + 1] = {
                    header = v,
                    txt = '',
                    params = {
                        event = 'apartments:client:RingMenu',
                        args = {
                            apartmentId = k
                        }
                    }

                }
            end

            apartmentMenu[#apartmentMenu + 1] = {
                header = Lang:t('text.close_menu'),
                txt = '',
                params = {
                    event = 'qb-menu:client:closeMenu'
                }

            }
            exports['qb-menu']:openMenu(apartmentMenu)
        end
    end, ClosestHouse)
end

function CloseMenuFull()
    exports['qb-menu']:closeMenu()
end

-- Event Handlers

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if HouseObj ~= nil then
            exports['qb-interior']:DespawnInterior(HouseObj, function()
                CurrentApartment = nil
                TriggerEvent('qb-weathersync:client:EnableSync')
                DoScreenFadeIn(500)
                while not IsScreenFadedOut() do
                    Wait(10)
                end
                SetEntityCoords(PlayerPedId(), Apartments.Locations[ClosestHouse].coords.enter.x, Apartments.Locations[ClosestHouse].coords.enter.y, Apartments.Locations[ClosestHouse].coords.enter.z)
                SetEntityHeading(PlayerPedId(), Apartments.Locations[ClosestHouse].coords.enter.w)
                Wait(1000)
                InApartment = false
                DoScreenFadeIn(1000)
            end)
        end

        DeleteApartmentsEntranceTargets()
        DeleteInApartmentTargets()
    end
end)


-- Events

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    CurrentApartment = nil
    InApartment = false
    CurrentOffset = 0

    DeleteApartmentsEntranceTargets()
    DeleteInApartmentTargets()
end)

RegisterNetEvent('apartments:client:setupSpawnUI', function(cData)
    QBCore.Functions.TriggerCallback('apartments:GetOwnedApartment', function(result)
        if result then
            TriggerEvent('qb-spawn:client:setupSpawns', cData, false, nil)
            TriggerEvent('qb-spawn:client:openUI', true)
            TriggerEvent('apartments:client:SetHomeBlip', result.type)
        else
            if Apartments.Starting then
                TriggerEvent('qb-spawn:client:setupSpawns', cData, true, Apartments.Locations)
                TriggerEvent('qb-spawn:client:openUI', true)
            else
                TriggerEvent('qb-spawn:client:setupSpawns', cData, false, nil)
                TriggerEvent('qb-spawn:client:openUI', true)
                TriggerEvent('apartments:client:SetHomeBlip', nil)
            end
        end
    end, cData.citizenid)
end)

RegisterNetEvent('apartments:client:SpawnInApartment', function(apartmentId, apartment)
    local pos = GetEntityCoords(PlayerPedId())
    if RangDoorbell ~= nil then
        local doorbelldist = #(pos - vector3(Apartments.Locations[RangDoorbell].coords.enter.x, Apartments.Locations[RangDoorbell].coords.enter.y, Apartments.Locations[RangDoorbell].coords.enter.z))
        if doorbelldist > 5 then
            QBCore.Functions.Notify(Lang:t('error.to_far_from_door'))
            return
        end
    end
    ClosestHouse = apartment
    EnterApartment(apartment, apartmentId, true)
    IsOwned = true
end)

RegisterNetEvent('qb-apartments:client:LastLocationHouse', function(apartmentType, apartmentId)
    ClosestHouse = apartmentType
    EnterApartment(apartmentType, apartmentId, false)
end)

RegisterNetEvent('apartments:client:SetHomeBlip', function(home)
    CreateThread(function()
        SetClosestApartment()
        for name, _ in pairs(Apartments.Locations) do
            RemoveBlip(Apartments.Locations[name].blip)

            Apartments.Locations[name].blip = AddBlipForCoord(Apartments.Locations[name].coords.enter.x, Apartments.Locations[name].coords.enter.y, Apartments.Locations[name].coords.enter.z)
            if (name == home) then
                SetBlipSprite(Apartments.Locations[name].blip, 475)
                SetBlipCategory(Apartments.Locations[name].blip, 11)
            else
                SetBlipSprite(Apartments.Locations[name].blip, 476)
                SetBlipCategory(Apartments.Locations[name].blip, 10)
            end
            SetBlipDisplay(Apartments.Locations[name].blip, 4)
            SetBlipScale(Apartments.Locations[name].blip, 0.65)
            SetBlipAsShortRange(Apartments.Locations[name].blip, true)
            SetBlipColour(Apartments.Locations[name].blip, 3)
            AddTextEntry(Apartments.Locations[name].label, Apartments.Locations[name].label)
            BeginTextCommandSetBlipName(Apartments.Locations[name].label)
            EndTextCommandSetBlipName(Apartments.Locations[name].blip)
        end
    end)
end)

RegisterNetEvent('apartments:client:RingMenu', function(data)
    RangDoorbell = ClosestHouse
    TriggerServerEvent('InteractSound_SV:PlayOnSource', 'doorbell', 0.1)
    TriggerServerEvent('apartments:server:RingDoor', data.apartmentId, ClosestHouse)
end)

RegisterNetEvent('apartments:client:RingDoor', function(player, _)
    CurrentDoorBell = player
    TriggerServerEvent('InteractSound_SV:PlayOnSource', 'doorbell', 0.1)
    QBCore.Functions.Notify(Lang:t('info.at_the_door'))
end)

RegisterNetEvent('apartments:client:DoorbellMenu', function()
    MenuOwners()
end)

RegisterNetEvent('apartments:client:EnterApartment', function()
    QBCore.Functions.TriggerCallback('apartments:GetOwnedApartment', function(result)
        if result ~= nil then
            EnterApartment(ClosestHouse, result.name)
        end
    end)
end)

RegisterNetEvent('apartments:client:UpdateApartment', function()
    local apartmentType = ClosestHouse
    local apartmentLabel = Apartments.Locations[ClosestHouse].label
    QBCore.Functions.TriggerCallback('apartments:GetOwnedApartment', function(result)
        if result == nil then
            TriggerServerEvent("apartments:server:CreateApartment", apartmentType, apartmentLabel, false)
        else
            TriggerServerEvent('apartments:server:UpdateApartment', apartmentType, apartmentLabel)
        end
    end)

    IsOwned = true

    DeleteApartmentsEntranceTargets()
    DeleteInApartmentTargets()
end)

RegisterNetEvent('apartments:client:OpenDoor', function()
    if CurrentDoorBell == 0 then
        QBCore.Functions.Notify(Lang:t('error.nobody_at_door'))
        return
    end
    TriggerServerEvent('apartments:server:OpenDoor', CurrentDoorBell, CurrentApartment, ClosestHouse)
    CurrentDoorBell = 0
end)

RegisterNetEvent('apartments:client:LeaveApartment', function()
    LeaveApartment(ClosestHouse)
end)

RegisterNetEvent('apartments:client:OpenStash', function()
    if CurrentApartment ~= nil then
        TriggerServerEvent("InteractSound_SV:PlayOnSource", "StashOpen", 0.4)
        if not ox_inventory then
            TriggerServerEvent("inventory:server:OpenInventory", "stash", CurrentApartment)
            TriggerEvent("inventory:client:SetCurrentStash", CurrentApartment)
        else
            if not ox_inventory:openInventory('stash', CurrentApartment) then
                TriggerServerEvent('qb-apartments:server:RegisterStash', CurrentApartment, Apartments.Locations[ClosestHouse].label)
                ox_inventory:openInventory('stash', CurrentApartment)
            end
        end
    end
end)

RegisterNetEvent('apartments:client:ChangeOutfit', function()
    TriggerServerEvent('InteractSound_SV:PlayOnSource', 'Clothes1', 0.4)
    TriggerEvent('qb-clothing:client:openOutfitMenu')
end)

RegisterNetEvent('apartments:client:Logout', function()
    TriggerServerEvent('vms_multichars:relog')
end)


-- Threads

if UseTarget then
    CreateThread(function()
        local sleep = 5000
        while not LocalPlayer.state.isLoggedIn do
            -- do nothing
            Wait(sleep)
        end

        while true do
            sleep = 1000

            if not InApartment then
                SetClosestApartment()
                SetApartmentsEntranceTargets()
            elseif InApartment then
                SetInApartmentTargets()
            end
            Wait(sleep)
        end
    end)
else
    CreateThread(function()
        local sleep = 5000
        while not LocalPlayer.state.isLoggedIn do
            -- do nothing
            Wait(sleep)
        end

        while true do
            sleep = 1000

            if not InApartment then
                SetClosestApartment()
                SetApartmentsEntranceTargets()

                if IsInsideEntranceZone then
                    sleep = 0
                    if IsControlJustPressed(0, 38) then
                        OpenEntranceMenu()
                        exports['qb-core']:HideText()
                    end
                end
            elseif InApartment then
                sleep = 0

                SetInApartmentTargets()

                if IsInsideExitZone then
                    if IsControlJustPressed(0, 38) then
                        OpenExitMenu()
                        exports['qb-core']:HideText()
                    end
                end

                if IsInsideStashZone then
                    if IsControlJustPressed(0, 38) then
                        TriggerEvent('apartments:client:OpenStash')
                        exports['qb-core']:HideText()
                    end
                end

                if IsInsideOutfitsZone then
                    if IsControlJustPressed(0, 38) then
                        TriggerEvent('apartments:client:ChangeOutfit')
                        exports['qb-core']:HideText()
                    end
                end

                if IsInsideLogoutZone then
                    if IsControlJustPressed(0, 38) then
                        TriggerEvent('apartments:client:Logout')
                        exports['qb-core']:HideText()
                    end
                end
            end

            Wait(sleep)
        end
    end)
end
