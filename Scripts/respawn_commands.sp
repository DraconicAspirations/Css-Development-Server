// === respawn_commands.sp ===

#include <sourcemod>
#include <sdktools>
#include <cstrike>

ConVar gCvarAutoRespawn;
ConVar gCvarRespawnDelay;
int gRespawnTeam = 0; // 0 = all, 2 = T, 3 = CT
int gRespawnType = 0; // 0 = all, 1 = humans, 2 = bots

public Plugin myinfo = {
    name = "Respawn Commands",
    author = "OpenAI",
    description = "Manual and automatic player respawn commands with delay",
    version = "1.4"
};

public void OnPluginStart() {
    RegAdminCmd("sm_respawn", Command_Respawn, ADMFLAG_SLAY);
    RegAdminCmd("sm_autorespawn", Command_AutoRespawnToggle, ADMFLAG_GENERIC);

    gCvarAutoRespawn = CreateConVar("sm_autorespawn_enabled", "0", "Enable autorespawn globally", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    gCvarRespawnDelay = CreateConVar("sm_autorespawn_delay", "3.0", "Delay (in seconds) before a player is auto-respawned", FCVAR_NOTIFY, true, 0.0, true, 30.0);

    HookEvent("player_death", Event_PlayerDeath);
}

// Manual respawn by name
public Action Command_Respawn(int client, int args) {
    if (args < 1) {
        ReplyToCommand(client, "[Respawn] Usage: sm_respawn <player name>");
        return Plugin_Handled;
    }

    char nameArg[64];
    GetCmdArg(1, nameArg, sizeof(nameArg));

    for (int i = 1; i <= MaxClients; i++) {
        if (!IsClientInGame(i) || IsPlayerAlive(i)) continue;

        char playerName[64];
        GetClientName(i, playerName, sizeof(playerName));

        if (StrEqual(nameArg, playerName, false)) {
            CS_RespawnPlayer(i);
            PrintToChatAll("[Respawn] %N has been respawned.", i);
            return Plugin_Handled;
        }
    }

    ReplyToCommand(client, "[Respawn] Player not found or already alive.");
    return Plugin_Handled;
}

// Autorespawn toggle
public Action Command_AutoRespawnToggle(int client, int args) {
    if (args < 1) {
        ReplyToCommand(client, "[Respawn] Usage: sm_autorespawn <enable/disable> <all-teams|ct|t> <all-players|humans|bots>");
        return Plugin_Handled;
    }

    char arg1[16], arg2[16], arg3[16];
    GetCmdArg(1, arg1, sizeof(arg1));
    gCvarAutoRespawn.SetBool(StrEqual(arg1, "enable", false));

    if (args >= 2) {
        GetCmdArg(2, arg2, sizeof(arg2));
        if (StrEqual(arg2, "ct", false)) gRespawnTeam = CS_TEAM_CT;
        else if (StrEqual(arg2, "t", false)) gRespawnTeam = CS_TEAM_T;
        else gRespawnTeam = 0;
    } else {
        gRespawnTeam = 0;
    }

    if (args >= 3) {
        GetCmdArg(3, arg3, sizeof(arg3));
        if (StrEqual(arg3, "humans", false)) gRespawnType = 1;
        else if (StrEqual(arg3, "bots", false)) gRespawnType = 2;
        else gRespawnType = 0;
    } else {
        gRespawnType = 0;
    }

    ReplyToCommand(client, "[Respawn] Autorespawn %s | Team: %s | Type: %s",
        gCvarAutoRespawn.BoolValue ? "ENABLED" : "DISABLED",
        gRespawnTeam == CS_TEAM_CT ? "CT" : gRespawnTeam == CS_TEAM_T ? "T" : "ALL",
        gRespawnType == 1 ? "Humans" : gRespawnType == 2 ? "Bots" : "All Players");

    return Plugin_Handled;
}

// Event hook for player death
public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
    if (!gCvarAutoRespawn.BoolValue) return;

    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!IsClientInGame(client)) return;

    if (gRespawnTeam != 0 && GetClientTeam(client) != gRespawnTeam) return;
    if (gRespawnType == 1 && IsFakeClient(client)) return;
    if (gRespawnType == 2 && !IsFakeClient(client)) return;

    CreateTimer(gCvarRespawnDelay.FloatValue, Timer_RespawnPlayer, client);
}

// Timer callback to respawn a player
public Action Timer_RespawnPlayer(Handle timer, any client) {
    if (IsClientInGame(client) && !IsPlayerAlive(client)) {
        CS_RespawnPlayer(client);
    }
    return Plugin_Stop;
}
