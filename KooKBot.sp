#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <ripext>
static char API_Web[] = "";
static char KooK_Token[] = "";
static char KooK_Chanel[] = "";
public Plugin myinfo = 
{
	name = "KooK Bot",
	author = "ELDment",
	description = "KooK Bot",
	version = "1.0.0",
	url = "http://github.com/ELDment"
};
public void OnPluginStart()
{
	RegConsoleCmd("sm_kook", KooK_Send);
}
public void OnMapStart()
{
	CreateTimer(15.0, KooK_Receive, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}
public Action KooK_Send(int client, int args)
{
    char Msg[2048];
    GetCmdArgString(Msg, sizeof(Msg));
    TrimString(Msg);
    if (strlen(Msg) == 0)
    {
        if (IsValidClient(client))
        {
            PrintToChat(client, "\x04[KooK Bot] \x02不能发送空内容");
        }
        return Plugin_Continue;
    }
    char Time[64];
    FormatTime(Time, sizeof(Time), "%H:%M:%S", GetTime());
    Format(Msg, sizeof(Msg), "[%N %s] %s", client, Time, Msg);
    Post_Msg(Msg, client, false);
    return Plugin_Continue;
}
public Action KooK_Receive(Handle timer)
{
    if (GetClientCount(true) > 0)
    {
        Receive_Msg();
    }
    return Plugin_Continue;
}
public void Post_Msg(const char[] Msg, int client, bool type)
{
    JSONObject data = new JSONObject();
    data.SetString("content", Msg);
    data.SetString("target_id", KooK_Chanel);
    if (type)
        data.SetInt("type", 9);
    HTTPRequest request = new HTTPRequest("https://www.kookapp.cn/api/v3/message/create");
    request.SetHeader("Authorization", "Bot %s", KooK_Token);
    if (type)
    {
        request.Post(data, Post_Callback, -1);
    }else{
        request.Post(data, Post_Callback, client);
    }
    delete data;
}
public void Receive_Msg()
{
    HTTPRequest request = new HTTPRequest(API_Web);
    request.Get(Get_Callback);
}
public void Post_Callback(HTTPResponse response, int client)
{
    if (IsValidClient(client))
    {
        if (response.Data == null)
        {
            PrintToChat(client, "\x04[KooK Bot] \x07状态取回失败!");
            return;
        }
        if (response.Status == HTTPStatus_OK)
        {
            PrintToChat(client, "\x04[KooK Bot] \x07信息发送成功!");
            return;
        }else{
            PrintToChat(client, "\x04[KooK Bot] \x07信息处理异常!");
            return;
        }
    }
}
public void Get_Callback(HTTPResponse response, int client)
{
    if (response.Status != HTTPStatus_OK)
    {
        return;
    }
    if (response.Data == null)
    {
        return;
    }
    JSONArray Array = view_as<JSONArray>(response.Data);
    int Arraynum = Array.Length;
    JSONObject Json;
    char Id[30];
    char Msg[2048];
    char Time[13];
    for (int i = 0; i < Arraynum; i++) {
        Json = view_as<JSONObject>(Array.Get(i));
        Json.GetString("Id", Id, sizeof(Id));
        Json.GetString("Msg", Msg, sizeof(Msg));
        Json.GetString("Time", Time, sizeof(Time));
        FormatTime(Time, sizeof(Time), "%H:%M:%S", StringToInt(Time, 10));
        PrintToChatAll("\x07[KooK Bot] (%s)\x04%s", Time, Msg);
        Return_Msg(Msg, Id);
        delete Json;
    }
}
public void Return_Msg(const char[] Msg, const char[] Id)
{
    char RMsg[128];
    Format(RMsg, sizeof(RMsg), "**KooK Bot**\n> 信息已发送.\n[%s]\n\n(met)%d(met)", Msg, StringToInt(Id, 10));
    Post_Msg(RMsg, -1, true);
}
public bool IsValidClient(int client) 
{
    return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client) && !IsClientSourceTV(client);
}