#include <sourcemod>
#include <sdktools>

bool g_uavEnabled[MAXPLAYERS + 1];
int g_lineBudget[MAXPLAYERS + 1];

public void OnPluginStart() {
    RegConsoleCmd("sm_ping", Cmd_UAVToggle);
    RegConsoleCmd("sm_pinglines", Cmd_SetLineBudget);
}

public void OnMapStart() {
    CreateTimer(0.25, Timer_UAVScan, _, TIMER_REPEAT);
}

public Action Cmd_UAVToggle(int client, int args) {
    if (!IsClientInGame(client)) return Plugin_Handled;

    g_uavEnabled[client] = !g_uavEnabled[client];
    PrintToChat(client, "[CsNetstat] Auto Ping is now %s. 192.168.1.132:32400    DESKTOP-2KB351L:64730  ESTABLISHED: )", g_uavEnabled[client] ? "ENABLED" : "DISABLED");

    return Plugin_Handled;
}

public Action Cmd_SetLineBudget(int client, int args) {
    if (!IsClientInGame(client)) return Plugin_Handled;

    if (args < 1) {
        PrintToChat(client, "[CsNetstat] Usage: sm_pinglines <number of ping lines to use>");
        return Plugin_Handled;
    }

    char buffer[8];
    GetCmdArg(1, buffer, sizeof(buffer));
    int val = StringToInt(buffer);
    g_lineBudget[client] = val;

    PrintToChat(client, "[CsNetstat] Max ping lines set to %d.", val);
    return Plugin_Handled;
}

public Action Timer_UAVScan(Handle timer) {
    for (int client = 1; client <= MaxClients; client++) {
        if (!IsClientInGame(client) || !IsPlayerAlive(client) || IsFakeClient(client))
            continue;

        if (!g_uavEnabled[client])
            continue;

        int lineLimit = g_lineBudget[client];
        if (lineLimit <= 0)
            continue;

        float playerPos[3];
        GetClientAbsOrigin(client, playerPos);

        float eyeAngles[3];
        GetClientEyeAngles(client, eyeAngles); 

        int botCount = 0;
        int botIds[MAXPLAYERS + 1];
        float botDistances[MAXPLAYERS + 1];
        float botAngles[MAXPLAYERS + 1];

        for (int i = 1; i <= MaxClients; i++) {
            if (!IsClientInGame(i) || !IsPlayerAlive(i))
                continue;

            if (GetClientTeam(i) == GetClientTeam(client))
                continue; // Only show enemies

            float botPos[3];
            GetClientAbsOrigin(i, botPos);

            float dx = botPos[0] - playerPos[0];
            float dy = botPos[1] - playerPos[1];
            float angleRad = ArcTangent2(dy, dx);
            float angleDeg = RadToDeg(angleRad);
            if (angleDeg < 0.0) angleDeg += 360.0;

            float yaw = eyeAngles[1];
            if (yaw < 0.0) yaw += 360.0;

            float relAngle = angleDeg - yaw;
            if (relAngle < 0.0) relAngle += 360.0;

            float dist = GetVectorDistance(playerPos, botPos) / 52.4934; // Units to meters

            botIds[botCount] = i;
            botDistances[botCount] = dist;
            botAngles[botCount] = relAngle;
            botCount++;
        }

        for (int a = 0; a < botCount - 1; a++) {
            for (int b = a + 1; b < botCount; b++) {
                if (botDistances[a] > botDistances[b]) {
                    float td = botDistances[a]; botDistances[a] = botDistances[b]; botDistances[b] = td;
                    float ta = botAngles[a]; botAngles[a] = botAngles[b]; botAngles[b] = ta;
                    int ti = botIds[a]; botIds[a] = botIds[b]; botIds[b] = ti;
                }
            }
        }

        int linesUsed = 0;

        for (int j = 0; j < botCount && linesUsed < lineLimit; j++) {
            char radar[32];
            if (!GetRadarBar(botAngles[j], radar))
                continue;

            char fullName[64];
            GetClientName(botIds[j], fullName, sizeof(fullName));

            char name4[5] = "    ";
            strcopy(name4, sizeof(name4), fullName);

            int meters = RoundFloat(botDistances[j]);
            if (meters < 1) meters = 0;
            else if (meters > 99) meters = 99;

            PrintToChat(client, "- %-4s %02d ms %s ping", name4, meters, radar);
            linesUsed++;
        }
        for (int i = linesUsed; i < lineLimit; i++) {
            PrintToChat(client, ".");
        }
    }

    return Plugin_Continue;
}

bool GetRadarBar(float relAngle, char[] output) {
    float offset = relAngle;
    if (offset > 180.0) offset -= 360.0;

    if (offset < -80.0 || offset > 80.0) {
        return false; 
    }

    int width = 21;
    int pos = RoundFloat(((offset + 80.0) / 160.0) * (width - 1));

    for (int i = 0; i < width; i++) {
        output[i] = 'I';
    }

    output[width - 1 - pos] = 'X';
    output[width] = '\0';

    return true;
}
