-- handles slash commands
local addonName, cobdt = ...
local module = {}
cobdt.modules.slash = module

-- cobdt module
local options, db
function module.init(opt, database)
    options, db = opt, database
end

-- cobdt locals
local addonPrint = cobdt.addonPrint
local debugPrint = cobdt.debugPrint
local play = cobdt.play
local firstToUpper = cobdt.firstToUpper
local commandAlias
local player = cobdt.player
local handlers = {}


-- localise lua stuff
local format = string.format

-- misc data
local validChannels
do
    local channelList = {
        master = "Master",
        sfx = "SFX",
        music = "Music",
        ambience = "Ambience",
        dialog = "Dialog",
    }
    local channelList_mt = {
        __call = function(t)
            local str = ""
            for k in pairs(t) do
                str = str .. k .. ", "
            end
            str = str:sub(1, #str-2)

            return str
        end
    }
    validChannels = setmetatable(channelList, channelList_mt)
end

-- SLASH_XX setup
SLASH_CoBDT1 = "/cobdt"

-- holds all the final command handlers
handlers.help = {
    command = function()
        addonPrint("Valid commands for CoBDT are;")

        for label, cmd in pairs(handlers) do
            local argHint = cmd.hint or ""
            local debug = ""
            local desc = ""
            local skip = false

            -- add debug flag?
            if cmd.debug then
                if options.debug then
                    debug = " |cffaf0000[DEBUG]|r "
                else
                    skip = true
                end
            end

            if not skip then

                -- add command aliases
                local aliases = {}
                for key, handler in pairs(commandAlias) do
                    if handler == cmd then
                        aliases[#aliases+1] = key
                    end
                end
                local slashCmds = ("|cff00f000/cobdt %s|r "):format(table.concat(aliases, ", "))

                -- add argument hint?
                if argHint then
                    argHint = "|cffC0C0C0" .. argHint .. "|r"
                end

                -- add description
                if cmd.description then
                    desc = "\n  > |cffC0FFFF"..cmd.description.."|r"
                end

                print(slashCmds .. argHint .. debug .. desc)
            else
                -- do nothing
            end
        end
        return true
    end,

    description = "Shows you this very list, that you are already reading..."
}

handlers.testPlay = {
    command = function()
        C_Timer.After(0.1, function()
            play("test")
        end)
        C_Timer.After(0.2, function()
            play("test")
        end)
        C_Timer.After(0.3, function()
            play("test")
        end)
        return true
    end,

    debug = true,

    description = "Plays a triple wilhelm scream."
}

handlers.listAll = {
    command = function()
        addonPrint("Currently known TM characters:")
        for main, data in pairs(cobdt.characterData) do
            local lst = firstToUpper(main)
            if next(data.alts) then
                lst = lst .. " |cffa9a9a9(" .. table.concat(data.alts, ", ") .. ")|r"
            end

            print(lst)
        end

        return true
    end,

    description = "List all currently known TM characters.",
}

handlers.toggleMute = {
    command = function(args)
        if args[2] and type(args[2]) == "string" then
            local character = strtrim(args[2])
            local member = cobdt.isTMCharacter(character)

            if member then
                if db.mutedCharacters[member] then
                    db.mutedCharacters[member] = nil
                else
                    db.mutedCharacters[member] = true
                end

                local newState = db.mutedCharacters[member] and ("|cffff0000" .. "Muted") or ("|cff00ff00" .. "Unmuted")
                addonPrint("%s is now %s.", firstToUpper(member), newState)
                return true
            else
                addonPrint("No known TM character called %s.", firstToUpper(character))
                return false
            end
        else
            options.muteall = not options.muteall
            local newState = options.muteall and ("|cffff0000" .. "CoBDT Muted") or ("|cff00ff00" .. "CoBDT Unmuted")
            addonPrint(newState)
            return true
        end
    end,

    description = "Toggles muting CoBDT completely, or if character name provided, mutes that specific character.",
    hint = "<main or alt>"
}

handlers.listMuted = {
    command = function()
        if next(db.mutedCharacters) then
            addonPrint("Muted characters:")
            for character in pairs(db.mutedCharacters) do
                print(firstToUpper(character))
            end
        else
            addonPrint("There are no muted characters.")
        end

        return true
    end,

    description = "Lists all currently muted (main) characters."
}

handlers.toggleMuteSpecial = {
    command = function()
        options.mutespecial = not options.mutespecial
        local newState = options.mutespecial and ("|cffff0000" .. "Secret Muted") or ("|cff00ff00" .. "Secret Unmuted")
        addonPrint(newState)
        return true
    end,

    description = "Toggles muting the secret thing.. Rule #1 about the secret thing: You don't ask about the secret thing."
}

handlers.toggleSelf = {
    command = function()
        options.muteself = not options.muteself
        local newState = options.muteself and ("|cffff0000" .. "Muted") or ("|cff00ff00" .. "Unmuted")
        addonPrint("Play own death is %s", newState)
        return true
    end,

    description = "Toggles muting your own death announces / sound effect."
}

handlers.toggleDebug = {
    command = function()
        options.debug = not options.debug
        local newState = options.debug and ("|cff00ff00" .. "Enabled") or ("|cffff0000" .. "Disabled")
        addonPrint("debug is %s", newState)
        return true
    end,

    description = "Toggles debugging mode (don't touch unless Av told you to).",
    debug = true
}

handlers.setGetChannel = {
    command = function(args)
        if args[2] then
            if type(args[2]) == "string" then
                local channel = validChannels[strtrim(args[2])]
                if channel then
                    addonPrint("Changed output channel to '%s'", channel)
                    options.channel = channel
                else
                    addonPrint("Invalid output channel '%s'! Must be one of: [%s]", args[2], validChannels())
                end
            else
                addonPrint("Current output channel is '%s'. Options are: %s", options.channel, validChannels())
            end

            return true
        else
            return false
        end
    end,

    description = "Sets which audio channel is used to play CoBDT effects. If used with no arguments, shows current setting.",
    hint = "<sound channel>",
}

handlers.getAlts = {
    command = function(args)
        if args[2] then
            local main = strtrim(args[2])

            if cobdt.isTMCharacter(main) then
                if #cobdt.characterData[main].alts > 0 then
                    local alts = table.concat(cobdt.characterData[main].alts, ", ")
                    addonPrint("%s has %i alts: [%s]", firstToUpper(main), #cobdt.characterData[main].alts, alts)
                else
                    addonPrint("%s has no alts", firstToUpper(main))
                end
            else
                addonPrint("No known TM main characters called %s", firstToUpper(main))
            end

            return true
        else
            return false
        end
    end,

    description = "Lists all registered alts for a main character.",
    hint = "<main name>"
}

handlers.setAlt = {
    command = function(args)
        if args[2] and args[3] then
            local main = strtrim(args[2])
            local newalt = strtrim(args[3])

            if cobdt.isTMCharacter(main) then
                local dbec = db.extraCharacters
                if not dbec[main] then dbec[main] = {} end

                if tContains(dbec[main], newalt) then
                    addonPrint("Alt %s already added to %s", firstToUpper(newalt), firstToUpper(main))
                else
                    if not dbec[main] then
                        dbec[main] = {}
                    end
                    tinsert(dbec[main], newalt)
                    cobdt.patchCharacterList(db.extraCharacters)

                    addonPrint("created a new alt for main %s called %s", firstToUpper(main), firstToUpper(newalt))
                end
            else
                addonPrint("No known TM main characters called %s, no alt added", firstToUpper(main))
            end

            return true
        else
            return false
        end
    end,

    description = "Add a new alt to a known TM main character.",
    hint = "<main name> <alt name>",
}

handlers.removeAlt = {
    command = function(args)
        if not (args[2] and args[3]) then
            return false
        end

        local main = strtrim(args[2])
        local alt = strtrim(args[3])

        if cobdt.isTMCharacter(main) then
            local dbec = db.extraCharacters
            if dbec[main] then
                local found = false
                for i, name in pairs(dbec[main]) do
                    if name == alt then
                        table.remove(dbec[main], i)
                        found = true
                    end
                end

                if not next(dbec[main]) then
                    dbec[main] = nil
                end

                if found then
                    addonPrint("deleted alt %s for main %s", firstToUpper(alt), firstToUpper(main))
                else
                    addonPrint("unknown alt %s for main %s", firstToUpper(alt), firstToUpper(main))
                end
            else
                addonPrint("main %s has no alts to remove", firstToUpper(main))
            end
        else
            addonPrint("No known TM main characters called %s, no alt removed", firstToUpper(main))
        end

        return true
    end,

    description = "Remove an alt from a known main. Only works for alts you added via /cobdt setalt",
    hint = "<main name> <alt name>",
}

handlers.queryName = {
    command = function(args)
        if args[2] then
            local query = firstToUpper(args[2])
            local tmChar = cobdt.isTMCharacter(query)
            local mainCharacter = tmChar and firstToUpper(tmChar) or false
            addonPrint("\"%s\" %s", query, mainCharacter and format("is a known TM character (main: \"%s\")", mainCharacter) or ("is NOT a known TM character"))

            return true
        else
            return false
        end
    end,

    description = "Check whether a character name is recognized in CoBDT, searches all mains and alts.",
    hint = "<name to query>",
}

handlers.fakeDeathEvent = {
    command = function(args)
        if args[2] then
            play(args[2])
            debugPrint("|cffaf0000Fake death: %s", args[2])
            return true
        else
            return false
        end
    end,

    debug = true,
    description = "Play sound and show a notification as if <character> died. Does not increase death counter nor show for other people.",
    hint = "<character name>"
}

handlers.fakeSaelEvent = {
    command = function()
        play("saelspecial")
        return true
    end,

    description = "Hmm. Mysterious.",
    debug = true,
}

handlers.wipeSettings = {
    command = function()
        addonPrint("Wiped settings & (extra) alt database")
        wipe(db.extraCharacters)
        wipe(CoBDT_Options)
        cobdt.verifyOptions()
        return true
    end,

    description = "Wipes out your CoBDT settings and your custom alt database, if any.",
}

handlers.checkGuilded = {
    command = function()

        if IsInGuild() then
            local guild = GetGuildInfo("player")
            if guild == cobdt.guildName then
                addonPrint("%s is a member of <%s>", player, cobdt.guildName)
            else
                addonPrint("%s is |cffff0000NOT|r a member of <%s>", player, cobdt.guildName)
            end
        else
            addonPrint("%s is not in a guild.", player)
        end

        return true
    end,

    description = "Check whether the current character is detected as being a member of the <" .. cobdt.guildName .. "> guild.",
}

-- picks the appropriate handler based on keywords / aliases
commandAlias = {
    mute = handlers.toggleMute,
    muteself = handlers.toggleSelf,
    channel = handlers.setGetChannel,
    mutespecial = handlers.toggleMuteSpecial,
    muted = handlers.listMuted,
    mutelist = handlers.listMuted,
    listmuted = handlers.listMuted,

    -- character db stuff
    list = handlers.listAll,
    characters = handlers.listAll,
    setalt = handlers.setAlt,
    addalt = handlers.setAlt,
    alts = handlers.getAlts,
    listalts = handlers.getAlts,
    removealt = handlers.removeAlt,

    -- misc
    wipe = handlers.wipeSettings,
    help = handlers.help,

    -- debug-ish stuff
    test = handlers.testPlay,
    query = handlers.queryName,
    fake = handlers.fakeDeathEvent,
    fakespecial = handlers.fakeSaelEvent,
    debug = handlers.toggleDebug,
    guilded = handlers.checkGuilded,
}

-- handlers incoming slash cmd and dispatches to handler if valid alias match can be made
local function commandHandler(msg, EditBox)
    msg = strtrim(msg)

    -- split into parts
    local args = {}
    for word in string.gmatch(msg, "[^ ]+") do
        tinsert(args, word:lower()) -- ALL INCOMING WORDS ARE TRIMMED AND LOWERCASED
    end

    local cmd = args[1] or nil
    if not cmd then
        addonPrint("No command.")
        return false
    else
        if commandAlias[cmd] then
            local success, err = commandAlias[cmd].command(args)

            if not success then
                if commandAlias[cmd].hint then
                    addonPrint("Usage: /cobdt %s %s", cmd, commandAlias[cmd].hint)
                else
                    addonPrint("Error trying to use /cobdt %s", cmd)
                end
            end
        else
            if msg ~= "" then
                addonPrint("Unknown command '%s'", msg)
                return
            end
        end
    end
end

SlashCmdList["CoBDT"] = commandHandler