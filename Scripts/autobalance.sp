#include <sourcemod>
#include <sdktools>

#define MAX_COMMAND_LEN 128

// --- Configurable teammates list ---
char SHOULD_BE_ON_MY_TEAM[][] = {
    "Dreamclaw",
    "Conroe (rus=mute)",
    "PsiPatrolFranek2015",
    "Jeramo",
    "Sammii"
};

char g_Me[64] = "Sammii"; // Your player name

// --- Utility ---
bool InMyTeamList(const char[] name)
{
    for (int i = 0; i < sizeof(SHOULD_BE_ON_MY_TEAM); i++)
    {
        if (StrEqual(SHOULD_BE_ON_MY_TEAM[i], name))
        {
            return true;
        }
    }
    return false;
}

// --- Autobalance logic ---
ArrayList CalculateAutobalanceCommands(char[][] ctPlayers, int ctCount, char[][] tPlayers, int tCount)
{
    ArrayList commands = new ArrayList(MAX_COMMAND_LEN);
    char command[MAX_COMMAND_LEN];

    int myTeam = 0;

    // Detect my team
    for (int i = 0; i < ctCount; i++)
    {
        if (StrEqual(ctPlayers[i], g_Me))
        {
            myTeam = 1;
            break;
        }
    }

    if (myTeam == 0)
    {
        for (int i = 0; i < tCount; i++)
        {
            if (StrEqual(tPlayers[i], g_Me))
            {
                myTeam = 2;
                break;
            }
        }
    }

    if (myTeam == 0)
        return commands;

    char myTeamStr[4];
    char otherTeamStr[4];
    strcopy(myTeamStr, sizeof(myTeamStr), myTeam == 1 ? "ct" : "t");
    strcopy(otherTeamStr, sizeof(otherTeamStr), myTeam == 1 ? "t" : "ct");

    if (myTeam == 1)
    {
        for (int i = 0; i < ctCount; i++)
        {
            if (!InMyTeamList(ctPlayers[i]))
            {
                Format(command, sizeof(command), "move:::%s:::%s", ctPlayers[i], otherTeamStr);
                commands.PushString(command);
            }
        }

        for (int i = 0; i < tCount; i++)
        {
            if (InMyTeamList(tPlayers[i]))
            {
                Format(command, sizeof(command), "move:::%s:::%s", tPlayers[i], myTeamStr);
                commands.PushString(command);
            }
        }
    }
    else // myTeam == 2
    {
        for (int i = 0; i < tCount; i++)
        {
            if (!InMyTeamList(tPlayers[i]))
            {
                Format(command, sizeof(command), "move:::%s:::%s", tPlayers[i], otherTeamStr);
                commands.PushString(command);
            }
        }

        for (int i = 0; i < ctCount; i++)
        {
            if (InMyTeamList(ctPlayers[i]))
            {
                Format(command, sizeof(command), "move:::%s:::%s", ctPlayers[i], myTeamStr);
                commands.PushString(command);
            }
        }
    }

    return commands;
}

ArrayList AutoBalanceBots(int ctCount, int tCount)
{
    ArrayList commands = new ArrayList(MAX_COMMAND_LEN);

    int diff = ctCount - tCount;

    if (diff < 0)
    {
        int botsToAdd = (tCount - 1) - ctCount;
        for (int i = 0; i < botsToAdd; i++)
        {
            commands.PushString("spawn-bot:::ct");
        }
    }
    else if (diff > 0)
    {
        int botsToAdd = (ctCount - 1) - tCount;
        for (int i = 0; i < botsToAdd; i++)
        {
            commands.PushString("spawn-bot:::t");
        }
    }

    // Remove extra bots if too many
    if (diff > 1)
    {
        for (int i = 0; i < diff - 1; i++)
        {
            commands.PushString("kill-bot:::ct");
        }
    }
    else if (diff < -1)
    {
        for (int i = 0; i < (-diff) - 1; i++)
        {
            commands.PushString("kill-bot:::t");
        }
    }

    return commands;
}

// --- Command executor ---
void HandleCommand(const char[] command)
{
    if (StrContains(command, "move:::") == 0)
    {
        char parts[3][64];
        ExplodeString(command, ":::", parts, sizeof(parts), sizeof(parts[]));
        int team = StrEqual(parts[2], "ct") ? 3 : 2;

        for (int i = 1; i <= MaxClients; i++)
        {
            if (!IsClientInGame(i)) continue;

            char name[64];
            GetClientName(i, name, sizeof(name));

            if (StrEqual(name, parts[1]))
            {
                ChangeClientTeam(i, team);
                break;
            }
        }
    }
    else if (StrEqual(command, "spawn-bot:::ct"))
    {
        ServerCommand("bot_add_ct");
    }
    else if (StrEqual(command, "spawn-bot:::t"))
    {
        ServerCommand("bot_add_t");
    }
    else if (StrEqual(command, "kill-bot:::ct"))
    {
        KickOneBotFromTeam(3);
    }
    else if (StrEqual(command, "kill-bot:::t"))
    {
        KickOneBotFromTeam(2);
    }
}

void KickOneBotFromTeam(int team)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == team)
        {
            KickClient(i);
            break;
        }
    }
}

// --- Main command ---
public Action Command_RunBalance(int client, int args)
{
    char ctPlayers[16][64];
    char tPlayers[16][64];
    int ctCount = 0;
    int tCount = 0;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i)) continue;
        if (IsFakeClient(i)) continue;

        char name[64];
        GetClientName(i, name, sizeof(name));

        int team = GetClientTeam(i);
        if (team == 3)
        {
            strcopy(ctPlayers[ctCount++], sizeof(ctPlayers[]), name);
        }
        else if (team == 2)
        {
            strcopy(tPlayers[tCount++], sizeof(tPlayers[]), name);
        }
    }

    ArrayList cmds1 = CalculateAutobalanceCommands(ctPlayers, ctCount, tPlayers, tCount);
    ArrayList cmds2 = AutoBalanceBots(ctCount, tCount);

    char cmd[MAX_COMMAND_LEN];

    for (int i = 0; i < cmds1.Length; i++)
    {
        cmds1.GetString(i, cmd, sizeof(cmd));
        HandleCommand(cmd);
    }

    for (int i = 0; i < cmds2.Length; i++)
    {
        cmds2.GetString(i, cmd, sizeof(cmd));
        HandleCommand(cmd);
    }

    ReplyToCommand(client, "[AutoBalancer] Balance complete.");
    return Plugin_Handled;
}

// --- Plugin startup ---
public void OnPluginStart()
{
    RegConsoleCmd("sm_runbalance", Command_RunBalance);
    PrintToServer("[AutoBalancer] Plugin loaded. Use sm_runbalance to trigger balancing.");
}
