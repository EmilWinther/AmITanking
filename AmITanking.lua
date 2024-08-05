local frame = CreateFrame("Frame")
local aggroText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
aggroText:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
aggroText:Hide()

-- Register for relevant events
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
frame:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")

-- Function to get the aggro percentage
local function GetAggroPercentage()
    local totalAttackingMonsters = 0
    local fullAggroMonsters = 0

    -- Iterate over all group members and their targets
    local prefix = IsInRaid() and "raid" or "party"
    local numMembers = IsInRaid() and GetNumGroupMembers() or GetNumSubgroupMembers()
    
    for i = 0, numMembers do
        local unit = (i == 0) and "player" or prefix..i
        local targetUnit = unit.."target"
        
        if UnitExists(targetUnit) and UnitCanAttack("player", targetUnit) and UnitAffectingCombat(targetUnit) then
            totalAttackingMonsters = totalAttackingMonsters + 1
            local isTanking, status, _, _, _ = UnitDetailedThreatSituation("player", targetUnit)
            if isTanking and status == 3 then
                fullAggroMonsters = fullAggroMonsters + 1
            end
        end
    end

    -- Calculate and return the aggro percentage
    if totalAttackingMonsters > 0 then
        return (fullAggroMonsters / totalAttackingMonsters) * 100
    else
        return 0
    end
end

-- Function to update the aggro text
local function UpdateAggroText()
    local aggroPercentage = GetAggroPercentage()
    aggroText:SetText(string.format("Aggro: %.0f%%", aggroPercentage))
end

-- Event handler function
local function OnEvent(self, event, ...)
    if event == "UNIT_THREAT_LIST_UPDATE" or event == "UNIT_THREAT_SITUATION_UPDATE" then
        UpdateAggroText()
    elseif event == "PLAYER_REGEN_DISABLED" then
        aggroText:Show()
        UpdateAggroText()
    elseif event == "PLAYER_REGEN_ENABLED" then
        aggroText:Hide()
    end
end

-- Set the script for handling events
frame:SetScript("OnEvent", OnEvent)

-- Create a timer to update the aggro text periodically
local updateTimer = 0
frame:SetScript("OnUpdate", function(self, elapsed)
    updateTimer = updateTimer + elapsed
    if updateTimer >= 0.5 then  -- Update every 0.5 seconds
        updateTimer = 0
        if UnitAffectingCombat("player") then
            UpdateAggroText()
        end
    end
end)
