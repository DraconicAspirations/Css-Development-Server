#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo = {
    name = "Auto Grenade Giver (Wipe & Give, Fixed)",
    author = "ChatGPT",
    description = "Removes all grenades and gives standard set if in buy zone (with flash fix)",
    version = "1.6"
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_g_grenades", Command_GiveGrenades, "Removes grenades and gives fresh set");
    RegConsoleCmd("say", OnSayCmd);
}

public Action OnSayCmd(int client, int args)
{
    char text[128];
    GetCmdArgString(text, sizeof(text));
    TrimString(text);

    if (StrEqual(text, "!g_grenades", false) || StrEqual(text, "/g_grenades", false))
    {
        Command_GiveGrenades(client, 0);
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

public Action Command_GiveGrenades(int client, int args)
{
    if (!IsClientInGame(client) || !IsPlayerAlive(client))
    {
        PrintToChat(client, "[AutoBuy] You must be alive.");
        return Plugin_Handled;
    }

    if (!IsPlayerInBuyZone(client))
    {
        PrintToChat(client, "[AutoBuy] You must be in a buyzone.");
        return Plugin_Handled;
    }

    RemovePlayerGrenades(client);

    GivePlayerItem(client, "weapon_hegrenade");

    int flash = GivePlayerItem(client, "weapon_flashbang");
    if (flash != -1)
    {
        SetEntProp(client, Prop_Send, "m_iAmmo", 1, _, 11); // slot 11 is flashbang ammo
    }

    GivePlayerItem(client, "weapon_smokegrenade");

    PrintToChat(client, "[AutoBuy] Your grenades have been refreshed.");
    return Plugin_Handled;
}

void RemovePlayerGrenades(int client)
{
    int maxEnts = GetMaxEntities();

    for (int i = 1; i < maxEnts; i++)
    {
        if (!IsValidEdict(i) || !IsValidEntity(i))
            continue;

        char classname[64];
        GetEdictClassname(i, classname, sizeof(classname));

        if (StrContains(classname, "weapon_", false) != 0)
            continue;

        if (!IsGrenade(classname))
            continue;

        int owner = GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity");
        if (owner == client)
        {
            RemovePlayerItem(client, i);
            RemoveEdict(i);
        }
    }
}

bool IsGrenade(const char[] classname)
{
    return StrEqual(classname, "weapon_hegrenade") ||
           StrEqual(classname, "weapon_flashbang") ||
           StrEqual(classname, "weapon_smokegrenade");
}

bool IsPlayerInBuyZone(int client)
{
    return GetEntProp(client, Prop_Send, "m_bInBuyZone") != 0;
}
