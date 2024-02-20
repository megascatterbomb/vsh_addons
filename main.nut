local maxHealth;
local currentHealth;

// Helper to erase listeners we want to replace.
function EraseListener(event, order, indexToRemove)
{
    local listenerToRemove = null;
    if(listeners[event] == null) {
        return;
    }
    local count = 0;
    for(local i = 0; i < listeners[event].len(); i++)
    {
        if(listeners[event][i][0] == order && count == indexToRemove) {
            listenerToRemove = listeners[event][i][1];
            break;
        } else if (listeners[event][i][0] == order) {
            count++;
        }
    }
    if(listenerToRemove != null)
    {
        printl("Removing listener "+event+" "+order);
        RemoveListener(listenerToRemove);
    }
}

// Reduce health for higher player counts
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

// Increase setup time for very high player counts.
// Round start can be very laggy for high player counts; extra time helps the less fortunate.
// Also gives players more time to spread out.
AddListener("setup_start", 10, function ()
{
    local setupTime = clampFloor(16, ceil(validMercs.len() / 3.0));
    EntFireByHandle(team_round_timer, "SetTime", "" + setupTime, 0, null, null);
});

// Increase round time for high playercounts
AddListener("setup_end", 0, function()
{
    local time = ceil(clampFloor(240, validMercs.len() * 8));
    EntFireByHandle(team_round_timer, "SetTime", "" + time, 0, null, null);
    ClampRoundTime();
});

AddListener("death", 0, function(attacker, victim, params)
{
    ClampRoundTime();
    BroadcastDamageOnDeath(attacker, victim);
});

AddListener("dead_ringer", 0, function(attacker, victim, params)
{
    BroadcastDamageOnDeath(attacker, victim, true);
});

AddListener("round_end", 5, function (winnerTeam)
{
    BroadcastBestPlayers();
});

// Track current health for damage calculations.
AddListener("tick_always", 5, function(timeDelta)
{
    if(!IsRoundOver() && IsAnyBossAlive())
    {
        local boss = GetBossPlayers()[0];
        currentHealth = boss.GetHealth();
    }
});

// Replacement for listener in /_gamemode/round_logic.nut
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

// Clamp stab damage (and market gardner) to 5000 max
function CalcStabDamage(victim)
{
    return clamp(GetPerPlayerDamageQuota(victim), 500, 5000);
}

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

// Broadcast player's damage in chat when they die.
function BroadcastDamageOnDeath(attacker, victim, deadRinger = false) {
    if(IsBoss(victim))
    {
        return;
    }
    local name = GetPropString(victim, "m_szNetname");
    local damage = GetRoundDamage(victim);

    local target = deadRinger ? GetBossPlayers()[0] : null;

    ClientPrint(target, 3, "Player '"+name+"' dealt "+damage+" damage to Hale before dying."+(damage ? "" : " How embarrassing!"));
}

// Broadcast top players at end of round.
function BroadcastBestPlayers()
{
    local topN = 3;
    local damageBoard = GetDamageBoardSorted();

    if(damageBoard.len() == 0)
    {
        ClientPrint(null, 3, "None of you managed to scratch Hale this round. Pathetic!");
        return;
    }
    local playerDamage = 0;
    ClientPrint(null, 3, "Top players this round:");
    for(local i = 0; i < damageBoard.len(); i++) {
        local name = GetPropString(damageBoard[i][0], "m_szNetname");
        local damage = damageBoard[i][1];
        playerDamage += damage;
        if(damage > 0 && i < topN) {
            ClientPrint(null, 3, "#"+(i+1)+": "+name+" dealt "+damage+" damage.");
        }
    }
    local totalDamage = maxHealth - currentHealth;
    local playerPercent = floor(100 * playerDamage / maxHealth);
    if(!IsAnyBossAlive())
    {
        totalDamage = maxHealth;
    }
    local otherDamage = totalDamage - playerDamage;
    local otherPercent = floor(100 * otherDamage / maxHealth);
    local totalPercent = floor(100 * totalDamage / maxHealth);

    if(otherDamage > 0) {
        ClientPrint(null, 3, "Player Damage: "+playerDamage+" ("+playerPercent+"%)");
        ClientPrint(null, 3, "Other Damage: "+otherDamage+" ("+otherPercent+"%)");
    }
    ClientPrint(null, 3, "Total Damage: "+totalDamage+"/"+maxHealth+" ("+totalPercent+"%)");
}

// Ensure death message gets printed to Hale when dead ringer is used.
function OnGameEvent_player_death(params)
{
    if (IsNotValidRound())
        return;
    local player = GetPlayerFromParams(params);
    if (!IsValidPlayer(player))
        return;
    local attacker = GetPlayerFromParams(params, "attacker");
    if(params.death_flags & TF_DEATHFLAG.DEAD_RINGER) {
        FireListeners("dead_ringer", attacker, player, params);
        return;
    }

    FireListeners("death", attacker, player, params);
}