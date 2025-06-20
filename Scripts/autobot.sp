#include <sourcemod>
#include <sdktools>
#include <colors>

#define MAX_BOTS 5
#define CHECK_INTERVAL 5.0

bool g_bEnabled = true;

public Plugin myinfo = 
{
    name = "Auto Bot Spawner",
    author = "You",
    description = "Spawns enemy team bots during a match, with toggle support.",
    version = "1.1"
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_autobot", Command_ToggleBotSpawn, "Toggles automatic bot spawning");
    CreateTimer(CHECK_INTERVAL, CheckBotCount, _, TIMER_REPEAT);
    PrintToServer("[AutoBot] Plugin loaded. Type !autobot to toggle.");
}

public Action Command_ToggleBotSpawn(int client, int args)
{
    g_bEnabled = !g_bEnabled;

    if (client > 0)
    {
        CPrintToChat(client, "{green}[AutoBot]{default} Auto bot spawning is now {lightgreen}%s", g_bEnabled ? "ENABLED" : "DISABLED");
    }
    else
    {
        PrintToServer("[AutoBot] Auto bot spawning is now %s", g_bEnabled ? "ENABLED" : "DISABLED");
    }

    return Plugin_Handled;
}

public Action CheckBotCount(Handle timer)
{
    if (!g_bEnabled) return Plugin_Continue;

    int tCount = 0;
    int ctCount = 0;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && IsFakeClient(i))
        {
            int team = GetClientTeam(i);
            if (team == 2) tCount++;
            else if (team == 3) ctCount++;
        }
    }

    int humanTeam = GetDominantHumanTeam();

    int botTeam = (humanTeam == 2) ? 3 : 2;
    int botCount = (botTeam == 2) ? tCount : ctCount;

    if (botCount < MAX_BOTS)
    {
        int botsToAdd = MAX_BOTS - botCount;
        for (int i = 0; i < botsToAdd; i++)
        {
            if (botTeam == 2)
                ServerCommand("bot_add_t");
            else
                ServerCommand("bot_add_ct");
        }
        PrintToServer("[AutoBot] Added %d bot(s) to team %s.", botsToAdd, botTeam == 2 ? "T" : "CT");
    }

    return Plugin_Continue;
}

int GetDominantHumanTeam()
{
    int tHumans = 0;
    int ctHumans = 0;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            int team = GetClientTeam(i);
            if (team == 2) tHumans++;
            else if (team == 3) ctHumans++;
        }
    }

    if (tHumans >= ctHumans)
        return 2;
    else
        return 3;
}
