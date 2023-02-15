-- handles initial setup, savedvariables, and initial event registration
local addonName, cobdt = ...
cobdt.modules = {}

-- event frame setup --
-----------------------
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

-- lua locals
local format = string.format

-- CoBDT locals
local addonMsgPrefix = "CoBDTMsg"
local eventHandlers = {}
local options = {}
local db = {}

-- TODO: fix a different colour scheme

local colors = {
    tm_green = "|cff00af00",
    tm_red = "|cffff0000",
    tm_purple = "|cffff00ff",
    tm_debug = "|cffafaf00",
}

-- option handling
local function verifyOptions()
    local opts = {
        channel = "Master",
        muteall = false,
        muteself = false,
        debug = false,
        mutespecial = false,
        timeout = 5,
    }

    for k, v in pairs(opts) do
        if not CoBDT_Options[k] then
            CoBDT_Options[k] = v
        end
    end
end

-- init or patch db
local function verifyDB()
    local dbstruct = {
        extraCharacters = {},
        deathcount = 0,
        mutedCharacters = {}
    }

    for k, v in pairs(dbstruct) do
        if (not db[k]) or (type(db[k]) ~= type(v)) then
            db[k] = v
        end
    end
end

-- print helper
local function addonPrint(msg, ...)
    if ... then
        msg = format(msg, ...)
    end

    print(format("%sCoB|r%sDT|r:: %s", colors.tm_green, colors.tm_purple, msg))
end
cobdt.addonPrint = addonPrint

-- debugPrint helper
local function debugPrint(msg, ...)
    if ... then
        msg = format(msg, ...)
    end

    if options.debug then
        print(format("%sCoB|r%sDT%sDebug|r:: %s", colors.tm_green, colors.tm_purple, colors.tm_debug, msg))
    end
end
cobdt.debugPrint = debugPrint

-- handle addon load complete
function eventHandlers.ADDON_LOADED(self, ...)
    if ... == addonName then
        frame:UnregisterEvent("ADDON_LOADED")

        -- Hook up SavedVariables: CoBDT_Options, CoBDT_DB
        CoBDT_Options = CoBDT_Options or {}
        options = CoBDT_Options
        verifyOptions()

        CoBDT_DB = CoBDT_DB or {}
        db = CoBDT_DB
        verifyDB()

        -- initialize all other addon files now that we have the SavedVariables figured out
        for name, mod in pairs(cobdt.modules) do
            mod.init(options, db, frame)

            debugPrint("cobdt initialized module [%s]", name)
        end

        if db.extraCharacters then
            cobdt.patchCharacterList(db.extraCharacters)
        end

        local identity = cobdt.isCoBCharacter(cobdt.player)
        addonPrint("Loaded. You are %s%s|r.", identity and "|cff00aa00" or "|cffaa0000", identity and cobdt.firstToUpper(identity) or "not a recognized CoB member")
    end
end

function eventHandlers.PLAYER_ENTERING_WORLD(self, ...)
    if not C_ChatInfo.IsAddonMessagePrefixRegistered(addonMsgPrefix) then
        C_ChatInfo.RegisterAddonMessagePrefix(addonMsgPrefix)
    end
end

-- hook up events to handlers
frame:SetScript("OnEvent", function(self, event, ...)
    if eventHandlers[event] then
        eventHandlers[event](self, ...)
    end
end)

-- gather and export some info
cobdt.player = GetUnitName("player")
cobdt.playerClass  = UnitClassBase("player")

-- export some stuff to addon namespace
cobdt.addonMsgPrefix = addonMsgPrefix
cobdt.eventHandlers = eventHandlers
cobdt.frame = frame
cobdt.options = options
cobdt.db = db
cobdt.verifyOptions = verifyOptions
cobdt.guildName = "Cats on Balconies"