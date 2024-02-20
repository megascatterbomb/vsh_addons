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

AddListener("death", 0, function(attacker, victim, params)
{
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