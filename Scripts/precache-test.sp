#include <sourcemod>
#include <sdktools>

public Plugin myinfo = {
    name = "Precache Custom Sounds",
    author = "ChatGPT",
    description = "Precaches custom sounds so they can be played during the game",
    version = "1.0"
};

public void OnMapStart() {
    // Hitmarkers
    PrecacheSound("hitmarkers/hit_body.wav", true);
    PrecacheSound("hitmarkers/hit_headshot.wav", true);
    PrecacheSound("hitmarkers/kill_body.wav", true);
    PrecacheSound("hitmarkers/kill_headshot.wav", true);

    // Mashines
    PrecacheSound("mashines/deep_boil.wav", true);
    PrecacheSound("mashines/electroshock-mono_loop.wav", true);
    PrecacheSound("mashines/power_transformer_loop_1.wav", true);
    PrecacheSound("mashines/power_transformer_loop_2.wav", true);

    PrintToServer("[PrecacheCustomSounds] All custom sounds precached.");
}