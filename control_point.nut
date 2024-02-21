::mercBuff <- false
::haleBuff <- false

::healthHealed <- 0

local increment = 1;

// OVERRIDE: Replace stalemate function to account for a captured control point.
function PrepareStalemate()
{
    local boss = GetRandomBossPlayer();
    local delay = clampFloor(60, API_GetFloat("stalemate_time"));

    local text_tf = SpawnEntityFromTable("game_text_tf", {
        message = "#vsh_end_this",
        icon = "ico_notify_flag_moving_alt",
        background = 0,
        display_to_team = 0
    });
    EntFireByHandle(text_tf, "Display", "", delay - 60, null, null);
    // Display message for a bit longer
    EntFireByHandle(text_tf, "Kill", "", delay - 55, null, null);

    RunWithDelay("EntFireByHandle(team_round_timer, `SetTime`, `60`, 0, null, null)", null, delay - 60);

    PlayAnnouncerVODelayed(boss, "count5", delay - 6);
    PlayAnnouncerVODelayed(boss, "count4", delay - 5);
    PlayAnnouncerVODelayed(boss, "count3", delay - 4);
    PlayAnnouncerVODelayed(boss, "count2", delay - 3);
    PlayAnnouncerVODelayed(boss, "count1", delay - 2);

    RunWithDelay("EndRoundTime", null, delay);
}

// Remove outputs intended to end the round on point capture and add our own.
AddListener("setup_end", 0, function()
{
    // Out with the old...
    local controlPoint = Entities.FindByClassname(null, "team_control_point");
    EntityOutputs.RemoveOutput(controlPoint,
        "OnCapTeam"+(TF_TEAM_MERCS-1),
        vsh_vscript_name,
        "RunScriptCode",
        "EndRound("+TF_TEAM_MERCS+")"
    );
    EntityOutputs.RemoveOutput(controlPoint,
        "OnCapTeam"+(TF_TEAM_BOSS-1),
        vsh_vscript_name,
        "RunScriptCode",
        "EndRound("+TF_TEAM_BOSS+")"
    );

    // ...and in with the new.
    EntityOutputs.AddOutput(controlPoint,
        "OnCapTeam"+(TF_TEAM_MERCS-1),
        vsh_vscript_name,
        "RunScriptCode",
        "BuffMercs()",
        0, -1);
    EntityOutputs.AddOutput(controlPoint,
        "OnCapTeam"+(TF_TEAM_BOSS-1),
        vsh_vscript_name,
        "RunScriptCode",
        "BuffHale()",
        0, -1);
});

// Continuously regens or damages hale until the round ends.
function EndgameInterval(killHale)
{
    if(IsRoundOver()) {
        return;
    }

    local boss = GetBossPlayers()[0];
    local newHealth = ceil(killHale ? currentHealth - increment : currentHealth + increment);

    if(killHale) {
        // Adds hud-icon but not damage.
        boss.AddCondEx(TF_COND_GRAPPLINGHOOK_BLEEDING, 1, boss);
        boss.TakeDamageCustom(boss, boss, null, Vector(1, 1, 1), Vector(0, 0, 0), increment, 0, TF_DMG_CUSTOM_BLEEDING);
    } else if(!killHale && newHealth >= maxHealth) {
        healthHealed += clampCeiling(maxHealth - currentHealth, newHealth - currentHealth);
        boss.SetHealth(maxHealth);
        EndRound(TF_TEAM_BOSS);
        return;
    } else {
        boss.SetHealth(newHealth);
    }

    increment++;

    // Loop continuously at 1 second intervals.
    RunWithDelay("EndgameInterval("+killHale+")", null, 1);
}

// Starts the endgame bleed/health regen.
// Calculates the appropriate starting increment to use.
function BeginEndgame(killHale) {

    EntFireByHandle(team_round_timer, "Pause", "", 0, null, null);
    EntFireByHandle(team_round_timer, "Disable", "", 0, null, null);

    local controlPoint = Entities.FindByClassname(null, "team_control_point");
    EntFireByHandle(controlPoint, "SetLocked", "1", 0, null, null);

    local sum = killHale ? currentHealth : maxHealth - currentHealth;
    local mercsKilled = startMercCount - GetAliveMercCount();
    local desiredTimeUnclamped = 5 * (killHale ? mercsKilled : GetAliveMercCount());

    local desiredTime = clampFloor(60, desiredTimeUnclamped);

    local startingIncrement = (2*sum/desiredTime - desiredTime + 1)/2.0;

    increment = clamp(ceil(startingIncrement), 1, maxHealth / 100);

    EndgameInterval(killHale);
}

// Removes Hale's cooldown on abilities.
// Hale's health regenerates an ever-increasing amount until it's max, at which point Hale wins.
::BuffHale <- function() {
    haleBuff = true;

    // Buff ability cooldown
    IncludeScript("vsh_addons/ability_cooldown_override.nut");

    // Super regen
    BeginEndgame(false);
}

// Mercs get 5s of massive regen and full crits on all weapons for the rest of the round.
// Hale bleeds an ever-increasing amount until the round ends.
::BuffMercs <- function() {
    mercBuff = true;

    // Give huge health buff
    local mercs = GetAliveMercs();
    for(local i = 0; i < mercs.len(); i++) {
        mercs[i].AddCondEx(TF_COND_HALLOWEEN_QUICK_HEAL, 5, mercs[i]);
    }

    // Super bleed
    BeginEndgame(true);
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


// Stalemates if point isn't owned.
function EndRoundTime() {
    if(mercBuff || haleBuff) {
        return;
    }
    EndRound(TF_TEAM_UNASSIGNED);
}