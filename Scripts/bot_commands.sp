#include <sourcemod>
#include <sdktools>
#include <cstrike>

ConVar gCvarBlockPlant;

public Plugin myinfo = {
    name = "Bot Commands",
    author = "OpenAI",
    description = "Bot control commands including bomb plant blocking",
    version = "1.0"
};

public void OnPluginStart() {
    RegAdminCmd("sm_addbots", Command_AddBots, ADMFLAG_RCON);
    RegAdminCmd("sm_kickbots", Command_KickBots, ADMFLAG_RCON);

    gCvarBlockPlant = CreateConVar("sm_block_bombplant", "1", "Prevent Terrorists from planting the bomb (1 = yes, 0 = no)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    HookEvent("bomb_beginplant", Event_BombBeginPlant, EventHookMode_Pre);
}

public Action Event_BombBeginPlant(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!IsClientInGame(client) || GetClientTeam(client) != CS_TEAM_T) return Plugin_Continue;

    if (gCvarBlockPlant.BoolValue) {
        PrintToChatAll("[Bot] %N tried to plant the bomb - blocked.", client);
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

public Action Command_AddBots(int client, int args) {
    if (args < 2) {
        ReplyToCommand(client, "[Bot] Usage: sm_addbots <t/ct> <count>");
        return Plugin_Handled;
    }

    char teamStr[8], countStr[8];
    GetCmdArg(1, teamStr, sizeof(teamStr));
    GetCmdArg(2, countStr, sizeof(countStr));

    int num = StringToInt(countStr);
    if (num < 1) {
        ReplyToCommand(client, "[Bot] Bot count must be at least 1.");
        return Plugin_Handled;
    }

    for (int i = 0; i < num; i++) {
        if (teamStr[0] == 't') ServerCommand("bot_add_t");
        else if (teamStr[0] == 'c') ServerCommand("bot_add_ct");
        else {
            ReplyToCommand(client, "[Bot] Invalid team. Use 't' or 'ct'.");
            return Plugin_Handled;
        }
    }

    ReplyToCommand(client, "[Bot] Added %d bots to %s team.", num, teamStr);
    return Plugin_Handled;
}

public Action Command_KickBots(int client, int args) {
    if (args < 1) {
        ReplyToCommand(client, "[Bot] Usage: sm_kickbots <t/ct/all>");
        return Plugin_Handled;
    }

    char teamStr[8];
    GetCmdArg(1, teamStr, sizeof(teamStr));

    if (teamStr[0] == 't') ServerCommand("bot_kick_t");
    else if (teamStr[0] == 'c') ServerCommand("bot_kick_ct");
    else if (StrEqual(teamStr, "all", false)) ServerCommand("bot_kick");
    else {
        ReplyToCommand(client, "[Bot] Invalid team. Use t, ct, or all.");
        return Plugin_Handled;
    }

    ReplyToCommand(client, "[Bot] Bots kicked from team: %s", teamStr);
    return Plugin_Handled;
}
