local jumped = false;

function OnFrameTickAlive()
{
    local buttons = GetPropInt(boss, "m_nButtons");

    if (!boss.IsOnGround())
    {
        if (jumpStatus == BOSS_JUMP_STATUS.WALKING)
            jumpStatus = BOSS_JUMP_STATUS.JUMP_STARTED;
        else if (jumpStatus == BOSS_JUMP_STATUS.JUMP_STARTED && !(buttons & IN_JUMP))
            jumpStatus = BOSS_JUMP_STATUS.CAN_DOUBLE_JUMP;
    }
    else
        jumpStatus = BOSS_JUMP_STATUS.WALKING;

    if (buttons & IN_JUMP && jumpStatus == BOSS_JUMP_STATUS.CAN_DOUBLE_JUMP)
    {
        if (!IsRoundSetup() && Time() - voiceLinePlayed > 1.5)
        {
            voiceLinePlayed = Time();
            EmitPlayerVO(boss, "jump");
        }

        jumpStatus = BOSS_JUMP_STATUS.DOUBLE_JUMPED;
        Perform();
    }

    if (!jumped && Time() > lastTimeJumped + API_GetInt("setup_length") + 30)
    {
        NotifyJump();
    }
}

function BraveJumpTrait::Perform()
{
    jumped = true;
    local factor = 1;
    local dampDuration = 5;
    if(Time() < lastTimeJumped + dampDuration) {
        factor = clampFloor(0.5, (Time() - lastTimeJumped) / dampDuration);
    }

    lastTimeJumped = Time();

    local buttons = GetPropInt(boss, "m_nButtons");
    local eyeAngles = boss.EyeAngles();
    local forward = eyeAngles.Forward();
    forward.z = 0;
    forward.Norm();
    local left = eyeAngles.Left();
    left.z = 0;
    left.Norm();

    local forwardmove = 0
    if (buttons & IN_FORWARD)
        forwardmove = 1;
    else if (buttons & IN_BACK)
        forwardmove = -1;
    local sidemove = 0
    if (buttons & IN_MOVELEFT)
        sidemove = -1;
    else if (buttons & IN_MOVERIGHT)
        sidemove = 1;

    local newVelocity = Vector(0,0,0);
    newVelocity.x = forward.x * forwardmove + left.x * sidemove;
    newVelocity.y = forward.y * forwardmove + left.y * sidemove;
    newVelocity.Norm();
    newVelocity *= 300 * factor;
    newVelocity.z = jumpForce * factor;

    local currentVelocity = boss.GetAbsVelocity();
    if (currentVelocity.z < 300)
        currentVelocity.z = 0;

    SetPropEntity(boss, "m_hGroundEntity", null);
    boss.SetAbsVelocity(currentVelocity + newVelocity);
}

function BraveJumpTrait::NotifyJump()
{
    local text_tf = SpawnEntityFromTable("game_text_tf", {
        message = "#ClassTips_1_2",
        icon = "ico_notify_flag_moving_alt",
        background = TF_TEAM_BOSS,
        display_to_team = TF_TEAM_BOSS
    });
    EntFireByHandle(text_tf, "Display", "", 0.1, player, player);
    EntFireByHandle(text_tf, "Kill", "", 1, player, player);
}