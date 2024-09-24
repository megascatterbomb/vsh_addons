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
function HaleBeginEndGame() {
    local controlPoint = Entities.FindByClassname(null, "team_control_point");
    spawnPoint = controlPoint.GetOrigin() + Vector(0, 0, 16);

    RunWithDelay("HaleSpawnComrades()", null, 0);
}

// Respawn all fallen mercenaries to work for Hale.
function HaleSpawnComrades() {
    foreach (player in GetValidMercs()) {
        if (!IsAlive(player) || !(player in potentialTraitors)) continue;

        player.SwitchTeam(TF_TEAM_BOSS);
        player.ForceRegenerateAndRespawn();
        player.SetOrigin(spawnPoint);
        player.AddCond(TF_COND_INVULNERABLE_USER_BUFF, 3);
    }
}

// Only mercs present at the end of setup time may join the fight.
AddListener("setup_end", 11, function()
{
    foreach(player in GetValidMercs()) {
        potentialTraitors.push(merc);
    }
});