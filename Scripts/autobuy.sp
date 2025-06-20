#include <sourcemod>
#include <sdktools>

#define MAX_WEAPONS 64

new String:g_ItemNames[][] = {
    "glock", "usp", "p228", "deagle", "elite", "fiveseven",
    "mac10", "tmp", "mp5navy", "ump45", "p90",
    "galil", "famas", "ak47", "m4a1", "sg552", "aug", "scout", "awp", "g3sg1", "sg550",
    "m3", "xm1014",
    "m249",
    "vest", "vesthelm", "flashbang", "hegrenade", "smokegrenade", "defuser", "nvgs"
};

new g_ItemPrices[] = {
    400, 500, 600, 650, 800, 750,
    1400, 1250, 1500, 1700, 2350,
    2000, 2250, 2500, 3100, 3500, 3500, 2750, 4750, 5000, 4200,
    1700, 3000,
    5750,
    650, 1000, 200, 300, 300, 200, 1250
};

new String:g_MapTypePrimaryWeapon[][][] = {
    { "tmp;vesthelm", "mp5navy;vesthelm", "p90;vesthelm", "famas;vesthelm", "m4a1;vesthelm" },       // SHORT_CT
    { "deagle", "mp5navy;vesthelm", "p90;vesthelm", "ak47;vesthelm" },                               // SHORT_T
    { "tmp", "tmp;vesthelm", "mp5navy", "mp5navy;vesthelm", "p90;vesthelm", "famas;vesthelm", "m4a1;vesthelm", "aug;vesthelm", "sg550;vesthelm", "awp;vesthelm" }, // MID_CT
    { "deagle", "ak47;vesthelm", "sg552;vesthelm", "awp;vesthelm" },                                 // MID_T
    { "tmp", "tmp;vesthelm", "aug;vesthelm", "sg550;vesthelm", "awp;vesthelm" },                     // LONG_CT
    { "deagle", "ak47;vesthelm", "sg552;vesthelm", "awp;vesthelm" }                                  // LONG_T
};

enum MapRangeTeam {
    SHORT_CT,
    SHORT_T,
    MID_CT,
    MID_T,
    LONG_CT,
    LONG_T
};

MapRangeTeam GetMapRangeTeam(const char[] map, const char[] team)
{
    if (StrEqual(map, "cs_office"))
        return StrEqual(team, "ct") ? SHORT_CT : SHORT_T;

    if (StrEqual(map, "de_rats_rc_1337v4") || StrEqual(map, "de_aztec") || StrEqual(map, "cs_compound"))
        return StrEqual(team, "ct") ? LONG_CT : LONG_T;

    return StrEqual(team, "ct") ? MID_CT : MID_T;
}

int GetItemPrice(const char[] item)
{
    for (int i = 0; i < sizeof(g_ItemNames); i++)
    {
        if (StrEqual(item, g_ItemNames[i]))
            return g_ItemPrices[i];
    }
    return 0;
}

int GetComboPrice(const char[] combo)
{
    decl String:items[4][32];
    int count = ExplodeString(combo, ";", items, sizeof(items), sizeof(items[]));
    int total = 0;
    for (int i = 0; i < count; i++)
    {
        total += GetItemPrice(items[i]);
    }
    return total;
}

void GetBestCombo(const String:map[], const String:team[], int money, String:bestCombo[64])
{
    MapRangeTeam key = GetMapRangeTeam(map, team);

    int maxSpent = 0;
    bestCombo[0] = '\0';

    for (int i = 0; i < sizeof(g_MapTypePrimaryWeapon[key]); i++)
    {
        const char[] combo = g_MapTypePrimaryWeapon[key][i];
        int cost = GetComboPrice(combo);

        if (cost <= money && cost > maxSpent)
        {
            maxSpent = cost;
            strcopy(bestCombo, 64, combo);
        }
    }
}

void Autobuy(int client, int money, const char[] map, const char[] team)
{
    if (money <= 800)
        return;

    decl String:combo[64];
    GetBestCombo(map, team, money, combo);

    if (combo[0] == '\0')
        return;

    decl String:items[4][32];
    int count = ExplodeString(combo, ";", items, sizeof(items), sizeof(items[]));

    for (int i = 0; i < count; i++)
    {
        Format(items[i], sizeof(items[]), "buy %s", items[i]);
        ClientCommand(client, items[i]);
    }
}

// Register command: sm_autobuy_primary
public void OnPluginStart()
{
    RegConsoleCmd("sm_autobuy_primary", Command_AutobuyPrimary);
}

public Action Command_AutobuyPrimary(int client, int args)
{
    if (!IsClientInGame(client) || !IsPlayerAlive(client))
    {
        PrintToChat(client, "[AutoBuy] You must be alive to autobuy.");
        return Plugin_Handled;
    }

    decl String:map[32];
    GetCurrentMap(map, sizeof(map));

    // Simple team check
    int teamId = GetClientTeam(client);
    if (teamId != 2 && teamId != 3) // 2 = T, 3 = CT
    {
        PrintToChat(client, "[AutoBuy] You must be on a valid team.");
        return Plugin_Handled;
    }

    decl String:teamStr[4];
    strcopy(teamStr, sizeof(teamStr), teamId == 2 ? "t" : "ct");

    int money = GetEntProp(client, Prop_Send, "m_iAccount");
    Autobuy(client, money, map, teamStr);

    return Plugin_Handled;
}
