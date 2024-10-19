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
    --melee = { 114008, 114009, 114010, 114011 }, -- Example melee spell IDs
    --range = { 114012, 114013 }, -- Example ranged spell IDs
    magic = { 114087, }, -- Example magic spell IDs
}

-- Icon paths for each stance
local stanceIcons = {
    melee = "Interface\\Icons\\meleepray.blp", -- Replace with actual path for melee icon
    range = "Interface\\Icons\\rangepray.blp", -- Replace with actual path for ranged icon
    magic = "Interface\\Icons\\magicpray.blp", -- Replace with actual path for magic icon
    meleeActive = "Interface\\Icons\\active_meleepray.blp", -- Replace with actual path for melee active icon
    rangeActive = "Interface\\Icons\\active_rangepray.blp", -- Replace with actual path for ranged active icon
    magicActive = "Interface\\Icons\\active_magicpray.blp", -- Replace with actual path for magic active icon
    meleePrayID = 465,
    rangePrayID = 79500,
    magicPrayID = 79501,
}

-- Create a frame for the stance/prayer icon
local prayerIconFrame = CreateFrame("Frame", "WORS_PrayerSwitchFrame", UIParent)
prayerIconFrame:SetSize(175, 175) -- Adjust the size of the icon
prayerIconFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0) -- Set the position of the frame
prayerIconFrame:Hide() -- Hide initially

-- Create a texture for the icon
prayerIconFrame.texture = prayerIconFrame:CreateTexture(nil, "BACKGROUND")
prayerIconFrame.texture:SetAllPoints(true) -- Texture covers the entire frame

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
    if UnitExists("target") and UnitIsPlayer("target") then
        print("Checking buffs for target: " .. UnitName("target"))

        local stanceDetected
        local foundBuffs = false -- To track if any buffs are found

        for i = 1, 40 do
            local name, _, _, count, dispelType, duration, expires, caster, isStealable, _, spellID = UnitBuff("target", i)
            if not spellID then break end

            -- Print all buffs for debugging
            print(string.format("Buff [%d]: %s (Spell ID: %d)", i, name or "nil", spellID))

            -- First check the buff against specific spell IDs for priority
            for stance, ids in pairs(stanceSpellIDs) do
                for _, id in ipairs(ids) do
                    if spellID == id then
                        stanceDetected = stance
                        foundBuffs = true
                        print(stance:gsub("^%l", string.upper) .. " stance detected by ID: " .. name .. " (Spell ID: " .. spellID .. ")")
                        break
                    end
                end
                if foundBuffs then break end -- Stop checking if stance is found
            end

            -- If no stance was detected by ID, check if the buff name contains any of the stance keywords
            if not foundBuffs then
                for _, keyword in ipairs(stanceKeywords.melee) do
                    if name and name:find(keyword) then
                        stanceDetected = "melee" -- Set stance as melee
                        foundBuffs = true
                        print("Melee stance detected: " .. name .. " (Spell ID: " .. spellID .. ")")
                        break
                    end
                end

                if not foundBuffs then
                    for _, keyword in ipairs(stanceKeywords.range) do
                        if name and name:find(keyword) then
                            stanceDetected = "range" -- Set stance as range
                            foundBuffs = true
                            print("Ranged stance detected: " .. name .. " (Spell ID: " .. spellID .. ")")
                            break
                        end
                    end
                end

                if not foundBuffs then
                    for _, keyword in ipairs(stanceKeywords.magic) do
                        if name and name:find(keyword) then
                            stanceDetected = "magic" -- Set stance as magic
                            foundBuffs = true
                            print("Magic stance detected: " .. name .. " (Spell ID: " .. spellID .. ")")
                            break
                        end
                    end
                end
            end

            if foundBuffs then break end -- Stop checking buffs if any stance is found
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
            
            -- Flip the icons
            prayerIconFrame.texture:SetTexCoord(1, 0, 0, 1) -- Flips the icon horizontally
            prayerIconFrame:Show() -- Show the frame with the icon
            print("Displaying icon for stance: " .. stanceDetected)
        else
            prayerIconFrame:Hide() -- Hide the frame if no stance is detected
            print("No stance detected.")
        end
    else
        prayerIconFrame:Hide() -- Hide the frame if no valid target
        print("No valid target.")
    end
end

-- Make the frame movable
prayerIconFrame:SetMovable(true)
prayerIconFrame:EnableMouse(true)

-- Allow dragging the frame
prayerIconFrame:SetScript("OnMouseDown", function(self)
    self:StartMoving()
end)

prayerIconFrame:SetScript("OnMouseUp", function(self)
    self:StopMovingOrSizing()
end)

-- Event frame to handle target changes and buff updates
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED") -- Update when the target changes
eventFrame:RegisterEvent("UNIT_AURA") -- Update when a unit's aura (buffs) change
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_TARGET_CHANGED" then
        UpdatePrayerIcon() -- Call update on target change
    elseif event == "UNIT_AURA" then
        local unit = ... 
        if unit == "target" then
            UpdatePrayerIcon() -- Call update if aura changes on the target
        end
    end
end)

-- Update icon immediately when addon is loaded
UpdatePrayerIcon()
