#include <sourcemod>
#include <sdktools>
#include <cstrike>

ConVar gCvarBlockPlant;

public Plugin myinfo = {
    name = "Sammiis Commands",
    author = "SamMii & ChatGPT",
    description = "Custom admin tools: respawn, team switch, bot control, block bomb plant",
    version = "1.2"
};

public void OnPluginStart() {
    RegAdminCmd("sm_respawn", Command_Respawn, ADMFLAG_SLAY);
    RegAdminCmd("sm_setteam", Command_SetTeam, ADMFLAG_GENERIC);
    RegAdminCmd("sm_addbots", Command_AddBots, ADMFLAG_RCON);
    RegAdminCmd("sm_kickbots", Command_KickBots, ADMFLAG_RCON);

    // Create toggleable ConVar
    gCvarBlockPlant = CreateConVar("sm_block_botplant", "1", "Prevent Terrorists from planting the bomb (1 = yes, 0 = no)", FCVAR_NOTIFY, true, 0.0, true, 1.0);

    // Hook planting event
    HookEvent("bomb_beginplant", Event_BombBeginPlant, EventHookMode_Pre);
}

// --- Block Bomb Planting for Terrorists ---
public Action Event_BombBeginPlant(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (!IsClientInGame(client) || GetClientTeam(client) != CS_TEAM_T)
        return Plugin_Continue;

    if (gCvarBlockPlant.BoolValue) {
        PrintToChatAll("[SammiisCmd] %N tried to plant the bomb — blocked.", client);
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

// --- Respawn Command ---
public Action Command_Respawn(int client, int args) {
    if (args < 1) {
        ReplyToCommand(client, "[SammiisCmd] Usage: sm_respawn <target>");
        return Plugin_Handled;
    }

    char arg[64];
    GetCmdArg(1, arg, sizeof(arg));

    int targets[MAXPLAYERS], count;
    bool tn;
    if ((count = ProcessTargetString(arg, client, targets, sizeof(targets), COMMAND_FILTER_DEAD, tn)) <= 0) {
        ReplyToTargetError(client, count);
        return Plugin_Handled;
    }

    for (int i = 0; i < count; i++) {
        if (IsClientInGame(targets[i]) && !IsPlayerAlive(targets[i])) {
            CS_RespawnPlayer(targets[i]);
            PrintToChatAll("[SammiisCmd] %N was respawned!", targets[i]);
        }
    }
    return Plugin_Handled;
}

// --- Team Switch Command ---
public Action Command_SetTeam(int client, int args) {
    if (args < 2) {
        ReplyToCommand(client, "[SammiisCmd] Usage: sm_setteam <client index or name> <1=Spec, 2=T, 3=CT>");
        return Plugin_Handled;
    }

    char targetStr[64], teamStr[8];
    GetCmdArg(1, targetStr, sizeof(targetStr));
    GetCmdArg(2, teamStr, sizeof(teamStr));

    int team = StringToInt(teamStr);
    if (team < 1 || team > 3) {
        ReplyToCommand(client, "[SammiisCmd] Invalid team number. Use 1=Spec, 2=T, 3=CT.");
        return Plugin_Handled;
    }

    int target = StringToInt(targetStr);
    if (target <= 0 || target > MaxClients || !IsClientInGame(target)) {
        target = 0;
        for (int i = 1; i <= MaxClients; i++) {
            if (!IsClientInGame(i)) continue;

            char name[64];
            GetClientName(i, name, sizeof(name));

            if (StrEqual(targetStr, name, false)) {
                target = i;
                break;
            }
        }

        if (target == 0) {
            ReplyToCommand(client, "[SammiisCmd] Could not find player '%s'", targetStr);
            return Plugin_Handled;
        }
    }

    if (IsPlayerAlive(target)) {
        ForcePlayerSuicide(target);
    }

    CS_SwitchTeam(target, team);
    CreateTimer(0.1, Timer_Respawn, target);

    PrintToChatAll("[SammiisCmd] %N moved to team %d", target, team);
    return Plugin_Handled;
}

// Delayed respawn after team switch
public Action Timer_Respawn(Handle timer, any client) {
    if (IsClientInGame(client) && !IsPlayerAlive(client)) {
        CS_RespawnPlayer(client);
    }
    return Plugin_Stop;
}

// --- Add Bots Command ---
public Action Command_AddBots(int client, int args) {
    if (args < 2) {
        ReplyToCommand(client, "[SammiisCmd] Usage: sm_addbots <t/ct> <count>");
        return Plugin_Handled;
    }

    char teamStr[8], countStr[8];
    GetCmdArg(1, teamStr, sizeof(teamStr));
    GetCmdArg(2, countStr, sizeof(countStr));

    int num = StringToInt(countStr);
    if (num < 1) {
        ReplyToCommand(client, "[SammiisCmd] Bot count must be at least 1.");
        return Plugin_Handled;
    }

    for (int i = 0; i < num; i++) {
        if (teamStr[0] == 't')
            ServerCommand("bot_add_t");
        else if (teamStr[0] == 'c')
            ServerCommand("bot_add_ct");
        else {
            ReplyToCommand(client, "[SammiisCmd] Invalid team. Use 't' or 'ct'.");
            return Plugin_Handled;
        }
    }

    ReplyToCommand(client, "[SammiisCmd] Added %d bots to %s team.", num, teamStr);
    return Plugin_Handled;
}

// --- Kick Bots Command ---
public Action Command_KickBots(int client, int args) {
    if (args < 1) {
        ReplyToCommand(client, "[SammiisCmd] Usage: sm_kickbots <t/ct/all>");
        return Plugin_Handled;
    }

    char teamStr[8];
    GetCmdArg(1, teamStr, sizeof(teamStr));

    if (teamStr[0] == 't')
        ServerCommand("bot_kick_t");
    else if (teamStr[0] == 'c')
        ServerCommand("bot_kick_ct");
    else if (StrEqual(teamStr, "all", false))
        ServerCommand("bot_kick");
    else {
        ReplyToCommand(client, "[SammiisCmd] Invalid team. Use t, ct, or all.");
        return Plugin_Handled;
    }

    ReplyToCommand(client, "[SammiisCmd] Bots kicked from team: %s", teamStr);
    return Plugin_Handled;
}
