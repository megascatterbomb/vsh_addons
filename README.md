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
    - A percentage of how much health RED Team managed to chip away is shown.

Changes:
- Legend:
  - $n$ is the number of opponents.
- Hale's health:
  - Added an additional factor that reduces Hale's health for >32 players.
  - Old formula (for $n \gt 32$): 40n^2 + 2000
  - New Formula (for $n \gt 32$): 40n^2 * (n-32)/200 + 2000
  - Health values for $n \leq 32$ are unchanged.
- Round timer:
  - Setup Time:
    - Old value: 16 seconds.
    - New value: `max(16, n/3)` seconds.
  - Time before point unlocks:
    - Old value: 4 minutes (drops to 1 minute once only 5 players are alive).
    - New behaviour: Starts at `max(60, n*8)` seconds. On player death, time remaining is clamped down to `max(60, n*10)` seconds.
  - Sudden death time is unchanged.
- Weapons:
  - Market Gardener and Backstab damage (and anything else using `CalcStabDamage()`) capped at 5000.
    - Affects very high playercounts only.