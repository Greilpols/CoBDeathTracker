-- core CoBDT code
local addonName, cobdt = ...
local module = {}
cobdt.modules.core = module

-- cobdt module
local options, db, frame
function module.init(opt, database, addonframe)
    options, db, frame = opt, database, addonframe

    frame:RegisterEvent("CHAT_MSG_ADDON")
    frame:RegisterEvent("PLAYER_DEAD")
    frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end

-- lua locals
local format = string.format

-- module locals
local addonMsgPrefix = cobdt.addonMsgPrefix
local eventHandlers = cobdt.eventHandlers
local addonPrint = cobdt.addonPrint
local debugPrint = cobdt.debugPrint
local player = cobdt.player
local CoBDTEventHandlers = {}
local deathEventCooldown = false

-- helpers
local function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end
cobdt.firstToUpper = firstToUpper

-- play a sound by "id" (usually character name)
local function play(id)
    local soundFile, errmsg = cobdt.getCharacterSound(id)

    if soundFile then
        PlaySoundFile(soundFile, options.channel)
    else
        debugPrint("getCharacterSound(%s) error: %s", id, errmsg)
    end
end
cobdt.play = play

-- makes every value in the table equal to its key
local function enumify(t)
    for k in pairs(t) do
        t[k] = k
    end

    return t
end

-- table data
local allowedInstanceTypes = {
    none = true,
    pvp = false,
    party = true,
    raid = true,
    scenario = false,
}
enumify(allowedInstanceTypes)

local addonMessageChannels = {
    PARTY = true,
    RAID = true,
    INSTANCE_CHAT = true,
    GUILD = true,
    OFFICER = true,
    WHISPER = true,
    CHANNEL = true,
    SAY = true,
    YELL = true,
}
enumify(addonMessageChannels)

-- CoBDT addonMessage types
local CoBDTEvent = {
    SAEL_DIED = true,
    MEMBER_DIED = true,
    OTHER_DIED = true,
    NEW_MOUNT_ACQUIRED = true,
}
enumify(CoBDTEvent)

-- addon msg stuff
-- broadcasts a message
local function broadcast(data)
    local event, msg, channel, target = data.event, data.message, data.channel, data.target

    if not (msg and channel) then
        debugPrint("CoBDT_ERROR: Missing argument to broadcast()")
        if not msg then
            debugPrint("Missing: msg")
        end
        if not channel then
            debugPrint("Missing: channel")
        end

        return
    end

    local payload = format("%s#%s", event, data.message)

    debugPrint("AddonMsg Echo <%s> %s: %s", channel, target and ("["..target.."]") or "", payload)

    if addonMessageChannels[channel] then
        C_ChatInfo.SendAddonMessage(addonMsgPrefix, payload, channel, target)
    else
        addonPrint("|cffff0000Error:|r Tried to use invalid AddonCommsChannel '%s'", channel)
    end
end

-- handle CoBDT events, these are for INCOMING events.
function CoBDTEventHandlers.MEMBER_DIED(name)
    if not options.muteall then
        if not db.mutedCharacters[name] then
            cobdt.play(name)
        else
            debugPrint("Skipped muted character effect: %s", name)
        end
    end
end

function CoBDTEventHandlers.SAEL_DIED(character, count)
    local playerRoot = cobdt.isCOBCharacter(player)

    if (playerRoot == "saelaris") or UnitInRaid(character) or UnitInParty(character) then
        -- don't do anything if we are in party with or identify as saelaris
        return
    elseif not (options.mutespecial or options.muteall) then
        print(format("|cff8f8f8fSomewhere, somehow, |cffC79C6ESaelaris|r died. Again."))
        play("saelspecial")
    end
end

function CoBDTEventHandlers.NEW_MOUNT_ACQUIRED(character)
    if not (options.mutespecial or options.muteall) then
        play("hiddeneasteregg")
    end
end

-- handle WoW events
function eventHandlers.CHAT_MSG_ADDON(self, prefix, message, channel, sender, target, _, localId, channelName, _)
    if prefix == addonMsgPrefix then
        -- print(table.concat({message, channel, sender, target, channelName}, ", "))
        local eventData = {}

        for piece in string.gmatch(message, "[^#]+") do
            tinsert(eventData, piece)
        end

        -- verify that it's a valid CoBDT event
        local event = eventData[1]
        if CoBDTEventHandlers[event] then
            -- call event with all payload packets as arguments
            CoBDTEventHandlers[event](unpack(eventData, 2))
            debugPrint("dispatched %s event. Payload: %s", event, table.concat(eventData, ", ", 2))
        else
            debugPrint("|cffff0000CoBDTError: Unhandled event: %s", tostring(event))
        end
    end
end

function eventHandlers.PLAYER_DEAD()
    if deathEventCooldown then
        -- bail immediately, we already triggered this event very recently (bug, or player dying again REALLY FAST!)
        return
    else
        db.deathcount = db.deathcount + 1
        deathEventCooldown = true
        C_Timer.After(options.timeout, function() deathEventCooldown = false end)
    end

    local member = cobdt.isCOBCharacter(player)
    local guilded = IsInGuild() and GetGuildInfo("player") == cobdt.guildName
    local isParty = IsInGroup()
    local isRaid = IsInRaid()
    local instanced, instanceType = IsInInstance()

    if member then
        if member == "saelaris" then
            if guilded and allowedInstanceTypes[instanceType] then
                broadcast{
                    event = CoBDTEvent.SAEL_DIED,
                    message = string.lower(player),
                    channel = addonMessageChannels.GUILD,
                }
            else
                -- do nothing
            end
        end

        if allowedInstanceTypes[instanceType] then
            local msgChannel

            if isParty and not isRaid then
                msgChannel = addonMessageChannels.PARTY
            elseif isParty and isRaid then
                msgChannel = addonMessageChannels.RAID
            else
                -- bail, we're in an instance, but not in a party or raid, i.e. solo
                return
            end

            broadcast{
                event = CoBDTEvent.MEMBER_DIED,
                message = member,
                channel = msgChannel,
            }
        else
            -- do nothing?
        end
    end
end

function eventHandlers.UNIT_SPELLCAST_SUCCEEDED(null, caster, something, spellID)
    --Lack of actual proper documentation makes the fishing for in game bits a bit more tricky
    --debugPrint("SpellID: %s", spellID) -- 55884 is the (only) accurate one found so far; also includes some pets
    --Does not break anything either, so entirely safe to use; worst case scenario it goes off when someone gets a pet
    if spellID == 55884 and caster == "player" then
        broadcast{
                event = COBDTEvent.NEW_MOUNT_ACQUIRED,
                message = "hiddeneasteregg", -- TODO find fitting name for mount acquired
                channel = addonMessageChannels.GUILD,
            }
            -- TODO: Remove this and make it a full function ala saelspecial
    end
end