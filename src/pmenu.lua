local isLC = GetConvarInt("sh_libertyCity", 0) == 1
local GetGameTimer = GetGameTimer
local HasModelLoaded = HasModelLoaded
local HasAnimDictLoaded = HasAnimDictLoaded
local HasAnimSetLoaded = HasAnimSetLoaded
local IsNewLoadSceneLoaded = IsNewLoadSceneLoaded
local HasCollisionLoadedAroundEntity = HasCollisionLoadedAroundEntity
local GetGroundZAndNormalFor_3dCoord = GetGroundZAndNormalFor_3dCoord
local DisableControlAction = DisableControlAction

function ShowLoadingPrompt(showText, showTime, showType)
	Citizen.CreateThread(function()
		Citizen.Wait(0)
		BeginTextCommandBusyspinnerOn("STRING")
		AddTextComponentSubstringPlayerName(showText)
		EndTextCommandBusyspinnerOn(showType)
		Citizen.Wait(showTime)
		BusyspinnerOff()
	end)
end

function SecondsToClock(seconds)
	seconds = tonumber(seconds)

	if seconds <= 0 then
		return "00:00"
	else
		local mins = string.format("%02.f", math.floor(seconds / 60))
		local secs = string.format("%02.f", math.floor(seconds - mins * 60))
		return string.format("%s:%s", mins, secs)
	end
end

function ShowAboveRadarMessage(message, back)
	if back then ThefeedNextPostBackgroundColor(back) end
	BeginTextCommandThefeedPost("jamyfafi")
	AddLongString(message)
	return EndTextCommandThefeedPostTicker(0, 1)
end

function ShowNotificationWithButton(button, message, back)
	if back then ThefeedNextPostBackgroundColor(back) end
	BeginTextCommandThefeedPost("jamyfafi")
	return EndTextCommandThefeedPostReplayInput(1, button, message)
end

function DrawTopNotification(txt, beep)
	BeginTextCommandDisplayHelp("jamyfafi")
	AddLongString(txt)
	EndTextCommandDisplayHelp(0, 0, beep, -1)
end

function DrawCustomNotif(txt)
	BeginTextCommandThefeedPost("jamyfafi")
	AddLongString(txt)
	EndTextCommandThefeedPostMessagetextTu("CHAR_SOCIAL_CLUB", "CHAR_SOCIAL_CLUB", 0, 0, "mee", "qsdqsdsdqqsd", 1.0)
	EndTextCommandThefeedPostTicker(0, 1)
end

function ShowAboveRadarMessageIcon(icon, intType, sender, title, text, back)
	if type(icon) == "number" then
		local ped = GetPlayerPed(GetPlayerFromServerId(icon))
		icon = ped and GetPedHeadshot(ped) or GetPedHeadshot(PlayerPedId())
	elseif not HasStreamedTextureDictLoaded(icon) then
		RequestStreamedTextureDict(icon, false)
		while not HasStreamedTextureDictLoaded(icon) do Wait(0) end
	end

	if back then
		ThefeedNextPostBackgroundColor(back)
	end
	BeginTextCommandThefeedPost("jamyfafi")
	AddLongString(text)

	EndTextCommandThefeedPostMessagetext(icon, icon, true, intType, sender, title)
	SetStreamedTextureDictAsNoLongerNeeded(icon)
	return EndTextCommandThefeedPostTicker(0, 1)
end

function DrawCenterText(msg, time)
	ClearPrints()
	BeginTextCommandPrint("STRING")
	AddTextComponentSubstringPlayerName(msg)
	EndTextCommandPrint(time and math.ceil(time) or 0, true)
end

local done
function MoveRightPos(p, ent)
	done = true
	DoScreenFadeOut(100)
	Citizen.Wait(100)
	done = SetEntCoords(p, ent)
	while not done do
		Citizen.Wait(0)
	end
	DoScreenFadeIn(100)
end

function DrawSub(msg, time)
    ClearPrints()
    BeginTextCommandPrint('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandPrint(time, 1)
end

function SetEntCoords(pos, ent, trustPos)
	if not pos or not pos.x or not pos.y or not pos.z or (ent and not DoesEntityExist(ent)) then return true end
	local x, y, z = pos.x, pos.y, pos.z + 1.0
	ent = ent or GetPlayerPed(-1)

	RequestCollisionAtCoord(x, y, z)

	if not isLC then
		NewLoadSceneStart(x, y, z, x, y, z, 50.0, 0)

		local tempTimer = GetGameTimer()
		while not IsNewLoadSceneLoaded() do
			if GetGameTimer() - tempTimer > 3000 then
				break
			end

			Citizen.Wait(0)
		end
	end

	SetEntityCoordsNoOffset(ent, x, y, z)

	local tempTimer = GetGameTimer()
	while not HasCollisionLoadedAroundEntity(ent) do
		if GetGameTimer() - tempTimer > 3000 then
			break
		end

		Citizen.Wait(0)
	end

	local foundNewZ, newZ
	if not trustPos then
		foundNewZ, newZ = GetGroundZAndNormalFor_3dCoord(x, y, z)
		tempTimer = GetGameTimer()
		while not foundNewZ do
			z = z + 10.0
			foundNewZ, newZ = GetGroundZAndNormalFor_3dCoord(x, y, z)
			Wait(0)

			if GetGameTimer() - tempTimer > 2000 then
				break
			end
		end
	end

	SetEntityCoordsNoOffset(ent, x, y, foundNewZ and newZ or z)

	if not isLC then
		NewLoadSceneStop()
	end

	if type(pos) ~= "vector3" and pos.a then SetEntityHeading(ent, pos.a) end
	return true
end

function AddLongString(txt)
	local maxLen = 100
	for i = 0, string.len(txt), maxLen do
		local sub = string.sub(txt, i, math.min(i + maxLen, string.len(txt)))
		AddTextComponentSubstringPlayerName(sub)
	end
end

function CreateCBlip(vector3Pos, intSprite, intColor, stringText, boolRoad, floatScale, intDisplay, intAlpha)
	local blip = AddBlipForCoord(vector3Pos.x, vector3Pos.y, vector3Pos.z)
	SetBlipSprite(blip, intSprite)
	SetBlipAsShortRange(blip, true)
	if intColor then SetBlipColour(blip, intColor) end
	if floatScale then SetBlipScale(blip, floatScale) end
	if boolRoad then SetBlipRoute(blip, boolRoad) end
	if intDisplay then SetBlipDisplay(blip, intDisplay) end
	if intAlpha then SetBlipAlpha(blip, intAlpha) end
	if stringText and (not intDisplay or intDisplay ~= 8) then
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentSubstringPlayerName(stringText)
		EndTextCommandSetBlipName(blip)
	end
	return blip
end

function RequestAndWaitModel(modelName)
	if modelName and IsModelInCdimage(modelName) and not HasModelLoaded(modelName) then
		RequestModel(modelName)
		while not HasModelLoaded(modelName) do Citizen.Wait(100) end
	end
end

function RequestAndWaitDict(dictName)
	if dictName and DoesAnimDictExist(dictName) and not HasAnimDictLoaded(dictName) then
		RequestAnimDict(dictName)
		while not HasAnimDictLoaded(dictName) do Citizen.Wait(100) end
	end
end

function RequestAndWaitSet(setName)
	if setName and not HasAnimSetLoaded(setName) then
		RequestAnimSet(setName)

		local startTime = GetGameTimer()
		while not HasAnimSetLoaded(setName) and startTime + 3000 > GetGameTimer() do Citizen.Wait(100) end
	end
end

KEEP_FOCUS = false
local threadCreated = false

local controlDisabled = {1, 2, 3, 4, 5, 6, 18, 24, 25, 37, 68, 69, 70, 91, 92, 182, 199, 200, 257}

function IsInNuiKeepMode()
	return KEEP_FOCUS
end

function SetKeepInputMode(bool)
	if SetNuiFocusKeepInput then
		SetNuiFocusKeepInput(bool)
	end

	KEEP_FOCUS = bool

	if not threadCreated and bool then
		threadCreated = true

		Citizen.CreateThread(function()
			while KEEP_FOCUS do
				Wait(0)

				for _,v in pairs(controlDisabled) do
					DisableControlAction(0, v, true)
				end
			end

			threadCreated = false
		end)
	end
end

function IsPlayerControlFree()
	return not (KEEP_FOCUS or UpdateOnscreenKeyboard() == 0)
end

function RegisterControlKey(strKeyName, strDescription, strKey, cbPress, cbRelease)
    RegisterKeyMapping("+" .. strKeyName, strDescription, "keyboard", strKey)

	RegisterCommand("+" .. strKeyName, function()
		if not cbPress or UpdateOnscreenKeyboard() == 0 then return end
        cbPress()
    end, false)

    RegisterCommand("-" .. strKeyName, function()
        if not cbRelease or UpdateOnscreenKeyboard() == 0 then return end
        cbRelease()
    end, false)
end

-- Warning, only use it outside of main thread to no block the main thread
function IsAnyVehicleNearPoint2(position, radius, waitTime)
	local selfPos = LocalPlayer().Pos

	-- Volontary put to 300 since stream range seems to be 350, keep a small margin
	-- https://github.com/citizenfx/fivem/blob/147d405a6f3f47654bd6735e5a39b695d6c84848/code/components/citizen-server-impl/src/state/ServerGameState.cpp#L710
	if GetDistanceBetweenCoords(selfPos, position) >= 300.0 then
		local wasFaded = IsScreenFadedOut()
		if not wasFaded then DoScreenFadeOut() end
		-- Force focus to pos to load entities outside of your scope
		SetFocusPosAndVel(position.x, position.y, position.z)
		-- Is this will be enough or too much ???
		Citizen.Wait(waitTime or 5000)
		local isFree = IsAnyVehicleNearPoint(position.x, position.y, position.z, radius)
		ClearFocus()
		if not wasFaded then DoScreenFadeIn() end
		return isFree
	else
		return IsAnyVehicleNearPoint(position.x, position.y, position.z, radius)
	end
end

ESX = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(10)
	end
end)

-- LOCAL
local color_white = {255, 255, 255}
local color_black = {0, 0, 0}
local defaultHeader = {"commonmenu", "interaction_bgd"}
local defaultMenu = { { name = "Vide" } }
local _intX, _intY = .24, .175
local _intW, _intH = .225, .035
local spriteW, spriteH = .225, .0675
local PMenu = {}
local parentSliderSize = .25

-- local natives
local drawSprite = DrawSprite
local BeginTextCommandWidth = BeginTextCommandWidth
local AddTextComponentSubstringPlayerName = AddTextComponentSubstringPlayerName
local SetTextFont = SetTextFont
local SetTextScale = SetTextScale
local EndTextCommandGetWidth = EndTextCommandGetWidth
local GetControlNormal = GetControlNormal
local RequestStreamedTextureDict = RequestStreamedTextureDict
local SetStreamedTextureDictAsNoLongerNeeded = SetStreamedTextureDictAsNoLongerNeeded
local IsControlPressed = IsControlPressed
local IsDisabledControlPressed = IsDisabledControlPressed
local IsControlJustPressed = IsControlJustPressed
local UpdateOnscreenKeyboard = UpdateOnscreenKeyboard
local SetTextDropShadow = SetTextDropShadow
local SetTextEdge = SetTextEdge
local SetTextColour = SetTextColour
local SetTextJustification = SetTextJustification
local SetTextWrap = SetTextWrap
local SetTextEntry = SetTextEntry
local AddTextComponentString = AddTextComponentString
local DrawText = DrawText
local DrawRect = DrawRect
local AddTextEntry = AddTextEntry
local DisplayOnscreenKeyboard = DisplayOnscreenKeyboard
local GetOnscreenKeyboardResult = GetOnscreenKeyboardResult
local ShowCursorThisFrame = ShowCursorThisFrame
local DisableControlAction = DisableControlAction
local defaultCheckbox = { [0] = {"commonmenu", "shop_box_blank"}, [1] = {"commonmenu", "shop_box_tickb"}, [2] = {"commonmenu", "shop_box_tick"} }

local function MeasureStringWidth(str, font, scale)
	BeginTextCommandWidth("STRING")
	AddTextComponentSubstringPlayerName(str)
	SetTextFont(font or 0)
	SetTextScale(1.0, scale or 0)
	return EndTextCommandGetWidth(true)
end

function IsMouseInBounds(X, Y, Width, Height)
	local MX, MY = GetControlNormal(0, 239) + Width / 2, GetControlNormal(0, 240) + Height / 2
	return (MX >= X and MX <= X + Width) and (MY > Y and MY < Y + Height)
end

function PMenu:resetMenu()
	self.Data = { back = {}, currentMenu = "", intY = _intY, intX = _intX }
	self.Pag = { 1, 10, 1, 1 }
	self.Base = {
		Header = defaultHeader,
		Color = color_black,
		HeaderColor = color_white,
		Title = GM and GM.State.user and GM.State.user.name or "Menu",
		Checkbox = { Icon = defaultCheckbox }
	}

	self.Menu = {}
	self.Events = {}
	self.tempData = {}
	self.IsVisible = false
end

function stringsplit(inputstr, sep)
    if not inputstr then return end
    if sep == nil then
        sep = "%s"
    end
    local t = {} ; i = 1
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end

--[[function PMenu:CloseMenu(bypass)
	if self.IsVisible and (not self.Base.Blocked or bypass) then
		self.IsVisible = false
		if self.Events["onExited"] then self.Events["onExited"](self.Data, self, true) end

		exports.pichot_scaleform:SetMenuVisible(false)
		self:resetMenu()
	end
end--]]

function SetMenuVisible(bool)
	IsVisible = bool
end


function PMenu:CloseMenu(bypass)
	if self.IsVisible and (not self.Base.Blocked or bypass) then
		self.IsVisible = false
		if self.Events["onExited"] then self.Events["onExited"](self.Data, self, true) end
		SetMenuVisible(false)
		self:resetMenu()
	end
end

function PMenu:GetButtons(customMenu)
	local menu = customMenu or self.Data.currentMenu
	local menuData = self.Menu and self.Menu[menu]
	local allButtons = menuData and menuData.b
	if not allButtons then return {} end

	local tblFilter = {}
	allButtons = type(allButtons) == "function" and allButtons(self, menu) or allButtons
	if not allButtons or type(allButtons) ~= "table" then return {} end

	if self.Events and self.Events["onLoadButtons"] then allButtons = self.Events["onLoadButtons"](self, menu, allButtons) or allButtons end
	for _,v in pairs(allButtons) do
		if v and type(v) == "table" and (v.canSee and (type(v.canSee) == "function" and v.canSee() or v.canSee == true) or v.canSee == nil) and (not menuData.filter or string.find(string.lower(v.name), menuData.filter)) then
			if v.customSlidenum then v.slidenum = type(v.customSlidenum) == "function" and v.customSlidenum() or v.customSlidenum end

			local max = type(v.slidemax) == "function" and v.slidemax(v, self) or v.slidemax
			if type(max) == "number" then
				local tbl = {}
				for i = 0, max do
					tbl[#tbl + 1] = i
				end
				max = tbl
			end

			if max then
				v.slidenum = v.slidenum or 1
				local slideName = max[v.slidenum]
				if slideName then
					v.slidename = slideName and type(slideName) == "table" and slideName.name or tostring(slideName)
				end
			end

			tblFilter[#tblFilter + 1] = v
		end
	end

	if #tblFilter <= 0 then tblFilter = defaultMenu end

	self.tempData = { tblFilter, #tblFilter }
	return tblFilter, #tblFilter
end

function PMenu:OpenMenu(stringName, boolBack)
	if stringName and not self.Menu[stringName] then print("[pMenu] " .. stringName .. " cannot be opened, the menu doesn't exist.") return end

	local newButtons, currentButtonsCount = self:GetButtons(stringName)
	--if not boolBack and (newButtons and newButtons[self.Pag[3]] and newButtons[self.Pag[3]].name ~= string.lower(stringName)) then
	if not boolBack and self.Data and self.Data.back then
		self.Data.back[#self.Data.back + 1] = self.Data.currentMenu
	end

	if boolBack then
		self.Data.back[#self.Data.back] = nil
	end

	local intSelect = boolBack and self.Pag[4] or 1
	local max = math.max(10, math.min(intSelect))
	self.Pag = { max - 9, max, intSelect, self.Pag[3] or 1 } -- min, max, current, ancien menu
	self.tempData = { newButtons, currentButtonsCount }
	self.Data.currentMenu = stringName
	if self.Events and self.Events["onButtonSelected"] then self.Events["onButtonSelected"](self.Data.currentMenu, self.Pag[3], self.Data.back, newButtons[1] or {}, self) end
end

function PMenu:Back()
	local historyCount = #self.Data.back
	if historyCount == 0 and not self.Base.Blocked then
		self:CloseMenu()
	elseif historyCount > 0 and not self.Base.BackBlocked then
		self:OpenMenu(self.Data.back[#self.Data.back], true)
		if self.Events["onBack"] then self.Events["onBack"](self.Data, self) end
	end
end

function PMenu:CreateMenu(tableMenu, tempData)
	if (self.Base and self.Base.Blocked and self.IsVisible and IsMenuOpened()) or not tableMenu then return end
	if not self.IsVisible and tableMenu then
		self:resetMenu()
		tableMenu.Base = tableMenu.Base or {}
		for k,v in pairs(tableMenu.Base) do
			if k == "Header" then RequestStreamedTextureDict(v[1]) SetStreamedTextureDictAsNoLongerNeeded(v[1]) end
			self.Base[k] = v
		end

		tableMenu.Data = tableMenu.Data or {}
		for k,v in pairs(tableMenu.Data) do
			self.Data[k] = v
		end

		tableMenu.Events = tableMenu.Events or {}
		for k,v in pairs(tableMenu.Events) do
			self.Events[k] = v
		end

		tableMenu.Menu = tableMenu.Menu or {}
		for k,v in pairs(tableMenu.Menu) do
			self.Menu[k] = v
		end

		self.Data.temp = tempData
		self.Base.CustomHeader = self.Base.Header and self.Base.Header[2] ~= "interaction_bgd"
		_intY = self.Base.CustomHeader and .205 or .17

		if self.Events["onButtonSelected"] then
			-- maybe get buttons
			local allButtons, count = self:GetButtons()
			self.tempData = { allButtons, count }
			self.Events["onButtonSelected"](self.Data.currentMenu, 1, {}, allButtons[1] or {}, self)
		end
		self:OpenMenu(self.Data.currentMenu)
		local boolVisible = self.Base and self.Base.Blocked or not self.IsVisible
		self.IsVisible = boolVisible
		SetMenuVisible(boolVisible)
		if self.IsVisible and self.Events and self.Events["onOpened"] then self.Events["onOpened"](self.Data, self) end
	else
		self:CloseMenu(true)
	end
end

local lastRefresh
function PMenu:ProcessControl()
	local boolUP, boolDOWN, boolRIGHT, boolLEFT = IsControlPressed(1, 172), IsControlPressed(1, 173), IsControlPressed(1, 175), IsControlPressed(1, 174)
	local currentMenu = self.Menu and self.Menu[self.Data.currentMenu]

	local currentButtons, currentButtonsCount = table.unpack(self.tempData)
	local currentBtn = currentButtons and currentButtons[self.Pag[3]]

	if currentMenu and currentMenu.refresh and (not lastRefresh or GetGameTimer() >= lastRefresh) then
		lastRefresh = GetGameTimer() + (currentMenu.refresh == true and 1 or currentMenu.refresh)
		self:GetButtons()
	end

	if (boolUP or boolDOWN) and currentButtonsCount and self.Pag[3] then
		if boolDOWN and (self.Pag[3] < currentButtonsCount) or boolUP and (self.Pag[3] > 1) then
			self.Pag[3] = self.Pag[3] + (boolDOWN and 1 or -1)
			if currentButtonsCount > 10 and (boolUP and (self.Pag[3] < self.Pag[1]) or (boolDOWN and (self.Pag[3] > self.Pag[2]))) then
				self.Pag[1] = self.Pag[1] + (boolDOWN and 1 or -1)
				self.Pag[2] = self.Pag[2] + (boolDOWN and 1 or -1)
			end
		else
			self.Pag = { boolUP and currentButtonsCount - 9 or 1, boolUP and currentButtonsCount or 10, boolDOWN and 1 or currentButtonsCount, self.Pag[4] or 1 }
			if currentButtonsCount > 10 and (boolUP and (self.Pag[3] > self.Pag[2]) or (boolDOWN and (self.Pag[3] < self.Pag[1]))) then
				self.Pag[1] = self.Pag[1] + (boolDOWN and -1 or 1)
				self.Pag[2] = self.Pag[2] + (boolDOWN and -1 or 1)
			end
		end

		local newButton = currentButtons[self.Pag[3]]
		if self.Events["onButtonSelected"] and newButton and self:canUseButton(newButton) then
			self.Events["onButtonSelected"](self.Data.currentMenu, self.Pag[3], self.Data.back, newButton, self)
		end

		Citizen.Wait(125)
	end

	if (boolRIGHT or boolLEFT) and currentBtn and self:canUseButton(currentBtn) then
		local slide = currentBtn.slide or currentMenu.slide or self.Events["onSlide"]
		if currentMenu.slidemax or currentBtn and currentBtn.slidemax or self.Events["onSlide"] or slide then
			local changeTo = currentMenu.slidemax and currentMenu or currentBtn.slidemax and currentBtn
			if changeTo and not changeTo.slidefilter or changeTo and not tableHasValue(changeTo.slidefilter, self.Pag[3]) then
				currentBtn.slidenum = currentBtn.slidenum or 0
				local max = type(changeTo.slidemax) == "function" and (changeTo.slidemax(currentBtn, self) or 0) or changeTo.slidemax
				if type(max) == "number" then
					local tbl = {}
					for i = 0, max do
						tbl[#tbl + 1] = i
					end
					max = tbl
				end

				currentBtn.slidenum = currentBtn.slidenum + (boolRIGHT and 1 or -1)
				if (boolRIGHT and (currentBtn.slidenum > #max) or boolLEFT and (currentBtn.slidenum < 1)) then
					currentBtn.slidenum = boolRIGHT and 1 or #max
				end

				local slideName = max[currentBtn.slidenum]
				currentBtn.slidename = slideName and type(slideName) == "table" and slideName.name or tostring(slideName)
				local Offset = MeasureStringWidth(currentBtn.slidename, 0, 0.35)

				currentBtn.offset = Offset
				if slide then slide(self.Data, currentBtn, self.Pag[3], self) end
				Citizen.Wait(currentMenu.slidertime or 175)
			end
		end

		if currentBtn.parentSlider ~= nil and self:canUseButton(currentBtn) and ((boolLEFT and currentBtn.parentSlider < 1.5 + parentSliderSize) or (boolRIGHT and currentBtn.parentSlider > .5 - parentSliderSize)) then
			currentBtn.parentSlider = boolLEFT and round(currentBtn.parentSlider + .01, 2) or round(currentBtn.parentSlider - .01, 2)
			if self.Events["onSlider"] then self.Events["onSlider"](self, self.Data, currentBtn, self.Pag[3], allButtons, currentBtn.parentSlider - parentSliderSize) end
			Citizen.Wait(10)
		end
	end

	if currentMenu and currentMenu.extra or currentBtn and currentBtn.opacity then
        if currentBtn.advSlider and IsDisabledControlPressed(0, 24) and self:canUseButton(currentBtn) then
            local x, y, w = table.unpack(self.Data.advSlider)
            local left, right = IsMouseInBounds(x - 0.01, self.Height, .015, .03), IsMouseInBounds(x - w + 0.01, self.Height, .015, .03)
            if left or right then
                local advPadding = 1
                currentBtn.advSlider[3] = math.max(currentBtn.advSlider[1], math.min(currentBtn.advSlider[2], right and currentBtn.advSlider[3] - advPadding or left and currentBtn.advSlider[3] + advPadding ))
                self.Events["onAdvSlide"](self, self.Data, currentBtn, self.Pag[3], currentButtons)
            end

            Citizen.Wait(75)
        end
    end

	if IsControlJustPressed(1, 202) and UpdateOnscreenKeyboard() ~= 0 then
		self:Back()
		Citizen.Wait(100)
	end

	if self.Pag[3] and currentButtonsCount and self.Pag[3] > currentButtonsCount then
		self.Pag = { 1, 10, 1, self.Pag[4] or 1 }
	end
end

function DrawText2(intFont, stirngText, floatScale, intPosX, intPosY, color, boolShadow, intAlign, addWarp)
	SetTextFont(intFont)
	SetTextScale(floatScale, floatScale)
	if boolShadow then
		SetTextDropShadow(0, 0, 0, 0, 0)
		SetTextEdge(0, 0, 0, 0, 0)
	end
	SetTextColour(color[1], color[2], color[3], 255)
	if intAlign == 0 then
		SetTextCentre(true)
	else
		SetTextJustification(intAlign or 1)
		if intAlign == 2 then
			SetTextWrap(.0, addWarp or intPosX)
		end
	end
	SetTextEntry("STRING")
	AddTextComponentString(stirngText)
	DrawText(intPosX, intPosY)
end	

function PMenu:canUseButton(button)
	if not button.role then return true end
	-- Only used in 'gtalife'
	if not GM or not GM.State or not GM.State.user or not GetLinkedRoles then return false end

	if button.role then
		local userRole = GM.State.user.group
		return userRole and tableHasValue(GetLinkedRoles(userRole), button.role)
	end

	return false
end

function PMenu:getHelpTextForBlockedButton(button)
	local desc
	
	if button.carteb then
		desc = "Vous avez déjà récupéré votre carte."
	end
	if not button.carteb then
		desc = "Vous n'avez pas le grade requis."
	end
	if button.notppa then
		desc = "Vous n'avez pas de permis de Port d'arme."
	end
	if not button.notppa then
		desc = "Vous n'avez pas le grade requis."
	end
	if button.permis then
		desc = "Vous avez déjà passé votre permis."
	end

	return desc
end

function PMenu:drawMenuButton(button, intX, intY, boolSelected, intW, intH, intID)
	local tableColor, add, currentMenuData = boolSelected and (button.colorSelected or { 255, 255, 255, 255 }) or (button.colorFree or { 0, 0, 0, 100 }), .0, self.Menu[self.Data.currentMenu]
	DrawRect(intX, intY, intW, intH, tableColor[1], tableColor[2], tableColor[3], tableColor[4])
	tableColor = boolSelected and color_black or color_white

	local stringPrefix = (((button.r and (((GM and GM.State.JobRank < button.r) or (button.rfunc and not button.rfunc())) and "~r~" or "")) or "") .. (self.Events["setPrefix"] and self.Events["setPrefix"](button, self.Data) or "")) or ""
	DrawText2(0, (button.price and "> " or "") .. stringPrefix .. (button.name or ""), .275, intX - intW / 2 + .005, intY - intH / 2 + .0025, tableColor)

	local unkCheckbox = currentMenuData and currentMenuData.checkbox or button.checkbox ~= nil and button.checkbox
	local slide = button.slidemax and button or currentMenuData
	local slideExist = slide and slide.slidemax and (not slide.slidefilter or not tableHasValue(slide.slidefilter, intID))
	local canUse = self:canUseButton(button)

	if canUse then
		if button.name and self.Menu[string.lower(button.name)] and not currentMenuData.item and not slideExist then
			drawSprite("commonmenutu", "arrowright", intX + (intW / 2.2), intY, .009, .018, 0.0, tableColor[1], tableColor[2], tableColor[3], 255)
			add = .0125
		end

		if unkCheckbox ~= nil and (button.checkbox ~= nil or currentMenuData and currentMenuData.checkbox ~= nil) then
			local bool = unkCheckbox ~= nil and (type(unkCheckbox) == "function" and unkCheckbox(GetPlayerPed(-1), button, self.Base.currentMenu, self)) or unkCheckbox
			if (button.locked) then
				bool = bool and bool == true and 2 or 0
			else
				bool = bool and bool == true and 1 or 0
			end

			if not self.Base.Checkbox["Icon"] or self.Base.Checkbox["Icon"][bool] then
				local successIcon = self.Base.Checkbox["Icon"] and self.Base.Checkbox["Icon"][bool]
				if successIcon and successIcon[1] and successIcon[2] then
					local checkboxColor = boolSelected and bool == 0 and color_black or color_white
					drawSprite(successIcon[1], successIcon[2], intX + (intW / 2.2), intY, .023, .045, 0.0, checkboxColor[1], checkboxColor[2], checkboxColor[3], 255)
					return
				end
			end
		elseif slideExist or button.ask or button.slidename then
			local max = slideExist and slide and (type(slide.slidemax) == "function" and slide.slidemax(button, self) or slide.slidemax)
			if (max and type(max) == "number" and max > 0 or type(max) == "table" and #max > 0) or not slideExist then
				local defaultIndex = slideExist and button.slidenum or 1
				local slideText = button.ask and (type(button.ask) == "function" and button.ask(self) or button.askValue or button.ask) or (button.slidename or (type(max) == "number" and (defaultIndex - 1) or type(max[defaultIndex]) == "table" and max[defaultIndex].name or tostring(max[defaultIndex])))
				slideText = tostring(slideText)
				if boolSelected and slideExist then
					drawSprite("commonmenu", "arrowright", intX + (intW / 2) - .01025, intY + 0.0004, .009, .018, 0.0, tableColor[1], tableColor[2], tableColor[3], 255)

					button.offset = MeasureStringWidth(slideText, 0, .275)
					drawSprite("commonmenu", "arrowleft", intX + (intW / 2) - button.offset - .016, intY + 0.0004, .009, .018, 0.0, tableColor[1], tableColor[2], tableColor[3], 255)
				end

				local textX = (not boolSelected or button.ask) and -.004 or - .0135
				DrawText2(0, slideText, .275, intX + intW / 2 + textX,  intY - intH / 2 + .00375, tableColor, false, 2)
				intX = boolSelected and intX - .0275 or intX - .0125
			end
		end

		if button.parentSlider ~= nil then
			local rectX, rectY = intX + .0925, intY + 0.005
			local proW, proH = .1, 0.01
			local prout = "mpleaderboard"

			drawSprite(prout, "leaderboard_female_icon", intX + (intW / 2) - .01025, intY + 0.0004, .0156, .0275, 0.0, tableColor[1], tableColor[2], tableColor[3], 255)
			drawSprite(prout, "leaderboard_male_icon", intX - .015, intY + 0.0004, .0156, .0275, 0.0, tableColor[1], tableColor[2], tableColor[3], 255)

			local slideW = proW * button.parentSlider
			DrawRect(rectX - proW / 2, rectY - proH / 2, proW, proH, 4, 32, 57, 255)
			DrawRect(rectX - slideW / 2, rectY - proH / 2, proW * parentSliderSize, proH, 57, 116, 200, 255)

			DrawRect(rectX - proW / 2, rectY - proH / 2, .002, proH + 0.005, tableColor[1], tableColor[2], tableColor[3], 255)
		end

		local textBonus = (self.Events["setBonus"] and self.Events["setBonus"](button, self.Data.currentMenu, self)) or (button.amount and button.amount) or (button.price and "~g~" .. math.floor(button.price) .. "$")
		if textBonus and string.len(textBonus) > 0 then
			DrawText2(0, textBonus, .275, intX + (intW / 2) - .005 - add,  intY - intH / 2 + .00375, tableColor, true, 2)
		end
	else
		drawSprite("commonmenu", "shop_lock", intX + (intW / 2.15), intY, .02, .034, 0.0, tableColor[1], tableColor[2], tableColor[3], 255)
	end
end

local function MultilineFormat(str, size)
	if tostring(str) then
		local PixelPerLine = _intW + .025
		local AggregatePixels = 0
		local output = ""
		local words = stringsplit(tostring(str), " ")

		for i = 1, #words do
			local offset = MeasureStringWidth(words[i], 0, size)
			AggregatePixels = AggregatePixels + offset
			if AggregatePixels > PixelPerLine then
				output = output .. "\n" .. words[i] .. " "
				AggregatePixels = offset + 0.003
			else
				output = output .. words[i] .. " "
				AggregatePixels = AggregatePixels + 0.003
			end
		end

		return output
	end
end

function PMenu:DrawButtons(tableButtons)
	local padding, pd = 0.0175, 0.0475
	for intID, data in ipairs(tableButtons) do
		local shouldDraw = intID >= self.Pag[1] and intID <= self.Pag[2]
		if shouldDraw then
			local boolSelected = intID == self.Pag[3]
			self:drawMenuButton(data, self.Width - _intW / 2, self.Height, boolSelected, _intW, _intH - 0.005, intID)
			self.Height = self.Height + pd - padding
			if not data.locked and boolSelected and IsControlJustPressed(1, 201) and data.name ~= "Vide" and self:canUseButton(data) then
				if self.Events["setCheckbox"] then self.Events["setCheckbox"](self.Data, data) end

				local slideEvent = data.slide or self.Events["onSlide"]
				if slideEvent or data.checkbox ~= nil then
					if not slideEvent then
						data.checkbox = not data.checkbox
					else
						slideEvent(self.Data, data, intID, self)
					end
				end

				local selectFunc, shouldContinue = self.Events["onSelected"], false
				if selectFunc then
					if data.slidemax and not data.slidenum and type(data.slidemax) == "table" then data.slidenum = 1 data.slidename = data.slidemax[1] end
					data.slidenum = data.slidenum or 1

					if data.ask and not data.askX then
						-- data.askValue = nil
						if data.name then AddTextEntry('FMMC_KEY_TIP8', data.askTitle or data.name) end

						local askValue = type(data.ask) == "function" and data.ask(self) or data.ask
						DisplayOnscreenKeyboard(false, "FMMC_KEY_TIP8", "", askValue or "", "", "", "", 60)
						while UpdateOnscreenKeyboard() == 0 do
							Citizen.Wait(50)
							if UpdateOnscreenKeyboard() == 1 and GetOnscreenKeyboardResult() and string.len(GetOnscreenKeyboardResult()) >= 1 then
								data.askValue = GetOnscreenKeyboardResult()
							end
						end
					end

					shouldContinue = selectFunc(self, self.Data, data, self.Pag[3], tableButtons)
				end

				if not shouldContinue and self.Menu[string.lower(data.name)] then
					self:OpenMenu(string.lower(data.name))
				end
			end
		end
	end
end

function setheader(header)
	headername = header
end

function PMenu:DrawHeader(intCount)
	local parentHeader, childHeader = table.unpack(self.Base.Header)
	local boolHeader = parentHeader and string.len(parentHeader) > 0
	local currentMenu = self.Menu[self.Data.currentMenu]
	local stringCounter = currentMenu and currentMenu["customSub"] and currentMenu["customSub"]() or string.format("%s/%s", self.Pag[3], intCount)

	if boolHeader then
		local intH = self.Base.CustomHeader and 0.1025 or spriteH
		drawSprite(parentHeader, childHeader, self.Width - spriteW / 2, self.Height - intH / 2, spriteW, intH, .0, self.Base.HeaderColor[1], self.Base.HeaderColor[2], self.Base.HeaderColor[3], 215)

		self.Height = self.Height - 0.03
		if not self.Base.CustomHeader then
			if self.Base.Title == nil and headername ~= nil then 
				DrawText2(1, headername, .7, self.Width  - spriteW / 2, self.Height - intH / 2 + .0125, color_white, false, 0)
			else
				DrawText2(1, self.Base.Title, .7, self.Width  - spriteW / 2, self.Height - intH / 2 + .0125, color_white, false, 0)
			end
		end 
	end

	self.Height = self.Height + 0.06
	local rectW, rectH = _intW, _intH - .005
	DrawRect(self.Width - rectW / 2, self.Height - rectH / 2, rectW, rectH, self.Base.Color[1], self.Base.Color[2], self.Base.Color[3], 255)

	self.Height = self.Height + 0.005
	DrawText2(0, firstToUpper(self.Data.currentMenu), .275, self.Width - rectW + .005, self.Height - rectH - 0.0015, color_white, true)

	self.Height = self.Height + 0.005
	DrawText2(0, stringCounter, .275, self.Width - rectW / 2 + .11, self.Height - _intH, color_white, true, 2)
	
	if currentMenu and currentMenu.charCreator then
		local spriteW, spriteH = .225, .21
		self.Height = self.Height + spriteH - 0.01
		local back = "pause_menu_pages_char_mom_dad"
		local mumanddad = "char_creator_portraits"
		
		drawSprite(back, "mumdadbg", self.Width - spriteW / 2, self.Height - spriteH / 2, spriteW, spriteH, 0.0, 255, 255, 255, 255)

		if currentMenu.father then
			spriteW, spriteH = .11875, .2111
			drawSprite(mumanddad, currentMenu.father, self.Width - spriteW / 2, self.Height - spriteH / 2, spriteW, spriteH, 0.0, 255, 255, 255, 255)
		end

		if currentMenu.mother then
			spriteW, spriteH = .11875, .2111
			local customX = self.Width - .1
			drawSprite(mumanddad, currentMenu.mother, customX - spriteW / 2, self.Height - spriteH / 2, spriteW, spriteH, 0.0, 255, 255, 255, 255)
			self.Height = self.Height + 0.01
		end
	end
	self.Height = self.Height + 0.005
end

function PMenu:DrawHelpers(tableButtons)
	local menuBase = self.Base
	local currentMenu = self.Data.currentMenu
	local currentButton = tableButtons[self.Pag[3]]

	local strHelp = currentButton and currentButton.Description or self.Menu[currentMenu] and self.Menu[currentMenu].Description or menuBase.Description

	if currentButton and not self:canUseButton(currentButton) then
		strHelp = self:getHelpTextForBlockedButton(currentButton)
	end

	if strHelp then
		local intH, scale = 0.0275, 0.275
		self.Height = self.Height - 0.015

		DrawRect(self.Width - _intW / 2, self.Height, _intW, 0.0025, 0, 0, 0, 255)

		local descText = MultilineFormat(strHelp, scale)
		local linesCount = #stringsplit(descText, "\n")

		local nwintH = intH + linesCount * 0.016
		self.Height = self.Height + intH / 2

		local padding = 0.015
		
		DrawSprite("commonmenu", "gradient_bgd", self.Width - _intW / 2, self.Height + nwintH / 2 - padding, _intW, nwintH, .0, 255, 255, 255, 255)
		DrawText2(0, descText, scale, self.Width - _intW + .005, self.Height - padding + 0.005, color_white)
	end
end

function round(num, numRoundNumber)
	local mult = 10^(numRoundNumber or 0)
	return math.floor(num * mult + 0.5) / mult
  end

function PMenu:DrawExtra(tableButtons)
	local button = tableButtons[self.Pag[3]]
	if not button or not self:canUseButton(button) then return end

	ShowCursorThisFrame()
	DisableControlAction(0, 1, true)
	DisableControlAction(0, 2, true)
	DisableControlAction(0, 24, true)
	DisableControlAction(0, 25, true)

	if button and button.opacity ~= nil then
		local proW, proH = _intW, 0.055
		self.Height =  self.Height - 0.01

		drawSprite("commonmenu", "gradient_bgd", self.Width - proW / 2, self.Height + proH / 2, proW, proH, 0.0, 255, 255, 255, 255)
		self.Height = self.Height + 0.005
		DrawText2(0, "0%", 0.275, self.Width - _intW + .005, self.Height, color_white, false, 1)
		DrawText2(0, "Opacité", 0.275, self.Width - _intW / 2, self.Height, color_white, false, 0)
		DrawText2(0, "100%", 0.275, self.Width - 0.005, self.Height, color_white, false, 2)

		self.Height = self.Height + .033
		local rectW, rectH = .215, 0.015
		local customW = rectW * ( 1 - button.opacity )
		local rectX, rectY = self.Width - rectW / 2 - 0.005, self.Height
		local customX = self.Width - customW / 2 - 0.005
		DrawRect(rectX, rectY, rectW, rectH, 245, 245, 245, 255)
		DrawRect(customX, rectY, customW, rectH, 87, 87, 87, 255)
		-- it is because....
		if IsDisabledControlPressed(0, 24) and IsMouseInBounds(rectX, rectY, rectW, rectH) then
			local mouseXPos = GetControlNormal(0, 239) - proH / 2
			button.opacity = round(math.max(0.0, math.min(1.0, mouseXPos / rectW)), 2)
			self.Events["onSlide"](self.Data, button, self.Pag[3], self)
		end
		self.Height = self.Height + 0.025
	end

	if button and button.advSlider ~= nil then
        local proW, proH = _intW, 0.055
        drawSprite("commonmenu", "gradient_bgd", self.Width - proW / 2, self.Height + proH / 2, proW, proH, 0.0, 255, 255, 255, 255)
        self.Height = self.Height + 0.005
        button.advSlider[3] = button.advSlider[3] or 0
        DrawText2(0, tostring(button.advSlider[1]), 0.275, self.Width - _intW + .005, self.Height, color_white, false, 1)
        DrawText2(0, "Variations disponibles", 0.275, self.Width - _intW / 2, self.Height, color_white, false, 0)
        DrawText2(0, tostring(button.advSlider[2]), 0.275, self.Width - 0.005, self.Height, color_white, false, 2)
        self.Height = self.Height + .03
        drawSprite("commonmenu", "arrowright", self.Width - 0.01, self.Height, .015, .03, 0.0, 255, 255, 255, 255)
        drawSprite("commonmenu", "arrowleft", self.Width - proW + 0.01, self.Height, .015, .03, 0.0, 255, 255, 255, 255)
        local rectW, rectH = .19, 0.015
        local rectX, rectY = self.Width - proW / 2, self.Height
        DrawRect(rectX, rectY, rectW, rectH, 87, 87, 87, 255)
        local sliderW = rectW / (button.advSlider[2] + 1)
        local sliderWFocus = button.advSlider[2] * (sliderW / 2)
        local customX = rectX - sliderWFocus + (sliderW * ( button.advSlider[3] / button.advSlider[2] )) * button.advSlider[2]
        DrawRect(customX, rectY, sliderW, rectH, 245, 245, 245, 255)
        self.Data.advSlider = { self.Width, self.Height, proW }
    end
end

function PMenu:Draw()
	local tableButtons, intCount = table.unpack(self.tempData)
	self.Height = self.Base and self.Base.intY or _intY
	self.Width = self.Base and self.Base.intX or _intX

	if tableButtons and intCount and not self.Invisible then
		self:DrawHeader(intCount) -- 0.03ms
		self:DrawButtons(tableButtons) -- 0.04ms
		self:DrawHelpers(tableButtons) -- 0.00ms

		local currentMenu, currentButton = self.Menu[self.Data.currentMenu], self.Pag[3] and tableButtons and tableButtons[self.Pag[3]]
		if currentMenu and (currentMenu.extra or currentButton and currentButton.opacity) then
			self:DrawExtra(tableButtons)
		end

		if currentMenu and currentMenu.useFilter then
			local keyFilter = 75
			DisableControlAction(1, keyFilter, true)

			if IsDisabledControlJustPressed(1, keyFilter) then
				AskEntry(function(n)
					currentMenu.filter = n and string.len(n) > 0 and string.lower(n) or false
					self:GetButtons()
				end, "Filtre", 30, currentMenu.filter)
			end
		end -- 0.00ms
	end
	if self.Events and self.Events["onRender"] then self.Events["onRender"](self, tableButtons, tableButtons[self.Pag[3]], self.Pag[3]) end
end

function CloseMenu(force)
	return PMenu:CloseMenu(force)
end

function CreateMenu(arrayMenu, tempData)
	return PMenu:CreateMenu(arrayMenu, tempData)
end

function OpenMenu(stringName)
	return PMenu:OpenMenu(stringName)
end

function AskEntry(callback, name, lim, default)
	AddTextEntry('FMMC_KEY_TIP8', name or "Montant")
	DisplayOnscreenKeyboard(false, "FMMC_KEY_TIP8", "", default, "", "", "", lim or 60)

	while UpdateOnscreenKeyboard() == 0 do
		Citizen.Wait(10)
		if UpdateOnscreenKeyboard() >= 1 then
			callback(GetOnscreenKeyboardResult())
			break
		end
	end
end

Citizen.CreateThread(function()
	while true do
		time = 350
		if PMenu.IsVisible then
			time = 0
			PMenu:Draw()
		end
		Citizen.Wait(time)
	end
end)

Citizen.CreateThread(function()
	while true do
		time = 350
		if PMenu.IsVisible and not PMenu.Invisible then
			time = 0
			PMenu:ProcessControl()
		end
		Citizen.Wait(time)
	end
end)

function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

function DrawSub(msg, time)
    ClearPrints()
    BeginTextCommandPrint('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandPrint(time, 1)
end

function KeyboardInput(TextEntry, ExampleText, MaxStringLength)
	AddTextEntry("FMMC_KEY_TIP1", TextEntry)
	DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", ExampleText, "", "", "", MaxStringLength)
	blockinput = true

	while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
		Citizen.Wait(0)
	end

	if UpdateOnscreenKeyboard() ~= 2 then
		local result = GetOnscreenKeyboardResult()
		Citizen.Wait(500)
		blockinput = false
		return result
	else
		Citizen.Wait(500)
		blockinput = false
		return nil
	end
end

function startAttitude(lib, anim)
	ESX.Streaming.RequestAnimSet(lib, function()
		SetPedMovementClipset(PlayerPedId(), anim, true)
	end)
end

function startAnim(lib, anim)
	ESX.Streaming.RequestAnimDict(lib, function()
		TaskPlayAnim(PlayerPedId(), lib, anim, 8.0, -8.0, -1, 0, 0.0, false, false, false)
	end)
end

function startHumeur(lib, anim)
    ped = GetPlayerPed(-1)
    ClearFacialIdleAnimOverride(ped)
    if Index ~= 1 then
        SetFacialIdleAnimOverride(ped, anim, 0)
    end
end

function addped(pedname, name, posx, posy, posz, posh)
	Citizen.CreateThread(function()
		local hash = GetHashKey(pedname)

		while not HasModelLoaded(hash) do
			RequestModel(hash)
			Citizen.Wait(5000)
		end

		local ped = CreatePed("PED_TYPE_CIVFEMALE", pedname, posx, posy, posz, posh, false, true)

		SetBlockingOfNonTemporaryEvents(ped, true)
		FreezeEntityPosition(ped, true)
		SetEntityInvincible(ped, true)

		while true do
			Citizen.Wait(0)
			pedtexte(posx, posy, posz + 2, name)
		end
	end)
end

function pedtexte(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local p = GetGameplayCamCoords()
    local distance = GetDistanceBetweenCoords(p.x, p.y, p.z, x, y, z, 1)
    local scale = (1 / distance) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    local scale = scale * fov
    if onScreen and distance < 8.0 then
        SetTextScale(0.0, 0.25)
        SetTextFont(0)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x,_y)
    end
end

function RefreshMenu(refresh)
	return PMenu:resetMenu(refresh)
end

function saveskin()
    TriggerEvent('skinchanger:getSkin', function(skin)
        TriggerServerEvent('esx_skin:save', skin)
    end)
end

function refreshskin()
    ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
        TriggerEvent('skinchanger:loadSkin', skin)
    end)
end

function changetenue(tshirt_1, tshirt_2, torso_1, torso_2, arms, arms_2, pants_1, pants_2, shoes_1, shoes_2, mask_1, mask_2, glasses_1, glasses_2, watches_1, watches_2, helmet_1, helmet_2, chain_1, chain_2, bags_1, bags_2, bproof_1, bproof_2)
    TriggerEvent('skinchanger:getSkin', function(skin)
        if skin.sex == 0 then
            local clothesSkin = {
                ['tshirt_1'] = tshirt_1, ['tshirt_2'] = tshirt_2,
                ['torso_1'] = torso_1, ['torso_2'] = torso_2,
                ['arms'] = arms, ['arms_2'] = arms_2,
                ['pants_1'] = pants_1, ['pants_2'] = pants_2,
                ['shoes_1'] = shoes_1, ['shoes_2'] = shoes_2,
                ['mask_1'] = mask_1, ['mask_2'] = mask_2,
                ['glasses_1'] = glasses_1, ['glasses_2'] = glasses_2,
                ['watches_1'] = watches_1, ['watches_2'] = watches_2,
                ['helmet_1'] = helmet_1, ['helmet_2'] = helmet_2,
                ['chain_1'] = chain_1, ['chain_2'] = chain_2,
                ['bags_1'] = bags_1, ['bags_2'] = bags_2,
                ['bproof_1'] = bproof_1, ['bproof_2'] = bproof_2,
            }
            TriggerEvent('skinchanger:loadClothes', skin, clothesSkin)
        elseif skin.sex == 1 then
            local clothesSkin = {
                ['tshirt_1'] = tshirt_1, ['tshirt_2'] = tshirt_2,
                ['torso_1'] = torso_1, ['torso_2'] = torso_2,
                ['arms'] = arms, ['arms_2'] = arms_2,
                ['pants_1'] = pants_1, ['pants_2'] = pants_2,
                ['shoes_1'] = shoes_1, ['shoes_2'] = shoes_2,
                ['mask_1'] = mask_1, ['mask_2'] = mask_2,
                ['glasses_1'] = glasses_1, ['glasses_2'] = glasses_2,
                ['watches_1'] = watches_1, ['watches_2'] = watches_2,
                ['helmet_1'] = helmet_1, ['helmet_2'] = helmet_2,
                ['chain_1'] = chain_1, ['chain_2'] = chain_2,
                ['bags_1'] = bags_1, ['bags_2'] = bags_2,
                ['bproof_1'] = bproof_1, ['bproof_2'] = bproof_2,
            }
            TriggerEvent('skinchanger:loadClothes', skin, clothesSkin)
        end
    end)
end

function startUI(time, text) 
	SendNUIMessage({
		type = "ui",
		display = true,
		time = time,
		text = text
	})
end

function LoadingPrompt(loadingText, spinnerType) if IsLoadingPromptBeingDisplayed() then   RemoveLoadingPrompt() end if (loadingText == nil) then BeginTextCommandBusyString(nil)else BeginTextCommandBusyString("STRING");AddTextComponentSubstringPlayerName(loadingText);end EndTextCommandBusyString(spinnerType)end