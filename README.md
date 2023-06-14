# ✨CSGO-KooK双向通讯✨
![License](https://img.shields.io/badge/license-GPL-orange.svg?style=plastic)
![Php](https://img.shields.io/badge/sourcemod-1.11-red)
![Mysql](https://img.shields.io/badge/mysql-8.0.2-blue)
![Php](https://img.shields.io/badge/php-7.4-green)<br>
![image](https://github.com/ELDment/KooKChanel-CSGOServer-TwoWay-Communication/blob/main/CSGO-KooK.png)<br>

# 步骤
* [获取配置](#获取配置)
* 扩展部署
* 插件编译&导入
* 传输测试

# 获取配置
[详见论坛教程](https://bbs.csgocn.net/thread-434.htm)

# 扩展部署
 2023年6月14日15:29:31
 这里有一些新手容易误解的地方需要注意的
  1. [sm-ripext](https://github.com/ErikMinekus/sm-ripext)直接下载覆盖即可<br>
  2. [sm-ext-socket](https://github.com/ErikMinekus/sm-ripext)需要注意要用<br>
    [alliedmods论坛](https://forums.alliedmods.net/showthread.php?t=67640)中提供的包 [点击下载](https://forums.alliedmods.net/attachment.php?attachmentid=83286&d=1299423920)<br>
  4. `API.php` 需要填写必要的连接信息后使用php>=7.4的进行部署。<br>
      如果你使用的是宝塔，在创建站之后 将`API.php`放在站点文件夹中,默认文档更改`index.html`为`API.php` ,这就是稍后要在KooKBot_Master.cp中填写的API
      例如:`http://你填写的站点域名/`
  5. 这两个扩展在`sourcemod`中都是exts，在导入到`sourcemod`目录中后应该使用`sm exts list`检查两个插件是否成功导入<br>
      (如果出现FAIL)一般在不可用插件后都会跟着不可用的原因<br>
      可以`sm exts load 插件名` 手动导入检查问题产生的原因
# 插件编译&导入
  `KooKBot_*.sp`文件在填写了必要的信息后需要放在`sourcemod\scripting`文件夹中,并使用目录下的`compile.sh`进行编译的<br>
   编译命令例如:`sh compile.sh KooKBot_Master.sp`<br>
   编译后的文件将会放在同目录`compiled`文件夹下,生成`KooKBot_Master.smx` 放在`sourcemod\plugins中`
# 传输测试
   重启服务器后 进入控制台输入`sm plugins list` 查看KOOKBOT 是否生效 <br>
   如若生效,需游戏登入服务器中进行命令调用测试
   > 如果服务器处于休眠状态(无人游玩)的状态时 插件是不会生效的
