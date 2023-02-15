-- contains known characters and their related data
local addonName, cobdt = ...
local module = {}
cobdt.modules.data = module

-- cobdt module
local options, db
function module.init(opt, database)
    options, db = opt, database
end

-- cobdt locals
local debugPrint = cobdt.debugPrint

--------------------
-- Character Data --
--------------------
local characterData = {}
characterData.saelaris = {
    alts = {
        "athall",
        "eleonar",
        "snikkels",
        "astarielle",
    },
    sound = "wilhelm"
}
characterData.avael = {
    alts = {
        "addonbabe",
        "airah",
        "manitvex",
        "ninriel",
        "mythricia",
        "hederine",
        "lorasha",
    },
    sound = "winxp_error"
}
characterData.horricee = {
    alts = {
        "irení",
        "irenious",
    },
    messages = {
        "This is my first totally original and very funny message, it can include my current death <n>.",
        "Avenge me for I am slain!",
        "This is my first death ever! Wait what no shut up I haven't died <n> times!",
        "Your god has fallen, fear not however for I shall arise again, this is the <nth> time after all!",
    },
    sound = "Horricee_death"
}
characterData.poplar = {
    alts = {
        "toasty",
        "bex",
        "becka",
        "hardwork",
        "bicks",
    },
    messages = {
        "I guess Becks will be LEAF-ing now, for the <nth> time",
        "Her BARK was worse than her bite. RIP Becks.",
        "Becks has gotten to the ROOT of the problem <n> times! Her health hit zero.",
        "Becks WOOD have lived <n> times if not for the tank.",
    },
    sound = "deathnoise"
}
characterData.illasei = {
    alts = {
        "killasei",
    },
    messages = {},
    sound = "oopsie"
}
characterData.kimora = {
    alts = {
        "effsie",
        "tailynn",
        "zerenity",
        "myseri",
        "lizzi",
        "kinney",
        "elveera",
        "bimini",
    },
    messages = {
        "Kimora was brought to death <n> times",
        "Kimora couldn't wake up <n> times",
        "It's not been a phase, mom, for <n> times",
    },
    sound = "Kimora_Death_Jingle"
}
characterData.shaixira = {
    alts = {
        "evory",
        "rheanwyn",
        "selece",
        "nerida",
        "daranya",
        "isdra",
    },
    messages = {},
    sound = "evory_death1"
}
characterData.makesha = {
    alts = {},
    messages = {},
    sound = "You_serious",
}
characterData.yvai = {
    alts = {},
    messages = {},
    sound = "Yvai_death",
}
characterData.tyfannia = {
    alts = {},
    messages = {},
    sound = "Tyfannia_death_sound"
}
characterData.pingwing = {
    alts = {},
    messages = {},
    sound = "pingwing"
}
characterData.tharri = {
    alts = {
        "peritaph"
    },
    messages = {},
    sound = "cleese_ping"
}
characterData.neshali = {
    alts = {
        "nesharil"
    },
    messages = {},
    sound = "FFXIV_sloppy"
}
characterData.talkui = {
    alts = {
        "kimrog",
        "enril"
    },
    messages = {},
    sound = "FelOrcWoundCritC"
}
characterData.rugnarson = {
    alts = {
        "puna"
    },
    messages = {},
    sound = "nani"
}
characterData.akaani = {
    alts = {
        "delthea",
        "yunara",
        "kallistra"
    },
    messages = {},
    sound = "RamDeath"
}
characterData.marvinator = {
    alts = {
        "rotahildr",
        "jandijilija",
        "nemetona",
        "xeneta"
    },
    messages = {
        "I knew I should've stayed in bed this morning.",
        "All out of that special sauce.",
    },
    sound = "Marinedeath"
}
characterData.zos = {
    alts = {},
    messages = {},
    sound = "zos"
}
characterData.hiddeneasteregg = {
    alts = {},
    messages = {},
    sound = "horsewhinny"
}
-- TODO: find better eastereggsound

-- check the characters table to make sure ALL NAMES are lowercase, and scream in your face if some aren't.
do
    local bad = {}
    for _, data in pairs(characterData) do
        for _, alt in pairs(data.alts) do
            if alt:match("[A-Z]") then
                tinsert(bad, alt)
            end
        end
    end

    if next(bad) then
        C_Timer.After(1, function()
            debugPrint("BAD! VERY BAD! There are characters with Capital Letters in the COBDT character database:")
            debugPrint(table.concat(bad, ", "))
        end)
    end
end


-- ship it
cobdt.characterData = characterData