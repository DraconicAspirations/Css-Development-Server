#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
    name = "RPCUpdates",
    author = "YourName",
    description = "RPCUpdates",
    version = "0.2"
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_getmoney", Command_GetMoney);
}

public Action Command_GetMoney(int client, int args)
{
    if (client <= 0 || client > MaxClients || !IsClientInGame(client))
    {
        PrintToServer("sm_getmoney - This command must be run by a player.");
        return Plugin_Handled;
    }

    int amount = 1000; // default amount

    // If argument is provided, parse it
    if (args >= 1)
    {
        char arg1[16];
        GetCmdArg(1, arg1, sizeof(arg1));
        amount = StringToInt(arg1);
    }

    int currentCash = GetEntProp(client, Prop_Send, "m_iAccount");
    int newCash = currentCash + amount;

    // Clamp to max cash (16000)
    if (newCash > 16000)
    {
        newCash = 16000;
    }

    SetEntProp(client, Prop_Send, "m_iAccount", newCash);

    return Plugin_Handled;
}
