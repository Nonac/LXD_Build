local_ip="192.168.11.40"
env_name="hashimoto"
passwd="isss_jien"
ssh_port=10900
tensorboard_port=10901



lxc launch ubuntu:22.04 $env_name
#lxc exec $env_name -- passwd
echo "root:$passwd" | lxc exec $env_name -- chpasswd

a=($(lxc list -c4 --format csv $env_name))
env_ip=$a
echo $env_ip

lxc config device add $env_name ssd disk source=/mnt/ssd path=/mnt/ssd
lxc config device add $env_name hdd disk source=/mnt/hdd path=/mnt/hdd
lxc config device add $env_name nas disk source=/mnt/nas/ path=/mnt/nas

#CPU limit
lxc config set $env_name limits.cpu 0-7
#lxc config set $env_name limits.cpu 8-15

#memory limit
lxc config set $env_name limits.memory 16000MB

#GPU limit
#lxc config device add $env_name gpu gpu
lxc config device add $env_name gpu1 gpu pci="0000:0B:00.0"
#lxc config device add $env_name gpu1 gpu pci="0000:0C:00.0"

lxc exec $env_name -- apt-get update
lxc exec $env_name -- apt-get upgrade -y
lxc exec $env_name -- apt-get dist-upgrade -y
lxc exec $env_name -- apt-get autoremove -y
lxc exec $env_name -- apt-get install build-essential -y
lxc config device add $env_name proxy1 proxy listen=tcp:$local_ip:$ssh_port connect=tcp:$env_ip:22 bind=host
lxc config device add $env_name proxy2 proxy listen=tcp:$local_ip:$tensorboard_port connect=tcp:$env_ip:6006 bind=host

lxc config set $env_name security.privileged true
lxc exec $env_name -- sh /mnt/ssd/drivers/NVIDIA-Linux-x86_64-515.86.01.run --no-kernel-module

#lxc exec $env_name -- vim /etc/ssh/sshd_config
lxc exec $env_name -- sed -i 's/#Port 22/Port 22/g' /etc/ssh/sshd_config
lxc exec $env_name -- sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
lxc exec $env_name -- sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
lxc exec $env_name -- /etc/init.d/ssh restart
