#include <sourcemod>
#include <ripext>
#include <socket>
/*-----------------------------------------------------------------------------------------*/
static char API_Web[] = "";		//你的API Web
static char KooK_Token[] = "";	//你的KooK Bot秘钥
static char KooK_Chanel[] = "";						//KooK频道id
static char MasterServerIP[] = "";						//[Socket] 服务器IP
static int SocketPort = ;										//[Socket] 服务器端口
static bool IsMasterServer = true;									//[Socket] 是否是Master
/*-----------------------------------------------------------------------------------------*/
bool connected = false;
Handle serverSocket = INVALID_HANDLE;
Handle clientSocket = INVALID_HANDLE;
ArrayList ARRAY_Connections;
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
	if (IsMasterServer)
		ARRAY_Connections = new ArrayList(128);
	RegConsoleCmd("sm_kook", KooK_Send);
	if (IsMasterServer)
	{
		CreateMasterServer();
	}else{
		ConnectToMasterServer();
	}
}
public void OnPluginEnd()
{
	if (connected && !IsMasterServer)
	{
		DisconnectFromMasterServer();
	}
	else if (IsMasterServer)
	{
		delete ARRAY_Connections;
		CloseHandle(serverSocket);
		serverSocket = INVALID_HANDLE;
	}
}
public void OnMapStart()
{
	if (IsMasterServer)
	{
		CreateTimer(15.0, KooK_Receive, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
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
	{
		data.SetInt("type", 9);
	}
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
	for (int i = 0; i < Arraynum; i++)
	{
		Json = view_as<JSONObject>(Array.Get(i));
		Json.GetString("Id", Id, sizeof(Id));
		Json.GetString("Msg", Msg, sizeof(Msg));
		Json.GetString("Time", Time, sizeof(Time));
		FormatTime(Time, sizeof(Time), "%H:%M:%S", StringToInt(Time, 10));
		char finMsg[2100];
		Format(finMsg, sizeof(finMsg), "\x07[KooK Bot](%s) \x04%s", Time, Msg)
		PrintToChatAll(finMsg);
		SendToAllClients(finMsg, sizeof(finMsg), serverSocket);
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
/*-------------------------------------------Socket-------------------------------------------*/
/*------------------------------Master------------------------------*/
public void CreateMasterServer()
{
	if (serverSocket == INVALID_HANDLE)
	{
		serverSocket = SocketCreate(SOCKET_TCP, OnServerSocketError);
		SocketBind(serverSocket, "0.0.0.0", SocketPort);
		SocketListen(serverSocket, OnSocketIncoming);	
		PrintToServer("[KooK Bot] Master Server is created.");
	}
}
public OnSocketIncoming(Handle socket, Handle newSocket, char[] remoteIP, int remotePort, any arg)
{
	if (IsMasterServer)
	{
		PrintToServer("[KooK Bot] Client connected to the chat server (%s:%d)", remoteIP, remotePort);
		//SocketSetReceiveCallback(newSocket, OnChildSocketReceive);			
		SocketSetDisconnectCallback(newSocket, OnChildSocketDisconnected);	
		SocketSetErrorCallback(newSocket, OnChildSocketError);
		if (FindValueInArray(ARRAY_Connections, socket) == -1)
		{
			ARRAY_Connections.Push(newSocket);
		}
	}
}
public OnServerSocketError(Handle socket, const int errorType, const int errorNum, any ary)
{
	LogError("[KooK Bot] Socket error %d (errno %d)", errorType, errorNum);
	CloseHandle(socket);
	serverSocket = INVALID_HANDLE;
	CreateTimer(30.0, TimerReconnect);
}
public OnChildSocketDisconnected(Handle socket, any hFile)
{
	int index = FindValueInArray(ARRAY_Connections, socket);
	if (index != -1)
	{
		RemoveFromArray(ARRAY_Connections, index);
	}
	CloseHandle(socket);
}
public OnChildSocketError(Handle socket, const int errorType, const int errorNum, any ary)
{
	LogError("[KooK Bot] child socket error %d (errno %d)", errorType, errorNum);
	int index = FindValueInArray(ARRAY_Connections, socket);
	if (index != -1)
	{
		RemoveFromArray(ARRAY_Connections, index);
	}
	CloseHandle(socket);
}
/*------------------------------General------------------------------*/
public void SendToAllClients(char[] Message, int msgSize, Handle sender)
{
	for (int i = 0; i < ARRAY_Connections.Length; i++)
	{
		Handle iSocket = ARRAY_Connections.Get(i);
		if (iSocket != INVALID_HANDLE && iSocket != sender && SocketIsConnected(iSocket))
		{
			SocketSend(iSocket, Message, msgSize);
		}
	}
}
public Action TimerReconnect(Handle tmr, any arg)
{
	if (IsMasterServer)
	{
		PrintToServer("[KooK Bot] Trying to recreate the master server...");
		CreateMasterServer();
	}else{
		PrintToServer("[KooK Bot] Trying to reconnect to the master server...");
		ConnectToMasterServer();
	}
	return Plugin_Continue;
}
/*------------------------------Clients------------------------------*/
public void ConnectToMasterServer()
{
	if (!IsMasterServer)
	{
		connected = false;
		clientSocket = SocketCreate(SOCKET_TCP, OnClientSocketError);
		PrintToServer("[KooK Bot] Attempt to connect to %s:%i ...", MasterServerIP, SocketPort);
		SocketConnect(clientSocket, OnClientSocketConnected, OnClientSocketReceive, OnClientSocketDisconnected, MasterServerIP, SocketPort);	
	}
}
public OnClientSocketError(Handle socket, const int errorType, const int errorNum, any ary)
{
	connected = false;
	LogError("[KooK Bot] Socket error %d (errno %d)", errorType, errorNum);
	CloseHandle(socket);
	clientSocket = INVALID_HANDLE;
	CreateTimer(30.0, TimerReconnect);
}
public OnClientSocketConnected(Handle socket, any arg)
{
	PrintToServer("[KooK Bot] Sucessfully connected to master server.");
	connected = true;
}
public OnClientSocketDisconnected(Handle socket, any hFile)
{
	connected = false;
	CloseHandle(socket);
	clientSocket = INVALID_HANDLE;
	CreateTimer(30.0, TimerReconnect);
}
public void DisconnectFromMasterServer()
{
	connected = false;
	CloseHandle(clientSocket);
	clientSocket = INVALID_HANDLE;
}
public OnClientSocketReceive(Handle socket, char[] receiveData, const int dataSize, any hFile)
{
	if (!IsMasterServer && connected)
	{
		PrintToChatAll(receiveData);
		//PrintToServer(receiveData);
	}
}