::mercBuff <- false
::haleBuff <- false

// OVERRIDE: Replace stalemate function to account for a captured control point.
function PrepareStalemate()
{
    local delay = clampFloor(60, API_GetFloat("stalemate_time"));

    RunWithDelay("DisplayStalemateAlert()", null, delay - 60);

    // Don't need to gate, entity is disabled when point captured.
    RunWithDelay("EntFireByHandle(team_round_timer, `SetTime`, `60`, 0, null, null)", null, delay - 60);

    RunWithDelay("PlayAnnouncerVODelayedGated(5)", null, delay - 6);
    RunWithDelay("PlayAnnouncerVODelayedGated(4)", null, delay - 5);
    RunWithDelay("PlayAnnouncerVODelayedGated(3)", null, delay - 4);
    RunWithDelay("PlayAnnouncerVODelayedGated(2)", null, delay - 3);
    RunWithDelay("PlayAnnouncerVODelayedGated(1)", null, delay - 2);

    RunWithDelay("EndRoundTime()", null, delay);
}

// Helper functions to gate against mercBuff and haleBuff

// Message displays for 5 seconds rather than 1
function DisplayStalemateAlert() {
    if(mercBuff || haleBuff) return;
    local text_tf = SpawnEntityFromTable("game_text_tf", {
        message = "#vsh_end_this",
        icon = "ico_notify_flag_moving_alt",
        background = 0,
        display_to_team = 0
    });
    EntFireByHandle(text_tf, "Display", "", 0, null, null);
    EntFireByHandle(text_tf, "Display", "", 2.5, null, null);
    EntFireByHandle(text_tf, "Kill", "", 5, null, null);
}

// Play stalemate countdown.
function PlayAnnouncerVODelayedGated(number) {
    if(mercBuff || haleBuff) return;
    local boss = GetRandomBossPlayer();
    PlayAnnouncerVODelayed(boss, "count"+number, 0);
}

// Stalemates if point isn't owned.
function EndRoundTime() {
    if(mercBuff || haleBuff) return;
    EndRound(TF_TEAM_UNASSIGNED);
}

// Remove outputs intended to end the round on point capture and add our own.
AddListener("setup_end", 0, function()
{
    // Out with the old...
    local controlPoint = Entities.FindByClassname(null, "team_control_point");
    EntityOutputs.RemoveOutput(controlPoint,
        "OnCapTeam"+(TF_TEAM_MERCS-1),
        vsh_vscript_name,
        "RunScriptCode",
        "EndRound("+TF_TEAM_MERCS+")"
    );
    EntityOutputs.RemoveOutput(controlPoint,
        "OnCapTeam"+(TF_TEAM_BOSS-1),
        vsh_vscript_name,
        "RunScriptCode",
        "EndRound("+TF_TEAM_BOSS+")"
    );

    // ...and in with the new.
    EntityOutputs.AddOutput(controlPoint,
        "OnCapTeam"+(TF_TEAM_MERCS-1),
        vsh_vscript_name,
        "RunScriptCode",
        "BuffMercs()",
        0, -1);
    EntityOutputs.AddOutput(controlPoint,
        "OnCapTeam"+(TF_TEAM_BOSS-1),
        vsh_vscript_name,
        "RunScriptCode",
        "BuffHale()",
        0, -1);
});

IncludeScript("vsh_addons/control_point_hale.nut");
IncludeScript("vsh_addons/control_point_mercs.nut");