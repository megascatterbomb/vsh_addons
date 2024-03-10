// OVERRIDE: Increase RPS damage to 1 Million to account for very high hale health
function TauntHandlerTrait::OnRPS(winner, loser, params)
{
    local voiceLine = null;
    if (IsBoss(winner))
        voiceLine = "rps_win_"+["rock","paper","scissors"][params.winner_rps];
    else if (IsBoss(loser))
    {
        lostByRPS = true;
        voiceLine = RandomInt(1, 2) == 1 ? "rps_lose" : "rps_lose_"+["rock","paper","scissors"][params.loser_rps];
        RunWithDelay2(this, 3, function(winner, loser) {
            if (!IsValidPlayer(loser))
                return;
            local attacker = IsValidPlayer(winner) ? winner : lower
            loser.TakeDamageEx(
                attacker,
                attacker,
                attacker.GetActiveWeapon(),
                Vector(0,0,0),
                attacker.GetOrigin(),
                999999, // <- the part we care about
                0);
        }, winner, loser);
    }

    if (voiceLine != null)
        PlayAnnouncerVODelayed(IsBoss(winner) ? winner : loser, voiceLine, 1);
}