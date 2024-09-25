local potentialTraitors = [];
local traitors = [];
local spawnPoint;

::BuffHale <- function()
{
    ::haleBuff <- true;
    ClientPrint(null, 3, "Hale has hired your fallen comrades, and his abilities have reduced cooldown!");

    // Reduce cooldown of abilities.
    IncludeScript("vsh_addons/ability_cooldown_override.nut");

    RunWithDelay("HaleBeginEndgame()", null, 0);
}

// Create portal effect around control point.
function HaleBeginEndgame()
{
    local controlPoint = Entities.FindByClassname(null, "team_control_point");
    spawnPoint = controlPoint.GetOrigin() + Vector(0, 0, 16);

    RunWithDelay("HaleSpawnComrades()", null, 0);
}

// Respawn all fallen mercenaries to work for Hale.
// TODO: On death after cap, move merc to BLU team.
function HaleSpawnComrades()
{
    // Prevent players we move to BLU from being forced back to RED.
    EraseListener("team_change", 0, 0);
    AddListener("team_change", 0, function(player, params)
    {
        if (IsBoss(player) && params.team != TF_TEAM_BOSS)
            RunWithDelay("SwitchPlayerTeam(activator, TF_TEAM_BOSS)", player, 0);
        // if (!IsBoss(player) && params.team == TF_TEAM_BOSS)
        //     RunWithDelay("SwitchPlayerTeam(activator, TF_TEAM_MERCS)", player, 0);
        if (!IsBoss(player) && params.team == TF_TEAM_SPECTATOR && params.silent)
        {
            local name = GetPropString(player, "m_szNetname");
            Say(null, "Player '"+name+"' was moved to spectators for some reason. Moving them back.", false);
            RunWithDelay("SwitchPlayerTeam(activator, TF_TEAM_MERCS)", player, 0);
        }
    });
    EraseListener("spawn", 0, 0);
    AddListener("spawn", 0, function (player, params)
    {
        if (IsRoundSetup())
            return;
        if (player.GetTeam() == TF_TEAM_BOSS && !IsBoss(player))
            return;
        player.TakeDamage(9999, 0, null);
        SetPropInt(player, "m_lifeState", LIFE_STATE.DEAD);
        if (player.GetTeam() != TF_TEAM_MERCS)
            player.ForceChangeTeam(TF_TEAM_MERCS, true);

        local ammoPack = null;
        while (ammoPack = Entities.FindByClassname(ammoPack, "tf_ammo_pack"))
            if (ammoPack.GetOwner() == player)
            {
                ammoPack.Kill();
                return;
            }
    });

    ::RecachePlayers <- function()
    {
        local validClientsL = [];
        local validPlayersL = [];
        local alivePlayersL = [];
        local validMercsL = [];
        local aliveMercsL = [];
        for (local i = 1; i <= MAX_PLAYERS; i++)
        {
            local player = PlayerInstanceFromIndex(i);
            if (IsValidClient(player))
            {
                validClientsL.push(player);
                if (player.GetTeam() > TF_TEAM_SPECTATOR)
                {
                    validPlayersL.push(player);

                    local isAlive = IsPlayerAlive(player);
                    local isMerc = !IsBoss(player) && !(player in traitors);

                    if (isAlive && isMerc)
                        aliveMercsL.push(player);
                    if (isAlive)
                        alivePlayersL.push(player);
                    if (isMerc)
                        validMercsL.push(player);
                }
            }
        }
        validClients = validClientsL;
        validPlayers = validPlayersL;
        validMercs = validMercsL;
        alivePlayers = alivePlayersL;
        aliveMercs = aliveMercsL;
    };

    AddListener("death", 11, function(attacker, victim, params) {
        if (victim.GetTeam() == TF_TEAM_MERCS)
        {
            local userid = NetProps.GetPropIntArray(tf_player_manager, "m_iUserID", victim.entindex());
             EntFireByHandle(vsh_vscript_entity, "RunScriptCode", "TurnIntoTraitor(" + userid + ")", 5.0, null, null);
        }
    });

    foreach (player in GetValidMercs()) {
        if (IsPlayerAlive(player)) continue;
        local userid = NetProps.GetPropIntArray(tf_player_manager, "m_iUserID", player.entindex());
        TurnIntoTraitor(userid);
    }
    RecachePlayers();
}

function TurnIntoTraitor(traitorid)
{
    local traitor = GetPlayerFromUserID(traitorid);
    traitors.push(traitor);
    traitor.SwitchTeam(TF_TEAM_BOSS);
    traitor.ForceRegenerateAndRespawn();
    traitor.SetAbsOrigin(spawnPoint);
    traitor.AddCondEx(TF_COND_INVULNERABLE_USER_BUFF, 3.0, traitor);
}

// Only mercs present at the end of setup time may join the fight.
AddListener("setup_end", 11, function()
{
    potentialTraitors = [];
    foreach(merc in GetValidMercs()) {
        potentialTraitors.push(merc);
    }
});