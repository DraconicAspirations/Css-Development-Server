#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
    name = "Tactical Dispatcher",
    author = "YourName",
    description = "Plays 'enemy down' radio for players when an enemy dies",
    version = "1.3",
    url = ""
};

public void OnPluginStart()
{
    HookEvent("player_death", OnPlayerDeath, EventHookMode_Post);
    PrecacheSound("radio/enemydown.wav", true);
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    if (victim <= 0 || !IsClientInGame(victim)) {
        return Plugin_Continue;
    }

    int victimTeam = GetClientTeam(victim);

    if (victimTeam < 2 || victimTeam > 3) {
        return Plugin_Continue;
    }

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || !IsPlayerAlive(i)) {
            continue;
        }

        int clientTeam = GetClientTeam(i);

        // Must be on actual team, and be enemy of victim
        if (clientTeam >= 2 && clientTeam != victimTeam)
        {
            EmitSoundToClient(i, "radio/enemydown.wav");
        }
    }

    return Plugin_Continue;
}
