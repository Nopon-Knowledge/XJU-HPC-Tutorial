# VS Code SSH连接教程

vs code远程连接首先需要在左方的Extension下载Remote Development插件，如下图所示：

<p align="center">
<img src="../images/vscode_plugdownload.png" width="70%" alt="vscode下载远程插件">
</p>

安装完成后，点击左侧的远程资源管理器，选择远程（隧道/SSH），再点击SSH选项栏右侧的配置按钮，如下图所示：

<p align="center">
<img src="../images/vscode_sshconfig1.png" width="30%" alt="vscode配置ssh">
</p>

点击后，上方会出现如下图所示的配置文件路径，点击进入

<p align="center">
<img src="../images/vscode_sshconfig2png" width="50%" alt="vscode选择配置文件">
</p>

然后会显示如下图一般的配置文件

<p align="center">
<img src="../images/vscode_sshconfig3.png" width="50%" alt="vscode配置文件">
</p>

将下面的ssh配置输入进去
   ```
   Host 【为该ssh连接取一个你想要的名字】
    HostName 【远程服务器的ip地址】
    User 【你的账户名】
    Port 【端口号 连接高算平台默认为22】
   ```
输入完成后，按ctrl+s或者左侧点击刷新按钮，SSH下会出现刚刚新建的SSH连接，点击箭头连接按钮，上方弹出窗口内选择Linux

<p align="center">
<img src="../images/vscode_sshconfig4.png" width="30%" alt="vscode开始ssh连接">
</p>

进入如下图所示终端：输入yes，再输入你的密码

<p align="center">
<img src="../images/vscode_terminal1.png" width="90%" alt="vscode终端连接1">
</p>

此时点击上方的 终端->新建终端，如果此时终端前缀显示远程服务器账户名@节点，则表示连接成功。