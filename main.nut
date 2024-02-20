::maxHealth <- 0;
::currentHealth <- 0;

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

IncludeScript("vsh_addons/health.nut");
IncludeScript("vsh_addons/damage_scoring.nut");
IncludeScript("vsh_addons/round_time.nut");
IncludeScript("vsh_addons/control_point.nut");

// Clamp stab damage (and market gardner) to 5000 max
function CalcStabDamage(victim)
{
    return clamp(GetPerPlayerDamageQuota(victim), 500, 5000);
}
