// Plugin: Hit Marker Sound Effects
// Description: Plays hit and kill sounds when a player damages or kills another player
// Author: ChatGPT (final version)

#include <sourcemod>
#include <sdkhooks>

public Plugin myinfo =
{
    name = "Hitmarker Sound Effects",
    author = "ChatGPT",
    description = "Plays sound effects for hits and kills",
    version = "1.0",
    url = ""
};

// Sound file paths (must be precached and in /sound/ directory relative to cstrike)
#define SOUND_HIT_HEADSHOT     "hitmarkers/hit_headshot.wav"
#define SOUND_HIT_BODY         "hitmarkers/hit_body.wav"
#define SOUND_KILL_HEADSHOT   "hitmarkers/kill_headshot.wav"
#define SOUND_KILL_BODY       "hitmarkers/kill_body.wav"

public void OnPluginStart()
{
    HookEvent("player_hurt", Event_PlayerHurt);
    HookEvent("player_death", Event_PlayerDeath);
    
    // Precache all the sounds
    PrecacheSound(SOUND_HIT_HEADSHOT, true);
    PrecacheSound(SOUND_HIT_BODY, true);
    PrecacheSound(SOUND_KILL_HEADSHOT, true);
    PrecacheSound(SOUND_KILL_BODY, true);
    
    PrintToServer("[Hitmarker] Plugin loaded and sounds precached.");
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    int victim = GetClientOfUserId(event.GetInt("userid"));

    if (attacker > 0 && attacker <= MaxClients && attacker != victim && IsClientInGame(attacker))
    {
        bool headshot = event.GetBool("headshot");

        if (headshot)
        {
            EmitSoundToClient(attacker, SOUND_HIT_HEADSHOT);
        }
        else
        {
            EmitSoundToClient(attacker, SOUND_HIT_BODY);
        }
    }
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    int victim = GetClientOfUserId(event.GetInt("userid"));

    if (attacker > 0 && attacker <= MaxClients && attacker != victim && IsClientInGame(attacker))
    {
        bool headshot = event.GetBool("headshot");

        if (headshot)
        {
            EmitSoundToClient(attacker, SOUND_KILL_HEADSHOT);
        }
        else
        {
            EmitSoundToClient(attacker, SOUND_KILL_BODY);
        }
    }
}
