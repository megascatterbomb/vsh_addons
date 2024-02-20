::mercBuff <- false
::haleBuff <- false

// Replace stalemate function to account for a captured control point.
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
    // TODO fix this shit
    EntityOutputs.AddOutput(controlPoint,
        "OnCapTeam"+(TF_TEAM_MERCS-1),
        vsh_vscript_name,
        "RunScriptCode",
        "BuffMercs",
        0, -1);
    EntityOutputs.AddOutput(controlPoint,
        "OnCapTeam"+(TF_TEAM_BOSS-1),
        vsh_vscript_name,
        "RunScriptCode",
        "BuffHale",
        0, -1);
});

// Used to calculate how much health that Hale regens/bleeds should initially increase by every second.
function CalculateStartingIncrement(killHale) {
    local sum = killHale ? currentHealth : maxHealth - currentHealth;
    local mercsKilled = startMercCount - GetAliveMercCount();
    local desiredTimeUnclamped = 5 * (killHale ? mercsKilled : GetAliveMercCount());

    local desiredTime = clampFloor(60, desiredTimeUnclamped);

    local startingIncrement = (2*sum/desiredTime - desiredTime + 1)/2.0;

    return clamp(ceil(startingIncrement), 1, maxHealth / 100);
}

// Massively reduces Hale's cooldown on abilities.
// Hale's health regenerates an ever-increasing amount until it's max, at which point Hale wins.
::BuffHale <- function() {
    printl("Hale has received buffs");
    // Buff ability cooldown
    IncludeScript("vsh_addons/ability_cooldown_override.nut");

    haleBuff = true;
}

function CalculateRespawnCount() {
    local mercsKilled = startMercCount - GetAliveMercCount();
}

// Mercs get a 3s health buff, full crits on all weapons for the rest of the round, and some reinforcements.
// All players who did above-average damage before dying are respawned.
// Hale bleeds an ever-increasing amount until the round ends.
::BuffMercs <- function() {
    // Give huge health buff
    local mercs = GetAliveMercs();
    for(local i = 0; i < mercs.len(); i++) {
        mercs[i].AddCondEx(TF_COND_HALLOWEEN_QUICK_HEAL, 3, mercs[i]);
    }

    // Give full crits for rest of round
    characterTraitsClasses.push(class extends CharacterTrait
    {
        function OnTickAlive(timeDelta)
        {
            player.AddCondEx(TF_COND_OFFENSEBUFF, 0.2, player);
            player.AddCondEx(TF_COND_CRITBOOSTED_ON_KILL, 0.2, player);
        }
    });

    mercBuff = true;
}

// Stalemates if point isn't owned.
function EndRoundTime() {

}