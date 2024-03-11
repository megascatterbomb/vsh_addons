local mercsIdleTracker = {};

local idleThreshold = 60;

local movementFlags = IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT;

function PrintIdleMessage(player, timeToKick)
{
    ClientPrint(player, 3, "You have "+timeToKick+" seconds to stop being AFK before you're fired!");
}

function PrintIdleMessageNearDeath(player, timeToKick)
{
    ClientPrint(player, 3, timeToKick+"...");
}

function CheckIfStillIdle(player)
{
    local buttons = GetPropInt(player, "m_nButtons");

    if(!(
        (buttons & movementFlags) || // WASD input
        (false) // Mouse input
    ))
    {
        return true;
    }
    mercsIdleTracker[player] = Time();
    return false;
}

function IdleTick()
{
    foreach(player in GetAliveMercs())
    {
        if(!(player in mercsIdleTracker))
        {
            continue;
        }
        CheckIfStillIdle(player);
    }
}

local adjustedMercCount = -1;

function AdjustHaleHealth(bootedPlayers)
{
    local bootCount = bootedPlayers.len();
    if(adjustedMercCount < 0) adjustedMercCount = startMercCount;
    local oldMercCount = adjustedMercCount;
    adjustedMercCount = adjustedMercCount - bootCount;

    if(bootCount <= 0 || adjustedMercCount <= 0) return;

    local boss = GetBossPlayers()[0];
    local currHealth = boss.GetHealth();
    local oldMaxHealth = GetStartingHealth(oldMercCount);
    local adjustedMaxHealth = GetStartingHealth(adjustedMercCount)

    local healthDiff = oldMaxHealth - adjustedMaxHealth;

    local damageDealtByAFKPlayers = 0;

    foreach(player in bootedPlayers)
    {
        local damage = GetRoundDamage(player);
        damageDealtByAFKPlayers = damageDealtByAFKPlayers + damage;
    }

    local healthPenalty = floor(clampCeiling(currHealth - 1,  healthDiff * (currHealth / oldMaxHealth))) - damageDealtByAFKPlayers;

    if(healthPenalty <= 0) return;

    boss.TakeDamageCustom(boss, boss, null, Vector(0.000001, 0.000001, 0.000001), Vector(0.000001, 0.000001, 0.000001), healthPenalty, DMG_PREVENT_PHYSICS_FORCE, TF_DMG_CUSTOM_BLEEDING);
    ClientPrint(null, 3, "Hale was penalized " + healthPenalty + " health to compensate for idling.");
}

function IdleStart()
{
    local now = Time();
    foreach(player in GetAliveMercs())
    {
        if(IsPlayerAlive(player) && !(player in mercsIdleTracker))
        {
            mercsIdleTracker[player] <- now;
        }
    }
    IdleSecondLoop();
    AddListener("tick_only_valid", 11, function (timeDelta)
    {
        IdleTick();
    });
}

function IdleSecondLoop()
{
    local bootedPlayers = [];
    foreach(player in GetAliveMercs())
    {
        if (player == null || !IsPlayerAlive(player)) continue;

        local timeIdle = floor(Time() - mercsIdleTracker[player]);
        if(timeIdle >= idleThreshold && IsPlayerAlive(player))
        {
            player.TakeDamage(999999, 0, null);
            local name = GetPropString(player, "m_szNetname");
            ClientPrint(null, 3, "Player '" + name + "' was fired for being AFK.");
            bootedPlayers.push(player);
            continue;
        }
        switch (timeIdle) {
            case (idleThreshold - 30):
                PrintIdleMessage(player, 30);
                break;
            case (idleThreshold - 20):
                PrintIdleMessage(player, 20);
                break;
            case (idleThreshold - 15):
                PrintIdleMessage(player, 15);
                break;
            case (idleThreshold - 10):
                PrintIdleMessage(player, 10);
                break;
            case (idleThreshold - 5):
                PrintIdleMessageNearDeath(player, 5);
                break;
            case (idleThreshold - 4):
                PrintIdleMessageNearDeath(player, 4);
                break;
            case (idleThreshold - 3):
                PrintIdleMessageNearDeath(player, 3);
                break;
            case (idleThreshold - 2):
                PrintIdleMessageNearDeath(player, 2);
                break;
            case (idleThreshold - 1):
                PrintIdleMessageNearDeath(player, 1);
                break;
        }
    }
    AdjustHaleHealth(bootedPlayers);

    RunWithDelay("IdleSecondLoop()", null, 1);
}

AddListener("setup_end", 10, function()
{
    IdleStart();
});


