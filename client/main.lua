ESX = nil

ESX.PlayerData = {}

Citizen.CreateThread(function ()
    addped("a_m_m_trampbeac_01", "Zakaria", -767.1, -230.72, 37.08-0.98, 123.05)
    while ESX == nil do
        Citizen.Wait(350)
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end) 
        ESX.PlayerData = ESX.GetPlayerData() 
    end

    for k,v in pairs(Config.concesspos) do
        local blip = AddBlipForCoord(v.x, v.y, v.z)
        SetBlipSprite(blip, 225)
        SetBlipScale(blip, 0.7)
        SetBlipDisplay(blip, 4)
        SetBlipColour(blip, 26)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Luxury-Autos")
        EndTextCommandSetBlipName(blip)
    end

    ConcessMenu = {
        Base = { Title = "Concessionnaire", Header = {"commonmenu", "interaction_bgd"}, Color = {color_black} },
        Data = { currentMenu = "Luxury-Autos" },
        Events = {

            onSelected = function(self, _, btn, PMenu, menuData, currentButton, currentBtn, currentSlt, result, slide)
                local result = GetOnscreenKeyboardResult()
                    if btn.name == 'Faire une facture' then
                        closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestPlayer ~= -1 and closestDistance <= 3.0 then
                            local Raison = KeyboardInput("Raison de la facture", '', 200)
                            if Raison == nil then ESX.ShowNotification("~r~Le champ ne peux pas rester vide.") return end
                            local montant = KeyboardInput("Montant", '', 7)
                            if montant == nil then ESX.ShowNotification("~r~Le champ ne peux pas rester vide.") return end
                            TriggerServerEvent('esx_billing:sendBill', GetPlayerServerId(closestPlayer), 'society_cardealer', Raison, montant)
                        else
                            ESX.ShowNotification("~r~Demandez à la personne de se rapprocher du comptoir")
                        end
                    end
            end,
        },

        Menu = {
            ["Luxury-Autos"] = {
                b = {
                    {name = "Faire une facture", askX = true},
                },
            },
        }
    }


    AttribuerMenu = {
        Base = { Title = "Attribution", Header = {"commonmenu", "interaction_bgd"}, Color = {color_black} },
        Data = { currentMenu = "Options Disponibles" },
        Events = {
            onOpened = function()
                derniereposition = GetEntityCoords(GetPlayerPed(-1), false)
                FreezeEntityPosition(PlayerPedId(), true)
            end,
            onExited = function()
                SetEntityCoords(GetPlayerPed(-1), derniereposition.x, derniereposition.y, derniereposition.z - 0.9, SetEntityHeading(PlayerPedId(), 130.0), 0, 0, 1)
                FreezeEntityPosition(PlayerPedId(), false)
            end,
            onSelected = function(self, _, btn, PMenu, menuData, currentButton, currentBtn, currentSlt, result, slide)
                if btn.name == "Acheter un véhicule" then
                    OpenMenu("Catégories Disponibles")
                end
                if btn.name == "Attribuer un véhicule" then
                    AttribuerMenu.Menu["Véhicules de l'entreprise"].b = {}
                    ESX.TriggerServerCallback("getvehicleentr", function(vehicles)
                        for k,v in pairs(vehicles) do
                            table.insert(AttribuerMenu.Menu["Véhicules de l'entreprise"].b, {name = v.name.." ~b~["..v.plate.."]", slidemax = {"Pour soi", "Personne à côté"} ,plate = v.plate, props = v.properties, model = v.model, askX = true, id = v.id, attribuer = true})
                        end
                    end)
                    OpenMenu("Véhicules de l'entreprise")
                end
                
                if btn.category then
                    AttribuerMenu.Menu["Véhicules"].b = {}
                    ESX.TriggerServerCallback("getvehicle", function(vehicles)
                        for k,v in pairs(vehicles) do
                            table.insert(AttribuerMenu.Menu["Véhicules"].b, {name = v.name, price = v.price, model = v.model, askX = true})
                        end
                    end, btn.name)
                    Wait(500)
                    OpenMenu("Véhicules")
                end

                if self.Data.currentMenu == "Véhicules" then
                    local props = ESX.Game.GetVehicleProperties(GetVehiclePedIsIn(PlayerPedId(), false))
                    TriggerServerEvent("concess:acheter", btn.price, props.plate, btn.name, btn.model, json.encode(props))
                end

                if btn.attribuer and btn.slidenum == 1 then
                    local name = KeyboardInput("Nom du véhicule du client", '', 500)
                    if name == nil then ESX.ShowNotification("~r~Le champ ne peux pas rester vide.") return end
                    TriggerServerEvent("concess:attribuer", GetPlayerServerId(PlayerId()), btn.plate, btn.model, name, btn.id, json.encode(btn.props))
                end

                if btn.attribuer and btn.slidenum == 2 then
                    closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                     if closestPlayer ~= -1 and closestDistance <= 3.0 then
                        local name = KeyboardInput("Nom du véhicule du client", '', 500)
                        if name == nil then ESX.ShowNotification("~r~Le champ ne peux pas rester vide.") return end
                        TriggerServerEvent("concess:attribuer", GetPlayerServerId(closestPlayer), btn.plate, btn.model, name, btn.id, json.encode(btn.props))
                    else
                        ESX.ShowNotification("~r~Demandez à la personne de se rapprocher")
                    end
                end
            end,
            onButtonSelected = function(currentMenu, currentBtn, menuData, newButtons, self)
                if currentMenu == "Véhicules" then
                    spawnCarPreview(newButtons.model)
                    DrawSub(newButtons.name, 1200)
                end
                if currentMenu == "Options Disponibles" then
                    TriggerEvent("esx:deleteVehicle")
                end
                if currentMenu == "Catégories Disponibles" then
                    TriggerEvent("esx:deleteVehicle")
                end
        end,
        },

        Menu = {
            ["Options Disponibles"] = {
                b = {
                    {name = "Acheter un véhicule", askX = true},
                    {name = "Attribuer un véhicule", askX = true}
                },
            },
            ["Catégories Disponibles"] = {
                b = {
                    {name = "Compacts", askX = true, category = true},
                    {name = "Coupés", askX = true, category = true},
                    {name = "Sedans", askX = true, category = true},
                    {name = "Sports", askX = true, category = true},
                    {name = "Sports Classics", askX = true, category = true},
                    {name = "Super", askX = true, category = true},
                    {name = "Muscle", askX = true, category = true},
                    {name = "Off Road", askX = true, category = true},
                    {name = "SUVs", askX = true, category = true},
                    {name = "Vans", askX = true, category = true},
                    {name = "Motos", askX = true, category = true},
                },
            },
            ["Véhicules"] = {
                useFilter = true,
                refresh = 100,
                b = {
                },
            },
            ["Véhicules de l'entreprise"] = {
                useFilter = true,
                refresh = 100,
                b = {
                },
            },
        }
    }

    Catalogue = {
        Base = { Title = "Catalogue", Header = {"commonmenu", "interaction_bgd"}, Color = {color_black} },
        Data = { currentMenu = "Catégories Disponibles" },
        Events = {
            onOpened = function()
                NetworkGTA = true
                derniereposition = GetEntityCoords(GetPlayerPed(-1), false)
                FreezeEntityPosition(PlayerPedId(), true)
            end,
            onExited = function()
                NetworkGTA = false
                TriggerEvent("esx:deleteVehicle")
                SetEntityCoords(GetPlayerPed(-1), derniereposition.x, derniereposition.y, derniereposition.z - 0.9, SetEntityHeading(PlayerPedId(), 130.0), 0, 0, 1)
                FreezeEntityPosition(PlayerPedId(), false)
            end,
            onSelected = function(self, _, btn, PMenu, menuData, currentButton, currentBtn, currentSlt, result, slide)
                local result = GetOnscreenKeyboardResult()
                if self.Data.currentMenu == "Catégories Disponibles" then
                    Catalogue.Menu["Véhicules"].b = {}
                    ESX.TriggerServerCallback("getvehicle", function(vehicles)
                        for k,v in pairs(vehicles) do
                            table.insert(Catalogue.Menu["Véhicules"].b, {name = v.name, price = v.price, model = v.model, askX = true})
                        end
                    end, btn.name)
                    Wait(500)
                    SetEntityCoords(GetPlayerPed(-1), -784.14, -223.83, 37.32, SetEntityHeading(PlayerPedId(), 224.84), 0, 0, 1)
                    OpenMenu("Véhicules")
                end
            end,
                onButtonSelected = function(currentMenu, currentBtn, menuData, newButtons, self)
                    if currentMenu == "Véhicules" then
                        spawnCarConcess(newButtons.model)
                        DrawSub(newButtons.name, 1200)
                        SetEntityVisible(PlayerPedId(), false)
                    end
                    if currentMenu == "Catégories Disponibles" then
                        SetEntityVisible(PlayerPedId(), true)
                    end
            end,
        },

        Menu = {
            ["Catégories Disponibles"] = {
                b = {
                    {name = "Compacts", askX = true},
                    {name = "Coupés", askX = true},
                    {name = "Sedans", askX = true},
                    {name = "Sports", askX = true},
                    {name = "Sports Classics", askX = true},
                    {name = "Super", askX = true},
                    {name = "Muscle", askX = true},
                    {name = "Off Road", askX = true},
                    {name = "SUVs", askX = true},
                    {name = "Vans", askX = true},
                    {name = "Motos", askX = true},
                },
            },
            ["Véhicules"] = {
                useFilter = true,
                b = {
                },
            },
        }
    }
    while true do
        ESX.PlayerData = ESX.GetPlayerData()
        time = 350
        local pos = GetEntityCoords(PlayerPedId())
        local dest = vector3(-794.51, -218.78, 37.08)
        local dest2 = vector3(-786.19, -229.41, 37.08)
        local dest3 = vector3(-767.1, -230.72, 37.08-0.98)
        local distance = GetDistanceBetweenCoords(pos, dest, true)
        local distance2 = GetDistanceBetweenCoords(pos, dest2, true)
        local distance3 = GetDistanceBetweenCoords(pos, dest3, true)

        if distance <= 10 and ESX.PlayerData.job.name == "cardealer" then
            time = 1
            DrawMarker(6, -794.51, -218.78, 37.08-0.98, 0.0, 0.0, 180.0, 0.0, 0.0, 0.0, 1.2, 1.2, 1.2, 93, 173, 226, 120, false, false, false, false)
        end

        if distance <= 1.7 and ESX.PlayerData.job.name == "cardealer" then
            time = 1
            DrawTopNotification("Appuyez sur ~INPUT_CONTEXT~ pour ouvrir le menu ~b~Luxury~s~.")
            if IsControlJustPressed(1, 51) then
                CreateMenu(ConcessMenu)
            end
        end

        if distance2 <= 1.7 then
            time = 1
            DrawTopNotification("Appuyez sur ~INPUT_CONTEXT~ pour ouvrir le ~b~catalogue~s~.")
            if IsControlJustPressed(1, 51) then
                CreateMenu(Catalogue)
            end
        end

        if distance3 <= 1.7 and ESX.PlayerData.job.name == "cardealer" then
            time = 1
            DrawTopNotification("Appuyez sur ~INPUT_CONTEXT~ pour ouvrir le ~b~menu~s~.")
            if IsControlJustPressed(1, 51) then
                CreateMenu(AttribuerMenu)
            end
        end
        
        Wait(time)
    end
end)

Citizen.CreateThread(function()
	while true do 
		Citizen.Wait(1)
		if NetworkGTA then 
			for id = 0,255 do
				if id ~= PlayerId() and NetworkIsPlayerActive(id) then
					NetworkFadeOutEntity(GetPlayerPed(id), false)
                    NetworkFadeOutEntity(GetVehiclePedIsIn(GetPlayerPed(id)), false)
				end
			end
		else
			Citizen.Wait(1000)
		end
        Citizen.Wait(0)
	end
end)

function spawnCarConcess(car)
    local car = GetHashKey(car)

    TriggerEvent("esx:deleteVehicle")

    RequestModel(car)
    while not HasModelLoaded(car) do
        RequestModel(car)
        Citizen.Wait(50)
    end

    local vehicle = CreateVehicle(car, -783.84, -223.5, 37.32, 224.84, true, false)

    SetPedIntoVehicle(PlayerPedId(), vehicle, -1)
    SetVehicleEngineOn(vehicle, false, true, true)
    SetEntityAsNoLongerNeeded(vehicle)
    SetModelAsNoLongerNeeded(vehicle)

    FreezeEntityPosition(GetVehiclePedIsIn(GetPlayerPed(-1), true), true)
    SetVehicleRadioEnabled(vehicle, false)
end

function spawnCarPreview(car)
    local car = GetHashKey(car)

    TriggerEvent("esx:deleteVehicle")

    RequestModel(car)
    while not HasModelLoaded(car) do
        RequestModel(car)
        Citizen.Wait(50)
    end

    local vehicle = CreateVehicle(car, -773.94, -233.09, 37.08, 202.79, true, false)

    SetPedIntoVehicle(PlayerPedId(), vehicle, -1)
    SetVehicleEngineOn(vehicle, false, true, true)
    SetEntityAsNoLongerNeeded(vehicle)
    SetModelAsNoLongerNeeded(vehicle)

    FreezeEntityPosition(GetVehiclePedIsIn(GetPlayerPed(-1), true), true)
    SetVehicleRadioEnabled(vehicle, false)
end
