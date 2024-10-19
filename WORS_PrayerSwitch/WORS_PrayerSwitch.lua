-- List of keywords for different stances
local stanceKeywords = {
    melee = {
        "Pound", -- Gmaul
        "Pummel", -- Gmaul
        "Chop", -- Gmaul
        "Hack", -- Gmaul
        "Slash", 
        "Smash", 
        "Stab",  
		"Crush",  
        "Block", 
    },
    range = {
        "Accurate", -- Example keyword; adjust based on actual buff names
        "Rapid", 
        "Longranged",  
    },
    magic = {
        "Spell -", -- Example keyword; adjust based on actual buff names
        "Bash -",
        "Focus",
    }
}

-- Spell ID mappings for each stance
local stanceSpellIDs = {
    magic = { 114087, }, -- Example magic spell IDs
}

-- Icon paths for each stance
local stanceIcons = {
    melee = "Interface\\Icons\\meleepray.blp", 
    range = "Interface\\Icons\\rangepray.blp", 
    magic = "Interface\\Icons\\magicpray.blp", 
    meleeActive = "Interface\\Icons\\active_meleepray.blp", 
    rangeActive = "Interface\\Icons\\active_rangepray.blp", 
    magicActive = "Interface\\Icons\\active_magicpray.blp", 
    meleePrayID = 465,
    rangePrayID = 79500,
    magicPrayID = 79501,
}

-- Set initial transparency values
local frameTransparency = 0.7
local textureTransparency = 1.0

-- Create a frame for the stance/prayer icon
local prayerIconFrame = CreateFrame("Frame", "WORS_PrayerSwitchFrame", UIParent)
prayerIconFrame:SetSize(175, 175)
prayerIconFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
prayerIconFrame:Hide()
prayerIconFrame:SetAlpha(frameTransparency)

-- Create a texture for the icon
prayerIconFrame.texture = prayerIconFrame:CreateTexture(nil, "BACKGROUND")
prayerIconFrame.texture:SetAllPoints(true)
prayerIconFrame.texture:SetAlpha(textureTransparency)

-- Function to check if the player has the correct prayer active
local function PlayerHasActivePrayer(prayID)
    for i = 1, 40 do
        local name, _, _, count, dispelType, duration, expires, caster, isStealable, _, spellID = UnitBuff("player", i)
        if not spellID then break end
        if spellID == prayID then
            return true -- Prayer is active
        end
    end
    return false -- Prayer is not active
end

-- Function to update the icon and print the target's stance in chat
local function UpdatePrayerIcon()
    if UnitExists("target") then
        local stanceDetected
        local foundBuffs = false -- To track if any buffs are found

        for i = 1, 40 do
            local name, _, _, count, dispelType, duration, expires, caster, isStealable, _, spellID = UnitBuff("target", i)
            if not spellID then break end

            -- First check the buff against specific spell IDs for priority
            for stance, ids in pairs(stanceSpellIDs) do
                for _, id in ipairs(ids) do
                    if spellID == id then
                        stanceDetected = stance
                        foundBuffs = true
                        break
                    end
                end
                if foundBuffs then break end
            end

            -- If no stance was detected by ID, check if the buff name contains any of the stance keywords
            if not foundBuffs then
                for _, keyword in ipairs(stanceKeywords.melee) do
                    if name and name:find(keyword) then
                        stanceDetected = "melee"
                        foundBuffs = true
                        break
                    end
                end

                if not foundBuffs then
                    for _, keyword in ipairs(stanceKeywords.range) do
                        if name and name:find(keyword) then
                            stanceDetected = "range"
                            foundBuffs = true
                            break
                        end
                    end
                end

                if not foundBuffs then
                    for _, keyword in ipairs(stanceKeywords.magic) do
                        if name and name:find(keyword) then
                            stanceDetected = "magic"
                            foundBuffs = true
                            break
                        end
                    end
                end
            end

            if foundBuffs then break end
        end

        if foundBuffs and stanceDetected then
            local prayID
            if stanceDetected == "melee" then
                prayID = stanceIcons.meleePrayID
            elseif stanceDetected == "range" then
                prayID = stanceIcons.rangePrayID
            elseif stanceDetected == "magic" then
                prayID = stanceIcons.magicPrayID
            end

            -- Check if the player has the correct prayer active
            local isActivePrayer = PlayerHasActivePrayer(prayID)

            -- Set the texture to the active or normal icon based on the prayer status
            if isActivePrayer then
                prayerIconFrame.texture:SetTexture(stanceIcons[stanceDetected .. "Active"])
            else
                prayerIconFrame.texture:SetTexture(stanceIcons[stanceDetected])
            end
            
            prayerIconFrame.texture:SetTexCoord(1, 0, 0, 1)
            prayerIconFrame:Show()
        else
            prayerIconFrame:Hide()
        end
    else
        prayerIconFrame:Hide()
    end
end

-- Make the frame movable
prayerIconFrame:SetMovable(true)
prayerIconFrame:EnableMouse(true)
prayerIconFrame:SetScript("OnMouseDown", function(self)
    self:StartMoving()
end)
prayerIconFrame:SetScript("OnMouseUp", function(self)
    self:StopMovingOrSizing()
end)

-- Event frame to handle target changes and buff updates
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_TARGET_CHANGED" then
        UpdatePrayerIcon()
    elseif event == "UNIT_AURA" then
        local unit = ...
        if unit == "target" or unit == "player" then
            UpdatePrayerIcon()
        end
    end
end)

-- Update icon immediately when addon is loaded
UpdatePrayerIcon()
