#include <sourcemod>
#include <ripext>

public Plugin myinfo = {
    name = "Interop Tester",
    author = "You",
    description = "Tests local interop C# API via JSON POST",
    version = "1.0"
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_interoptest", Command_InteropTest);
}

public Action Command_InteropTest(int client, int args)
{
    if (args < 2)
    {
        PrintToConsole(client, "Usage: sm_interoptest <foo> <bar>");
        return Plugin_Handled;
    }

    char foo[64], bar[64];
    GetCmdArg(1, foo, sizeof(foo));
    GetCmdArg(2, bar, sizeof(bar));

    JSONObject payload = new JSONObject();
    JSONObject argsObj = new JSONObject();

    argsObj.SetString("foo", foo);
    argsObj.SetString("bar", bar);
    argsObj.SetString("action", "test");

    payload.Set("args", argsObj);

    // DEBUG: Print final JSON payload
    char jsonOut[512];
    payload.ToString(jsonOut, sizeof(jsonOut));
    PrintToServer("[InteropTest] JSON Payload: %s", jsonOut);

    HTTPRequest request = new HTTPRequest("http://localhost:5047/interop");
    request.SetHeader("Content-Type", "application/json");
    request.SetHeader("Accept", "*/*");
    request.SetHeader("User-Agent", "InteropTestPlugin/1.0");

    request.Post(payload, OnInteropResponse, GetClientUserId(client));

    delete argsObj;
    delete payload;

    PrintToConsole(client, "Interop request sent...");
    return Plugin_Handled;
}

void OnInteropResponse(HTTPResponse response, any data)
{
    int client = GetClientOfUserId(data);
    if (client <= 0 || !IsClientInGame(client))
        return;

    if (response.Status != HTTPStatus_OK)
    {
        PrintToConsole(client, "Interop failed with HTTP %d", response.Status);
        return;
    }

    JSONObject json = view_as<JSONObject>(response.Data);
    JSONArray commands = view_as<JSONArray>(json.Get("commands"));

    if (commands == null)
    {
        PrintToConsole(client, "No 'commands' array in response.");
        return;
    }

    int count = commands.Length;
    for (int i = 0; i < count; i++)
    {
        char buffer[128];
        commands.GetString(i, buffer, sizeof(buffer));
        PrintToConsole(client, "Returned command: %s", buffer);
    }

    delete commands;
    delete json;
}
