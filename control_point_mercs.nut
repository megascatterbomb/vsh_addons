local increment = 0;
local idleMultiplier = 1;

local haleLastDamage = Time();
local idleTime = 30;

// Mercs get 5s of massive regen and full crits on all weapons for the rest of the round.
// Hale bleeds an ever-increasing amount until the round ends.
::BuffMercs <- function() {
    ::mercBuff <- true;
    ClientPrint(null, 3, "Hale is bleeding to death, and the Mercs now have permanent crits!");
    // Give huge health buff
    local mercs = GetAliveMercs();
    for(local i = 0; i < mercs.len(); i++) {
        mercs[i].AddCondEx(TF_COND_HALLOWEEN_QUICK_HEAL, 5, mercs[i]);
    }

    // Super bleed
    MercBeginEndgame();
}

// Starts the endgame bleed.
function MercBeginEndgame() {

    EntFireByHandle(team_round_timer, "Pause", "", 0, null, null);
    EntFireByHandle(team_round_timer, "Disable", "", 0, null, null);

    local controlPoint = Entities.FindByClassname(null, "team_control_point");
    EntFireByHandle(controlPoint, "SetLocked", "1", 0, null, null);

    haleLastDamage = Time();

    increment = 0;

    EndgameInterval(killHale);
}

// Continuously damages hale until the round ends.
function MercEndgameInterval(killHale)
{
    if(IsRoundOver()) {
        return;
    }

    local boss = GetBossPlayers()[0];
    local oldHealth = boss.GetHealth();
    local damageOrHealing = ceil(increment * idleMultiplier);
    local newHealth = ceil(oldHealth - damageOrHealing);

    // ClientPrint(null, 3, "Increment: " + increment);
    // ClientPrint(null, 3, "Idle multiplier: " + idleMultiplier);
    // ClientPrint(null, 3, "Damage: " + damageOrHealing);

    // Do the damage
    local vecPunch = GetPropVector(boss, "m_Local.m_vecPunchAngle");
    boss.TakeDamageCustom(boss, boss, null, Vector(0.000001, 0.000001, 0.000001), Vector(0.000001, 0.000001, 0.000001), damageOrHealing, DMG_BURN + DMG_PREVENT_PHYSICS_FORCE, TF_DMG_CUSTOM_BLEEDING);
    SetPropVector(boss, "m_Local.m_vecPunchAngle", vecPunch);


    increment++;
    // Speed things up if Hale hasn't dealt damage in the past 30 seconds.
    if(killHale && Time() > haleLastDamage + idleTime) {
        if(idleMultiplier == 1) {
            ClientPrint(null, 3, "Do some damage Saxton! Otherwise your health will drain even faster!");
        }
        idleMultiplier = idleMultiplier * 1.05;
    } else {
        idleMultiplier = 1;
    }

    // Loop continuously at 1 second intervals.
    RunWithDelay("EndgameInterval("+killHale+")", null, 1);
}

// Give full crits for rest of round
characterTraitsClasses.push(class extends CharacterTrait
{
    function OnTickAlive(timeDelta)
    {
        if(mercBuff){
            player.AddCondEx(TF_COND_OFFENSEBUFF, 0.2, player);
            player.AddCondEx(TF_COND_CRITBOOSTED_ON_KILL, 0.2, player);
        }
    }
});

// Listen for idle Hale
AddListener("damage_hook", 0, function (attacker, victim, params)
{
    if (IsBoss(attacker) && !IsBoss(victim)) {
        haleLastDamage = Time();
    }
});

// OVERRIDE: Prevent screenshake from the bleed damage dealt if RED caps
function ScreenShakeTrait::OnDamageDealt(victim, params)
{
    if (victim != null && victim.IsValid() && !IsBoss(victim))
        ScreenShake(victim.GetCenter(), 140, 1, 1, 10, 0, true);
}