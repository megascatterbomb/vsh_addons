local mercsIdleTracker = {};
local mercsInteractTracker = {};

local idleThreshold = 60;
local interactThreshold = 1000;

local movementFlags = IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT;

function PrintIdleMessage(player, timeToKick)
{
    ClientPrint(target, 3, "You have "+timeToKick+" seconds to stop being AFK before you're fired!");
}

function PrintIdleMessageNearDeath(player, timeToKick)
{
    ClientPrint(target, 3, timeToKick+"...");
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
    mercsInteractTracker[player]++;
    mercsIdleTracker[player] = Time();
    return false;
}

function IdleTick()
{
    foreach(player in GetAliveMercs())
    {
        if(!(player in mercsIdleTracker) || !(player in mercsInteractTracker))
        {
            continue;
        }
        else if(mercsIdleTracker[player] == -1)
        {
            mercsIdleTracker.rawdelete(player);
            continue;
        }
        CheckIfStillIdle(player);
    }
}

function AdjustHaleHealth(bootCount)
{
    if(bootCount <= 0) return;

    local newMercCount = startMercCount - bootCount;

    local effectiveMaxHealth = GetStartingHealth(newMercCount);

    local healthDiff = maxHealth - effectiveMaxHealth;

    local healthPenalty = floor(clampCeiling(currentHealth - 1,  healthDiff * (currentHealth / maxHealth))) - GetRoundDamage(player);

    if(healthPenalty <= 0) return;
}

function IdleSecondLoop()
{
    local needed = false;
    local bootCount = 0;
    foreach(player in mercsIdleTracker)
    {
        if(!IsPlayerAlive(player) || mercsInteractTracker[player] >= interactThreshold)
        {
            mercsIdleTracker[player] = -1;
            mercsInteractTracker.rawdelete(player);
            continue;
        }
        needed = true;
        local timeIdle = floor(Time() - mercsIdleTracker[player]);
        if(timeIdle >= idleThreshold && IsPlayerAlive(player))
        {
            bootCount++;
            player.TakeDamage(999999, 0, null);
            local name = GetPropString(player, "m_szNetname");
            ClientPrint(null, 3, "Player '" + name + "' was fired for being AFK.");
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
    AdjustHaleHealth(bootCount);

    if(!needed) return;
    RunWithDelay("IdleSecondLoop()", null, 1);
}

AddListener("setup_end", 10, function()
{
    foreach(player in GetAliveMercs())
    {
        mercsIdleTracker[player] = Time();
        mercsInteractTracker[player] = 0;
    }
    AddListener("tick_only_valid", 2, function (timeDelta)
    {
        IdleTick();
    });
    IdleSecondLoop();
});
