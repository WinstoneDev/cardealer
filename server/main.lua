ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

ESX.RegisterServerCallback("getvehicle", function (source, cb, category)
	MySQL.Async.fetchAll("SELECT * FROM vehicles WHERE category = @category", {
		["@category"] = category
	}, function (result)
		cb(result)
	end)
end)

ESX.RegisterServerCallback("getvehicleentr", function (source, cb)
	MySQL.Async.fetchAll("SELECT * FROM concess_vehic ", {}, function (result)
		cb(result)
	end)
end)

RegisterNetEvent("concess:acheter")
AddEventHandler("concess:acheter", function (price, plate, name, model, props)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	local job = xPlayer.job.name

	MySQL.Async.fetchAll("SELECT money FROM society WHERE name = @name", {
		['@name'] = job
	}, function (result)
		if result[1] then
		local money = result[1].money
		if money < price then
			TriggerClientEvent('esx:showNotification', _source, "~r~Ton entreprise n'a pas assez d'argent")
		else
			MySQL.Async.execute("UPDATE society SET money = money-@money WHERE name = @name", {
				['@name'] = job,
				['@money'] = price
			})
			TriggerClientEvent('esx:showNotification', _source, "Vous avez bien acheté le véhicule pour votre entreprise")
			MySQL.Async.execute("INSERT INTO concess_vehic (name, model, plate, properties) VALUES (@name, @model, @plate, @properties) ", {
				['@name'] = name,
				['@model'] = model, 
				['@plate'] = plate,
				['@properties'] = props
			})
		end
	end
	end)
end)

RegisterNetEvent("concess:attribuer")
AddEventHandler("concess:attribuer", function(target, plate, model, name, id, props)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(target)
	
	MySQL.Async.execute("DELETE FROM concess_vehic WHERE id = @id", {
		["@id"] = id
	})

	MySQL.Async.execute("INSERT INTO garage (owner, vehicle, name, plate, properties, stored) VALUES (@owner, @vehicle, @name, @plate, @properties, @stored) ", {
		['@owner'] = xPlayer.identifier,
		['@vehicle'] = model, 
		['@name'] = name, 
		['@plate'] = plate,
		['@properties'] = props,
		['@stored'] = 0
	})

	TriggerClientEvent('esx:showNotification', _source, "Vous avez bien attribué le véhicule ~b~"..name.."~s~ à ~g~"..GetPlayerName(target))
	TriggerClientEvent('esx:showNotification', target, "Un nouveau ~b~véhicule~s~ vient de vous être attribué")
end)