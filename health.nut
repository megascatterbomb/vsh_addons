// OVERRIDE: Reduce health for higher player counts
::CalcBossMaxHealth <- function(mercCount)
{
    if (mercCount < 2)
    {
        maxHealth = 1000;
        return 1000;
    }
    local factor = clampCeiling(1, 1.0 - ((mercCount - 32.0) / 200.0));
    local unrounded = mercCount * mercCount * factor * API_GetFloat("health_factor") + (mercCount < 6 ? 1300 : 2000);
    local rounded = floor(unrounded / 100) * 100;
    maxHealth = rounded;
    return rounded;
}

// Track current health for damage calculations.
AddListener("tick_always", 5, function(timeDelta)
{
    if(!IsRoundOver() && IsAnyBossAlive())
    {
        local boss = GetBossPlayers()[0];
        currentHealth = boss.GetHealth();
    }
});