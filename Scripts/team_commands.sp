
#include <sourcemod>
#include <sdktools>
#include <cstrike>

public Plugin myinfo = {
    name = "Team Commands",
    author = "OpenAI",
    description = "Team switch commands",
    version = "1.0"
};

public void OnPluginStart() {
    RegAdminCmd("sm_setteam", Command_SetTeam, ADMFLAG_GENERIC);
}

public Action Command_SetTeam(int client, int args) {
    if (args < 2) {
        ReplyToCommand(client, "[Team] Usage: sm_setteam <target> <1=Spec, 2=T, 3=CT>");
        return Plugin_Handled;
    }

    char targetStr[64], teamStr[8];
    GetCmdArg(1, targetStr, sizeof(targetStr));
    GetCmdArg(2, teamStr, sizeof(teamStr));

    int team = StringToInt(teamStr);
    if (team < 1 || team > 3) {
        ReplyToCommand(client, "[Team] Invalid team number. Use 1=Spec, 2=T, 3=CT.");
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
            ReplyToCommand(client, "[Team] Could not find player '%s'", targetStr);
            return Plugin_Handled;
        }
    }

    if (IsPlayerAlive(target)) {
        ForcePlayerSuicide(target);
    }

    CS_SwitchTeam(target, team);
    CreateTimer(0.1, Timer_RespawnPlayer, target);
    PrintToChatAll("[Team] %N was moved to team %d.", target, team);
    return Plugin_Handled;
}

public Action Timer_RespawnPlayer(Handle timer, any client) {
    if (IsClientInGame(client) && !IsPlayerAlive(client)) {
        CS_RespawnPlayer(client);
    }
    return Plugin_Stop;
}
