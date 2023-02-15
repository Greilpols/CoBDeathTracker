-- manages stuff and things, or something, I don't know anymore
local addonName, cobdt = ...
local module = {}
cobdt.modules.manager = module

-- cobdt module
local options, db
function module.init(opt, database)
    options, db = opt, database
end

-- module locals
local debugPrint = cobdt.debugPrint
local characterData = cobdt.characterData

-- paths
local pre = "Interface\\AddOns\\CoBDeathTracker\\Sounds\\"
local pre_special = "Interface\\AddOns\\CoBDeathTracker\\Sounds\\wilhelm_distant\\"
local post = ".mp3"
local testsound = "wilhelm"

-- sekrit speshul
local saelspecial = {
    "wilhelm_echo_left",
    "wilhelm_echo_right",
    "wilhelm_faded_left",
    "wilhelm_faded_right",
    "wilhelm_left",
    "wilhelm_right",
}

-- retrieves a sound by mian character name
function cobdt.getCharacterSound(id)
    if id == "test" then
        return pre .. testsound .. post
    elseif id == "saelspecial" then
        return pre_special .. saelspecial[math.random(1, #saelspecial)] .. post
    else
        local main = cobdt.isTMCharacter(id)
        if main then
            if characterData[main].sound then
                return pre .. characterData[main].sound .. post
            else
                return false, string.format("no sound: %s", main)
            end
        else
            return false, string.format("not a TM character: %s. This is a strange error, and you should screenshot this message and tell Avael.", id)
        end
    end
end

-- determines if <query> belongs to a known main TM member
local function isTMCharacter(queryName)
    queryName = queryName:lower()

    -- try to match a character name
    for main, data in pairs(characterData) do
        if queryName == main then
            return main
        else
            for i, alt in ipairs(data.alts) do
                if queryName == alt then
                    return main
                end
            end
        end
    end

    return false
end

-- patch character list if required
local function patchCharacterList(extraCharacters)
    local counter = 0
    local patched = {}

    for main, newChars in pairs(extraCharacters) do
        if characterData[main] then
            for i, char in ipairs(newChars) do
                if not tContains(characterData[main].alts, char) then
                    tinsert(characterData[main].alts, char)
                    if options.debug then
                        tinsert(patched, char)
                        counter = counter + 1
                    end
                end
            end
        end
    end

    debugPrint("patched %i extra characters", counter)
    if counter > 0 then
        debugPrint(table.concat(patched, ", "))
    end
end

-- make chars public for other uses
cobdt.patchCharacterList = patchCharacterList
cobdt.isTMCharacter = isTMCharacter