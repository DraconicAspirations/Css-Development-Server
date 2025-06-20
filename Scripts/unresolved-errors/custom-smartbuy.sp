// #include <sourcemod>
// #include <sdktools>

// #define MAX_CONFIG_LENGTH 256

// ConVar g_CvarSmartBuyEveryRound;
// char g_sSmartBuys[64][MAX_CONFIG_LENGTH]; // Simple hash-based storage

// public Plugin myinfo = {
//     name = "Smart Buy",
//     author = "ChatGPT",
//     description = "Custom smart buy per map with optional round-start automation",
//     version = "1.0"
// };

// public void OnPluginStart()
// {
//     RegServerCmd("mp_set_smartbuy", Command_SetSmartBuy);
//     RegConsoleCmd("mp_smartbuy", Command_SmartBuy);

//     g_CvarSmartBuyEveryRound = CreateConVar("mp_smartbuy_everyround", "0", "Enable smartbuy at start of every round (0/1)", FCVAR_ARCHIVE, true, 0.0, true, 1.0);
//     HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
// }

// public Action Command_SetSmartBuy(int args)
// {
//     if (args < 2)
//     {
//         PrintToServer("Usage: mp_set_smartbuy <mapname> <buystring>");
//         return Plugin_Handled;
//     }

//     char map[64], buystr[MAX_CONFIG_LENGTH];
//     GetCmdArg(1, map, sizeof(map));
//     GetCmdArgString(buystr, sizeof(buystr));

//     int space = FindCharInString(buystr, ' ');
//     if (space > 0)
//         StrTrimLeft(buystr, space + 1);

//     strcopy(g_sSmartBuys[HashMapIndex(map)], sizeof(buystr), buystr);
//     PrintToServer("[SmartBuy] Config for map %s set to: %s", map, buystr);
//     return Plugin_Handled;
// }

// public Action Command_SmartBuy(int client, int args)
// {
//     if (!IsClientInGame(client) || !IsPlayerAlive(client))
//         return Plugin_Handled;

//     char map[64], config[MAX_CONFIG_LENGTH];
//     GetCurrentMap(map, sizeof(map));
//     strcopy(config, sizeof(config), g_sSmartBuys[HashMapIndex(map)]);

//     if (config[0] == '\0')
//     {
//         PrintToChat(client, "[SmartBuy] No config set for this map.");
//         return Plugin_Handled;
//     }

//     AttemptSmartBuy(client, config);
//     return Plugin_Handled;
// }

// public void On
