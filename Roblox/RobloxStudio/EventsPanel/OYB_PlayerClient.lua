local player = game.Players.LocalPlayer
local lighting = game:GetService("Lighting")
local runService = game:GetService("RunService")
local tweenService = game:GetService("TweenService")
local soundService = game:GetService("SoundService")

local oybEventFolder = game.ReplicatedStorage:WaitForChild("OYBEVENT")
local clientEvent = oybEventFolder:WaitForChild("OYB_ClientEvent")
local adminEvent = oybEventFolder:WaitForChild("OYB_AdminEvent")

local Settings = require(game.ReplicatedStorage:WaitForChild("Settings"))

local clientSequenceTicket = 0
local activeDivineClone, activeDivineAnimTrack = nil, nil
local currentActiveEvent = nil
local activeCharacterEventConnections, activeCharacterVisuals, activeCharacterHiddenParts = {}, {}, {}
local cameraConnection, currentTimerConnection, activeTimerGui = nil, nil, nil
local currentPollGui = nil
local activePollId = nil
local pollTimerConnection = nil

local customThemes = {
	Cake = { Ambient = Color3.fromRGB(255, 150, 200), CC = Color3.fromRGB(255, 200, 220), Speed = 20, Size = 3, Rate = 15, Fog = false, RainEmoji = "🍰", Vibe = "Bouncy" },
	Lava = { Ambient = Color3.fromRGB(255, 30, 0), CC = Color3.fromRGB(255, 80, 80), Speed = 50, Size = 6, Rate = 25, Fog = true, FogColor = Color3.new(1,0,0), RainEmoji = "🔥", Vibe = "Fire" },
	Money = { Ambient = Color3.fromRGB(255, 200, 0), CC = Color3.fromRGB(255, 255, 150), Speed = 15, Size = 2.5, Rate = 30, Fog = false, RainEmoji = "💸", Vibe = "Rich" },
	Glitch = { Ambient = Color3.fromRGB(0, 255, 50), CC = Color3.fromRGB(100, 255, 100), Speed = 80, Size = 1.5, Rate = 50, Fog = false, RainEmoji = "👾", Vibe = "Glitchy" },
	Winter = { Ambient = Color3.fromRGB(200, 220, 255), CC = Color3.fromRGB(255, 255, 255), Speed = 8, Size = 1.5, Rate = 60, Fog = true, FogColor = Color3.new(1,1,1), RainEmoji = "❄️", Vibe = "Cold" },
	Acid = { Ambient = Color3.fromRGB(150, 0, 255), CC = Color3.fromRGB(200, 100, 255), Speed = 18, Size = 4, Rate = 15, Fog = true, FogColor = Color3.fromRGB(100,0,150), RainEmoji = "☣️", Vibe = "Poison" },
	Heart = { Ambient = Color3.fromRGB(255, 150, 150), CC = Color3.fromRGB(255, 200, 200), Speed = 10, Size = 2.5, Rate = 20, Fog = false, RainEmoji = "💖", Vibe = "Floaty" },
	Ocean = { Ambient = Color3.fromRGB(0, 100, 255), CC = Color3.fromRGB(100, 150, 255), Speed = 20, Size = 2, Rate = 40, Fog = true, FogColor = Color3.fromRGB(0,50,150), RainEmoji = "🫧", Vibe = "Underwater" },
	Shadow = { Ambient = Color3.fromRGB(10, 0, 0), CC = Color3.fromRGB(80, 30, 30), Clock = 0, Speed = 6, Size = 5, Rate = 8, Fog = true, FogColor = Color3.new(0,0,0), RainEmoji = "👁️", Vibe = "Scary" },
	Alien = { Ambient = Color3.fromRGB(50, 255, 100), CC = Color3.fromRGB(150, 255, 200), Speed = 25, Size = 3, Rate = 25, Fog = false, RainEmoji = "🛸", Vibe = "UFO" }
}

local eventsData = {
	Taco = { musicId = "rbxassetid://93810409296175", animId = "rbxassetid://507776043", emoji = "🌮" },
	MemeParty = { musicId = "rbxassetid://76662809515638", animId = "rbxassetid://507777623", emoji = "🧠" },
	Party = { musicId = "rbxassetid://140245756477343", animId = "rbxassetid://507771019", emoji = "🎉" },
	Zombie = { musicId = "rbxassetid://138112098699544", animId = nil, emoji = "🧟" },
	Space = { musicId = "rbxassetid://1842712396", animId = nil, emoji = "🌌" },
	Anime = { musicId = "rbxassetid://140504265985079", animId = "rbxassetid://3337994105", emoji = "🔥" }
}

local memePartyImages = {"rbxassetid://95934746711773", "rbxassetid://87747014552943", "rbxassetid://84943239102297"}
local activeEffects, activeAnimations, currentSound, currentEventConnection = {}, {}, nil, nil

local originalLighting = {
	Ambient = lighting.Ambient, Brightness = lighting.Brightness, ClockTime = lighting.ClockTime,
	FogEnd = lighting.FogEnd, FogColor = lighting.FogColor
}

local function getOrCreateMessagesContainer()
	local gui = player:WaitForChild("PlayerGui"):FindFirstChild("OYB_GlobalAnnouncements")
	if not gui then
		gui = Instance.new("ScreenGui")
		gui.Name = "OYB_GlobalAnnouncements"
		gui.ResetOnSpawn = false
		gui.IgnoreGuiInset = true
		gui.Parent = player.PlayerGui
		local container = Instance.new("Frame")
		container.Name = "MessagesContainer"
		container.Size = UDim2.new(0.9, 0, 0.3, 0)
		container.Position = UDim2.new(0.5, 0, 0.02, 0)
		container.AnchorPoint = Vector2.new(0.5, 0)
		container.BackgroundTransparency = 1
		container.Parent = gui
		local sizeConstraint = Instance.new("UISizeConstraint")
		sizeConstraint.MaxSize = Vector2.new(600, 300)
		sizeConstraint.Parent = container
		local layout = Instance.new("UIListLayout")
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, 2)
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.Parent = container
	end
	return gui:FindFirstChild("MessagesContainer")
end

local messagesContainer = getOrCreateMessagesContainer()

local function showEventTimer(emoji)
	if activeTimerGui then activeTimerGui:Destroy(); activeTimerGui = nil end
	if currentTimerConnection then currentTimerConnection:Disconnect(); currentTimerConnection = nil end
	local gui = Instance.new("ScreenGui")
	gui.Name = "OYB_EventTimer"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")
	activeTimerGui = gui
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 120, 0, 40)
	frame.Position = UDim2.new(0, -150, 1, -20)
	frame.AnchorPoint = Vector2.new(0, 1)
	frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	frame.BackgroundTransparency = 0.2
	frame.Parent = gui
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
	local stroke = Instance.new("UIStroke", frame)
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Transparency = 0.8
	stroke.Thickness = 1.5
	local emojiLbl = Instance.new("TextLabel", frame)
	emojiLbl.Size = UDim2.new(0.4, 0, 1, 0)
	emojiLbl.BackgroundTransparency = 1
	emojiLbl.Text = emoji
	emojiLbl.TextScaled = true
	local timeLbl = Instance.new("TextLabel", frame)
	timeLbl.Size = UDim2.new(0.6, 0, 1, -10)
	timeLbl.Position = UDim2.new(0.4, 0, 0, 5)
	timeLbl.BackgroundTransparency = 1
	timeLbl.Text = "..."
	timeLbl.TextColor3 = Color3.new(1, 1, 1)
	timeLbl.Font = Enum.Font.GothamBold
	timeLbl.TextScaled = true
	tweenService:Create(frame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0, 20, 1, -20)}):Play()
	currentTimerConnection = runService.RenderStepped:Connect(function()
		if currentSound and currentSound.IsLoaded and currentSound.TimeLength > 0 then
			local remaining = math.max(0, currentSound.TimeLength - currentSound.TimePosition)
			timeLbl.Text = string.format("%02d:%02d", math.floor(remaining / 60), math.floor(remaining % 60))
		else
			timeLbl.Text = "..."
		end
	end)
end

local function hideDivineCloneInstantly()
	if cameraConnection then cameraConnection:Disconnect(); cameraConnection = nil end
	if activeDivineAnimTrack then activeDivineAnimTrack:Stop(); activeDivineAnimTrack = nil end
	if activeDivineClone then activeDivineClone:Destroy(); activeDivineClone = nil end
	local cam = workspace.CurrentCamera
	if cam and cam.CameraType == Enum.CameraType.Scriptable then
		cam.CameraType = Enum.CameraType.Custom
		local char = player.Character
		if char and char:FindFirstChild("Humanoid") then cam.CameraSubject = char.Humanoid end
	end
end

local function cleanupCharacterEffects(charId)
	if activeCharacterEventConnections[charId] then activeCharacterEventConnections[charId]:Disconnect(); activeCharacterEventConnections[charId] = nil end
	if activeCharacterHiddenParts[charId] then
		for _, data in ipairs(activeCharacterHiddenParts[charId]) do
			if data.part and data.part.Parent then
				if data.origTrans then data.part.Transparency = data.origTrans end
				if data.origColor then data.part.Color = data.origColor end
			elseif data.inst then
				data.inst.Parent = data.parent
			elseif data.animTrack then
				data.animTrack.AnimationId = data.origId
			end
		end
		activeCharacterHiddenParts[charId] = nil
	end
	if activeCharacterVisuals[charId] then
		for _, obj in ipairs(activeCharacterVisuals[charId]) do if obj and obj.Parent then obj:Destroy() end end
		activeCharacterVisuals[charId] = nil
	end
end

local function stopAllEvents()
	currentActiveEvent = nil
	hideDivineCloneInstantly()
	if currentEventConnection then currentEventConnection:Disconnect(); currentEventConnection = nil end
	for _, p in ipairs(game.Players:GetPlayers()) do
		cleanupCharacterEffects(tostring(p.UserId))
		if p.Character then
			local hum = p.Character:FindFirstChild("Humanoid")
			if hum then hum.JumpPower = 50; hum.UseJumpPower = false end
			local hrp = p.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local bv = hrp:FindFirstChild("AirSwimBV")
				if bv then bv:Destroy() end
			end
		end
	end
	for _, v in ipairs(workspace:GetChildren()) do
		if v.Name == "OYB_Rain" or v.Name == "CustomEmojiRain" then
			v:Destroy()
		end
	end
	workspace.Gravity = 196.2
	local cam = workspace.CurrentCamera
	if cam then cam.FieldOfView = 70 end
	if currentTimerConnection then currentTimerConnection:Disconnect(); currentTimerConnection = nil end
	if activeTimerGui then
		local oldTimerGui = activeTimerGui
		activeTimerGui = nil
		local frame = oldTimerGui:FindFirstChildOfClass("Frame")
		if frame then tweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.new(0, -150, 1, -20)}):Play() end
		task.delay(0.6, function() if oldTimerGui then oldTimerGui:Destroy() end end)
	end
	if currentSound then
		local snd = currentSound; currentSound = nil
		tweenService:Create(snd, TweenInfo.new(1), {Volume = 0}):Play()
		task.delay(1, function() if snd then snd:Destroy() end end)
	end
	tweenService:Create(lighting, TweenInfo.new(3, Enum.EasingStyle.Sine), originalLighting):Play()
	for _, effect in ipairs(activeEffects) do
		if effect:IsA("SunRaysEffect") then tweenService:Create(effect, TweenInfo.new(3), {Intensity = 0}):Play()
		elseif effect:IsA("ColorCorrectionEffect") then tweenService:Create(effect, TweenInfo.new(3), {TintColor = Color3.fromRGB(255, 255, 255)}):Play()
		elseif effect:IsA("BlurEffect") then tweenService:Create(effect, TweenInfo.new(3), {Size = 0}):Play()
		elseif effect:IsA("BloomEffect") then tweenService:Create(effect, TweenInfo.new(3), {Intensity = 0}):Play() end
		task.delay(3.1, function() if effect then effect:Destroy() end end)
	end
	activeEffects = {}
	for _, anim in ipairs(activeAnimations) do if anim then anim:Stop() end end
	activeAnimations = {}
end

local function setupSingleCharacterEventEffects(targetPlayer, eventData)
	if not targetPlayer or not targetPlayer.Character then return end
	local character = targetPlayer.Character
	local humanoid = character:WaitForChild("Humanoid", 5)
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if not humanoid or not hrp then return end
	local charId = tostring(targetPlayer.UserId)
	cleanupCharacterEffects(charId)
	activeCharacterVisuals[charId] = {}
	activeCharacterHiddenParts[charId] = {}
	local isCustom = type(eventData) == "table"
	local eventName = isCustom and eventData.Theme or eventData
	local targetAnimId = isCustom and eventData.AnimId or (eventsData[eventName] and eventsData[eventName].animId)
	local loadedAnim = nil

	if targetAnimId then
		local anim = Instance.new("Animation")
		anim.AnimationId = targetAnimId
		loadedAnim = humanoid:LoadAnimation(anim)
		loadedAnim.Looped = true
		if eventName == "Anime" then
			loadedAnim.Priority = Enum.AnimationPriority.Action4
			loadedAnim:Play() 
		else
			loadedAnim.Priority = Enum.AnimationPriority.Action
		end
		table.insert(activeAnimations, loadedAnim)
	end

	if isCustom and customThemes[eventName] then
		local vibe = customThemes[eventName].Vibe
		if vibe == "Fire" then
			local fire = Instance.new("Fire", hrp)
			fire.Size = 6
			fire.Heat = 15
			table.insert(activeCharacterVisuals[charId], fire)
		elseif vibe == "Bouncy" then
			local sparkles = Instance.new("Sparkles", hrp)
			sparkles.SparkleColor = Color3.new(1, 0.5, 0.8)
			table.insert(activeCharacterVisuals[charId], sparkles)
		elseif vibe == "Rich" then
			local p = Instance.new("ParticleEmitter", hrp)
			p.Texture = "rbxassetid://134456042" 
			p.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
			p.Rate = 15; p.Speed = NumberRange.new(2, 5)
			table.insert(activeCharacterVisuals[charId], p)
		elseif vibe == "Cold" then
			local p = Instance.new("ParticleEmitter", hrp)
			p.Texture = "rbxassetid://243660364" 
			p.Color = ColorSequence.new(Color3.new(1, 1, 1))
			p.Rate = 20; p.Speed = NumberRange.new(1, 3)
			table.insert(activeCharacterVisuals[charId], p)
		elseif vibe == "Poison" then
			local p = Instance.new("ParticleEmitter", hrp)
			p.Texture = "rbxassetid://243660364"
			p.Color = ColorSequence.new(Color3.fromRGB(100, 255, 100))
			p.Rate = 25; p.Speed = NumberRange.new(3, 6)
			p.EmissionDirection = Enum.NormalId.Top
			table.insert(activeCharacterVisuals[charId], p)
		elseif vibe == "Floaty" then
			local att0 = Instance.new("Attachment", hrp); att0.Position = Vector3.new(0, 1, 0)
			local att1 = Instance.new("Attachment", hrp); att1.Position = Vector3.new(0, -1, 0)
			local trail = Instance.new("Trail", hrp)
			trail.Attachment0 = att0; trail.Attachment1 = att1
			trail.Color = ColorSequence.new(Color3.fromRGB(255, 105, 180))
			trail.Lifetime = 1
			table.insert(activeCharacterVisuals[charId], att0); table.insert(activeCharacterVisuals[charId], att1); table.insert(activeCharacterVisuals[charId], trail)
		elseif vibe == "Underwater" then
			local p = Instance.new("ParticleEmitter", hrp)
			p.Texture = "rbxassetid://243660364"
			p.Color = ColorSequence.new(Color3.fromRGB(150, 200, 255))
			p.Rate = 15; p.Speed = NumberRange.new(2, 4); p.EmissionDirection = Enum.NormalId.Top
			table.insert(activeCharacterVisuals[charId], p)
		elseif vibe == "Scary" then
			local light = Instance.new("PointLight", character:FindFirstChild("Head") or hrp)
			light.Color = Color3.new(1, 0, 0); light.Range = 12; light.Brightness = 2
			table.insert(activeCharacterVisuals[charId], light)
		elseif vibe == "UFO" then
			local light = Instance.new("SpotLight", hrp)
			light.Color = Color3.new(0, 1, 0); light.Angle = 60; light.Face = Enum.NormalId.Top; light.Brightness = 3
			table.insert(activeCharacterVisuals[charId], light)
		elseif vibe == "Glitchy" then
			local hl = Instance.new("Highlight", character)
			hl.FillColor = Color3.new(0, 1, 0); hl.OutlineColor = Color3.new(1, 1, 1)
			table.insert(activeCharacterVisuals[charId], hl)
		end
	end

	local rainPart = nil
	if eventName == "MemeParty" then
		rainPart = Instance.new("Part")
		rainPart.Name = "OYB_Rain"
		rainPart.Size, rainPart.Anchored, rainPart.CanCollide, rainPart.Transparency, rainPart.Massless = Vector3.new(300, 1, 300), true, false, 1, true
		rainPart.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 80, 0))
		rainPart.Parent = workspace
		for _, img in ipairs(memePartyImages) do
			local emitter = Instance.new("ParticleEmitter", rainPart)
			emitter.Texture, emitter.Rate, emitter.Lifetime, emitter.Speed, emitter.EmissionDirection, emitter.RotSpeed = img, 12, NumberRange.new(6, 10), NumberRange.new(20, 30), Enum.NormalId.Bottom, NumberRange.new(-20, 20)
			emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 4), NumberSequenceKeypoint.new(1, 4)}) 
		end
		table.insert(activeCharacterVisuals[charId], rainPart)

	elseif eventName == "Zombie" then
		for _, obj in ipairs(character:GetDescendants()) do
			if obj:IsA("Accessory") or obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic") or obj:IsA("CharacterMesh") then
				table.insert(activeCharacterHiddenParts[charId], {inst = obj, parent = obj.Parent})
				obj.Parent = nil
			elseif obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" then
				table.insert(activeCharacterHiddenParts[charId], {part = obj, origColor = obj.Color, origTrans = obj.Transparency})
				local n = obj.Name:lower()
				if n:find("torso") or n:find("leg") or n:find("foot") then
					obj.Color = Color3.fromRGB(101, 67, 33)
				else
					obj.Color = Color3.fromRGB(100, 160, 100)
				end
			end
		end
		local hl = Instance.new("Highlight", character)
		hl.FillColor = Color3.fromRGB(0, 255, 0)
		hl.FillTransparency = 0.95
		hl.OutlineColor = Color3.fromRGB(0, 50, 0)
		table.insert(activeCharacterVisuals[charId], hl)

		local animateScript = character:FindFirstChild("Animate")
		if animateScript then
			local zombieAnims = {
				idle = "rbxassetid://616158929",
				walk = "rbxassetid://616168032",
				run = "rbxassetid://616163682",
				jump = "rbxassetid://616161997",
				fall = "rbxassetid://616157476",
				climb = "rbxassetid://616156119"
			}
			for animName, newId in pairs(zombieAnims) do
				local animFolder = animateScript:FindFirstChild(animName)
				if animFolder then
					for _, child in ipairs(animFolder:GetChildren()) do
						if child:IsA("Animation") then
							table.insert(activeCharacterHiddenParts[charId], {animTrack = child, origId = child.AnimationId})
							child.AnimationId = newId
						end
					end
				end
			end
		end

	elseif eventName == "Anime" and not isCustom then
		local customAuraModel = oybEventFolder:FindFirstChild("AnimeAura")
		if customAuraModel then
			for _, effect in ipairs(customAuraModel:GetDescendants()) do
				if effect:IsA("ParticleEmitter") or effect:IsA("Trail") or effect:IsA("Beam") or effect:IsA("PointLight") or effect:IsA("Highlight") then
					local cloneEffect = effect:Clone()
					cloneEffect.Parent = hrp
					if cloneEffect:IsA("ParticleEmitter") then cloneEffect.Enabled = true end
					table.insert(activeCharacterVisuals[charId], cloneEffect)
				end
			end
		end
	end

	local idleTime = 0
	activeCharacterEventConnections[charId] = runService.Heartbeat:Connect(function(dt)
		if not character or not humanoid or not hrp or not hrp.Parent then return end
		if eventName == "MemeParty" and rainPart then rainPart.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 80, 0)) end

		if humanoid.Health > 0 and loadedAnim then
			if eventName == "Anime" then
				if not loadedAnim.IsPlaying then loadedAnim:Play() end
			else
				if humanoid.MoveDirection.Magnitude > 0.1 then
					idleTime = 0
					if loadedAnim.IsPlaying then loadedAnim:Stop(0.3) end
				else
					idleTime = idleTime + dt
					if idleTime >= 3 and not loadedAnim.IsPlaying then loadedAnim:Play(0.3) end
				end
			end
		end
	end)
end

local function setupAllCharactersEventEffects(eventData)
	for _, p in ipairs(game.Players:GetPlayers()) do setupSingleCharacterEventEffects(p, eventData) end
end

game.Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(function(newChar)
		if currentActiveEvent then
			task.wait(0.5); setupSingleCharacterEventEffects(p, currentActiveEvent)
			local isCustom = type(currentActiveEvent) == "table"
			local eventName = isCustom and currentActiveEvent.Theme or currentActiveEvent
			if eventName == "Space" then
				local hum = newChar:WaitForChild("Humanoid", 3)
				if hum then hum.UseJumpPower = true; hum.JumpPower = 85 end
			end
		end
	end)
end)

for _, p in ipairs(game.Players:GetPlayers()) do
	p.CharacterAdded:Connect(function(newChar)
		if currentActiveEvent then
			task.wait(0.5); setupSingleCharacterEventEffects(p, currentActiveEvent)
			local isCustom = type(currentActiveEvent) == "table"
			local eventName = isCustom and currentActiveEvent.Theme or currentActiveEvent
			if eventName == "Space" then
				local hum = newChar:WaitForChild("Humanoid", 3)
				if hum then hum.UseJumpPower = true; hum.JumpPower = 85 end
			end
		end
	end)
end

local function executeEventLogic(eventData, timeOffset)
	local myTicket = clientSequenceTicket
	currentActiveEvent = eventData

	local isCustom = type(eventData) == "table"
	local eventName = isCustom and eventData.Theme or eventData
	setupAllCharactersEventEffects(eventData)

	local targetMusicId = isCustom and eventData.MusicId or (eventsData[eventName] and eventsData[eventName].musicId)
	local targetEmoji = isCustom and eventData.Emoji or (eventsData[eventName] and eventsData[eventName].emoji or "✨")

	if targetMusicId then
		currentSound = Instance.new("Sound")
		currentSound.SoundId = targetMusicId
		currentSound.Parent = soundService 
		showEventTimer(targetEmoji)

		task.spawn(function()
			local waitTime = 0
			while not currentSound.IsLoaded and waitTime < 15 do task.wait(0.2); waitTime = waitTime + 0.2 end
			if currentSound.IsLoaded then
				if timeOffset and timeOffset > 0 and timeOffset < currentSound.TimeLength then currentSound.TimePosition = timeOffset end
				currentSound:Play() 
				local endedConn; endedConn = currentSound.Ended:Connect(function()
					if endedConn then endedConn:Disconnect() end
					if clientSequenceTicket == myTicket then 
						stopAllEvents() 
						adminEvent:FireServer("AutoStop") 
					end
				end)
				if currentSound.TimeLength > 0 then 
					task.delay(currentSound.TimeLength + 3, function() 
						if clientSequenceTicket == myTicket then 
							stopAllEvents() 
							adminEvent:FireServer("AutoStop")
						end 
					end) 
				end
			else if clientSequenceTicket == myTicket then stopAllEvents() end end
		end)
	end

	if customThemes[eventName] then
		local theme = customThemes[eventName]
		local vibe = theme.Vibe

		if vibe == "Floaty" or vibe == "UFO" then
			workspace.Gravity = 50
			for _, p in ipairs(game.Players:GetPlayers()) do
				local hum = p.Character and p.Character:FindFirstChild("Humanoid")
				if hum then hum.UseJumpPower = true; hum.JumpPower = 70 end
			end
		elseif vibe == "Cold" then
			workspace.Gravity = 100
		elseif vibe == "Bouncy" then
			workspace.Gravity = 120
			for _, p in ipairs(game.Players:GetPlayers()) do
				local hum = p.Character and p.Character:FindFirstChild("Humanoid")
				if hum then hum.UseJumpPower = true; hum.JumpPower = 90 end
			end
		end

		local lightParams = { Ambient = theme.Ambient, ClockTime = theme.Clock or 14 }
		if theme.Fog then lightParams.FogEnd = (vibe=="Scary" and 40 or 150); lightParams.FogColor = theme.FogColor else lightParams.FogEnd = 100000 end
		tweenService:Create(lighting, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), lightParams):Play()

		local cc = Instance.new("ColorCorrectionEffect", lighting)
		cc.TintColor = theme.CC
		table.insert(activeEffects, cc)

		if vibe == "Poison" or vibe == "Scary" then
			local blur = Instance.new("BlurEffect", lighting)
			blur.Size = 0
			table.insert(activeEffects, blur)
			tweenService:Create(blur, TweenInfo.new(2, Enum.EasingStyle.Sine), {Size = (vibe=="Scary" and 12 or 8)}):Play()
		end

		local rainFolder = Instance.new("Folder")
		rainFolder.Name = "CustomEmojiRain"
		rainFolder.Parent = workspace
		table.insert(activeEffects, rainFolder)

		task.spawn(function()
			local cam = workspace.CurrentCamera
			local origFOV = cam.FieldOfView
			local uis = game:GetService("UserInputService")

			while currentActiveEvent == eventData and clientSequenceTicket == myTicket do
				if vibe == "Glitchy" then
					cc.TintColor = Color3.fromRGB(math.random(220, 255), 255, math.random(220, 255))
					cam.FieldOfView = origFOV + math.random(-1, 1)
				end

				if vibe == "Underwater" and player.Character then
					local hrp = player.Character:FindFirstChild("HumanoidRootPart")
					local hum = player.Character:FindFirstChild("Humanoid")
					if hrp and hum and hum.Health > 0 then
						if hum.FloorMaterial == Enum.Material.Air then
							local bv = hrp:FindFirstChild("AirSwimBV")
							if not bv then
								bv = Instance.new("BodyVelocity")
								bv.Name = "AirSwimBV"
								bv.MaxForce = Vector3.new(100000, 100000, 100000)
								bv.Parent = hrp
							end
							local isJumping = hum.Jump or uis:IsKeyDown(Enum.KeyCode.Space)
							local upForce = isJumping and 35 or -5
							bv.Velocity = hum.MoveDirection * 35 + Vector3.new(0, upForce, 0)
						else
							local bv = hrp:FindFirstChild("AirSwimBV")
							if bv then bv:Destroy() end
						end
					end
				end

				if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					local hrpPos = player.Character.HumanoidRootPart.Position
					local dropPart = Instance.new("Part")
					dropPart.Size, dropPart.Transparency, dropPart.CanCollide = Vector3.new(1,1,1), 1, false

					local isGoingUp = (vibe == "Floaty" or vibe == "Underwater")
					local spawnHeight = isGoingUp and -60 or 100

					dropPart.Position = hrpPos + Vector3.new(math.random(-150, 150), spawnHeight, math.random(-150, 150))
					dropPart.Parent = rainFolder

					local bg = Instance.new("BillboardGui", dropPart)
					bg.Size = UDim2.new(theme.Size, 0, theme.Size, 0)
					bg.AlwaysOnTop = false
					bg.LightInfluence = 0
					local textLabel = Instance.new("TextLabel", bg)

					textLabel.Size, textLabel.BackgroundTransparency, textLabel.Text, textLabel.TextScaled = UDim2.new(1,0,1,0), 1, theme.RainEmoji, true

					local fallDuration = 100 / theme.Speed
					local targetPos = isGoingUp and (dropPart.Position + Vector3.new(0, 180, 0)) or (dropPart.Position - Vector3.new(0, 140, 0))

					tweenService:Create(dropPart, TweenInfo.new(fallDuration, Enum.EasingStyle.Linear), {Position = targetPos}):Play()
					game.Debris:AddItem(dropPart, fallDuration)
				end
				task.wait(1 / theme.Rate) 
			end

			if vibe == "Glitchy" then cam.FieldOfView = origFOV end
			if vibe == "Underwater" and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local bv = player.Character.HumanoidRootPart:FindFirstChild("AirSwimBV")
				if bv then bv:Destroy() end
			end
		end)
	end

	if eventsData[eventName] then
		if eventName == "Taco" then
			local cc = Instance.new("ColorCorrectionEffect", lighting); table.insert(activeEffects, cc)
			local hue = 0; currentEventConnection = runService.RenderStepped:Connect(function(dt) hue = (hue + (dt * 20)) % 360; cc.TintColor = Color3.fromHSV(hue/360, 0.2, 1) end)
		elseif eventName == "Party" then 
			tweenService:Create(lighting, TweenInfo.new(4), { ClockTime = 17.5, Ambient = Color3.fromRGB(200, 150, 120) }):Play()
			local sun = Instance.new("SunRaysEffect", lighting); sun.Intensity = 0; table.insert(activeEffects, sun); tweenService:Create(sun, TweenInfo.new(4), {Intensity = 0.25}):Play()
			local cc = Instance.new("ColorCorrectionEffect", lighting); cc.TintColor = Color3.fromRGB(255, 255, 255); table.insert(activeEffects, cc); tweenService:Create(cc, TweenInfo.new(4), {TintColor = Color3.fromRGB(255, 220, 190)}):Play()
		elseif eventName == "Zombie" then
			local cc = Instance.new("ColorCorrectionEffect", lighting); cc.TintColor = Color3.fromRGB(210, 230, 210); cc.Saturation = -0.2; table.insert(activeEffects, cc)
			tweenService:Create(lighting, TweenInfo.new(3), {ClockTime = 4, Ambient = Color3.fromRGB(90, 100, 90), FogEnd = 500, FogColor = Color3.fromRGB(40, 50, 40)}):Play()
		elseif eventName == "Space" then
			workspace.Gravity = 25 
			for _, p in ipairs(game.Players:GetPlayers()) do
				local hum = p.Character and p.Character:FindFirstChild("Humanoid")
				if hum then hum.UseJumpPower = true; hum.JumpPower = 85 end
			end
			tweenService:Create(lighting, TweenInfo.new(3), { ClockTime = 0, Ambient = Color3.fromRGB(120, 50, 200), Brightness = 1 }):Play()
			local cc = Instance.new("ColorCorrectionEffect", lighting); cc.TintColor, cc.Contrast = Color3.fromRGB(200, 150, 255), 0.1; table.insert(activeEffects, cc)
		elseif eventName == "Anime" then
			local cc = Instance.new("ColorCorrectionEffect", lighting); table.insert(activeEffects, cc)
			tweenService:Create(lighting, TweenInfo.new(2), { ClockTime = 12, Ambient = Color3.fromRGB(255, 100, 50) }):Play()
			tweenService:Create(cc, TweenInfo.new(2), {TintColor = Color3.fromRGB(255, 200, 150), Contrast = 0.2}):Play()
		end
	end
end

local function closePollGui(isInstant)
	if pollTimerConnection then pollTimerConnection:Disconnect(); pollTimerConnection = nil end
	if currentPollGui then
		local guiToDestroy = currentPollGui
		currentPollGui = nil
		if isInstant then
			guiToDestroy:Destroy()
		else
			local frame = guiToDestroy:FindFirstChild("MainFrame")
			if frame then
				tweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.new(0.5, 0, -0.5, 0)}):Play()
			end
			task.delay(0.6, function() if guiToDestroy then guiToDestroy:Destroy() end end)
		end
	end
end

clientEvent.OnClientEvent:Connect(function(action, data)
	if action == "ShowAnnouncement" then
		local notifySound = Instance.new("Sound")
		notifySound.SoundId = "rbxassetid://137402801272072"
		notifySound.Volume = 1.5
		notifySound.Parent = soundService
		notifySound:Play()
		game.Debris:AddItem(notifySound, 3)

		local newMsg = Instance.new("TextLabel")
		newMsg.Size = UDim2.new(1, 0, 0, 30) 
		newMsg.BackgroundTransparency = 1
		newMsg.TextStrokeTransparency = 0 
		newMsg.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		newMsg.TextScaled = true
		newMsg.RichText = true 
		newMsg.Font = Enum.Font.GothamBlack
		newMsg.Text = data
		newMsg.Parent = messagesContainer

		local textConstraint = Instance.new("UITextSizeConstraint")
		textConstraint.MaxTextSize = 26
		textConstraint.MinTextSize = 12
		textConstraint.Parent = newMsg

		task.delay(7, function()
			if newMsg then 
				tweenService:Create(newMsg, TweenInfo.new(0.5), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
				task.delay(0.5, function() newMsg:Destroy() end)
			end 
		end)

	elseif action == "StartPoll" then
		closePollGui(true) 
		activePollId = data.PollId

		local pollSound = Instance.new("Sound", soundService)
		pollSound.SoundId = "rbxassetid://6003730248"
		pollSound.Volume = 1.5
		pollSound:Play()
		game.Debris:AddItem(pollSound, 4)

		local gui = Instance.new("ScreenGui")
		gui.Name = "OYB_PollGui"
		gui.ResetOnSpawn = false
		gui.IgnoreGuiInset = true 
		gui.Parent = player:WaitForChild("PlayerGui")
		currentPollGui = gui

		local mainFrame = Instance.new("Frame", gui)
		mainFrame.Name = "MainFrame"
		mainFrame.Size = UDim2.new(0.35, 0, 0, 0) 
		mainFrame.Position = UDim2.new(0.5, 0, -0.5, 0) 
		mainFrame.AnchorPoint = Vector2.new(0.5, 0)
		mainFrame.BackgroundTransparency = 1
		mainFrame.AutomaticSize = Enum.AutomaticSize.Y 

		local sizeConst = Instance.new("UISizeConstraint", mainFrame)
		sizeConst.MaxSize = Vector2.new(450, 200) 
		sizeConst.MinSize = Vector2.new(260, 90) 

		local layout = Instance.new("UIListLayout", mainFrame)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, 3) 
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

		local topBarContainer = Instance.new("Frame", mainFrame)
		topBarContainer.Name = "TopBarContainer"
		topBarContainer.LayoutOrder = 1
		topBarContainer.Size = UDim2.new(1, -10, 0, 15) 
		topBarContainer.BackgroundTransparency = 1

		local senderLbl = Instance.new("TextLabel", topBarContainer)
		senderLbl.Size = UDim2.new(0.8, 0, 1, 0)
		senderLbl.BackgroundTransparency = 1
		local prefix = data.IsOwner and "<font color='#ff3333'>(Owner)</font> " or ""
		senderLbl.Text = string.format("%s<font color='#ffffff'>%s</font>", prefix, data.SenderName)
		senderLbl.RichText = true
		senderLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		senderLbl.TextStrokeTransparency = 0 
		senderLbl.Font = Enum.Font.GothamBlack
		senderLbl.TextScaled = true
		senderLbl.TextXAlignment = Enum.TextXAlignment.Left

		local timerLbl = Instance.new("TextLabel", topBarContainer)
		timerLbl.Name = "TimerLbl"
		timerLbl.Size = UDim2.new(0.2, 0, 1, 0)
		timerLbl.Position = UDim2.new(0.8, 0, 0, 0)
		timerLbl.BackgroundTransparency = 1
		timerLbl.Text = tostring(data.Duration) .. "s"
		timerLbl.TextColor3 = Color3.fromRGB(255, 80, 80)
		timerLbl.TextStrokeTransparency = 0
		timerLbl.Font = Enum.Font.GothamBlack
		timerLbl.TextScaled = true
		timerLbl.TextXAlignment = Enum.TextXAlignment.Right

		local questionLbl = Instance.new("TextLabel", mainFrame)
		questionLbl.LayoutOrder = 2
		questionLbl.Size = UDim2.new(1, -10, 0, 20) 
		questionLbl.BackgroundTransparency = 1
		questionLbl.Text = data.Question
		questionLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		questionLbl.TextStrokeTransparency = 0
		questionLbl.Font = Enum.Font.GothamBlack
		questionLbl.TextScaled = true
		questionLbl.TextWrapped = true 
		questionLbl.AutomaticSize = Enum.AutomaticSize.Y

		local qTextConst = Instance.new("UITextSizeConstraint", questionLbl)
		qTextConst.MaxTextSize = 16 

		local barContainer = Instance.new("Frame", mainFrame)
		barContainer.Name = "BarContainer"
		barContainer.LayoutOrder = 3
		barContainer.Size = UDim2.new(0.9, 0, 0, 25) 
		barContainer.BackgroundTransparency = 1

		local barBg = Instance.new("Frame", barContainer)
		barBg.Name = "BarBg"
		barBg.Size = UDim2.new(1, 0, 0, 10) 
		barBg.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
		local uiStrokeBar = Instance.new("UIStroke", barBg)
		uiStrokeBar.Thickness = 1.5
		uiStrokeBar.Color = Color3.new(0, 0, 0)
		Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

		local barFill = Instance.new("Frame", barBg)
		barFill.Name = "BarFill"
		barFill.Size = UDim2.new(0.5, 0, 1, 0)
		barFill.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
		Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

		local voteCount1 = Instance.new("TextLabel", barContainer)
		voteCount1.Name = "VoteCount1"
		voteCount1.Size = UDim2.new(0.5, 0, 0, 12)
		voteCount1.Position = UDim2.new(0, 0, 0, 13)
		voteCount1.BackgroundTransparency = 1
		voteCount1.Text = "0"
		voteCount1.TextColor3 = Color3.fromRGB(150, 200, 255)
		voteCount1.TextStrokeTransparency = 0
		voteCount1.Font = Enum.Font.GothamBold
		voteCount1.TextScaled = true
		voteCount1.TextXAlignment = Enum.TextXAlignment.Left

		local voteCount2 = Instance.new("TextLabel", barContainer)
		voteCount2.Name = "VoteCount2"
		voteCount2.Size = UDim2.new(0.5, 0, 0, 12)
		voteCount2.Position = UDim2.new(0.5, 0, 0, 13)
		voteCount2.BackgroundTransparency = 1
		voteCount2.Text = "0"
		voteCount2.TextColor3 = Color3.fromRGB(255, 150, 150)
		voteCount2.TextStrokeTransparency = 0
		voteCount2.Font = Enum.Font.GothamBold
		voteCount2.TextScaled = true
		voteCount2.TextXAlignment = Enum.TextXAlignment.Right

		local btnContainer = Instance.new("Frame", mainFrame)
		btnContainer.Name = "BtnContainer"
		btnContainer.LayoutOrder = 4
		btnContainer.Size = UDim2.new(0.95, 0, 0, 25) 
		btnContainer.BackgroundTransparency = 1

		local hasVoted = false

		local btn1 = Instance.new("TextButton", btnContainer)
		btn1.Size = UDim2.new(0.48, 0, 1, 0)
		btn1.Position = UDim2.new(0, 0, 0, 0)
		btn1.BackgroundColor3 = Color3.fromRGB(30, 80, 150)
		btn1.Text = data.Choice1
		btn1.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn1.Font = Enum.Font.GothamBold
		btn1.TextScaled = true
		Instance.new("UICorner", btn1).CornerRadius = UDim.new(0, 4)
		local stroke1 = Instance.new("UIStroke", btn1)
		stroke1.Color = Color3.new(0,0,0)
		stroke1.Thickness = 1.5

		local btn2 = Instance.new("TextButton", btnContainer)
		btn2.Size = UDim2.new(0.48, 0, 1, 0)
		btn2.Position = UDim2.new(0.52, 0, 0, 0)
		btn2.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
		btn2.Text = data.Choice2
		btn2.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn2.Font = Enum.Font.GothamBold
		btn2.TextScaled = true
		Instance.new("UICorner", btn2).CornerRadius = UDim.new(0, 4)
		local stroke2 = Instance.new("UIStroke", btn2)
		stroke2.Color = Color3.new(0,0,0)
		stroke2.Thickness = 1.5

		local function onVote(choiceNum, clickedBtn)
			if hasVoted then return end
			hasVoted = true
			tweenService:Create(clickedBtn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {Size = UDim2.new(0.45, 0, 0.9, 0)}):Play()
			if choiceNum == 1 then
				tweenService:Create(clickedBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(60, 120, 255)}):Play()
				stroke1.Color = Color3.fromRGB(255, 255, 255)
			else
				tweenService:Create(clickedBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(255, 60, 60)}):Play()
				stroke2.Color = Color3.fromRGB(255, 255, 255)
			end
			adminEvent:FireServer("SubmitVote", {PollId = activePollId, Choice = choiceNum})
		end

		btn1.MouseButton1Click:Connect(function() onVote(1, btn1) end)
		btn2.MouseButton1Click:Connect(function() onVote(2, btn2) end)

		tweenService:Create(mainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0.005, 0)}):Play()

		local remainingTime = data.Duration
		pollTimerConnection = runService.Heartbeat:Connect(function(dt)
			remainingTime = remainingTime - dt
			if timerLbl and timerLbl.Parent then
				timerLbl.Text = tostring(math.ceil(remainingTime)) .. "s"
			end
			if remainingTime <= 0 then
				closePollGui(false)
			end
		end)

	elseif action == "UpdatePollVotes" then
		if currentPollGui and data.PollId == activePollId then
			local mainFrame = currentPollGui:FindFirstChild("MainFrame")
			if mainFrame then
				local barContainer = mainFrame:FindFirstChild("BarContainer")
				if barContainer then
					local barBg = barContainer:FindFirstChild("BarBg")
					local vote1Lbl = barContainer:FindFirstChild("VoteCount1")
					local vote2Lbl = barContainer:FindFirstChild("VoteCount2")
					if vote1Lbl then vote1Lbl.Text = tostring(data.Votes1) end
					if vote2Lbl then vote2Lbl.Text = tostring(data.Votes2) end
					if barBg then
						local barFill = barBg:FindFirstChild("BarFill")
						local totalVotes = data.Votes1 + data.Votes2
						local fillPercentage = totalVotes == 0 and 0.5 or (data.Votes1 / totalVotes)
						if barFill then
							tweenService:Create(barFill, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(fillPercentage, 0, 1, 0)}):Play()
						end
					end
				end
			end
		end

	elseif action == "DivineSequence" then
		clientSequenceTicket = clientSequenceTicket + 1
		local myTicket = clientSequenceTicket
		stopAllEvents()

		if not Settings.UseDivineAnimation then executeEventLogic(data.eventData); return end

		local storedDummy = oybEventFolder:FindFirstChild("OYB_DivineDummy")
		if not storedDummy then return end
		activeDivineClone = storedDummy:Clone()
		local spawnCFrame = CFrame.new(0, 15000, 0)
		local eventPart = workspace:FindFirstChild("OYBNPCEVENT")
		if eventPart then spawnCFrame = eventPart.CFrame end
		activeDivineClone:PivotTo(spawnCFrame)
		activeDivineClone.Parent = workspace

		local hrp, hum, head = activeDivineClone:WaitForChild("HumanoidRootPart", 3), activeDivineClone:WaitForChild("Humanoid", 3), activeDivineClone:WaitForChild("Head", 3)
		if not hrp or not hum or not head then return end

		for _, part in ipairs(activeDivineClone:GetDescendants()) do
			if part:IsA("BasePart") then part.Anchored = (part.Name == "HumanoidRootPart"); part.Transparency = 1
			elseif part:IsA("Decal") or part:IsA("Texture") or part:IsA("FaceControls") then part.Transparency = 1 end
		end

		local highlight = Instance.new("Highlight", activeDivineClone)
		highlight.FillColor, highlight.FillTransparency, highlight.OutlineColor, highlight.OutlineTransparency = Color3.fromRGB(0, 200, 255), 0.85, Color3.fromRGB(150, 255, 255), 0.3

		local aura = Instance.new("ParticleEmitter", hrp)
		aura.Name, aura.Texture, aura.Color, aura.Rate, aura.Speed, aura.Lifetime, aura.LightEmission, aura.LockedToPart, aura.EmissionDirection, aura.Enabled = "DivineAura", "rbxassetid://822606139", ColorSequence.new(Color3.fromRGB(0, 150, 255), Color3.fromRGB(100, 255, 255)), 10, NumberRange.new(15, 30), NumberRange.new(1, 2), 0.8, true, Enum.NormalId.Top, true
		aura.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 10), NumberSequenceKeypoint.new(0.5, 35), NumberSequenceKeypoint.new(1, 10)})
		aura.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.4), NumberSequenceKeypoint.new(1, 1)})

		local cam = workspace.CurrentCamera
		cam.CameraType = Enum.CameraType.Scriptable
		local angle = 0
		cameraConnection = runService.RenderStepped:Connect(function(dt)
			if activeDivineClone and head then
				angle = angle + (Settings.CameraSpinSpeed * dt)
				cam.CFrame = CFrame.lookAt(head.Position + Vector3.new(math.cos(angle) * Settings.CameraDistance, Settings.CameraHeight, math.sin(angle) * Settings.CameraDistance), head.Position)
			end
		end)

		local thunder = Instance.new("Sound", soundService)
		thunder.SoundId, thunder.Volume = Settings.ThunderSoundID, 2; thunder:Play(); game.Debris:AddItem(thunder, 5)

		local flash = Instance.new("ColorCorrectionEffect", lighting)
		flash.Brightness = 1; tweenService:Create(flash, TweenInfo.new(1.5), {Brightness = 0}):Play(); game.Debris:AddItem(flash, 2)

		for _, part in ipairs(activeDivineClone:GetDescendants()) do
			if (part:IsA("BasePart") and part.Name ~= "HumanoidRootPart") or part:IsA("Decal") or part:IsA("Texture") then
				tweenService:Create(part, TweenInfo.new(0.2), {Transparency = 0}):Play()
			end
		end

		task.wait(0.2); if clientSequenceTicket ~= myTicket then return end

		local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
		local anim = Instance.new("Animation")
		anim.AnimationId = Settings.AnimID
		activeDivineAnimTrack = animator:LoadAnimation(anim)
		activeDivineAnimTrack.Priority, activeDivineAnimTrack.Looped = Enum.AnimationPriority.Action, false 
		activeDivineAnimTrack:Play()

		task.wait(Settings.SnapTime); if clientSequenceTicket ~= myTicket then return end

		local snap = Instance.new("Sound", soundService)
		snap.SoundId, snap.Volume = Settings.SnapSoundID, 3; snap:Play(); game.Debris:AddItem(snap, 3)

		aura.Enabled = false; tweenService:Create(highlight, TweenInfo.new(0.5), {FillTransparency = 1, OutlineTransparency = 1}):Play()
		executeEventLogic(data.eventData)

		local fadeOutDuration = 0.5
		if (Settings.TotalTime - Settings.SnapTime - fadeOutDuration) > 0 then task.wait(Settings.TotalTime - Settings.SnapTime - fadeOutDuration) end
		if clientSequenceTicket ~= myTicket then return end

		local outFlash = Instance.new("ColorCorrectionEffect", lighting)
		outFlash.Brightness = 0.5; tweenService:Create(outFlash, TweenInfo.new(fadeOutDuration), {Brightness = 0}):Play(); game.Debris:AddItem(outFlash, fadeOutDuration + 0.5)

		for _, part in ipairs(activeDivineClone:GetDescendants()) do
			if (part:IsA("BasePart") and part.Name ~= "HumanoidRootPart") or part:IsA("Decal") or part:IsA("Texture") then
				tweenService:Create(part, TweenInfo.new(fadeOutDuration), {Transparency = 1}):Play()
			end
		end

		task.wait(fadeOutDuration); if clientSequenceTicket == myTicket then hideDivineCloneInstantly() end

	elseif action == "PlayEvent" then
		clientSequenceTicket = clientSequenceTicket + 1
		stopAllEvents()
		if data ~= "Stop" then executeEventLogic(data) end

	elseif action == "SyncEvent" then
		local eventData, timeElapsed = data.eventData, data.timeElapsed
		local animTime = Settings.UseDivineAnimation and Settings.TotalTime or 0
		local soundOffset = timeElapsed - animTime
		if soundOffset >= 0 then
			clientSequenceTicket = clientSequenceTicket + 1
			stopAllEvents(); executeEventLogic(eventData, soundOffset)
		elseif timeElapsed < animTime and Settings.UseDivineAnimation then
			clientSequenceTicket = clientSequenceTicket + 1
			stopAllEvents(); executeEventLogic(eventData)
		end
	end
end)

task.spawn(function()
	if not player.Character then player.CharacterAdded:Wait() end
	oybEventFolder:WaitForChild("OYB_AdminEvent"):FireServer("PlayerReady")
end)
