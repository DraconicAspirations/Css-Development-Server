#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define DEFAULT_HEALTH 100
#define REGEN_INTERVAL 1.0         // How often the regen timer runs
#define REGEN_AMOUNT 5             // How much health is restored per tick
#define REGEN_DELAY 5.0            // Delay after damage before regen starts

int g_targetHealth = DEFAULT_HEALTH;
bool g_regenEnabled = true;
float g_lastDamageTime[MAXPLAYERS + 1];  // Tracks last damage time per player

public Plugin myinfo = 
{
    name = "Player Health Regen (CoD Style)",
    author = "You",
    description = "Health control with CoD-style delayed regeneration",
    version = "1.3"
};

public void OnPluginStart()
{
    RegAdminCmd("sm_set_player_health", Command_SetHealth, ADMFLAG_GENERIC, "sm_set_player_health <amount> - Set health for all players");
    RegAdminCmd("sm_toggle_regen", Command_ToggleRegen, ADMFLAG_GENERIC, "sm_toggle_regen - Toggle health regen on/off");

    HookEvent("player_hurt", OnPlayerHurt, EventHookMode_PostNoCopy);
    CreateTimer(REGEN_INTERVAL, Timer_RegenHealth, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action Command_SetHealth(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, "[SM] Usage: sm_set_player_health <amount>");
        return Plugin_Handled;
    }

    g_targetHealth = GetCmdArgInt(1);
    if (g_targetHealth <= 0)
    {
        ReplyToCommand(client, "[SM] Please enter a valid health amount.");
        return Plugin_Handled;
    }

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i))
        {
            SetEntProp(i, Prop_Send, "m_iHealth", g_targetHealth);
            g_lastDamageTime[i] = GetGameTime();  // prevent instant regen
        }
    }

    ReplyToCommand(client, "[SM] All players set to %d HP. Regen is active.", g_targetHealth);
    return Plugin_Handled;
}

public Action Command_ToggleRegen(int client, int args)
{
    g_regenEnabled = !g_regenEnabled;
    PrintToChatAll("[SM] Health regeneration is now %s.", g_regenEnabled ? "ON" : "OFF");
    return Plugin_Handled;
}

// Track when a player is hurt
public void OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    int userid = event.GetInt("userid");
    int client = GetClientOfUserId(userid);

    if (client > 0 && client <= MaxClients)
    {
        g_lastDamageTime[client] = GetGameTime();
    }
}

// Regen timer logic
public Action Timer_RegenHealth(Handle timer)
{
    if (!g_regenEnabled)
        return Plugin_Continue;

    float now = GetGameTime();

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i))
        {
            if (now - g_lastDamageTime[i] >= REGEN_DELAY)
            {
                int currentHealth = GetEntProp(i, Prop_Send, "m_iHealth");

                if (currentHealth < g_targetHealth)
                {
                    int newHealth = currentHealth + REGEN_AMOUNT;
                    if (newHealth > g_targetHealth)
                        newHealth = g_targetHealth;

                    SetEntProp(i, Prop_Send, "m_iHealth", newHealth);
                }
            }
        }
    }

    return Plugin_Continue;
}
