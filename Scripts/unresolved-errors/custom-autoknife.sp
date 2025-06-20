#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define MAX_CLIENTS 65

bool g_bAutoKnife[MAX_CLIENTS];

public Plugin:myinfo = 
{
    name = "Auto Knife on Round End",
    author = "ChatGPT",
    description = "Switches to knife when all enemies are dead for opted-in players",
    version = "1.1",
    url = ""
};

public void OnPluginStart()
{
    RegConsoleCmd("toggle_autoknife", Cmd_ToggleAutoKnife, "Usage: toggle_autoknife <0|1> - Enable or disable auto-knife on enemy wipe");
    HookEvent("player_death", OnPlayerDeath, EventHookMode_Post);
    HookEvent("round_start", OnRoundStart);
}

public void OnClientDisconnect(int client)
{
    g_bAutoKnife[client] = false;
}

public Action Cmd_ToggleAutoKnife(int client, int args)
{
    if (!IsClientInGame(client))
        return Plugin_Handled;

    if (args < 1)
    {
        PrintToChat(client, "[AutoKnife] Usage: toggle_autoknife <0|1>");
        return Plugin_Handled;
    }

    char arg[5];
    GetCmdArg(1, arg, sizeof(arg));

    int state = StringToInt(arg);
    if (state != 0 && state != 1)
    {
        PrintToChat(client, "[AutoKnife] Invalid value. Use 1 to enable, 0 to disable.");
        return Plugin_Handled;
    }

    g_bAutoKnife[client] = (state == 1);
    PrintToChat(client, "[AutoKnife] Auto-knife is now %s.", g_bAutoKnife[client] ? "ENABLED" : "DISABLED");

    return Plugin_Handled;
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
    // You can reset round-specific logic here if needed
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    // Slight delay to ensure game has updated states
    CreateTimer(0.2, Timer_CheckTeams);
}

public Action Timer_CheckTeams(Handle timer)
{
    int t_alive = 0;
    int ct_alive = 0;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && IsPlayerAlive(i))
        {
            int team = GetClientTeam(i);
            if (team == 2)
                t_alive++;
            else if (team == 3)
                ct_alive++;
        }
    }

    if (t_alive == 0 || ct_alive == 0)
    {
        int deadTeam = (t_alive == 0) ? 2 : 3;

        for (int i = 1; i <= MaxClients; i++)
        {
            if (!IsClientInGame(i) || !IsPlayerAlive(i))
                continue;

            if (GetClientTeam(i) != deadTeam && g_bAutoKnife[i])
            {
                FakeClientCommand(i, "slot3");
            }
        }
    }

    return Plugin_Stop;
}
