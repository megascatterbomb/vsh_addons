// Separate function so we can get maxhealth without setting the maxHealth variable.
::GetStartingHealth <- function(mercCount)
{
    if (mercCount < 2)
    {
        maxHealth = 1000;
        return 1000;
    }
    local factor = clampCeiling(1, 1.0 - ((mercCount - 32.0) / 200.0));
    local unrounded = mercCount * mercCount * factor * API_GetFloat("health_factor") + (mercCount < 6 ? 1300 : 2000);
    local rounded = floor(unrounded / 100) * 100;
    return rounded;
}

// OVERRIDE: Reduce health for higher player counts
::CalcBossMaxHealth <- function(mercCount)
{
    local health = GetStartingHealth(mercCount);
    maxHealth = health;
    return health;
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