#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = {
    name = "Match Commands",
    author = "YourName",
    description = "Prevents bomb planting by removing the bomb",
    version = "1.0",
    url = ""
};

public void OnPluginStart()
{
    HookEvent("bomb_pickup", OnBombPickup, EventHookMode_Post);
    HookEvent("bomb_drop", OnBombDrop, EventHookMode_Post);
    HookEvent("round_start", OnRoundStart, EventHookMode_Post);
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
    RemoveBomb();
}

public void OnBombPickup(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (IsClientInGame(client))
    {
        PrintToChat(client, "Bomb pickup disabled.");
        RemoveBomb();
    }
}

public void OnBombDrop(Event event, const char[] name, bool dontBroadcast)
{
    CreateTimer(0.1, Timer_RemoveBomb);
}

public Action Timer_RemoveBomb(Handle timer)
{
    RemoveBomb();
    return Plugin_Stop;
}

void RemoveBomb()
{
    int maxEntities = GetMaxEntities();
    for (int i = 1; i <= maxEntities; i++)
    {
        if (!IsValidEntity(i)) continue;

        char classname[64];
        GetEdictClassname(i, classname, sizeof(classname));

        if (StrEqual(classname, "weapon_c4") || StrEqual(classname, "planted_c4"))
        {
            RemoveEdict(i);
        }
    }
}
