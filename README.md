This is a vscript addon for the Versus Saxton Hale gamemode in Team Fortress 2.

To use this on your community server, simply place the file inside `/scripts/vscripts/vsh_addons`

New Features:
- Damage logging:
  - On death: the damage dealt by the player is broadcast in chat.
    - If the dead ringer is used, a fake message is displayed to Hale only.
    - Insults the player if they do 0 damage.
  - At round end:
    - The top 3 players' damage is listed.
    - The total damage by all players is displayed.
    - Damage by other sources (e.g. Distillery grinder) is listed separately.
    - Shows a percentage of how much health RED Team managed to chip away.

Changes:
- Legend:
  - $n$ is the number of RED players still alive.
  - $N$ is the number of RED players at the start of the round.
  - $h$ is the current health of Hale.
  - $H$ is the max health of Hale.
- Hale's health:
  - Added an additional factor that reduces Hale's health for >32 players.
  - Old formula (for $N \gt 32$): $H = 40N^2 + 2000$
  - New Formula (for $N \gt 32$): $H = 40N^2 * (N-32)/200 + 2000$
  - Max health for $N \leq 32$ are unchanged.
- Round timer:
  - Setup Time:
    - Old value: 16 seconds.
    - New value: $max(16, N/3)$ seconds.
  - Time before point unlocks:
    - Old value: 4 minutes (drops to 1 minute once only 5 players are alive).
    - New behaviour: Starts at $max(240, 8N)$ seconds, then clamped down to $max(60, 10n)$ seconds during the round (updated on round start and player death).
  - Stalemate time is unchanged.
- Weapons:
  - Market Gardener and Backstab damage (and anything else using `CalcStabDamage()`) capped at 5000.
    - Affects very high playercounts only.
- Control Point:
  - Capturing the point no longer instantly ends the round:
    - If RED caps, they get guaranteed crits on all weapons.
    - If Hale caps, the cooldown on his special abilities is removed.
  - On capture, the stalemate timer is disabled entirely and the point locks itself permanently.
  - The round will eventually end due to Hale's health changing over time:
    - When RED caps, Hale's health will tick down faster and faster. This guarantees his death if he doesn't manage to kill all of RED team first.
    - When Hale caps, his health will tick up faster and faster until it reaches max health, at which point Hale wins the round.
  - The health gained/lost each second starts at a value $c$, then increases by 1 every second.
  - $c$ is defined by the following equations, calculated on point capture:
    - $\Delta h = H - h$ if Hale capped, $h$ if RED capped.
    - $p = n$ if Hale capped, $N-n$ if RED capped.
    - $t = max(60, 5p)$ The result of this equation is equivalent to the remaining round duration in seconds assuming no other damage events post-capture and no clamping in the next equation.
    - $c = \lceil(2\Delta h/t - t + 1) / 2\rceil$ clamped between $1$ and $N/100$
  - $c$ is calculated in this manner to ensure a roughly consistent round duration.
  - These changes prevent either side from getting an undeserved victory, as the opponent still has a *slim* chance of winning after the capture.
  - Capturing the point produces exciting gameplay to finish a round as opposed to a sudden cutoff.