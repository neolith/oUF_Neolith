--[[-----------------------------------------------------

	oUF_Neolith
	by neolith of EU_Aegwynn
	Based upon oUF_Lily, oUF_Mastiff and countless others

-------------------------------------------------------]]



--[[     Files     ]]
local texture		= "Interface\\AddOns\\oUF_Neolith\\textures\\statusbar"			-- bar texture
local border		= "Interface\\AddOns\\oUF_Neolith\\textures\\border"				-- background border texture
local buffborder	= "Interface\\AddOns\\oUF_Neolith\\textures\\buffborder"			-- buff border texture
local font			= "Interface\\AddOns\\oUF_Neolith\\fonts\\ABF.ttf"				-- font
local overlay		= "Interface\\AddOns\\oUF_Neolith\\textures\\overlay"			-- overlay texture for debuffs on player
local mohighlight	= "Interface\\AddOns\\oUF_Neolith\\textures\\highlight"			-- mouseover highlight texture


--[[     Basic Values     ]]
local width				= 180			-- width of frame
local height			= 45			-- height of frame
local manaheight		= 15			-- height of mana bar
local targetoffset		= 50			-- space between player and target
local focusoffset		= 10			-- space between target and focus
local partypetheight	= 25
local partyspacing		= 20			-- space between groupmembers including petspace
local partytargetwidth	= 50
local _, class = UnitClass('player')


--[[     Basic Setup     ]]

local rainbowCPoints = false
local castBars = true		-- activating castbars
local castsafeZone = false

local deficit = true		-- deactivating health deficit (used by healers)

RuneFrame:Hide()			-- hiding the DKs' rune frame


--[[     Frame Background     ]]
local backdrop = {
	bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=], tile = true, tileSize = 16,		-- background texture
	edgeFile = border, edgeSize = 16,														-- border texture
	insets = {top = 4, left = 4, bottom = 4, right = 4},									-- insets (pixel of border texture from outside to middle)
}

local cbbackdrop = {
	bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=], tile = true, tileSize = 16,		-- background texture
}


--[[     Color Metatable (Energy Bar)     ]]
local colors = setmetatable({
	power = setmetatable({
		['MANA'] = {.31,.45,.63},
		['RAGE'] = {.69,.31,.31},
		['FOCUS'] = {.71,.43,.27},
		['ENERGY'] = {.65,.63,.35},
		['RUNIC_POWER'] = {0,.8,.9},
	}, {__index = oUF.colors.power}),
}, {__index = oUF.colors})


--[[     Shortname     ]]
oUF.Tags['[shortname]']  = function(u) local name = UnitName(u); if(name) then return name:sub(1, 12) else return '' end end
oUF.TagEvents['[shortname]']   = 'UNIT_NAME_UPDATE'


--[[     Veryshortname     ]]
oUF.Tags['[veryshortname]']  = function(u) local name = UnitName(u); if(name) then return name:sub(1, 6) else return '' end end
oUF.TagEvents['[veryshortname]']   = 'UNIT_NAME_UPDATE'


--[[     Menu     ]]
local menu = function(self)
	local unit = self.unit:sub(1, -2)
	local cunit = self.unit:gsub("(.)", string.upper, 1)

	if(unit == "party" or unit == "partypet") then
		ToggleDropDownMenu(1, nil, _G["PartyMemberFrame"..self.id.."DropDown"], "cursor", 0, 0)
	elseif(_G[cunit.."FrameDropDown"]) then
		ToggleDropDownMenu(1, nil, _G[cunit.."FrameDropDown"], "cursor", 0, 0)
	end
end


--[[     Shorten Values     ]]
local function ShortValue(value)
	if value >= 1e7 then
		return ('%.1fm'):format(value / 1e6):gsub('%.?0+([km])$', '%1')
	elseif value >= 1e6 then
		return ('%.2fm'):format(value / 1e6):gsub('%.?0+([km])$', '%1')
	elseif value >= 1e5 then
		return ('%.0fk'):format(value / 1e3)
	elseif value >= 1e3 then
		return ('%.1fk'):format(value / 1e3):gsub('%.?0+([km])$', '%1')
	elseif value <= -1e3 then
		return ('%.1fk'):format(value / 1e3):gsub('%.?0+([km])$', '%1')
	elseif value <= -1e5 then
		return ('%.0fk'):format(value / 1e3)
	elseif value <= -1e6 then
		return ('%.2fm'):format(value / 1e6):gsub('%.?0+([km])$', '%1')
	elseif value <= -1e7 then
		return ('%.1fm'):format(value / 1e6):gsub('%.?0+([km])$', '%1')
	else
		return value
	end
end


--[[     RTI     ]]
local updateRIcon = function(self, event)
	local index = GetRaidTargetIndex(self.unit)
	if(index) then
		self.RIcon:SetText(ICON_LIST[index].."22|t")
	else
		self.RIcon:SetText()
	end
end

--[[     UpdateCPoints     ]]
local UpdateCPoints = function(self, event, unit)
	if unit == PlayerFrame.unit then
		self.CPoints.unit = unit
	end
end

--[[     Health Bar Text     ]]
local updateHealth = function(self, event, unit, bar, min, max)
	local perc = floor(min/max*100)
	if(not UnitIsConnected(unit)) then
		bar:SetValue(0)
		bar.value:SetText('|cff808080'..'Offline')
	elseif(unit == 'targettarget' or unit == 'focustarget') then
		bar.value:SetText()
	elseif(UnitIsDead(unit)) then
		bar.value:SetText('|cff7A0609'..'Dead')
	elseif(UnitIsGhost(unit)) then
		bar.value:SetText('|cff00CAFF'..'Ghost')
	elseif(self:GetAttribute('unitsuffix') == 'pet' or self:GetAttribute('unitsuffix') == 'target')then
 		bar.value:SetText()
	elseif(min==max) then
		bar.value:SetFormattedText(ShortValue(min))
	else
		if(deficit)then
			if (unit == 'target') then
				bar.value:SetFormattedText('|cff00CAFF' ..ShortValue(min)..'|cffff3333'.. ShortValue(min-max).. "|cffffffff | " ..perc)
			else
				bar.value:SetFormattedText('|cffff3333'.. ShortValue(min-max).. "|cffffffff | " ..perc)
			end
		else
 			bar.value:SetFormattedText(ShortValue(min).. " " ..'|cffcc3333'..ShortValue(min-max))
		end
	end

end


--[[     Power Bar Text     ]]
local updatePower = function(self, event, unit, bar, min, max)
	if(min == 0 or UnitIsDead(unit) or UnitIsGhost(unit) or unit == "targettarget" or unit == "focustarget" or not UnitIsConnected(unit)) then
	  bar.value:SetText()
	elseif(self:GetAttribute('unitsuffix') == 'pet' or self:GetAttribute('unitsuffix') == 'target')then
 	  bar.value:SetText()
  	else
	  bar.value:SetFormattedText(ShortValue(min))
	end
	bar.value:SetTextColor(1,1,1)
end


--[[     Auras     ]]
local auraIcon = function(self, button, icons)
	local count = button.count
	count:ClearAllPoints()
	count:SetPoint("BOTTOM", button, 8, -4)
	icons.showDebuffType = true
	button.cd:SetReverse()
	button.overlay:SetTexture(buffborder)
	button.overlay:SetTexCoord(0, 1, 0, 1)
	button.overlay.Hide = function(self) self:SetVertexColor(0.25, 0.25, 0.25) end
end


--[[     Bar Styles     ]]
local func = function(self, unit)
	self.colors = colors
	self.menu = menu
	
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)
	
	self:RegisterForClicks"anyup"
	self:SetAttribute("*type2", "menu")
	
	
	--[[ Health ]]
--~ 	self.Health = CreateFrame("StatusBar", self:GetName()..'_health', self)
	self.Health = CreateFrame('StatusBar', self:GetName()..'_health', self)
	
	if (unit =='player' or self:GetParent():GetName():match'oUF_Party') then
		self.Health:SetHeight(height-manaheight-8)
	elseif (unit == 'target' or unit == 'focus' or unit == 'pet') then
		self.Health:SetHeight(height-manaheight-8)
	end
	
	self.Health:SetStatusBarTexture(texture)
--~ 	hp:SetFrameStrata(TOOLTIP)
	self.Health.colorTapping = true
  	self.Health.colorClass = true
	self.Health.colorReaction = true
	self.Health.frequentUpdates = true
	self.Health.colorHappiness = true
	if unit == 'player' then
		self.Health.Smooth = true
	end

	
	if unit == 'player' or unit == 'target' then
		self.Health:SetParent(self)
		self.Health:SetPoint("TOP", 0, -4)
		self.Health:SetPoint("LEFT", height-4, 0)
		self.Health:SetPoint("RIGHT", -4, 0)
	elseif (unit == 'focus' or unit == 'pettarget' or self:GetAttribute('unitsuffix') == 'target') then
		self.Health:SetParent(self)
		self.Health:SetPoint("TOP", 0, -4)
		self.Health:SetPoint("LEFT", 4, 0)
		self.Health:SetPoint("RIGHT", -4, 0)
--~ 	elseif (unit == 'pettarget' or self:GetAttribute('unitsuffix') == 'target') then
--~ 		self.Health:SetParent(self)
--~ 		self.Health:SetPoint("TOP", 0, -4)
--		self.Health:SetPoint("LEFT", height-4, 0)
--~ 		self.Health:SetPoint("LEFT", 4, 0)
--~ 		self.Health:SetPoint("RIGHT", -4, 0)	
	elseif (self:GetAttribute('unitsuffix') == 'pet') then	-- possible fix for partypets ???
		self.Health:SetParent(self)
		self.Health:SetPoint("TOP", 0, -4)
		self.Health:SetPoint("LEFT", 4, 0)
		self.Health:SetPoint("RIGHT", -4, 0)
		self.Health:SetPoint("BOTTOM", 0, 4)
	else
		self.Health:SetParent(self)
		self.Health:SetPoint("TOP", 0, -4)
		self.Health:SetPoint("LEFT", height-4, 0)
		self.Health:SetPoint("RIGHT", -4, 0)
	end
	
--~ 	self.Health:SetFrameLevel(2)										--++--++--++--++--++--++--++--++ THIS! for proper highlights
--~ 	self.Health:SetFrameLevel(unit and 1 or 2)
	if unit then
		self.Health:SetFrameLevel(1)
	elseif self:GetAttribute('unitsuffix') then
		self.Health:SetFrameLevel(3)
	elseif not unit then
		self.Health:SetFrameLevel(2)
	end

	
	self.Health.bg = self.Health:CreateTexture(nil, "BORDER")
	self.Health.bg:SetAllPoints(self.Health)
	self.Health.bg:SetTexture(texture)
	self.Health.bg.multiplier = .2

	self:SetBackdrop(backdrop)								-- BACKDROP
	self:SetBackdropColor(0, 0, 0, .7)
	self:SetBackdropBorderColor(.3, .3, .3, 1)
	
	
	--[[ Health Text ]]
	self.Health.value = self.Health:CreateFontString(nil, "OVERLAY")
	self.Health.value:SetFont(font, 10)
	self.Health.value:SetShadowOffset(1, -1)
	if(deficit)then
		self.Health.value:SetTextColor(8, 3, 3)
	else
		self.Health.value:SetTextColor(1, 1, 1)
	end
	self.Health.value:SetPoint("RIGHT", self.Health, -2, 0)
	
	self.PostUpdateHealth = updateHealth
	
	
	--[[ Power ]]
	self.Power = CreateFrame("StatusBar", self:GetName()..'_power', self)
	
	if (unit =='player' or self:GetParent():GetName():match'oUF_Party') then
		self.Power:SetHeight(manaheight)
	elseif (unit == 'target' or unit == 'focus' or unit == 'pet') then
		self.Power:SetHeight(manaheight)
	end
	
	self.Power:SetStatusBarTexture(texture)
	self.Power.colorPower = true
	self.Power.frequentUpdates = true
	
	if not (unit == 'focus' or self:GetAttribute('unitsuffix') == 'target') then
		self.Power:SetParent(self)
		self.Power:SetPoint("BOTTOM", 0, 4)
		self.Power:SetPoint("LEFT", height-4, 0)
		self.Power:SetPoint("RIGHT", -4, 0)
	else
		self.Power:SetParent(self)
		self.Power:SetPoint("BOTTOM", 0, 4)
		self.Power:SetPoint("LEFT", 4, 0)
		self.Power:SetPoint("RIGHT", -4, 0)
	end
	
--~ 	self.Power:SetFrameLevel(2)										--++--++--++--++--++--++--++--++ THIS! for proper highlights
--~ 	self.Power:SetFrameLevel(unit and 1 or 2)
	if unit then
		self.Power:SetFrameLevel(1)
	elseif self:GetAttribute('unitsuffix') then
		self.Power:SetFrameLevel(3)
	elseif not unit then
		self.Power:SetFrameLevel(2)
	end

	
	self.Power.bg = self.Power:CreateTexture(nil, "BORDER")
	self.Power.bg:SetAllPoints(self.Power)
	self.Power.bg:SetTexture(texture)
	self.Power.bg.multiplier = .2
	
	
	--[[ Power Text ]]
	self.Power.value = self.Power:CreateFontString(nil, "OVERLAY")
	self.Power.value:SetFont(font, 10)
	self.Power.value:SetShadowOffset(1, -1)
	self.Power.value:SetPoint("RIGHT", self.Power,-2, 0)
	self.Power.value:SetTextColor(1, 1, 1)
	
	self.PostUpdatePower = updatePower
	
	
	--[[ CastBar ]]
	if(castBars)then
		if unit == "target" or unit == 'focus' then
			self.Castbar = CreateFrame("StatusBar", self:GetName()..'_castbar', self)
			self.Castbar:SetStatusBarTexture(texture)
			self.Castbar:SetStatusBarColor(.9,.7,0)	-- CastBar Color
			if unit == 'target' then
				self.Castbar:SetWidth(width-height)
			else
				self.Castbar:SetWidth(width-height-12)
			end
			self.Castbar:SetHeight(12)
			self.Castbar:SetParent(self)
			self.Castbar:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -3, -13)
			self.Castbar:SetBackdrop(cbbackdrop)
			self.Castbar:SetBackdropColor(0, 0, 0, .7)
			self.Castbar:SetToplevel(true)
			
			self.Castbar.Text = self.Castbar:CreateFontString(nil, "OVERLAY")
			self.Castbar.Text:SetFont(font, 11)
			self.Castbar.Text:SetShadowOffset(1, -1)
			self.Castbar.Text:SetPoint("LEFT", self.Castbar, "LEFT", 2, 0)
			self.Castbar.Time = self.Castbar:CreateFontString(nil, 'OVERLAY')
			self.Castbar.Time:SetFont(font, 11)
			self.Castbar.Time:SetShadowOffset(1, -1)
			self.Castbar.Time:SetPoint("RIGHT", self.Castbar, "RIGHT",  -2, 0)
			
			self.Castbar.CustomTimeText = function(self, duration)
				if self.casting then
					self.Time:SetFormattedText("%.1f", self.max - duration)
				elseif self.channeling then
					self.Time:SetFormattedText("%.1f", duration)
				end
			end
			
			if(castsafeZone and unit == 'player') then
				self.Castbar.SafeZone = self.Castbar:CreateTexture(nil,'ARTWORK')
				self.Castbar.SafeZone:SetPoint('TOPRIGHT')
				self.Castbar.SafeZone:SetPoint('BOTTOMRIGHT')
				self.Castbar.SafeZone:SetTexture(texture)
				self.Castbar.SafeZone:SetVertexColor(.69,.31,.31)
			end
			
			self.Castbar.Icon = self.Castbar:CreateTexture(nil, 'ARTWORK')
			self.Castbar.Icon:SetHeight(15)
			self.Castbar.Icon:SetWidth(15)
			self.Castbar.Icon:SetTexCoord(0.1,0.9,0.1,0.9)
			self.Castbar.Icon:SetPoint('LEFT', -16, 0)
		end
	end
	
	
	--[[ Portrait ]]
	if(self:GetParent():GetName():match'oUF_Party' or unit == 'player' or unit == 'target' or unit =="pet") then
		if not (self:GetAttribute('unitsuffix') == 'target' or self:GetAttribute('unitsuffix') == 'pet') then
			self.Portrait = CreateFrame("PlayerModel", nil, self)
			self.Portrait:SetScript("OnShow", function(self) self:SetCamera(0) end)
			self.Portrait:SetWidth(height-9)
			self.Portrait:SetHeight(height-8)
			self.Portrait:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 4, 4)
			self.Portrait.type = "3D"
--~ 			self.Portrait:SetFrameLevel(2)										--++--++--++--++--++--++--++--++ THIS! for proper highlights
--~ 			self.Portrait:SetFrameLevel(unit and 1 or 2)
			if unit then
				self.Portrait:SetFrameLevel(1)
			elseif self:GetAttribute('unitsuffix') then
				self.Portrait:SetFrameLevel(3)
			elseif not unit then
				self.Portrait:SetFrameLevel(2)
			end

		end
	end
	
	
	--[[ Name ]]
	self.Info = self.Health:CreateFontString(nil, "OVERLAY")
    self.Info:SetPoint("LEFT", self.Health, 2, 0)
	self.Info:SetJustifyH"LEFT"
	self.Info:SetFont(font, 11)
 	self.Info:SetTextColor(1, 1, 1)
	self.Info:SetShadowOffset(1, -1)
	if not (unit =='pettarget' or self:GetAttribute('unitsuffix') == 'target') then
		self:Tag(self.Info,'[shortname]')
	else
		self:Tag(self.Info,'[veryshortname]')
	end
	
	
	--[[ Class ]]
	if not (unit == "targettarget" or unit == 'focustarget' or unit == 'pet' or self:GetAttribute('unitsuffix') == 'pet' or self:GetAttribute('unitsuffix') == 'target') then
		self.Info = self.Power:CreateFontString(nil, "OVERLAY")
		self.Info:SetPoint("LEFT")
		self.Info:SetFont(font, 11)
		self.Info:SetTextColor(1, 1, 1)
		self.Info:SetShadowOffset(1, -1)
		self:Tag(self.Info,' [difficulty][smartlevel] [raidcolor][smartclass]')
  	end
	
	
	--[[ Leader Icon ]]
	if(self:GetParent():GetName():match'oUF_Party' or unit == 'player') then
		if not(self:GetAttribute('unitsuffix') == 'pet' or self:GetAttribute('unitsuffix') == 'target')then
			self.Leader = self.Health:CreateTexture(nil, "OVERLAY")
			self.Leader:SetHeight(16)
			self.Leader:SetWidth(16)
			self.Leader:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT", -5, -7)
			self.Leader:SetTexture"Interface\\GroupFrame\\UI-Group-LeaderIcon"
		end
	end
	
	
	--[[ PvP Status Icon ]]
	if unit == "target" then
		self.PvP = self.Health:CreateTexture(nil, "OVERLAY")
		self.PvP:SetPoint("BOTTOMRIGHT", self.Health, "TOPRIGHT", 18, -20)
		self.PvP:SetHeight(28)
		self.PvP:SetWidth(28)
	end
	
	
	--[[ Resting Icon  ]]
	if unit == 'player' then
		self.Resting = self.Power:CreateTexture(nil, 'OVERLAY')
		self.Resting:SetHeight(16)
		self.Resting:SetWidth(18)
		self.Resting:SetPoint('BOTTOMLEFT', -8.5, -8.5)
		self.Resting:SetTexture('Interface\\CharacterFrame\\UI-StateIcon')
		self.Resting:SetTexCoord(0,0.5,0,0.421875)
	end
	
	
	--[[ RTIs ]]
	if not (unit == "targettarget" or unit == "focustarget") then
		self.RaidIcon = self.Health:CreateTexture(nil, "OVERLAY")
		self.RaidIcon:SetHeight(24)
		self.RaidIcon:SetWidth(24)
		self.RaidIcon:SetPoint("CENTER", self.Health, 0, 16)
		self.RaidIcon:SetTexture"Interface\\TargetingFrame\\UI-RaidTargetingIcons"
	end
	
	
	--[[ Buffs ]]
	if unit == "target" then
		self.Buffs = CreateFrame("Frame", nil, self)
		self.Buffs:SetHeight(16)
		self.Buffs:SetWidth(height)
		self.Buffs.initialAnchor = "TOPRIGHT"
		self.Buffs.num = 6
		self.Buffs["growth-y"] = "DOWN"
		self.Buffs["growth-x"] = "LEFT"
		self.Buffs.size = 16
		self.Buffs.spacing = 4
		self.Buffs:SetPoint("TOPRIGHT", self.Power, "BOTTOMLEFT", -2, -20)
	end
	
	
	--[[ Debuffs ]]
	if(unit == "target" or unit == "focus") then
		self.Debuffs = CreateFrame("Frame", nil, self)
		self.Debuffs:SetHeight(16)
		self.Debuffs:SetWidth(width)
		self.Debuffs.initialAnchor = "TOPRIGHT"
		self.Debuffs.num = 32
		self.Debuffs["growth-y"] = "DOWN"
		self.Debuffs["growth-x"] = "LEFT"
		self.Debuffs.size = 16
		self.Debuffs.spacing = 4
		self.Debuffs:SetPoint("TOPRIGHT", self.Power, "BOTTOMRIGHT", 0, -20)
	end
	
	
	--[[ Debuff Highlighting ]]
	self.DebuffHighlight = self.Health:CreateTexture(nil, "OVERLAY")
	self.DebuffHighlight:SetAllPoints(self)
	self.DebuffHighlight:SetTexture(overlay)
	self.DebuffHighlight:SetBlendMode("ADD")
	self.DebuffHighlight:SetVertexColor(0,0,0,0) -- set alpha to 0 to hide the texture
	
	
	--[[ MouseOverHighlight ]]
	self.Highlight = self:CreateTexture(nil, 'HIGHLIGHT')
	self.Highlight:SetAllPoints(self)
	self.Highlight:SetBlendMode('ADD')
	self.Highlight:SetTexture(mohighlight)
--~ 	if not(unit) then self.Highlight:SetFrameLevel(2) else self.Highlight:SetFrameLevel(1) end --++--++--++--++--++--++--++--++ THIS! for proper highlights
--~ 	self.Highlight:SetFrameLevel(1)
		
	
	--[[ Combo Points ]]
	if(class == "ROGUE" or class == "DRUID") and unit == 'player' then
		self.CPB = {}
		self.CPoints = {}
		self.CPoints.unit = PlayerFrame.unit
		for i = 1, 5 do
			self.CPB[i] = CreateFrame('Frame', self:GetName()..'_combopoint_'..i, self)
--~ 			self.f = CreateFrame("Frame", self:GetName().."TextureFrame", self)
--~ 			self.CPB[i]:SetVertexColor(0, 0, 0, 0)
			self.CPB[i]:SetBackdrop(backdrop)								-- BACKDROP
			self.CPB[i]:SetBackdropColor(0, 0, 0, .7)
			self.CPB[i]:SetBackdropBorderColor(.3, .3, .3, 1)
			self.CPB[i]:SetHeight(height*0.45)
			self.CPB[i]:SetWidth(width/5)
			
			self.CPoints[i] = self.Health:CreateTexture(nil, 'OVERLAY')
--~ 			self.CPoints[i] = CreateFrame('StatusBar', self:GetName()..'_combopoint_'..i, self)
			self.CPoints[i]:SetHeight(height*0.45-8)
			self.CPoints[i]:SetWidth(width/5-8)
			self.CPoints[i]:SetTexture(texture)
			self.CPoints[i]:SetVertexColor(0.69, 0.31, 0.31)
--~ 			self.CPoints[i]:SetStatusBarTexture(texture)
--~ 			self.CPoints[i]:SetStatusBarColor(0.69, 0.31, 0.31)
			if i == 1 then
				self.CPB[i]:SetPoint('BOTTOMLEFT', self, "TOPLEFT", 0, 0)
				self.CPoints[i]:SetPoint('BOTTOMLEFT', self, "TOPLEFT", 4, 4)
--~ 				self.CPoints[i]:SetPoint("TOP", 0, -4)
--~ 				self.CPoints[i]:SetPoint("LEFT", 4, 0)
--~ 				self.CPoints[i]:SetPoint("RIGHT", -4, 0)
--~ 				self.CPoints[i]:SetPoint("BOTTOM", 0, 4)
--~ 				self.CPoints[i]:SetVertexColor(0.69, 0.31, 0.31)
			else
				self.CPoints[i]:SetPoint('LEFT', self.CPoints[i-1], 'RIGHT', 8, 0)
				self.CPB[i]:SetPoint('LEFT', self.CPB[i-1], 'RIGHT', 0, 0)
			end
		end
		if rainbowCPoints then
			self.CPoints[1]:SetVertexColor(0.69, 0.31, 0.31)
			self.CPoints[2]:SetVertexColor(0.82, 0.55, 0.26)
			self.CPoints[3]:SetVertexColor(0.94, 0.78, 0.22)
			self.CPoints[4]:SetVertexColor(0.64, 0.68, 0.27)
			self.CPoints[5]:SetVertexColor(0.33, 0.59, 0.33)
		end
		self:RegisterEvent('UNIT_COMBO_POINTS', UpdateCPoints)
	end
	
	--[[ Update on PetHappiness Change]]
	if(unit == 'pet') then
		self:RegisterEvent("UNIT_HAPPINESS", updateHealth)
	end
	
	
	--[[ Range Check ]]
	if (not unit) then
		if not (self:GetAttribute('unitsuffix') == 'pet' or self:GetAttribute('unitsuffix') == 'target') then
			self.Range = true
			self.inRangeAlpha = 1
			self.outsideRangeAlpha = .35
		end
	end
	
	
	--[[ Heal Comm ]]
	if not (unit == 'player') then		-- player only
		self.ignoreHealComm = 1
	end
	
	
	--[[ Initial Sizes / Shrink ToT & FT ]]
	if (unit == 'targettarget' or unit =='focustarget') then 
		self:SetAttribute('initial-height', height*0.45)
		self:SetAttribute('initial-width', width-(height-4-4))
		self.Health:SetPoint("LEFT", 4, 0)
		self.Power:Hide()
	elseif (unit == 'focus') then
		self:SetAttribute('initial-height', height)
		self:SetAttribute('initial-width', width-(height-4-4))
	elseif (unit == 'pettarget') then
		self:SetAttribute('initial-height', height-manaheight)
		self:SetAttribute('initial-width', partytargetwidth)
		self.Health.value:Hide()
		self.Power:Hide()
	elseif(self:GetAttribute('unitsuffix') == 'pet')then
		self:SetAttribute('initial-height', height*0.45)
		self:SetAttribute('initial-width', width-(height-4-4))
		self.Health.value:Hide()
		self.Power:Hide()
	elseif(self:GetAttribute('unitsuffix') == 'target')then
		self:SetAttribute('initial-height', height-manaheight)
		self:SetAttribute('initial-width', partytargetwidth)
		self.Health.value:Hide()
		self.Power:Hide()
  	elseif(self:GetParent():GetName():match'oUF_Party')then
		self:SetAttribute('initial-height', height)
		self:SetAttribute('initial-width', width)
	else 
		self:SetAttribute('initial-height', height)
		self:SetAttribute('initial-width', width)
	end

	
	--[[ Vehicle Frame Swap ]]
	self.disallowVehicleSwap = true
	
	--[[ ? ]]
	self.PostCreateAuraIcon = auraIcon
	
	--[[ Return Data ]]
	return self
	
end


--[[     Register Style     ]]
oUF:RegisterStyle("Neolith", func)


--[[     Spawn Frames     ]]
oUF:SetActiveStyle"Neolith"

local player = oUF:Spawn('player', 'oUF_Neolith_player')
player:SetPoint("TOPLEFT", UIParent, 5, -50)
	
	local target = oUF:Spawn("target", 'oUF_Neolith_target')
	target:SetPoint("LEFT", oUF.units.player, "RIGHT", targetoffset, 0)
		local tot = oUF:Spawn("targettarget", 'oUF_Neolith_targettarget')
		tot:SetPoint("BOTTOMRIGHT", oUF.units.target, "TOPRIGHT", 0, 0)
	
	local focus = oUF:Spawn("focus", 'oUF_Neolith_focus')
	focus:SetPoint("LEFT", oUF.units.target, "RIGHT", focusoffset, 0)
		local fot = oUF:Spawn("focustarget", 'oUF_Neolith_focustarget')
		fot:SetPoint("BOTTOMRIGHT", oUF.units.focus, "TOPRIGHT", 0, 0)
		
	local pet = oUF:Spawn("pet", 'oUF_Neolith_pet')
	pet:SetPoint("TOPRIGHT", oUF.units.player, "BOTTOMRIGHT", 0, 0)
		local pettarget = oUF:Spawn("pettarget", 'oUF_Neolith_pettarget')
		pettarget:SetPoint("TOPLEFT", oUF.units.pet, "TOPRIGHT", 0, 0)
	
	local party = oUF:Spawn("header", "oUF_Party")
	party:SetPoint("TOPLEFT", oUF.units.player, 0, -100)
	party:SetManyAttributes("showParty", true, "yOffset", -partyspacing)
	party:SetAttribute("template", "oUF_NeolithParty")
--~ 		local partytarget = oUF:Spawn("partytarget", 'oUF_Neolith_partytarget')
--~ 		pettarget:SetPoint("TOPLEFT", oUF.units.pet, "TOPRIGHT", 0, 0)
	
	local partyToggle = CreateFrame('Frame')
	partyToggle:RegisterEvent('PLAYER_LOGIN')
	partyToggle:RegisterEvent('RAID_ROSTER_UPDATE')
	partyToggle:RegisterEvent('PARTY_LEADER_CHANGED')
	partyToggle:RegisterEvent('PARTY_MEMBERS_CHANGED')
	
	partyToggle:SetScript('OnEvent', function(self)
		if ((GetNumRaidMembers() > 0)) then
			party:Hide()
		else
			party:Show()
		end
	end)