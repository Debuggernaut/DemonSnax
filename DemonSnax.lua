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

print("Hello, world of warcraft!  Sincerely, DemonSnax")

DemonSnaxData = {}
DemonSnaxData.vfActive = false;
DemonSnaxData.vfExpires = 0;
DemonSnaxData.uiUpdateDelay = 1.0/60.0;
DemonSnaxData.nextUpdate = 0;


local DemonSnaxFrame = CreateFrame("FRAME", "DemonSnaxFrame")

local function OnEvent(self, event)
    print(CombatLogGetCurrentEventInfo())
end

DemonSnaxFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
DemonSnaxFrame:SetScript("OnEvent", OnEvent)

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

--TODO: REMOVE THIS BEFORE SHIPPING THE ADDON
-- If you are not me and you are reading this, I'm very sorry
-- that I accidentally shipped it
--
-- Sincerely,
--   A Fool
local function OnEventTraceLoaded()
	EventTrace.LogEvent_Original = EventTrace.LogEvent
	EventTrace.LogEvent = LogEvent
end

if EventTrace then
	OnEventTraceLoaded()
else
	local frame = CreateFrame("Frame")
	frame:RegisterEvent("ADDON_LOADED")
	frame:SetScript("OnEvent", function(self, event, ...)
		if event == "ADDON_LOADED" and (...) == "Blizzard_EventTrace" then
			OnEventTraceLoaded()
			self:UnregisterAllEvents()
		end
	end)
end
--------------------------------

coolKludge = {}
coolKludge.total = 0
DemonSnaxFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then  
        handleEvent(CombatLogGetCurrentEventInfo())
    end
end)

-- 1. Pick HELLOWORLD as the unique identifier.
-- 2. Pick /hiw and /hellow as slash commands (/hi and /hello are actual emotes)
SLASH_DEMONSNAX1, SLASH_DEMONSNAX2 = '/ds', '/DemonSnax'; -- 3.
function SlashCmdList.DEMONSNAX(msg, editbox) -- 4.
 print("Hello, World!");
 DemonSnax_Frame:Show()
 dcPrint("test");
end

function updateUI(timestamp)
    if timestamp > DemonSnaxData.nextUpdate then
        local dbg = false
        DemonSnaxData.nextUpdate = timestamp + DemonSnaxData.uiUpdateDelay
        if (DemonSnaxData.vfExpires == 0) then
            DemonSnaxData.vfExpires = timestamp + 15
            dbg = true
        end

        if (timestamp > DemonSnaxData.vfExpires + 5) then
            DemonSnaxData.vfExpires = 0
        end

        local handCastTime = 0
        local name, rank, icon, tyrantCastTime, minRange, maxRange = GetSpellInfo("Summon Demonic Tyrant")
        name, rank, icon, handCastTime, minRange, maxRange = GetSpellInfo("Hand of Gul'dan")
        tyrantCastTime = tyrantCastTime / 1000.0
        handCastTime = handCastTime / 1000.0
        local shadowBoltTime = tyrantCastTime
        local demonBoltTime = handCastTime
        local dogTime = demonBoltTime

        VilefiendTime:SetText(string.format("%.1f seconds", DemonSnaxData.vfExpires - timestamp))
        SBTime:SetText(string.format("%.1f seconds", tyrantCastTime))
        HandTime:SetText(string.format("%.1f seconds", handCastTime))

        if dbg then
            local bigHands = 2
            local setupTime = 15 --15 seconds after you cast Vilefiend to get out 1x bolt,
                -- 1x dogs, 1x hand w/ 3 shards, 1x bolt, 1x hand with 3 shards, (filler)
                -- then Summon Demonic Tyrant (+200ms leeway)
            local fillerTime = setupTime - tyrantCastTime - dogTime - 2*shadowBoltTime - 2*handCastTime - 0.2
            local bigHandTime = 3 * shadowBoltTime + handCastTime
            bigHands = bigHands + math.floor(fillerTime/bigHandTime)
            local remaining = fillerTime % bigHandTime
            remaining = remaining - shadowBoltTime - handCastTime
            local smallHand = 0
            if (remaining > 0) then
                local extraBolts = math.floor(remaining/shadowBoltTime)
                smallHand = 1 + extraBolts
            end
            print("filler:", fillerTime, " bht:", bigHandTime, " rem:", remaining, ", bHs:", bigHands)

            local imps = bigHands*3 + smallHand
            local hands = bigHands
            if (smallHand > 0) then
                hands = hands + 1
            end
    
            local bolts = imps
            if smallHand == 0 and remaining > shadowBoltTime then
                bolts = bolts + 1
            end
    
            MaxImpsNoCores:SetText(string.format("%d", imps))
            XBoltsYHands200:SetText(string.format("Time for %d bolts and %d hands (200ms margin)", bolts, hands))
    
            --doh, looks like you need to do 2x shadowbolt after the vilefiend, and if you get demonic calling you need to add
            -- a filler spell after that if you want your dogs to get hit with the tyrant when he comes out
            -- 
        end
    end
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

    elseif subevent == "SPELL_CAST_SUCCESS" then
        spellId, spellName, spellSchool = select(12, ...)
        if spellId == 265187 then
            print("Demonic Tyrant summoned!")
            coolKludge.total = 0
        end
    end

--Player-3678-09B406BD
    --print(cooldump(args))
    --print(subevent , ":" , sourceGUID , ", ==playerGUID? "  , (sourceGUID == playerGUID), spellId, spellName, amount, destName)
    if sourceGUID == playerGUID then
        dcPrint(cooldump({...}))
        if spellId == 267971 then
            print(cooldump({...}))
            coolKludge.total = coolKludge.total + amount
            print("DemonSnax dealt ", coolKludge.total, " damage")
        -- get the link of the spell or the MELEE globalstring
        --local action = spellId and GetSpellLink(spellId) or MELEE
        --print(MSG_CRITICAL_HIT:format(action, destName, amount))
        end
    end

    updateUI(timestamp)
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
