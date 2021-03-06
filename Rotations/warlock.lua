wl = {}
wl.maxIntCastLength = 1

wl.dottableUnits = {
    "target",
    "focus",
    "mouseover",
    "boss1",
    "boss2",
    "boss3",
    "boss4",
}

local function toSpellName(id) name = GetSpellInfo(id); return name end
wl.spells = {}
-- All Specs
wl.spells["opticalBlast"] = toSpellName(119911)
wl.spells["spellLock"] = toSpellName(19647)
wl.spells["mortalCoil"] = toSpellName(6789)
wl.spells["createHealthstone"] = toSpellName(6201)
wl.spells["curseOfTheElements"] = toSpellName(1490)
wl.spells["demonicCircleSummon"] = toSpellName(48018)
wl.spells["demonicCircleTeleport"] = toSpellName(48020)
wl.spells["demonicGateway"] = toSpellName(113901)
wl.spells["grimoireOfSacrifice"] = toSpellName(108503)
wl.spells["enslaveDemon"] = toSpellName(1098)
wl.spells["unendingResolve"] = toSpellName(104773)
wl.spells["twilightWard"] = toSpellName(6229)
wl.spells["commandDemon"] = toSpellName(119898)
wl.spells["darkIntent"] = toSpellName(109773)
wl.spells["fear"] = toSpellName(5782)
wl.spells["banish"] = toSpellName(710)
wl.spells["soulshatter"] = toSpellName(29858)
wl.spells["singeMagic"] = toSpellName(132411)
wl.spells["sacrificialPact"] = toSpellName(108416)
wl.spells["burningRush"] = toSpellName(111400)
--Affliction
wl.spells["corruption"] = toSpellName(172)
wl.spells["darkSoulMisery"] = toSpellName(113860)
wl.spells["felFlame"] = toSpellName(77799)
wl.spells["haunt"] = toSpellName(48181)
wl.spells["seedOfCorruption"] = toSpellName(27243)
wl.spells["maleficGrasp"] = toSpellName(103103)
wl.spells["drainSoul"] = toSpellName(1120)
wl.spells["lifeTap"] = toSpellName(1454)
wl.spells["soulSwap"] = toSpellName(86121)
wl.spells["soulburn"] = toSpellName(74434)
wl.spells["drainSoul"] = toSpellName(1120)
wl.spells["maleficGrasp"] = toSpellName(103103)
--Destruction
wl.spells["immolate"] = toSpellName(348)
wl.spells["felFlame"] = toSpellName(77799)
wl.spells["backdraft"] = toSpellName(117896)
wl.spells["rainOfFire"] = toSpellName(5740)
wl.spells["darkSoulInstability"] = toSpellName(113858)
wl.spells["havoc"] = toSpellName(80240)
wl.spells["fireAndBrimstone"] = toSpellName(108683)
wl.spells["emberTap"] = toSpellName(114635)
wl.spells["felFlame"] = toSpellName(77799)
wl.spells["shadowburn"] = toSpellName(17877)
wl.spells["chaosBolt"] = toSpellName(116858)
wl.spells["incinerate"] = toSpellName(29722)
wl.spells["conflagrate"] = toSpellName(17962)
-- Professions
wl.spells["lifeblood"] = toSpellName(121279)


function wl.hasKilJaedensCunning()
    local selected, talentIndex = GetTalentRowSelectionInfo(6)
    return talentIndex == 17
end


local function npcId(unit)
    if UnitExists(unit) then return tonumber(UnitGUID(unit):sub(6, 10), 16) end
    return -1
end

local interruptSpellTables = {}
function wl.getInterruptSpell(unit)
    return function()
        if not interruptSpellTables[unit] then interruptSpellTables[unit] = {{"macro", "/cast " .. wl.spells.commandDemon }, false , unit} end
        local canInterrupt = false
        if jps.canCast(wl.spells.opticalBlast, unit) then -- Observer Pet 
            canInterrupt = true
        elseif jps.canCast(wl.spells.spellLock, unit) then -- Felhunter Pet
            canInterrupt = true
        elseif jps.canCast(wl.spells.commandDemon, unit) and select(3,GetSpellInfo(wl.spells.commandDemon))=="Interface\\Icons\\Spell_Shadow_MindRot" then -- GoSac Felhunter
            canInterrupt = true
        end
        local shouldInterrupt = jps.Interrupts and jps.shouldKick(unit) and jps.CastTimeLeft(unit) < wl.maxIntCastLength
        interruptSpellTables[unit][2] = canInterrupt and shouldInterrupt
        return interruptSpellTables[unit]
    end
end

-- stop spam curse of the elements at invalid targets @ mop
function wl.isCotEBlacklisted(unit) 
    local table_noSpamCotE = {
        56923, -- Twilight Sapper
        56341, 56575, -- Burning Tendons 4.3.0/5.2.0
        53889, -- Corrupted Blood
        60913, -- Energy Charge
        60793, -- Celestial Protector
    }
    for i,j in pairs(table_noSpamCotE) do
        if npcId(unit) == j then return true end
    end
    return false
end

function wl.isTrivial(unit)
    local minHp = 1000000
    if IsInGroup() or IsInRaid() then minHp = minHp * GetNumGroupMembers() end
    return  UnitHealth(unit) <= minHp
end

function wl.attackFocus()
    return UnitExists("focus") ~= nil and UnitGUID("target") ~= UnitGUID("focus") and not UnitIsFriend("player", "focus")
end

-- Helper to prevent Recasts
function wl.isRecast(spell,target)
    return jps.LastCast == spell and jps.LastTarget == target
end


-- Deactivate Burning Rush after n seconds of not moving
local burningRushNotMovingSeconds = 0
function wl.deactivateBurningRushIfNotMoving(seconds)
    if not seconds then seconds = 0 end
    if jps.Moving or not jps.buff(wl.spells.burningRush) then
        burningRushNotMovingSeconds = 0
    else
        if burningRushNotMovingSeconds >= seconds then
            RunMacroText("/cancelaura Burning Rush")
        else
            burningRushNotMovingSeconds = burningRushNotMovingSeconds + jps.UpdateInterval
        end
    end
end