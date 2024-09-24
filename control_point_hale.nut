local potentialTraitors = [];
local spawnPoint;

::BuffHale <- function() {
    ::haleBuff <- true;
    ClientPrint(null, 3, "Hale has hired your fallen comrades, and his abilities have reduced cooldown!");

    // Reduce cooldown of abilities.
    IncludeScript("vsh_addons/ability_cooldown_override.nut");

    RunWithDelay("HaleBeginEndgame()", null, 0);
}

// Create portal effect around control point.
function HaleBeginEndgame() {
    local controlPoint = Entities.FindByClassname(null, "team_control_point");
    spawnPoint = controlPoint.GetOrigin() + Vector(0, 0, 16);

    RunWithDelay("HaleSpawnComrades()", null, 0);
}

// Respawn all fallen mercenaries to work for Hale.
// TODO: On death after cap, move merc to BLU team.
function HaleSpawnComrades() {
    foreach (traitor in GetValidMercs()) {
        if (IsPlayerAlive(traitor)) continue;

        traitor.SwitchTeam(TF_TEAM_BOSS);
        traitor.ForceRegenerateAndRespawn();
        traitor.SetAbsOrigin(spawnPoint);
        traitor.AddCondEx(TF_COND_INVULNERABLE_USER_BUFF, 3.0, traitor);
    }
}

// Only mercs present at the end of setup time may join the fight.
AddListener("setup_end", 11, function()
{
    foreach(merc in GetValidMercs()) {
        potentialTraitors.push(merc);
    }
});