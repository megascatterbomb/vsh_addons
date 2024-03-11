This is a vscript addon for the Versus Saxton Hale gamemode in Team Fortress 2.

To use this on your community server, simply place all the .nut files inside `/scripts/vscripts/vsh_addons`. No sourcemod required!

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
- Anti-AFK measures:
  - If a player fails to send a keyboard input for 60 seconds, they are killed.
  - When this happens, Hale's health is reduced to compensate, as though the idle player was never there in the first place.
  - Chat messages are sent to the idle player to give them an opportunity to come back before the idle-death.

Changes:
- Legend:
  - $n$ is the number of RED players still alive.
  - $N$ is the number of RED players at the start of the round.
  - $H$ is the max health of Hale.
- Hale's health:
  - Added an additional factor that reduces Hale's health for >32 players.
  - Old formula (for $N \gt 32$): $H = 40N^2 + 2000$
  - New Formula (for $N \gt 32$): $H = 40N^2 * (1 - (N-32)/200) + 2000$
  - Max health for $N \leq 32$ are unchanged.
- Brave Jump:
  - Added a 3 second cooldown. Has a supporting hud element.
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
    - If RED caps, they get guaranteed crits on all weapons and a powerful 5 second health regen.
    - If Hale caps, the cooldown on his special abilities is removed.
  - On capture, the stalemate timer is disabled entirely and the point locks itself permanently.
  - The round will eventually end due to Hale's health changing over time:
    - When RED caps, Hale's health will tick down faster and faster. This guarantees his death if he doesn't manage to kill all of RED team first.
    - When Hale caps, his health will tick up faster and faster until it reaches max health, at which point Hale wins the round.
  - The health gained/lost each second starts at 1, then increases by 1 every second.
  - If RED has the point and Hale doesn't do any damage to RED for 30 seconds, an additional 1.05 multiplier is added onto the health drain *each second*.
    - For example This means a $1.05^{15} = 2.08$ multiplier to the health drain per tick after 45 seconds of not dealing damage. The multiplier resets to 1.0 once Hale deals damage.
    - The reverse is also true if Hale owns the point and the mercs don't deal damage to Hale for 30 seconds; Hale's health will regenerate faster via a similar multiplier.
  - These changes prevent either side from getting an undeserved victory, as the opponent still has a *slim* chance of winning after the capture.
  - Capturing the point produces exciting gameplay to finish a round as opposed to a sudden cutoff.