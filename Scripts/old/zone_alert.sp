#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_NAME "Zone Voice Alert"
#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = {
    name = PLUGIN_NAME,
    author = "You",
    description = "Plays a voice alert when an enemy enters a specific zone",
    version = PLUGIN_VERSION
};

// Define your zone (world coordinates, in hammer units)
float g_ZoneMin[3] = { 100.0, 200.0, -100.0 };
float g_ZoneMax[3] = { 200.0, 300.0, 100.0 };

public void OnPluginStart()
{
    HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
    SDKHook_StartTouchAll();
}

// Checks if the player's origin is within the defined zone
bool IsPlayerInZone(int client)
{
    float origin[3];
    GetClientAbsOrigin(client, origin);

    return (origin[0] >= g_ZoneMin[0] && origin[0] <= g_ZoneMax[0] &&
            origin[1] >= g_ZoneMin[1] && origin[1] <= g_ZoneMax[1] &&
            origin[2] >= g_ZoneMin[2] && origin[2] <= g_ZoneMax[2]);
}

// Called frequently - you can optimize this later
public void OnGameFrame()
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client) || !IsPlayerAlive(client))
            continue;

        if (IsPlayerInZone(client))
        {
            // Only alert if it's a T entering CT territory, or similar
            int team = GetClientTeam(client);
            if (team == 2) // T team
            {
                EmitSoundToAll("vo/announcer_alert.wav", client);
            }
        }
    }
}
