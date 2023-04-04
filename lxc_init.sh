#!/bin/bash

# Get current local ip
local_ip=`ifconfig -a|grep inet|grep 192.168.11.*|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"​`
#driver="NVIDIA-Linux-x86_64-515.86.01.run"
driver="NVIDIA-Linux-x86_64-525.89.02.run"
cuda="cuda_11.8.0_520.61.05_linux.run"
cudaShort="cuda-11.8"
#BUG: cudnn counld not install auto. Need manully install in container.
cudnn="cudnn-linux-x86_64-8.8.1.3_cuda11-archive.tar.xz"
cudnnShort="cudnn-linux-x86_64-8.8.1.3_cuda11-archive"
anaconda="Anaconda3-2022.10-Linux-x86_64.sh"
python=3.8
pytorch="conda install pytorch torchvision torchaudio pytorch-cuda=11.8 -c pytorch -c nvidia"
#pytorch="conda install pytorch torchvision torchaudio pytorch-cuda=11.7 -c pytorch -c nvidia"


# Get user.csv
# the user.csv should be like that:
#
#    test,123456,10000,0-8,16000MB,0000:0B:00.0|0000:0C:00.0,/mnt/ssd|/mnt/hdd|/mnt/nas/,10001
#
#    container_name,password,ssh port,cpu limit,memory limit, gpu limit, disk limit,tensorboard port

USERPATH="user.csv"

# read csv file as a array
arr_csv=() 
while IFS= read -r line 
do
    arr_csv+=("$line")
done < $USERPATH


launchContainer(){
    # launch the container
    lxc launch ubuntu:22.04 $env_name
    echo "root:$passwd" | lxc exec $env_name -- chpasswd
}

setPort(){
    # set container's ssh port
    lxc config device add $env_name proxy0 proxy listen=tcp:$local_ip:$ssh_port connect=tcp:$env_ip:22 bind=host
}

setTensorboardPort(){
    lxc config device add $env_name proxy1 proxy listen=tcp:$local_ip:$tensorboard_port connect=tcp:$env_ip:6006 bind=host
}

setCPULimit(){
    #CPU limit
    lxc config set $env_name limits.cpu $cpu_limit
}

setRAMLimit(){
    #memory limit
    lxc config set $env_name limits.memory $memory_limit
}

setGPULimit(){
    #GPU limit
    gpus=(`echo $gpu_limit | tr '|' ' '`)
    cnt=0
    for i in ${gpus[@]}
    do
        lxc config device add $env_name gpu$cnt gpu pci=$i
        cnt=`expr $cnt + 1`
    done
}

filefolderNotExist(){
    if [ ! -d $i$env_name ]; then
            mkdir $i$env_name
            echo "$i$env_name not exists. Has been created."
    fi
}


setDiskLimit(){
    # mount local device to container
    disks=(`echo $disk_limit | tr '|' ' '`)
    cnt=0
    for i in ${disks[@]}
    do
        filefolderNotExist $i $env_name
        lxc config device add $env_name disk$cnt disk source=$i$env_name path=$i
        cnt=`expr $cnt + 1`
    done
}

mountNAS(){
    # mount personal filefolder in nas to container
    lxc config device add $env_name nas disk source=/mnt/nas/$env_name path=/mnt/$env_name
    lxc config device add $env_name nas0 disk source=/mnt/nas path=/mnt/nas
}

setPrivilege(){
    #container root privilege
    lxc config set $env_name security.privileged true
}

initAPT(){
    # install app
    lxc exec $env_name -- apt-get update -qq
    lxc exec $env_name -- apt-get upgrade -qq > /dev/null
    lxc exec $env_name -- apt-get dist-upgrade -qq > /dev/null
    lxc exec $env_name -- apt-get autoremove -qq > /dev/null
    lxc exec $env_name -- apt-get install build-essential net-tools -qq > /dev/null
}

initSSH(){
    # set ssh config
    lxc exec $env_name -- sed -i 's/#Port 22/Port 22/g' /etc/ssh/sshd_config
    lxc exec $env_name -- sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
    lxc exec $env_name -- sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    lxc exec $env_name -- /etc/init.d/ssh restart
}

installDriver(){
    lxc exec $env_name -- sh /mnt/nas/drivers/$driver --no-kernel-module --silent
}

installCUDA(){
    lxc exec $env_name -- sh /mnt/nas/drivers/$cuda --silent --toolkit
    lxc exec $env_name -- sh -c "echo '' >> ~/.bashrc"
    lxc exec $env_name -- sh -c "echo 'export PATH=/usr/local/$cudaShort/bin${PATH:+:${PATH}}' >> ~/.bashrc"
    lxc exec $env_name -- sh -c "echo 'export LD_LIBRARY_PATH=/usr/local/$cudaShort/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}' >> ~/.bashrc"
    #lxc exec $env_name -- . .bashrc
}

installCUDNN(){
    lxc exec $env_name -- cp /mnt/nas/drivers/$cudnn /root/
    lxc exec $env_name -- tar -xf /root/$cudnn
    lxc exec $env_name -- cp /root/$cudnnShort/include/* /usr/local/$cudaShort/include/
    lxc exec $env_name -- cp /root/$cudnnShort/lib/* /usr/local/$cudaShort/lib64/
    #lxc exec $env_name -- rm -r /root/cudnn*
}

installAnaConda(){
    lxc exec $env_name -- bash /mnt/nas/drivers/$anaconda -b
    lxc exec $env_name -- /root/anaconda3/bin/conda init
    lxc exec $env_name -- . .bashrc
    lxc exec $env_name -- /root/anaconda3/bin/conda config --set auto_activate_base true
}

installPyTorch(){
    lxc exec $env_name -- /root/anaconda3/bin/conda create -n pytorch python=$python -y
    lxc exec $env_name -- /root/anaconda3/bin/$pytorch -n pytorch -y 
}

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
    tensorboard_port=$(echo $line | cut -d , -f 8)

    echo "env_name:$env_name passwd:$passwd ssh_port:$ssh_port cpu_limit:$cpu_limit memory_limit:$memory_limit gpu_limit:$gpu_limit disk_limit:$disk_limit tensorboard_port:$tensorboard_port"

    launchContainer $env_name $passwd

  
    setCPULimit $env_name $cpu_limit
    setRAMLimit $env_name $memory_limit
    setGPULimit $env_name $gpu_limit
    setDiskLimit $env_name $disk_limit

    mountNAS $env_name
    setPrivilege $env_name
    
    # get the container's ip
    env_ip=($(lxc list -c4 --format csv  $env_name))

    setPort $env_name $local_ip $ssh_port $env_ip
    
    setTensorboardPort $env_name $local_ip $tensorboard_port $env_ip
    
    
    initAPT $env_name
    initSSH $env_name

    installDriver $env_name $driver
    installCUDA $env_name $cuda $cudaShort
    installCUDNN $env_name $cudnn $cudnnShort $cudaShort
    installAnaConda $env_name $anaconda
    installPyTorch $env_name $python $pytorch

    # umount nas
    lxc config device remove $env_name nas0
    lxc restart $env_name
    ((index++))
done
