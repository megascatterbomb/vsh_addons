// Send bots after Hale
AddListener("setup_end", 20, function()
{
    foreach(player in GetAliveMercs())
    {
        if(!player.IsBotOfType(1337))
        {
            continue;
        }
        local team = GetPropInt(player, "m_iTeamNum");
        if(team == TF_TEAM_BOSS)
        {
            SetBossMission(player);
        } else if (team == TF_TEAM_MERCS) {
            SetMercMission(player);
        }
    }
});

// Mission 1 is

function SetBossMission(bot)
{

}

function SetMercMission(bot)
{
    bot.SetMission(1, true);
    bot.SetMissionTarget(GetBossPlayers()[0]);
}