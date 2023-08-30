# VIP Operational Manual (中文版)
By Yinan YANG
v1.0 edited in 2022.8.24
v2.0 edited in 2023.2

<!-- vscode-markdown-toc -->
* 1. [ 摘要](#)
* 2. [ 引言](#-1)
	* 2.1. [ 什么样的设备是研究者友好的深度学习设备？](#-1)
	* 2.2. [ 我们如何操控云设备以及推荐的工具：](#-1)
	* 2.3. [ 设备虚拟化技术——LXD (Linux Container Hypervisor)](#LXDLinuxContainerHypervisor)
* 3. [ 硬件部分：我们有什么？](#-1)
* 4. [ 从0开始搭建深度学习公共服务器](#0)
	* 4.1. [ 如何选择Ubuntu版本](#Ubuntu)
	* 4.2. [ 安装Ubuntu Server](#UbuntuServer)
	* 4.3. [ 硬盘挂载](#-1)
		* 4.3.1. [ 服务器本地硬盘挂载](#-1)
		* 4.3.2. [ 服务器网络硬盘挂载](#-1)
	* 4.4. [ 安装GPU驱动、CUDA和CUDNN。](#GPUCUDACUDNN)
		* 4.4.1. [ GPU驱动安装](#GPU)
		* 4.4.2. [ CUDA](#CUDA)
		* 4.4.3. [ CUDNN](#CUDNN)
	* 4.5. [ 安装初始化 LXD](#LXD)
		* 4.5.1. [ 安装存储后端和LXD](#LXD-1)
		* 4.5.2. [ LXD init](#LXDinit)
		* 4.5.3. [ 创建LXD容器](#LXD-1)
* 5. [ 在文书电脑中安装Windows 10操作系统](#Windows10)
	* 5.1. [ 安装系统引导盘](#-1)
	* 5.2. [ 手动设定安装版本](#-1)
	* 5.3. [安装要点](#-1)
* 6. [ 网络存储服务器NAS：TrueNAS Scale](#NASTrueNASScale)
	* 6.1. [ 什么是NAS，我们为什么使用NAS：](#NASNAS)
	* 6.2. [ TrueNAS Scale](#TrueNASScale)
		* 6.2.1. [ TrueNAS Scale的介绍以及新手教学](#TrueNASScale-1)
		* 6.2.2. [ 我们利用TrueNAS的主要功能](#TrueNAS)
* 7. [ 开源的软路由器管理系统OpenWRT](#OpenWRT)
	* 7.1. [ 什么是OpenWRT，为什么使用这个系统](#OpenWRT-1)
	* 7.2. [ 安装教程](#-1)
	* 7.3. [ 使用的主要功能](#-1)
		* 7.3.1. [ 静态地址分配](#-1)
		* 7.3.2. [ 端口映射（也称端口转发）](#-1)

<!-- vscode-markdown-toc-config
	numbering=true
	autoSave=true
	/vscode-markdown-toc-config -->
<!-- /vscode-markdown-toc -->



##  1. <a name=''></a> 摘要
深度学习的底层设备与环境搭建是如今视觉实验室的重要架构之一。本文目的介绍小型深度学习实验室硬件、系统、网络、虚拟环境的搭建，给后续管理者运维思路。


##  2. <a name='-1'></a> 引言
###  2.1. <a name='-1'></a> 什么样的设备是研究者友好的深度学习设备？
首先我们需要明确，我们想要的系统架构能做到什么事情，这一点尤为重要。我认为有以下四点：
1. 对于训练而言，硬件本身的参数质量要过硬，这一点我们将在后面的章节分析制约深度学习的硬件参数。
2. 易于安装与切换的环境，快速的部署，方便的管理。
3. 若多人共享同一台设备，每个人的任务不能冲突，资源最大限度地利用，与训练无关的进程资源占用率极低。
4. 多人合作项目时，可以随时检查研究进度状态。

现如今最流行的大规模训练平台Google GCP、Amazon AWS等均是使用的云计算的运行思路，将编写代码和运行训练分开。运作流程是：1首先研究者编写代码，调用统一的框架接口；将训练任务推动给后台资源调度服务器，请求足够的资源进行训练；互联网远程实时监控训练。这依赖于云计算的三个尤为重要的底层技术：
1. 用于管理物理计算资源的操作系统
2. 用于把资源分给多人同时使用的虚拟化技术
3. 用于远程接入的互联网

作为小型实验室，虽然我们没有办法实现巨型云计算平台的完成流程，但是我们仍然可以利用小型团队级别的云将资源隔离，实现算力动态浮动。

###  2.2. <a name='-1'></a> 我们如何操控云设备以及推荐的工具：

非常不建议连接云计算设备使用Remote UI界面，原因有以下三点：1. Remote UI造成的系统资源占用极高，尤其使用占用宝贵的GPU显存；2. 效率低，网络带宽要求很高；3. 很多高级系统级应用没有UI界面。所以我们建议使用特殊的网络协议来完成客户端和云计算资源的通讯。最常用的网络协议是SSH协议，推荐工具如下：
1. Xshell, XFTP
    这是一个Windows平台的SSH客户端软件，可以通过SSH协议远程连接服务器。XShell是Terminal软件。XFTP是文件管理软件，可以方便上传下载文件。如果声明是个人用户是免费的。
    https://www.xshell.com/en/free-for-home-school/

2. WinSCP
    这是一个Windows平台的免费SFTP协议文件管理软件，类似于XFTP。这个软件的优势是稳定，擅长传输大规模文件。
    https://winscp.net/eng/download.php

3. Termius
   MacOS中最流行的远程Terminal APP。一定从官网下载，不要安装APP Store版本。APP Store版本没有SFTP功能。
   https://termius.com/

4. VS code with "Remote - SSH" plusin
   凭借"Remote - SSH"插件，VS Code是全世界最流行的免费远程程序编写软件。这里不推荐JetBrains的PyChaim Perfession，因为在之前的版本中，PyChaim连接远程服务器的逻辑是“将远程服务器中的文件与本地文件同步”，而不是VS Code的“直接修改远程文件”。这个显著差异就导致了，如果网络环境发生变化或者网络质量降低，远端代码的版本是无法确定的。

    VS Code: https://code.visualstudio.com/

    "Remote - SSH" plusin: https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh
   
5. 一些教程：
   
         一个简单的Unix教程： http://www.ee.surrey.ac.uk/Teaching/Unix/
         一个简单的vi教程： https://www.cs.colostate.edu/helpdocs/vi.html
         MIT发布的，课堂上不会教，但是非常常用的计算机操作知识：https://missing-semester-cn.github.io/

###  2.3. <a name='LXDLinuxContainerHypervisor'></a> 设备虚拟化技术——LXD (Linux Container Hypervisor)
LXD是一个现代、安全和强大的系统容器和虚拟机管理器。https://linuxcontainers.org/lxd/introduction/
我们之所以选择LXD，是因为LXD允许在几乎不损失性能的前提下，完成CPU、RAM、GPU的资源隔离。具体来说，当我们把一个双GPU共享服务器分配给两个人使用时，一般的做法是两个人协商使用不同编号的GPU。但是这就造成了运行程序的时候会有参数误设、线程挤占等问题。当两个程序的其中一个引发系统故障，另一个程序也会受到故障影响。

LXD可以重新配置隶属于系统下的完整子系统容器，通过给容器分配设备的方式，让容器看到受限的设备。上述例子中，两人在自己的容器内部只能看到属于自己的GPU，一半的CPU和一半的RAM。这样在设定程序的时候，二人就会根据有限的资源优化程序，从而达到多人共享运算资源的目的。LXD容器可以快速的部署，当出发容器故障时，我们可以直接删掉故障容器，重新部署新容器。

##  3. <a name='-1'></a> 硬件部分：我们有什么？
下面是截至2023年2月，VIP实验室设备的网络拓扑图。结合vip port mapping.xlsx文档我们详细解读这些设备都是什么。
![VIP](VIP_Network_Topology.png)

1. 我们有三个墙壁网络接口，每个接口都是CAT6级别的。这也就意味着校园内网的有线带宽是1 Gbit/s（55米内是10 Gbit/s）。一个线材设备科普：https://cn.fs.com/blog/24086.html  三个网络接口分别使用三个网络路由器，以静态IP的形式连接互联网。其中vip_east和vip_west是无线网络路由器，vip_north仅仅是有线网络。有线网络中以交换机来分享信号，给更多的有线终端使用。所有的公共服务器都要求以有线的方式连接，增强稳定性。图中vip_east的平行分支有一个拥有独立IP的服务器。这个服务器是http://www.vip.is.ritsumei.ac.jp/ 和vip cloud的服务器；
2. 图中电脑主机+显示屏所示的是深度学习公共服务器，这些服务器配备算力高的显卡支持深度学习训练；
3. 图中所示显示器是文书电脑，也可以称作弱算力客户机。这一类机器配备简单的核心显卡或者低端独显，帮助客户端连接主要服务器；
4. 图中vip_north下有一个N23设备，这是VIP的网络存储服务器NAS，基于Linux的TrueNAS SCALE。
5. 图中vip_north网络路由器使用的系统是OpenWRT，一个专门用于路由器的开源Linux发行版。
   
下面的篇章我们将依次介绍，如何从0搭建上述2-5的设备。
   

##  4. <a name='0'></a> 从0开始搭建深度学习公共服务器
所有的公共服务器都是Ubuntu服务器。子用户虚拟架构使用LXD（Linux Docker）。本章主要介绍服务器架构的构建和使用方法。

###  4.1. <a name='Ubuntu'></a> 如何选择Ubuntu版本
如果是共享显卡的深度服务器，优先选择Ubuntu Server。但是实验室很多电脑主板限制，没有办法安装Ubuntu Server的，尝试安装Ubuntu Desktop。以下是Ubuntu Server的安装教程和注意点。


###  4.2. <a name='UbuntuServer'></a> 安装Ubuntu Server


选择一个合适大小的SSD来安装Ubuntu服务器，一个<5人使用的服务器系统盘推荐256GB m.2 nvme。一个教程： https://blog.csdn.net/weixin_55972781/article/details/125208944 有几件事需要注意：

1. Ubuntu对DP视频连接的原生支持不是很完整，所以安装时请使用HDMI、VGA或DVI。

2. 只有极少数的无线模块可以支持ubuntu，而不需要额外安装驱动程序，所以我们强烈建议使用**有线网络连接**进行所有的安装和进一步使用。

3. 在安装过程中打开openssh将使以后从命令行连接变得更容易。

4. 安装完系统后，在安装任何其他程序之前，使用以下四条命令将已安装的软件包升级到最新的，包括系统内核。安装完系统后，在安装任何其他程序之前，使用以下四条命令将已安装的软件包升级到最新的，包括系统内核。
      ```bash
      sudo apt-get update

      sudo apt-get upgrade

      sudo apt-get dist--upgrade

      sudo apt-get autoremove
      ```
   使用`sudo apt-get upgrade`来检查是否有什么东西需要更新。
5. 必要的编译工具库、net-tools和vi文本编辑器。
   ```bash
   sudo apt-get install build-essential vim net-tools
   ```

6. 如果重启后得到 `A start job is running for wait for network to be Configured` 的时间过长，那么 
   ```bash
   sudo vim /etc/systemd/system/network-online.target.wants/systemd-networkd-wait-online.service
   ```
   ```vi
   [Service]
    Type=oneshot
    ExecStart=/lib/systemd/systemd-networkd-wait-online
    RemainAfterExit=yes
    TimeoutStartSec=2sec
   ```
   添加`TimeoutStartSec=2sec`，重新启动。

###  4.3. <a name='-1'></a> 硬盘挂载
####  4.3.1. <a name='-1'></a> 服务器本地硬盘挂载
挂载硬盘和SSD。我们强烈建议在`/mnt/`下挂载所有非系统驱动器。用下面的命令来检查你要挂载的设备。
   ```bash
   sudo fdisk -l
   ```

假设设备是`/dev/sda`，如果未正确分区，那么使用如下命令对设备分区
   ```bash
   sodu fdisk /dev/sda
   ```

输入m查看帮助信息，一般要对照帮助进行操作，避免出错；输入n新建分区；输入分区号1，然后输入大小,默认是一个分区，全部的空间大小；然后查看要创建的分区表，这时还没有创建，按w保存退出后才成功。可以再次执行 
   ```bash
   sudo fdisk -l
   ```

查看是否创建。将新分区格式化为ext4
   ```bash
   sudo mkfs -t ext4 /dev/sda1
   ```

假设等待挂载的分区是`/dev/sda1`。临时挂载命令是 
   ```bash
   sodu mount /dev/sda1 /mnt/ssd
   ```
稳定的挂载是
   ```bash
   sudo blkid #check partition UUID, if the UUID=94A44F91A44F74B0
   sudo vim /etc/fstab
   ```

添加如下 
   ```vi
   UUID=94A44F91A44F74B0 /mnt/ssd ntfs defaults 0 1
   ```
####  4.3.2. <a name='-1'></a> 服务器网络硬盘挂载
VIP研究室的网络存储NAS开启了Samba分享功能，可以共享给局域网中的其他计算机使用。本节只简单介绍如何将NAS挂载到Ubuntu系统中，涉及到的具体权限问题，我们将在后面的章节介绍。我们通过修改`/etc/fstab`完成开机自动挂载。

   ```bash  
   sudo vim /etc/fstab
   ```

多人共享服务器挂载NAS添加如下 ，需要修改username和password：

   ```vi
   //192.168.11.2/vip /mnt/nas cifs rw,dir_mode=0777,file_mode=0777,vers=3.0,username=<username>,password=<passwd> 0 0
   ```

个人服务器挂载NAS添加如下，比如添加David这个人的共享账户 ，需要修改username和password：

   ```vi
   //192.168.11.2/vip/David /mnt/nas cifs rw,dir_mode=0777,file_mode=0777,vers=3.0,username=<username>,password=<passwd> 0 0
   ```



###  4.4. <a name='GPUCUDACUDNN'></a> 安装GPU驱动、CUDA和CUDNN。

####  4.4.1. <a name='GPU'></a> GPU驱动安装

   ```bash
   ubuntu-drivers devices # 检查能安装的驱动版本，如果执行这条命令报错，则执行下一句，否则跳过
   sudo apt install ubuntu-drivers-common #上条命令执行报错时执行

   sudo apt-get install nvidia-driver-XXX-server
   sudo reboot
   ```

   我们强烈建议从官方网站下载相同版本的显卡驱动到本地硬盘，以便后续LXD安装。
   <font color=red>关于GPU驱动版本选择：截至2023年2月，稳定的PyTorch发行版1.13.1要求的CUDA为11.7，对应的GPU驱动为>=450.80.02。现在实验室统一部署的515.86.01版本。等PyTorch发布支持CUDA12.0的正式版后，再统一驱动升级。</font>
     
   打开nvidia-persistenced，这是为了防止由于显存没有任何数据导致刷新率显存异常。具体的操作链接https://forums.developer.nvidia.com/t/setting-up-nvidia-persistenced/47986/11?u=user48333

   ```bash
   sudo systemctl status nvidia-persistenced # check the status of nvidia-persistenced
   sudo systemctl enable nvidia-persistenced # Enable nvidia-persistenced
   sudo reboot # Reboot for execution

   #If there are issues in the above-mentioned second step, developers need to do the following.
   sudo vim /lib/systemd/system/nvidia-persistenced.service # Open nvidia-persistenced.service
   ```
   [Service]
   
   把源文件中的这行

   ```vi
   ExecStart=/usr/bin/nvidia-persistenced --user nvidia-persistenced --no-persistence-mode --verbose
   ```
   改成
   ```vi
   ExecStart=/usr/bin/nvidia-persistenced --user nvidia-persistenced --persistence-mode --verbose
   ```

   在文件中加入以下几行。
   ```vi
   [Install] 
   WantedBy=multi-user.target 
   RequiredBy=nvidia.service
   ```

####  4.4.2. <a name='CUDA'></a> CUDA
   
   找到安装命令，在 https://developer.nvidia.com/cuda-11-7-0-download-archive
   

   ```bash
    wget https://developer.download.nvidia.com/compute/cuda/11.7.1/local_installers/cuda_11.7.1_515.65.01_linux.run
    sudo sh cuda_11.7.1_515.65.01_linux.run
   ```

   **在cuda安装过程中不要安装重复的重复的显卡驱动。** 在source bashrc中添加cuda PATH。

   ```bash
    sudo vim ~/.bashrc
   ```
   添加 (**将cuda的11.7版本改为你的版本号**) 

   ```vi
    export PATH=/usr/local/cuda-11.7/bin${PATH:+:${PATH}}
    export LD_LIBRARY_PATH=/usr/local/cuda-11.7/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
   ```
   ```bash
    source ~/.bashrc # refresh source | リフレッシュソース
    nvcc -V # check cuda |チェックキューダ
   ```
####  4.4.3. <a name='CUDNN'></a> CUDNN

    找到正确的版本，在 https://developer.nvidia.com/rdp/cudnn-download 
    

   ```bash
    tar -xf cudnn-linux-x86_64-8.5.0.96_cuda11-archive.tar.xz # un-tar
    cd cudnn-linux-x86_64-8.5.0.96_cuda11-archive/
    sudo cp include/* /usr/local/cuda-11.7/include
    sudo cp lib/* /usr/local/cuda-11.7/lib64
   ```

###  4.5. <a name='LXD'></a> 安装初始化 LXD
####  4.5.1. <a name='LXD-1'></a> 安装存储后端和LXD
   
   ```bash
    sudo apt install -y zfsutils-linux
    sudo snap install lxd
   ```

####  4.5.2. <a name='LXDinit'></a> LXD init

   ```bash
   sudo lxd init
   ```
   所有的设置都是默认的。
   
   容器存储设备的大小（GB）（最小1GB）[default=30GB] 需要你设置一个足够大的大小来创建许多虚拟机。比如300GB/500GB。根据经验，一个安装了驱动以及PyTorch的容器需要30GB以上的空间。
   

####  4.5.3. <a name='LXD-1'></a> 创建LXD容器
 <font color=red>我们开发了多用户lxd深度学习环境部署脚本。截至2023年2月已经进行了三次主要迭代。链接如下：https://github.com/Nonac/vip_lxd_create</font>

 ##### 如何使用vip_lxd_create
 首先把这个仓库clone到本地

 ```bash
   git clone https://github.com/Nonac/vip_lxd_create.git
 ```
 其次，修改user.csv文件。user.csv文件的每一行是设定每一个容器的具体参数，解释如下：

 ```bash
   container_name,password,ssh port,cpu limit,memory limit, gpu limit, disk limit, personal filefolder in nas
   test,123456,10000,0-8,16000MB,0000:0B:00.0|0000:0C:00.0,/mnt/nas/|/mnt/ssd|/mnt/hdd,YANGYinan
 ```
      1. container_name: 本机内部的容器名称，不能与其他容器名称重复，建议使用用户名字。
      2. password: 容器root登陆的密码。
      3. ssh port：本机公开的网络端口，用来映射容器内部SSH的22端口。
      4. cpu limit：0-8指的是限制0-8共9个cpu线程给容器。
      5. memory limit：限制容器使用的RAM。
      6. gpu limit： 限制容器使用的GPU地址。多GPU的情况用|分隔每一个地址。
      7. disk limit：限制容器使用的内部存储设备，第一个一定要是研究室NAS。
      8. personal filefolder in nas： 用户个人在NAS中的文件夹。
   其中4-6为硬件限制，具体的语法设定可以参考：https://linuxcontainers.org/lxd/docs/stable-4.0/instances/
   如果需要开放容器内部的其他网络端口，如Tensorboard:6006,参考脚本备注掉的这一句进行设定。
   ```bash
   lxc config device add $env_name proxy2 proxy listen=tcp:$local_ip:$tensorboard_port connect=tcp:$env_ip:6006 bind=host
   ```

   当修改完全部参数后，执行脚本：
   ```bash
   bash lxc_init.sh
   ```
   脚本将自动调用NAS中保存的driver、cuda、cudnn、Anaconda在容器内安装。脚本自动创建名叫pytorch的conda环境安装PyTorch。
    <font color=red>截至2023年2月，调用的部件版本为：
   NVIDIA driver: 515.86.01
   cuda: 11.7
   cudnn: 8.6.0
   Anaconda3: 2022.05
   PyTorch: 1.13.1
    </font>

##### 注意：



#####  LXD的简单命令
   ```bash
   lxc list #list container | リスト容器
   lxc stop $env_name #stop container | ストップ容器
   lxc restart $env_name #restart | 再起動 
   lxc delete $env_name --force # delete | 消す
   ```

##### 使用容器
   远程SSH工具(xShell，CMD，MacOS Terimal)，使用如下方式就可以连接容器：
   ```bash
      ssh root@<服务器在小局域网中的ip> -p <5.3.1中设定的ssh port>

      如：
      ssh root@192.168.11.34 -p 10000

      下一条命令要求输入<5.3.1中设定的password>就可以连接了。
   ```


##### 容器规则
 1. **在任何情况下，都不允许在虚拟环境中的`/mnt/ssd`，`/mnt/hdd`，`/mnt/<NAS个人文件夹>`以外的目录中保存数据集。**
 2. 2023-5-30 更新 LXD 又出现这样的断网问题
把 net.ipv4.ip_forward=1 增加到 /etc/sysctl.conf 最后一行，重启。
问题解决，实锤了是 https://wiki.debian.org/LXD 中描述的 LXD 与 Docker 链接冲突的问题。
 3. 路由器端口映射后，连接到vpn后可以连接到校园网外的容器。
##### Tips：
 1. 安装Tensorflow 2.4报错处理：
   ```bash
      ln -s /usr/local/cuda-11.8/targets/x86_64-linux/lib/libcusolver.so.11 /usr/local/cuda-11.8/targets/x86_64-linux/lib/libcusolver.so.10
   ```


##  5. <a name='Windows10'></a> 在文书电脑中安装Windows 10操作系统
<font color=red> 安装日语版本</font>

###  5.1. <a name='-1'></a> 安装系统引导盘
选择一个大于8G的U盘，在如下网址下载在线安装程序。
https://www.microsoft.com/ja-jp/software-download/windows10
选择U盘安装引导盘，等待安装完成。

###  5.2. <a name='-1'></a> 手动设定安装版本
在一个windows设备中插入系统引导盘，加入引导盘盘符为H。打开powershell或cmd界面，执行如下命令：

```bash
# 查看引导盘中安装文件共包含几个版本
DISM /Get-ImageInfo /ImageFile:H:\sources\install.esd

# 将安装文件解包，提取SourceIndex:3，也就是windows 10 profession的版本，复制到D盘
DISM /Export-Image /SourceImageFile:H:\sources\install.esd /SourceIndex:3 /DestinationImageFile:D:\install.esd
```
将已经解包完成的install.esd替换原始的install.esd文件。通过这样的操作，这个引导盘就会直接安装profession的版本，而不需要后期选择。

###  5.3. <a name='-1'></a>安装要点
安装时，如果系统讯问有无激活码，选择没有，继续安装。后期再手动激活。
安装后，系统设定时，如询问是否设定在线用户（用户名是outlook邮箱）的情况，点否，使用离线账户。这样设定的好处是可以统一用户名，而且密码可以安装完成后，学生自行设定。

##  6. <a name='NASTrueNASScale'></a> 网络存储服务器NAS：TrueNAS Scale

###  6.1. <a name='NASNAS'></a> 什么是NAS，我们为什么使用NAS：
什么是NAS：https://zh.wikipedia.org/wiki/%E7%BD%91%E7%BB%9C%E9%99%84%E6%8E%A5%E5%AD%98%E5%82%A8
为什么要用NAS：https://developer.aliyun.com/article/674455
###  6.2. <a name='TrueNASScale'></a> TrueNAS Scale
####  6.2.1. <a name='TrueNASScale-1'></a> TrueNAS Scale的介绍以及新手教学
官方网站：https://www.truenas.com/truenas-scale/
新手向安装教学视频：https://www.youtube.com/watch?v=iaIezpQsaOE&ab_channel=%E5%8F%B8%E6%B3%A2%E5%9B%BE
####  6.2.2. <a name='TrueNAS'></a> 我们利用TrueNAS的主要功能
#####  文件备份与共享

在完成TrueNAS的安装后，我们需要设定smb共享。
一个简介：https://gao4.top/538.html/
当前，研究室NAS的目录结构：
```tree
.
├──mnt
   ├──VIPNAS
      ├──vip
         ├── AOKUSATsukushi
         ├── B4
         ├── datasets
         ├── drivers
         ├── IWASAKIYoshiharu
         ├── JIYing
         ├── KIBAShunya
         ├── LIUJiaqing
         ├── LIXinyuan
         ├── LIYu
         ├── OKUDAMasaki
         ├── URASUMIKoshiro
         ├── YAMAWAKIShoma
         ├── YANGYinan
         ├── YUJinhong
         └── ZHAOLongjiao
      ├──graduate_files
         ├── 2019年度修了 
         ├── 2019年度卒業  
         ├── 2020年度修了  
         ├── 2020年度卒業	
         ├── 2022年度修了  
         ├── 2022年度卒業


```

个人文件夹的命名规则为姓氏大写，名的第一个字母大写，中间没有符号。
datasets中保存大型数据集，所有人可以复制到其他地址，只有管理员可以写入。
drivers有常用软件列表，如GPU驱动，cuda，cudnn，Anaconda，打印机驱动，XShell等。

Windows系统挂载NAS是在如下的位置输入信息即可。
![windows1](windows_nas.png)![windows2](windows_nas2.png)

#####  下载大型数据集
大型数据集经常被放在google drive或者one drive中，下载教程如下：
https://www.truenas.com/docs/scale/scaletutorials/dataprotection/cloudsynctasks/cloudsynctaskgoogledrive/

#####  多用户权限管理——ACL
TrueNAS多账户权限的简介：
https://www.bilibili.com/read/cv13803623?from=search
https://www.cnblogs.com/sparkdev/p/5536868.html

当前，研究室的TrueNAS用户组和用户设定如下：

|  用户组  | 用户  | 备注  |
|  ----  | ----  | ----  |
| root  | root | 拥有最高权限，但不能用于samba共享认证  |
| root | vip | 继承了root账户的权限，拥有文件rwx的权限，有samba共享认证权限  |
| vipmember  | vipserver | 有文件增删改查的权限，属于vipmember组，用于共享服务器的NAS挂载  |
| vipmember  | gr*、is* | 有个人文件夹的写权限，有其他文件夹的读权限，属于vipmember组，分配给每个学生  |
用户的添加与权限更改在<web管理地址>/ui/credentials/users中完成。在命令行中设定某一单独用户的权限的操作主要命令是：
```bash
setfacl [-bkRd] [{-m|-x} acl参数] 文件/目录名
-m ：配置后面的 acl 参数给文件/目录使用，不可与 -x 合用;
-x ：删除后续的 acl 参数，不可与 -m 合用;
-b ：移除所有的 ACL 配置参数;
-k ：移除默认的 ACL 参数;
-R ：递归配置 acl;
-d ：配置"默认 acl 参数"，只对目录有效，在该目录新建的数据会引用此默认值;
例如：
# 将drivers文件夹的读取|写入|执行权限赋予给gr0528xf用户
setfacl -m u:gr0528xf:rwx -R drivers

# 获取drivers文件夹的acl权限信息
getfacl drivers
```

##  7. <a name='OpenWRT'></a> 开源的软路由器管理系统OpenWRT
###  7.1. <a name='OpenWRT-1'></a> 什么是OpenWRT，为什么使用这个系统
项目官网：https://openwrt.org/zh/start

**为什么要使用高扩展的软路由器系统？**
研究室使用的是静态IP的方式连接校内网，因此研究室内部每一台独立设备没有可被外部访问的IP。为了网络安全，我们在进行远程操作的时候需要登陆学校VPN来达到和研究室网关同级别的网络层级。研究室大量的设备通过端口映射的方式映射服务到校内网范围。
普通的路由器采用的是ARM64架构，具有便宜、功耗低的特点。厂家为了设备的稳定安全，会人为限制网关端口映射的数量。因此不适合研究室大规模映射网络服务。
现在我们使用的路由器是具有Intel 4核处理器的微电脑架构，等同于一台功耗较低的mini电脑，OpenWRT有能力且没有限制的转发网络服务至校内网范围。同时OpenWRT基于Linux，可安装docker，具有丰富的拓展可能。

###  7.2. <a name='-1'></a> 安装教程
https://youtu.be/2o1N5MjSo38
当前使用的是eSir编译的OpenWRT 22.03 原版，内部搭载了最少量的必要软件，可以在系统内部使用apt命令安装Linux原生软件。安装包下载地址：https://drive.google.com/drive/folders/1-q1OZ6gZIwDPlAj73LpRFezDaouhJOM1

###  7.3. <a name='-1'></a> 使用的主要功能
####  7.3.1. <a name='-1'></a> 静态地址分配
在<路由器管理地址>/cgi-bin/luci/admin/network/dhcp 可以设定每一个连接电脑的IP地址。研究室内部网段为192.168.11.*，其中192.168.11.2-200为静态ip网段，201-255为动态ip网段。当一个新设备加入该网络时，设备会被分配201-255的随机ip地址，当前动态ip地址刷新时间为3天，如果设备处于长时间离线之后突然上线，有几率会分配与之前不同的动态ip地址。因此在静态地址分配中根据该机器的mac地址分配新的不重复的静态ip地址后，该机器在这个路由器下将永久使用该ip地址。
特殊的ip地址：
|  IP地址  | 设备  | 备注  |
|  ----  | ----  | ----  |
| 192.168.11.1  | 路由器 |   |
| 192.168.11.2  | NAS |   |

####  7.3.2. <a name='-1'></a> 端口映射（也称端口转发）
在<路由器管理地址>/cgi-bin/luci/admin/network/firewall/forwards中可以修改。记录的是路由器下每一个设备的网络服务端口在路由器公网IP地址中的映射列表。如：
![nas](nas.png)
就是将局域网内部的192.168.11.2（NAS）的445端口映射到本路由器WAN IP地址（172.25.7.24）的445端口。445端口是smb分享的通用端口，这个映射的作用是，在校内网范围通过使用smb客户端直接搜索172.25.7.24就可以探测到NAS的smb服务。
端口映射列表通过vip port mapping.xlsx 人工记录维护。一些通用的端口功能：
|  端口  | 功能  | 备注  |
|  ----  | ----  | ----  |
| 22  | SSH协议 |   |
| 80  | HTTP服务 |   |
| 443  | HTTPS服务 |   |
| 445  | SMB协议 |   |
| 631  |  网络打印机端口 |   |
| 3389  | Windows 远程操作端口 |   |
| 6006  | Tensorboard |   |
| 8443  | LXD网络通讯端口 |   |
| 8888  | Jupyter默认端口 |   |