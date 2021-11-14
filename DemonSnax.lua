function cooldump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. cooldump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

local function G(rawVal)
    return string.format("%.1f", (rawVal / 10000)).."G"
end

local className, classFilename, classID = C_PlayerInfo.GetClass(PlayerLocation:CreateFromUnit("player"))

local DemonSnaxFrame = {}

DemonSnaxData = {}
DemonSnaxData.vfActive = false;
DemonSnaxData.vfExpires = 0;
DemonSnaxData.uiUpdateDelay = 1.0/60.0;
DemonSnaxData.nextUpdate = 0;
DemonSnaxData.tyrants = {};
DemonSnaxData.lastSpamTime = 0;

local function OnEvent(self, event)
    print(CombatLogGetCurrentEventInfo())
end


local function dcPrint(msg)
    --local t = DemonSnaxEditBox:GetText() or ""
    --DemonSnaxEditBox:SetText(t .. "\n" .. msg);
    print(msg)
end

local function LogEvent(self, event, ...)
	if event == "COMBAT_LOG_EVENT_UNFILTERED" or event == "COMBAT_LOG_EVENT" then
		self:LogEvent_Original(event, CombatLogGetCurrentEventInfo())
	elseif event == "COMBAT_TEXT_UPDATE" then
		self:LogEvent_Original(event, (...), GetCurrentCombatTextEventInfo())
	else
		self:LogEvent_Original(event, ...)
	end
end

function eventHandlerWrapper(self, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then  
        handleEvent(CombatLogGetCurrentEventInfo())
    elseif event == "ADDON_LOADED" then
        DemonSnax_Frame:Show()
    end
end


if (classID == 9) then
    DemonSnaxFrame = CreateFrame("FRAME", "DemonSnaxFrame")
    DemonSnaxFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    --DemonSnaxFrame:SetScript("OnEvent", OnEvent)

	DemonSnaxFrame:RegisterEvent("ADDON_LOADED")
    DemonSnaxFrame:SetScript("OnEvent", eventHandlerWrapper)
end

local czas={
	"cza1",
	"cza2"
}


SLASH_DEMONSNAX1, SLASH_DEMONSNAX2 = '/ds', '/DemonSnax';
function SlashCmdList.DEMONSNAX(msg, editbox)
    --for i,v in ipairs(czas) do C_FriendList.AddFriend(v, "CZA") end
    if (classID == 9) then
        DemonSnax_Frame:Show()
    else
        print("Silly " .. className .. "!  DemonSnax are for Warlocks!")
    end
	print("Handy DemonSnax commands:")
	print("Dump info DemonSnax has recorded this run:")
	print("/dump DemonSnaxData")
	print("Test the countdown code in case you're using TellMeWhen alerts:")
	print("/run DemonSnaxData.vfExpires = GetTime()+15")
end

--To use these functions with TellMeWhen, copy in this line of code without the "--" at the front
-- if DemonSnax_TyrantAlert ~= nil then return DemonSnax_TyrantAlert(); else return false; end

-- if DemonSnax_LastHandAlert ~= nil then return DemonSnax_LastHandAlert(); else return false; end

function DemonSnax_TyrantAlert()
    return DemonSnax_Alert(2)
end

function DemonSnax_LastHandAlert()
    return DemonSnax_Alert(1)
end

local spams = {
	"Yo, Q-Ball, hit me with that PI!",
	"Hey, you got any more of them Power Infusions?",
	"Grant me your POWER!!!!!!!!!!!!",
	"Now summoning THE DEMONIC TYRANT!  The more haste, the more demons he can snax on",
	"It begins!!!!!!!!!!!",
	"Dear Farfallablu, I would like to humbly request that you cast your next power infusion on me.  Sincerely, Bernycinders",
	"Excuse me sir I noticed that you appear to have a [Power Infusion] and was wondering if you might be willing to cast it upon me",
	"u ned that [Power Infusion]",
	"As the Demonic Tyrant cooldown approaches, I am once again asking for your haste support."
}

function begForPI()
	if (GetTime() - DemonSnaxData.lastSpamTime < 30) then
		return
	end

	if quinePICD ~= nil then
		if quinePICD() < 3 then
			SendChatMessage(spams[math.random( #spams )], "WHISPER", nil, "Farfallablu")
			DemonSnaxData.lastSpamTime = GetTime()
		end
	end
end

function DemonSnax_Alert(which)
    if DemonSnaxData == nil then
        return false
    end
    local vfTimeLeft = DemonSnaxData.vfExpires - GetTime()

    if (vfTimeLeft < 0) then
        DemonSnaxData.vfExpires = 0
        vfTimeLeft = 0
    end

    local handCastTime = 0
    local name, rank, icon, tyrantCastTime, minRange, maxRange = GetSpellInfo("Summon Demonic Tyrant")
    name, rank, icon, handCastTime, minRange, maxRange = GetSpellInfo("Hand of Gul'dan")
	if (tyrantCastTime == nil) then
		DemonSnax_Frame:Hide()
		return
	end
	tyrantCastTime = tyrantCastTime / 1000.0
    handCastTime = handCastTime / 1000.0
    local shadowBoltTime = tyrantCastTime
    local demonBoltTime = handCastTime
    local dogTime = demonBoltTime

    local spell, _, _, _, endTimeMs = UnitCastingInfo("player")
    local gcdStart, duration, _, _ = GetSpellCooldown(61304)
    local timeAfterCur = vfTimeLeft
    if (endTimeMs ~= nil and vfTimeLeft ~= 0) then
        local endTime = endTimeMs / 1000
        timeAfterCur = DemonSnaxData.vfExpires - endTime
    elseif (gcdStart ~= 0 and vfTimeLeft ~= 0) then
        local endTime = gcdStart + duration
        timeAfterCur = DemonSnaxData.vfExpires - endTime
    end

    local deadline = 0.2 + tyrantCastTime
    local tyrantDeadline = deadline
    deadline = deadline + handCastTime
    local handDeadline = deadline
    deadline = deadline + shadowBoltTime
    
    if (tyrantDeadline < timeAfterCur and handDeadline > timeAfterCur) then
        if (which == 2) then            
            return true
        else 
            return false
        end
    elseif (handDeadline + demonBoltTime > timeAfterCur and handDeadline < timeAfterCur) then
        if (which == 1) then            
            return true
        else 
            return false
        end
    else
        return false
    end
--end
end

function DemonSnax_updateUI(self, elapsed)
    --if timestamp > DemonSnaxData.nextUpdate then
        local dbg = false
        --DemonSnaxData.nextUpdate = timestamp + DemonSnaxData.uiUpdateDelay
        -- if (DemonSnaxData.vfExpires == 0) then
        --     DemonSnaxData.vfExpires = GetTime() + 15
        --     dbg = true
        -- end

        local lastTyrant, tyrantCD, _, _ = GetSpellCooldown(265187)
		if (lastTyrant ~= nil) then
			local tyrantCDLeft = lastTyrant + tyrantCD - GetTime()
			if (tyrantCDLeft < 0) then
				tyrantCDLeft = 0
			end
			
			if (tyrantCDLeft < 26 and tyrantCDLeft > 24) then
				--print("Would beg for PI now")
				begForPI()
			end
		end

        local vfTimeLeft = DemonSnaxData.vfExpires - GetTime()

        if (vfTimeLeft < 0) then
            DemonSnaxData.vfExpires = 0
            vfTimeLeft = 0
        end

        local handCastTime = 0
        local name, rank, icon, tyrantCastTime, minRange, maxRange = GetSpellInfo("Summon Demonic Tyrant")
        name, rank, icon, handCastTime, minRange, maxRange = GetSpellInfo("Hand of Gul'dan")
		if (tyrantCastTime == nil) then
			DemonSnax_Frame:Hide()
			return
		end
        tyrantCastTime = tyrantCastTime / 1000.0
        handCastTime = handCastTime / 1000.0
        local shadowBoltTime = tyrantCastTime
        local demonBoltTime = handCastTime
        local dogTime = demonBoltTime

        local spell, _, _, _, endTimeMs = UnitCastingInfo("player")
        local gcdStart, gcdDuration, _, _ = GetSpellCooldown(61304)
        local timeAfterCur = vfTimeLeft
        if (endTimeMs ~= nil and vfTimeLeft ~= 0) then
            local endTime = endTimeMs / 1000
            timeAfterCur = DemonSnaxData.vfExpires - endTime
        elseif (gcdStart ~= 0 and vfTimeLeft ~= 0) then
            local endTime = gcdStart + gcdDuration
            timeAfterCur = DemonSnaxData.vfExpires - endTime
        end
        --TODO: GCD

        VilefiendTime:SetText(string.format("%.1f seconds", vfTimeLeft))
        SBTime:SetText(string.format("%.1f seconds", tyrantCastTime))
        HandTime:SetText(string.format("%.1f seconds", handCastTime))

        local deadline = 0.2 + tyrantCastTime
        local tyrantDeadline = deadline
        deadline = deadline + handCastTime
        local handDeadline = deadline
        deadline = deadline + shadowBoltTime
        --Deadline_LastSBolt:SetText(string.format("%.1f seconds", deadline))
		
		local GCDsLeft = math.floor((timeAfterCur - tyrantDeadline)/demonBoltTime)
		Deadline_GCDs:SetText(string.format("%d",GCDsLeft ))
        
        if (tyrantDeadline < timeAfterCur and handDeadline > timeAfterCur) then
            TimeLeftAfterCurCast:SetText(string.format("** %.1f seconds **", timeAfterCur))
            Deadline_Tyrant:SetText(string.format("--> %.1f seconds <--", tyrantDeadline))
            Deadline_LastHand:SetText(string.format("%.1f seconds", deadline))
        elseif (handDeadline + demonBoltTime > timeAfterCur and handDeadline < timeAfterCur) then
            TimeLeftAfterCurCast:SetText(string.format("%.1f seconds", timeAfterCur))
            Deadline_Tyrant:SetText(string.format("%.1f seconds", tyrantDeadline))
            Deadline_LastHand:SetText(string.format("--> %.1f seconds", handDeadline))
        else
            TimeLeftAfterCurCast:SetText(string.format("%.1f seconds", timeAfterCur))
            Deadline_Tyrant:SetText(string.format("%.1f seconds", tyrantDeadline))
            Deadline_LastHand:SetText(string.format("%.1f seconds", handDeadline))
        end
    --end
end

function handleEvent(...)
    local playerGUID = UnitGUID("player")
    local MSG_CRITICAL_HIT = "Your %s hit %s for %d damage!"

    local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = ...
    local spellId, spellName, spellSchool = 0,"",""
    local amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand
    local missType = ""

    if subevent == "SPELL_DAMAGE" then
        spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = select(12, ...)
        --print("id: " , spellId , ", name: " , spellName, " target:", destName, ", amount:", amount, ", absorbed:", absorbed)
    elseif subevent == "SPELL_MISSED" then
        spellId, spellName, spellSchool, missType, isOffHand, amount, critical = select(12, ...)

    elseif sourceGUID == playerGUID and subevent == "SPELL_CAST_SUCCESS" then
        spellId, spellName, spellSchool = select(12, ...)
        if spellId == 265187 then
            print("Demonic Tyrant summoned!")
			local tt = {}
            tt.timestamp = timestamp
            tt.total = 0
			tt.targets = {}
			tt.callback = false
			
            DemonSnaxData.tyrants[#DemonSnaxData.tyrants+1] = tt
        end
    elseif sourceGUID == playerGUID and subevent == "SPELL_SUMMON" then
        spellId, spellName, spellSchool = select(12, ...)
        if spellId == 264119 then
            DemonSnaxData.vfActive = true
            DemonSnaxData.vfExpires = GetTime() + 15
			begForPI()
        end
        --print("Summon!", spellName, spellId)
        --    DemonSnaxData.tyrants[#DemonSnaxData.tyrants+1] = {}
        --    DemonSnaxData.tyrants[#DemonSnaxData.tyrants].timestamp = timestamp
        --    DemonSnaxData.tyrants[#DemonSnaxData.tyrants].total = 0
        --end
    end

--Player-3678-09B406BD
    --print(cooldump(args))
    --print(subevent , ":" , sourceGUID , ", ==playerGUID? "  , (sourceGUID == playerGUID), spellId, spellName, amount, destName)
    if sourceGUID == playerGUID then
        --dcPrint(cooldump({...}))
        if spellId == 267971 then
            --print(cooldump({...}))
            local cur = #DemonSnaxData.tyrants
            --print("cur: ", cur, ", amount:", amount)
            DemonSnaxData.tyrants[cur].total = DemonSnaxData.tyrants[cur].total + amount
			local d = DemonSnaxData.tyrants[cur].targets[destName]
			if d == nil then
				DemonSnaxData.tyrants[cur].targets[destName] = {}
				DemonSnaxData.tyrants[cur].targets[destName].count = 1
				DemonSnaxData.tyrants[cur].targets[destName].damage = amount
			else
				d.count = d.count + 1
				d.damage = d.damage + amount
			end
			if DemonSnaxData.tyrants[cur].callback == false then
				DemonSnaxData.tyrants[cur].callback = true
				C_Timer.After(3, 
				function()
					print("TOTAL: ", DemonSnaxData.tyrants[cur].total, " damage!")
					for i,v in pairs(DemonSnaxData.tyrants[cur].targets) do 
						print("    ", i, "-", v.count,",",v.damage,"damage")
					end
				end)
			end
            
        -- get the link of the spell or the MELEE globalstring
        --local action = spellId and GetSpellLink(spellId) or MELEE
        --print(MSG_CRITICAL_HIT:format(action, destName, amount))
        end
    end

    --updateUI(timestamp)
end


function DemonSnaxFrame:craftEm()
--     DemonSnaxEditBox:SetText("yo\n")
-- DemonSnaxEditBox:Insert("yo\n")

-- local itemName, itemLink = GetItemInfo(114821)

-- DemonSnaxEditBox:SetHyperlinksEnabled(true)

-- DemonSnaxEditBox:Insert(itemName .. "\n")
-- DemonSnaxEditBox:Insert(itemLink)

    local success = C_TradeSkillUI.OpenTradeSkill(773)
    if success ~= true then
        print("Error: Couldn't open the Inscription crafting window")
    end

    for i = 1, #toCraft do
        local recipeItemLink = C_TradeSkillUI.GetRecipeItemLink( toCraft[i].recipeID )
        local itemID = GetItemInfoInstant(recipeItemLink)
        if GetItemCount(itemID) > 0 then
            print("Already have " .. toCraft[i].name .. " in bags")
        else
            print("Crafting " .. toCraft[i].name .. "...")
            C_TradeSkillUI.CraftRecipe(toCraft[i].recipeID, 1)
            -- Right now can only do one recipe per click, TODO
            return
        end
    end
end
