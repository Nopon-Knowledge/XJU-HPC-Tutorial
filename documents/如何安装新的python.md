# Python安装教程 

高算平台默认只有一个3.9版本的python，但是深度学习项目所需环境多种多样，显然一个3.9版本是不够的，那么我们还需要想办法安装其它的python版本。

## 1、下载Linux版本的Python源代码压缩包

Python下载地址：https://www.python.org/downloads/source/

进入该页面，选择所需的python版本，选择对应的“download Gzipped source tarball”，下载一个后缀为"tgz"的压缩文件，这是python的源代码压缩包，还需要上传至服务器再进行编译得到可运行的python文件。

<p align="center">
    <img src="../images\python_download.png" width="40%" alt="linux python下载页面">
</p>

## 2、上传至远程服务器

用web端网页的上传功能、用IDE的部署同步等、用filezilla等软件均可。

## 3、运行脚本解压并编译

这里我们需要运行[linux_compile_python.sh](linux_compile_python.sh)脚本，该脚本我们主要需要关注5-10行，这部分为可改参数。

   ```
    # ===== 可改参数 =====
    PYVER=3.13.9                            # 改为你要安装的目录名
    SRCDIR="Python-$PYVER"                  # 官方解包目录名，不用管
    BASE="$HOME/library/python"             # 改为源码包目录，只要写到源码包所在目录即可！不用将源码包文件也写进去！（不以 / 结尾）
    PREFIX="$BASE/$PYVER"                   # 安装到这里，不用管
    WORK="$BASE/src"                        # 解包与编译的临时目录，不用管
    LOGDIR="$BASE/build-logs"               # 日志目录，不用管
   ```

修改后，在远程终端使用如下命令编译

   ```
   #路径更改为你对应的项目路径
    bash "%HOME/python_project/test/linux_compile_python.sh"
   ```

编译后，会在 PREFIX="$BASE/$PYVER" 处，出现以该python版本号命名的文件夹，比如这里就会出现一个“3.13.9”文件，点击进入，看看bin文件夹内是否有对应版本的pip以及pythoon，如下图所示。

<p align="center">
    <img src="../" width="40%" alt="python源码包编译后，待上传">
</p>