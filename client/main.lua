local QBCore = exports['qb-core']:GetCoreObject()
local InApartment = false
local InApartmentTargets = {}
local ClosestHouse = nil
local CurrentApartment = nil
local IsOwned = false
local CurrentDoorBell = 0
local CurrentOffset = 0
local houseObj = {}
local POIOffsets = nil
local rangDoorbell = nil


-- Functions

local function RegisterInApartmentTarget(targetKey, coords, heading, options)
    if not InApartment then
        return
    end

    if InApartmentTargets[targetKey] and InApartmentTargets[targetKey].created then
        return
    end

    local boxName = 'inApartmentTarget_' .. targetKey
    exports['qb-target']:AddBoxZone(boxName, coords, 1, 1, {
        name = boxName,
        heading = heading,
        debugPoly = false,
    }, {
        options = options,
        distance = 1
    })

    InApartmentTargets[targetKey] = InApartmentTargets[targetKey] or {}
    InApartmentTargets[targetKey].created = true
end

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
                type = "client",
                event = "apartments:client:EnterApartment",
                label = Lang:t("text.enter"),
            },
        }
    else
        options = {
            {
                type = "client",
                event = "apartments:client:UpdateApartment",
                label = Lang:t('text.move_here'),
            }
        }
    end
    table.insert(options, {
        type = "client",
        event = "apartments:client:DoorbellMenu",
        label = Lang:t('text.ring_doorbell'),
    })

    exports['qb-target']:AddBoxZone(boxName, coords, boxData.length, boxData.width, {
        name = boxName,
        heading = boxData.heading,
        debugPoly = boxData.debug,
        minZ = boxData.minZ,
        maxZ = boxData.maxZ,
    }, {
        options = options,
        distance = boxData.distance
    })

    boxData.created = true
end

local function SetApartmentsEntranceTargets()
    if Apartments.Locations and next(Apartments.Locations) then
        for id, apartment in pairs(Apartments.Locations) do
            if apartment and apartment.coords and apartment.coords['enter'] then
                RegisterApartmentEntranceTarget(id, apartment)
            else
                print('apartment ' .. id .. ' does not have entrance coords')
            end
        end
    else
        print('no apartments configured')
    end
end

local function DeleteApartmentsEntranceTargets()
    if Apartments.Locations and next(Apartments.Locations) then
        for id, apartment in pairs(Apartments.Locations) do
            exports['qb-target']:RemoveZone('apartmentEntrance_' .. id)
            apartment.polyzoneBoxData.created = false
        end
    end
end

local function DeleteInAparmtnetTargets()
    if InApartmentTargets and next(InApartmentTargets) then
        for id, _ in pairs(InApartmentTargets) do
            exports['qb-target']:RemoveZone('inApartmentTarget_' .. id)
        end
    end
    InApartmentTargets = {}
end

local function loadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Wait(5)
    end
end

local function openHouseAnim()
    loadAnimDict("anim@heists@keycard@")
    TaskPlayAnim( PlayerPedId(), "anim@heists@keycard@", "exit", 5.0, 1.0, -1, 16, 0, 0, 0, 0 )
    Wait(400)
    ClearPedTasks(PlayerPedId())
end

local function EnterApartment(house, apartmentId, new)
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "houses_door_open", 0.1)
    openHouseAnim()
    Wait(250)
    QBCore.Functions.TriggerCallback('apartments:GetApartmentOffset', function(offset)
        if offset == nil or offset == 0 then
            QBCore.Functions.TriggerCallback('apartments:GetApartmentOffsetNewOffset', function(newoffset)
                if newoffset > 230 then
                    newoffset = 210
                end
                CurrentOffset = newoffset
                TriggerServerEvent("apartments:server:AddObject", apartmentId, house, CurrentOffset)
                local coords = { x = Apartments.Locations[house].coords.enter.x, y = Apartments.Locations[house].coords.enter.y, z = Apartments.Locations[house].coords.enter.z - CurrentOffset}
                data = exports['qb-interior']:CreateApartmentFurnished(coords)
                Wait(100)
                houseObj = data[1]
                POIOffsets = data[2]
                InApartment = true
                CurrentApartment = apartmentId
                ClosestHouse = house
                rangDoorbell = nil
                Wait(500)
                TriggerEvent('qb-weathersync:client:DisableSync')
                Wait(100)
                TriggerServerEvent('qb-apartments:server:SetInsideMeta', house, apartmentId, true, false)
                TriggerServerEvent("InteractSound_SV:PlayOnSource", "houses_door_close", 0.1)
                TriggerServerEvent("QBCore:Server:SetMetaData", "currentapartment", CurrentApartment)
            end, house)
        else
            if offset > 230 then
                offset = 210
            end
            CurrentOffset = offset
            TriggerServerEvent("InteractSound_SV:PlayOnSource", "houses_door_open", 0.1)
            TriggerServerEvent("apartments:server:AddObject", apartmentId, house, CurrentOffset)
            local coords = { x = Apartments.Locations[ClosestHouse].coords.enter.x, y = Apartments.Locations[ClosestHouse].coords.enter.y, z = Apartments.Locations[ClosestHouse].coords.enter.z - CurrentOffset}
            data = exports['qb-interior']:CreateApartmentFurnished(coords)
            Wait(100)
            houseObj = data[1]
            POIOffsets = data[2]
            InApartment = true
            CurrentApartment = apartmentId
            Wait(500)
            TriggerEvent('qb-weathersync:client:DisableSync')
            Wait(100)
            TriggerServerEvent('qb-apartments:server:SetInsideMeta', house, apartmentId, true, true)
            TriggerServerEvent("InteractSound_SV:PlayOnSource", "houses_door_close", 0.1)
            TriggerServerEvent("QBCore:Server:SetMetaData", "currentapartment", CurrentApartment)
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
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "houses_door_open", 0.1)
    openHouseAnim()
    TriggerServerEvent("qb-apartments:returnBucket")
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(10) end
    exports['qb-interior']:DespawnInterior(houseObj, function()
        TriggerEvent('qb-weathersync:client:EnableSync')
        SetEntityCoords(PlayerPedId(), Apartments.Locations[house].coords.enter.x, Apartments.Locations[house].coords.enter.y,Apartments.Locations[house].coords.enter.z)
        SetEntityHeading(PlayerPedId(), Apartments.Locations[house].coords.enter.w)
        Wait(1000)
        TriggerServerEvent("apartments:server:RemoveObject", CurrentApartment, house)
        TriggerServerEvent('qb-apartments:server:SetInsideMeta', CurrentApartment, false)
        CurrentApartment = nil
        InApartment = false
        CurrentOffset = 0
        DoScreenFadeIn(1000)
        TriggerServerEvent("InteractSound_SV:PlayOnSource", "houses_door_close", 0.1)
        TriggerServerEvent("QBCore:Server:SetMetaData", "currentapartment", nil)
    end)

    if Apartments.UseTarget then
        DeleteInAparmtnetTargets()
    end
end

local function SetClosestApartment()
    local pos = GetEntityCoords(PlayerPedId())
    local current = nil
    local dist = 100
    for id, house in pairs(Apartments.Locations) do
        local distcheck = #(pos - vector3(Apartments.Locations[id].coords.enter.x, Apartments.Locations[id].coords.enter.y, Apartments.Locations[id].coords.enter.z))
            if distcheck < dist then
                current = id
            end

    end
    if current ~= ClosestHouse and LocalPlayer.state.isLoggedIn and not InApartment then
        ClosestHouse = current
        QBCore.Functions.TriggerCallback('apartments:IsOwner', function(result)
            IsOwned = result
            if Apartments.UseTarget then
                DeleteApartmentsEntranceTargets()
            end
        end, ClosestHouse)
    end
end

function MenuOwners()
    QBCore.Functions.TriggerCallback('apartments:GetAvailableApartments', function(apartments)
        if next(apartments) == nil then
            QBCore.Functions.Notify(Lang:t('error.nobody_home'), "error", 3500)
            closeMenuFull()
        else
            local vehicleMenu = {
                {
                    header = Lang:t('text.tennants'),
                    isMenuHeader = true
                }
            }

            for k, v in pairs(apartments) do
                vehicleMenu[#vehicleMenu+1] = {
                    header = v,
                    txt = "",
                    params = {
                        event = "apartments:client:RingMenu",
                        args = {
                            apartmentId = k
                        }
                    }

                }
            end

            vehicleMenu[#vehicleMenu+1] = {
                header = Lang:t('text.close_menu'),
                txt = "",
                params = {
                    event = "qb-menu:client:closeMenu"
                }

            }
            exports['qb-menu']:openMenu(vehicleMenu)
        end
    end, ClosestHouse)
end

function closeMenuFull()
    exports['qb-menu']:closeMenu()
end

-- Handlers

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if houseObj ~= nil then
            exports['qb-interior']:DespawnInterior(houseObj, function()
                CurrentApartment = nil
                TriggerEvent('qb-weathersync:client:EnableSync')
                DoScreenFadeIn(500)
                while not IsScreenFadedOut() do
                    Wait(10)
                end
                SetEntityCoords(PlayerPedId(), Apartments.Locations[ClosestHouse].coords.enter.x, Apartments.Locations[ClosestHouse].coords.enter.y,Apartments.Locations[ClosestHouse].coords.enter.z)
                SetEntityHeading(PlayerPedId(), Apartments.Locations[ClosestHouse].coords.enter.w)
                Wait(1000)
                InApartment = false
                DoScreenFadeIn(1000)
            end)
        end

        if Apartments.UseTarget then
            DeleteApartmentsEntranceTargets()
            DeleteInAparmtnetTargets()
        end
    end
end)

-- Events

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    CurrentApartment = nil
    InApartment = false
    CurrentOffset = 0

    if Apartments.UseTarget then
        DeleteApartmentsEntranceTargets()
        DeleteInAparmtnetTargets()
    end
end)

RegisterNetEvent('apartments:client:setupSpawnUI', function(cData)
    QBCore.Functions.TriggerCallback('apartments:GetOwnedApartment', function(result)
        if result then
            TriggerEvent('qb-spawn:client:setupSpawns', cData, false, nil)
            TriggerEvent('qb-spawn:client:openUI', true)
            TriggerEvent("apartments:client:SetHomeBlip", result.type)
        else
            if Apartments.Starting then
                TriggerEvent('qb-spawn:client:setupSpawns', cData, true, Apartments.Locations)
                TriggerEvent('qb-spawn:client:openUI', true)
            else
                TriggerEvent('qb-spawn:client:setupSpawns', cData, false, nil)
                TriggerEvent('qb-spawn:client:openUI', true)
            end
        end
    end, cData.citizenid)
end)

RegisterNetEvent('apartments:client:SpawnInApartment', function(apartmentId, apartment)
    local pos = GetEntityCoords(PlayerPedId())
    if rangDoorbell ~= nil then
        local doorbelldist = #(pos - vector3(Apartments.Locations[rangDoorbell].coords.enter.x, Apartments.Locations[rangDoorbell].coords.enter.y,Apartments.Locations[rangDoorbell].coords.enter.z))
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
        for name, apartment in pairs(Apartments.Locations) do
            RemoveBlip(Apartments.Locations[name].blip)

            Apartments.Locations[name].blip = AddBlipForCoord(Apartments.Locations[name].coords.enter.x, Apartments.Locations[name].coords.enter.y, Apartments.Locations[name].coords.enter.z)
            if (name == home) then
                SetBlipSprite(Apartments.Locations[name].blip, 475)
            else
                SetBlipSprite(Apartments.Locations[name].blip, 476)
            end
            SetBlipDisplay(Apartments.Locations[name].blip, 4)
            SetBlipScale(Apartments.Locations[name].blip, 0.65)
            SetBlipAsShortRange(Apartments.Locations[name].blip, true)
            SetBlipColour(Apartments.Locations[name].blip, 3)

            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(Apartments.Locations[name].label)
            EndTextCommandSetBlipName(Apartments.Locations[name].blip)
        end
    end)
end)

RegisterNetEvent('apartments:client:RingMenu', function(data)
    rangDoorbell = ClosestHouse
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "doorbell", 0.1)
    TriggerServerEvent("apartments:server:RingDoor", data.apartmentId, ClosestHouse)
end)

RegisterNetEvent('apartments:client:RingDoor', function(player, house)
    CurrentDoorBell = player
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "doorbell", 0.1)
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
    TriggerServerEvent("apartments:server:UpdateApartment", apartmentType, apartmentLabel)
    IsOwned = true
    if Apartments.UseTarget then
        DeleteApartmentsEntranceTargets()
    end
end)

RegisterNetEvent('apartments:client:OpenDoor', function()
    if CurrentDoorBell == 0 then
        QBCore.Functions.Notify(Lang:t('error.nobody_at_door'))
        return
    end
    TriggerServerEvent("apartments:server:OpenDoor", CurrentDoorBell, CurrentApartment, ClosestHouse)
    CurrentDoorBell = 0
end)

RegisterNetEvent('apartments:client:LeaveApartment', function()
    LeaveApartment(ClosestHouse)
end)

RegisterNetEvent('apartments:client:OpenStash', function()
    if CurrentApartment ~= nil then
        TriggerServerEvent("inventory:server:OpenInventory", "stash", CurrentApartment)
        TriggerServerEvent("InteractSound_SV:PlayOnSource", "StashOpen", 0.4)
        TriggerEvent("inventory:client:SetCurrentStash", CurrentApartment)
    end
end)

RegisterNetEvent('apartments:client:ChangeOutfit', function()
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "Clothes1", 0.4)
    TriggerEvent('qb-clothing:client:openOutfitMenu')
end)

RegisterNetEvent('apartments:client:Logout', function()
    TriggerServerEvent('qb-houses:server:LogoutLocation')
end)

-- Threads

CreateThread(function()
    while true do
        if LocalPlayer.state.isLoggedIn and not InApartment then
            SetClosestApartment()
        end
        Wait(5000)
    end
end)

CreateThread(function()
    local shownHeader = false

    while true do
        local sleep = 1000

        if Apartments.UseTarget then
            SetApartmentsEntranceTargets()
        end

        if LocalPlayer.state.isLoggedIn and ClosestHouse then
            sleep = 5
            if InApartment then
                local headerMenu = {}
                local inRange = false
                local pos = GetEntityCoords(PlayerPedId())
                local entrancePos = vector3(Apartments.Locations[ClosestHouse].coords.enter.x - POIOffsets.exit.x, Apartments.Locations[ClosestHouse].coords.enter.y - POIOffsets.exit.y - 0.5, Apartments.Locations[ClosestHouse].coords.enter.z - CurrentOffset + POIOffsets.exit.z)
                local stashPos = vector3(Apartments.Locations[ClosestHouse].coords.enter.x - POIOffsets.stash.x, Apartments.Locations[ClosestHouse].coords.enter.y - POIOffsets.stash.y, Apartments.Locations[ClosestHouse].coords.enter.z - CurrentOffset + POIOffsets.stash.z)
                local outfitsPos = vector3(Apartments.Locations[ClosestHouse].coords.enter.x - POIOffsets.clothes.x, Apartments.Locations[ClosestHouse].coords.enter.y - POIOffsets.clothes.y, Apartments.Locations[ClosestHouse].coords.enter.z - CurrentOffset + POIOffsets.clothes.z)
                local logoutPos = vector3(Apartments.Locations[ClosestHouse].coords.enter.x - POIOffsets.logout.x, Apartments.Locations[ClosestHouse].coords.enter.y + POIOffsets.logout.y, Apartments.Locations[ClosestHouse].coords.enter.z - CurrentOffset + POIOffsets.logout.z)
                      
                if not Apartments.UseTarget then
                    local entrancedist = #(pos - entrancePos)
                    local stashdist = #(pos - stashPos)
                    local outfitsdist = #(pos - outfitsPos)
                    local logoutdist = #(pos - logoutPos)

                    -- Enter
                    if CurrentDoorBell ~= 0 then
                        if entrancedist <= 1 then
                            inRange = true
                            headerMenu[#headerMenu+1] = {
                                header = Lang:t('text.open_door'),
                                params = {
                                    event = 'apartments:client:OpenDoor',
                                    args = {}
                                }
                            }
                        end
                    end

                    --Exit
                    if entrancedist <= 1 then
                        inRange = true
                        headerMenu[#headerMenu+1] = {
                            header = Lang:t('text.leave'),
                            params = {
                                event = 'apartments:client:LeaveApartment',
                                args = {}
                            }
                        }
                    elseif entrancedist <= 3 then
                        local x = Apartments.Locations[ClosestHouse].coords.enter.x - POIOffsets.exit.x
                        local y = Apartments.Locations[ClosestHouse].coords.enter.y - POIOffsets.exit.y
                        local z = Apartments.Locations[ClosestHouse].coords.enter.z - CurrentOffset + POIOffsets.exit.z
                        DrawMarker(2, x, y, z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.2, 0.15, 200, 0, 0, 222, false, false, false, true, false, false, false)
                    end

                    --Stash
                    if stashdist <= 1.2 then
                        inRange = true
                        headerMenu[#headerMenu+1] = {
                            header = Lang:t('text.open_stash'),
                            params = {
                                event = 'apartments:client:OpenStash',
                                args = {}
                            }
                        }
                    elseif stashdist <= 3 then
                        local x = Apartments.Locations[ClosestHouse].coords.enter.x - POIOffsets.stash.x
                        local y = Apartments.Locations[ClosestHouse].coords.enter.y - POIOffsets.stash.y
                        local z = Apartments.Locations[ClosestHouse].coords.enter.z - CurrentOffset + POIOffsets.stash.z + 1.0
                        DrawMarker(2, x, y, z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.2, 0.15, 200, 0, 0, 222, false, false, false, true, false, false, false)
                    end

                    --Outfits
                    if outfitsdist <= 1 then
                        inRange = true
                        headerMenu[#headerMenu+1] = {
                            header = Lang:t('text.change_outfit'),
                            params = {
                                event = 'apartments:client:ChangeOutfit',
                                args = {}
                            }
                        }
                    elseif outfitsdist <= 3 then
                        local x = Apartments.Locations[ClosestHouse].coords.enter.x - POIOffsets.clothes.x
                        local y = Apartments.Locations[ClosestHouse].coords.enter.y - POIOffsets.clothes.y
                        local z = Apartments.Locations[ClosestHouse].coords.enter.z - CurrentOffset + POIOffsets.clothes.z
                        DrawMarker(2, x, y, z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.2, 0.15, 200, 0, 0, 222, false, false, false, true, false, false, false)
                    end

                    --Logout
                    if logoutdist <= 1 then
                        inRange = true
                        headerMenu[#headerMenu+1] = {
                            header = Lang:t('text.logout'),
                            params = {
                                event = 'apartments:client:Logout',
                                args = {}
                            }
                        }
                    elseif logoutdist <= 3 then
                        local x = Apartments.Locations[ClosestHouse].coords.enter.x - POIOffsets.logout.x
                        local y = Apartments.Locations[ClosestHouse].coords.enter.y + POIOffsets.logout.y
                        local z = Apartments.Locations[ClosestHouse].coords.enter.z - CurrentOffset + POIOffsets.logout.z
                        DrawMarker(2, x, y, z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.2, 0.15, 200, 0, 0, 222, false, false, false, true, false, false, false)
                    end

                    if inRange and not shownHeader then
                        shownHeader = true
                        exports['qb-menu']:showHeader(headerMenu)
                    end

                    if not inRange and shownHeader then
                        shownHeader = false
                        exports['qb-menu']:closeMenu()
                    end
                else          
                    if Apartments.UseTarget then
                        RegisterInApartmentTarget('entrancePos', entrancePos, 0, {
                            {
                                type = "client",
                                event = "apartments:client:OpenDoor",
                                label = Lang:t('text.open_door'),
                            },
                            {
                                type = "client",
                                event = "apartments:client:LeaveApartment",
                                label = Lang:t('text.leave'),
                            },
                        })
                        RegisterInApartmentTarget('stashPos', stashPos, 0, {
                            {
                                type = "client",
                                event = "apartments:client:OpenStash",
                                label = Lang:t('text.open_stash'),
                            },
                        })
                        RegisterInApartmentTarget('outfitsPos', outfitsPos, 0, {
                            {
                                type = "client",
                                event = "apartments:client:ChangeOutfit",
                                label = Lang:t('text.change_outfit'),
                            },
                        })
                        RegisterInApartmentTarget('logoutPos', logoutPos, 0, {
                            {
                                type = "client",
                                event = "apartments:client:Logout",
                                label = Lang:t('text.logout'),
                            },
                        })
                    end
                end
            elseif not Apartments.UseTarget then
                local headerMenu = {}
                local inRange = false
                local pos = GetEntityCoords(PlayerPedId())
                local entrance = #(pos - vector3(Apartments.Locations[ClosestHouse].coords.enter.x, Apartments.Locations[ClosestHouse].coords.enter.y,Apartments.Locations[ClosestHouse].coords.enter.z))

                if IsOwned then
                   if entrance <= 1 then
                        inRange = true
                        headerMenu[#headerMenu+1] = {
                            header = Lang:t('text.enter'),
                            params = {
                                event = 'apartments:client:EnterApartment',
                                args = {}
                            }
                        }

                        headerMenu[#headerMenu+1] = {
                            header = Lang:t('text.ring_doorbell'),
                            params = {
                                event = 'apartments:client:DoorbellMenu',
                                args = {}
                            }
                        }
                    end
                elseif not IsOwned then
                    if entrance <= 1 then
                        inRange = true
                        headerMenu[#headerMenu+1] = {
                            header = Lang:t('text.move_here'),
                            params = {
                                event = 'apartments:client:UpdateApartment',
                                args = {}
                            }
                        }


                        headerMenu[#headerMenu+1] = {
                            header = Lang:t('text.ring_doorbell'),
                            params = {
                                event = 'apartments:client:DoorbellMenu',
                                args = {}
                            }
                        }

                    end
                end

                if inRange and not shownHeader then
                    shownHeader = true
                    exports['qb-menu']:showHeader(headerMenu)
                end

                if not inRange and shownHeader then
                    shownHeader = false
                    exports['qb-menu']:closeMenu()
                end
            end
        end
        Wait(sleep)
    end
end)
