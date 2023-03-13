#!/bin/bash

# Get current local ip
local_ip=`ifconfig -a|grep inet|grep 192.168.11.*|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"​`

# Get user.csv
# the user.csv should be like that:
#
#    test,123456,10000,0-8,16000MB,0000:0B:00.0|0000:0C:00.0,/mnt/ssd|/mnt/hdd|/mnt/nas/,YANGYinan
#
#    container_name,password,ssh port,cpu limit,memory limit, gpu limit, disk limit, personal filefolder in nas

USERPATH="user.csv"

# read csv file as a array
arr_csv=() 
while IFS= read -r line 
do
    arr_csv+=("$line")
done < $USERPATH


index=0
for line in "${arr_csv[@]}"
do
    env_name=$(echo $line | cut -d , -f 1)
    passwd=$(echo $line | cut -d , -f 2)
    ssh_port=$(echo $line | cut -d , -f 3)
    cpu_limit=$(echo $line | cut -d , -f 4)
    memory_limit=$(echo $line | cut -d , -f 5)
    gpu_limit=$(echo $line | cut -d , -f 6)
    disk_limit=$(echo $line | cut -d , -f 7)
    #personal_filefolder=$(echo $line | cut -d , -f 8)

    echo "env_name:$env_name passwd:$passwd ssh_port:$ssh_port cpu_limit:$cpu_limit memory_limit:$memory_limit gpu_limit:$gpu_limit disk_limit:$disk_limit"

    # launch the container
    lxc launch ubuntu:22.04 $env_name
    echo "root:$passwd" | lxc exec $env_name -- chpasswd

    # get the container's ip
    env_ip=($(lxc list -c4 --format csv  $env_name))

    # set container's ssh port
    lxc config device add $env_name proxy1 proxy listen=tcp:$local_ip:$ssh_port connect=tcp:$env_ip:22 bind=host
    #lxc config device add $env_name proxy2 proxy listen=tcp:$local_ip:$tensorboard_port connect=tcp:$env_ip:6006 bind=host

    #CPU limit
    lxc config set $env_name limits.cpu $cpu_limit

    #memory limit
    lxc config set $env_name limits.memory $memory_limit

    #GPU limit
    gpus=(`echo $gpu_limit | tr '|' ' '`)
    cnt=0
    for i in ${gpus[@]}
    do
        lxc config device add $env_name gpu$cnt gpu pci=$i
        cnt=`expr $cnt + 1`
    done

    # mount local device to container

    disks=(`echo $disk_limit | tr '|' ' '`)
    cnt=0
    for i in ${disks[@]}
    do
        if [ ! -d $i$env_name ]; then
            mkdir $i$env_name
            echo "$i$env_name not exists. Has been created."
        fi
        lxc config device add $env_name disk$cnt disk source=$i$env_name path=$i
        cnt=`expr $cnt + 1`
    done

    # mount personal filefolder in nas to container
    lxc config device add $env_name nas disk source=/mnt/nas/$env_name path=/mnt/$env_name
    lxc config device add $env_name nas0 disk source=/mnt/nas path=/mnt/nas

    #container root privilege
    lxc config set $env_name security.privileged true
    lxc restart $env_name


    # install app
    lxc exec $env_name -- apt-get update -qq
    lxc exec $env_name -- apt-get upgrade -qq > /dev/null
    lxc exec $env_name -- apt-get dist-upgrade -qq > /dev/null
    lxc exec $env_name -- apt-get autoremove -qq > /dev/null
    lxc exec $env_name -- apt-get install build-essential net-tools -qq > /dev/null

    # set ssh config
    lxc exec $env_name -- sed -i 's/#Port 22/Port 22/g' /etc/ssh/sshd_config
    lxc exec $env_name -- sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
    lxc exec $env_name -- sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    lxc exec $env_name -- /etc/init.d/ssh restart

    
    # install nvidia driver 515.86 in nas
    lxc exec $env_name -- sh /mnt/nas/drivers/NVIDIA-Linux-x86_64-515.86.01.run --no-kernel-module --silent

    # install cuda 11.7.1
    lxc exec $env_name -- sh /mnt/nas/drivers/cuda_11.7.1_515.65.01_linux.run --silent --toolkit
    lxc exec $env_name -- sh -c "echo '' >> ~/.bashrc"
    lxc exec $env_name -- sh -c "echo 'export PATH=/usr/local/cuda-11.7/bin${PATH:+:${PATH}}' >> ~/.bashrc"
    lxc exec $env_name -- sh -c "echo 'export LD_LIBRARY_PATH=/usr/local/cuda-11.7/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}' >> ~/.bashrc"
    #lxc exec $env_name -- . .bashrc

    # install cudnn 8.6.0
    lxc exec $env_name -- cp /mnt/nas/drivers/cudnn-linux-x86_64-8.6.0.163_cuda11-archive.tar.xz /root/
    lxc exec $env_name -- tar -xvf /root/cudnn-linux-x86_64-8.6.0.163_cuda11-archive.tar.xz
    lxc exec $env_name -- cp /root/cudnn-linux-x86_64-8.6.0.163_cuda11-archive/include/* /usr/local/cuda-11.7/include/
    lxc exec $env_name -- cp /root/cudnn-linux-x86_64-8.6.0.163_cuda11-archive/lib/* /usr/local/cuda-11.7/lib64/
    lxc exec $env_name -- rm -r /root/cudnn*

    # install Anaconda3
    lxc exec $env_name -- bash /mnt/nas/drivers/Anaconda3-2022.05-Linux-x86_64.sh -b
    lxc exec $env_name -- /root/anaconda3/bin/conda init
    lxc exec $env_name -- . .bashrc
    lxc exec $env_name -- /root/anaconda3/bin/conda config --set auto_activate_base true

    # init pytorch
    lxc exec $env_name -- /root/anaconda3/bin/conda create -n pytorch python=3.8 -y
    lxc exec $env_name -- /root/anaconda3/bin/conda install pytorch torchvision torchaudio pytorch-cuda=11.7 -c pytorch -c nvidia -n pytorch -y 

    # umount nas
    lxc config device remove $env_name nas0
   
    ((index++))
done
