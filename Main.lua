local _, Addon = ...
local events = CreateFrame("Frame")
local loggedIn = false
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        if type(SpellClarityDB) ~= "table" then SpellClarityDB = {} end
        Addon.session.language = SpellClarityDB.language == "svSE" and "svSE" or "enUS"
        loggedIn = true
        if not Addon.Active() then
            print("SpellClarity: paused while Aevum Tooltips is loaded. Disable that addon to use SpellClarity.")
        end
    end
    if loggedIn then Addon.Install() end
end)

SLASH_SPELLCLARITY1 = "/spellclarity"
SlashCmdList.SPELLCLARITY = function(message)
    local language = message:lower():match("^%s*(.-)%s*$")
    if language == "sv" or language == "en" then
        SpellClarityDB.language = language == "sv" and "svSE" or "enUS"
        print("SpellClarity: "..SpellClarityDB.language..". /reload to apply.")
    else
        print("SpellClarity: /spellclarity en | sv — tooltip language; /reload to apply.")
    end
end
