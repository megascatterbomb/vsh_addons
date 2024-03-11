// Clamp time for when hale kills mercs quickly.
// Prevents a round dragging on with few players.
function ClampRoundTime()
{
    local maxTime = ceil(clampFloor(60, aliveMercs.len() * 10));
    local currentTime = clampCeiling(GetPropFloat(team_round_timer, "m_flTimerEndTime") - Time(), GetPropFloat(team_round_timer, "m_flTimeRemaining"));
    if (currentTime > maxTime)
    {
        EntFireByHandle(team_round_timer, "SetTime", "" + maxTime, 0, null, null);
    }
}

AddListener("death", 0, function(attacker, victim, params)
{
    ClampRoundTime();
});

// Increase setup time for very high player counts.
// Round start can be very laggy for high player counts; extra time helps the less fortunate.
// Also gives players more time to spread out.
// Negative ordering because this needs to run before the VO for setup is set in motion.
AddListener("setup_start", -10, function ()
{
    local setupTime = clampFloor(16, ceil(validMercs.len() / 3.0));
    VSH_API_VALUES.setup_length <- setupTime;
    EntFireByHandle(team_round_timer, "SetTime", "" + setupTime, 0, null, null);
});

// Increase round time for high playercounts
AddListener("setup_end", 0, function()
{
    local time = ceil(clampFloor(240, validMercs.len() * 8));
    EntFireByHandle(team_round_timer, "SetTime", "" + time, 0, null, null);
    ClampRoundTime();
});

// OVERRIDE: Replacement for listener in /_gamemode/round_logic.nut
// Removes vanilla logic for timer clamp.
EraseListener("tick_always", 8, 0);
AddListener("tick_always", 8, function(timeDelta)
{
    if (IsInWaitingForPlayers())
        return;
    if (IsRoundSetup())
    {
        if (GetValidPlayerCount() <= 1 && !IsAnyBossAlive())
        {
            SetPropInt(team_round_timer, "m_bTimerPaused", 1);
            return;
        }
        //Bailout
        if (!IsAnyBossAlive())
        {
            Convars.SetValue("mp_bonusroundtime", 5);
            EndRound(TF_TEAM_UNASSIGNED);
        }
        return;
    }

    // Removed as we have a replacement
    // if (GetAliveMercCount() <= 5 && GetPropFloat(team_round_timer, "m_flTimeRemaining") > 60)
    //    EntFireByHandle(team_round_timer, "SetTime", "60", 0, null, null);

    local noBossesAlive = !IsAnyBossAlive();
    local noMercsAlive = GetAliveMercCount() <= 0;

    if (noBossesAlive && noMercsAlive)
        EndRound(TF_TEAM_UNASSIGNED);
    else if (noBossesAlive)
        EndRound(TF_TEAM_MERCS);
    else if (noMercsAlive)
        EndRound(TF_TEAM_BOSS);
});
