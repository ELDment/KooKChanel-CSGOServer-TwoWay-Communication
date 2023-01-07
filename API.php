<?php
@header("Content-type: application/json");
ini_set('display_errors', 0);

$Command = "@kook";
$Token = "";
$Chanel_id = "";

$Database = array(
    "dbhost" => "",
    "username" => "",
    "password" => "",
    "dbname" => ""
);

$mysql = new mysqli($Database['dbhost'], $Database['username'], $Database['password'], $Database['dbname']);

function get_msg()
{
    global $Token, $Chanel_id;
    $get_data = array(
        "target_id" => "$Chanel_id",
        "pin" => 0,
        "page_size" => 1
    );
    $get_header = "Authorization: Bot $Token";
    $curl = curl_init();
    curl_setopt($curl, CURLOPT_URL, 'https://www.kookapp.cn/api/v3/message/list');
    curl_setopt($curl, CURLOPT_TIMEOUT, 10);
    curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($curl, CURLOPT_SSL_VERIFYHOST, false);
    curl_setopt($curl, CURLOPT_HTTPHEADER, array($get_header));
    curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
    curl_setopt($curl, CURLOPT_POST, 1);
    curl_setopt($curl, CURLOPT_POSTFIELDS, $get_data);
    $data = curl_exec($curl);
    curl_close($curl);
    return $data;
}
function kook_msg($json, $Command)
{
    $array_result = array();
    $result = [];
    $object = json_decode(json_encode(json_decode($json) -> data -> items));
    foreach ($object as $unit)
    {
        if (stripos($unit -> content, $Command) !== false)
        {
            $arg = trim(str_ireplace($Command, '', $unit -> content));
            if ($arg !== '' && $arg !== ' ')
            {
                if (stripos(substr($unit -> content, 0, mb_strlen($Command,'utf8')), $Command) !== false)
                {
                    if (mysql_check($unit -> id))
                    {
                        if (mysql_insert($unit -> author -> id, $unit -> id, $unit -> author -> nickname.': '.$arg, substr($unit -> create_at, 0, 10)) !== 'error')
                        {
                            $arr['Id'] = $unit -> author -> id;
                            $arr['Msgid'] = $unit -> id;
                            $arr['Msg'] = $unit -> author -> nickname.': '.$arg;
                            $arr['Time'] = substr($unit -> create_at, 0, 10);
                            $result[ ] = $arr;
                        }
                    }
                }
            }
        }
    }
    return $result;
}
function mysql_check($msgid)
{
    global $mysql;
    if (mysql_status())
    {
        $query = "SELECT * FROM `KooK_Msg` WHERE `Msg_id` = '$msgid'";
        $result = $mysql -> query($query);
        if ($result -> num_rows > 0)
        {
            return false;
        }else{
            return true;
        }
    }else{
        http_response_code(404);
        exit(404);
    }
}
function mysql_insert($id, $msgid, $msg, $unix)
{
    global $mysql;
    if (mysql_status())
    {
        $userid = intval($id);
        $time = date('Y-m-d h:i:s', intval($unix));
        $query = "INSERT INTO `KooK_Msg`(`Id`, `Msg_id`, `Msg`, `Time`) VALUES ($userid, '$msgid', '$msg', '$time')";
        if (!mysqli_query($mysql, $query)) 
        {
        	return 'error';
        }
    }
}
function mysql_create_table()
{
    global $mysql;
    if (mysql_status())
    {
        $query = "CREATE TABLE IF NOT EXISTS `KooK_Msg` ( `Id` INT(32) NULL DEFAULT NULL COMMENT '用户id' , `Msg_id` VARCHAR(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '信息id' , `Msg` TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '昵称及信息' , `Time` VARCHAR(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '信息创建时间' , PRIMARY KEY (`Msg_id`)) ENGINE = InnoDB CHARSET=utf8mb4 COLLATE utf8mb4_general_ci COMMENT = 'KooK信息存储';";
        if (!mysqli_query($mysql, $query)) 
        {
        	http_response_code(404);
            exit(404);
        }
    }else{
        http_response_code(404);
        exit(404);
    }
}
function msg_status($msg)
{
    if (json_decode($msg) -> message == '操作成功')
    {
        return true;
    }else{
        return false;
    }
}
function message_monitor()
{
    global $Command;
    $get = get_msg();
    if ($get !== '')
    {
        if (msg_status($get))
        {
            $output = kook_msg($get, $Command);
            if (!empty($output))
            {
                echo json_encode($output);
            }else{
                http_response_code(404);
                exit(404);
            }
        }
    }else{
        http_response_code(404);
        exit(404);
    }
}
function mysql_status()
{
    global $mysql;
    global $Database;
    if ($mysql -> connect_error)
    {
        @$mysql -> close();
    	$mysql = new mysqli($Database['dbhost'], $Database['username'], $Database['password'], $Database['dbname']);
    	if ($mysql -> connect_error)
    	{
    	    @$mysql -> close();
    	    exit;
    	}
    	return true;
    }
    return true;
}
function kook_main()
{
    if (!file_exists(__DIR__.'/KooKBot.log'))
    {
        mysql_create_table();
        fopen(__DIR__.'/KooKBot.log', 'w');
    }
    message_monitor();
}
kook_main();
?>