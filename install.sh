#!/bin/bash
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>log.out 2>&1


# INITIAL UPDATES and CORE PACKAGE 
apt update && apt upgrade -f -y --force-yes
apt install openssh-server git
sleep 5
systemctl status sshd
systemctl enable --now sshd

# USER and GROUPS
id -u arbiter &>/dev/null || useradd -m arbiter
useradd -m vpn
WORK_HOME=/home/arbiter
cd $WORK_HOME

#DOCKER and PORTAINER
apt update
apt install -y ca-certificates curl gnupg lsb-release
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
docker run hello-world

docker volume create portainer_data
docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest


# OTHER PACKAGES
apt install samba ffmpeg lvm2 smartmontools rsync rsnapshot
mkdir -p $WORK_HOME/media-playback
cd $WORK_HOME/media-playback; mkdir config tv movies
cd $WORK_HOME
apt install openvpn -y

# Install for YT-DLP
curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
chmod a+rx /usr/local/bin/yt-dlp  # Make executable
apt install smartmontools


# TELEGRAPH GRAPHANA INFLIXDB STACK
# https://www.linuxserver.io/blog/2017-11-25-how-to-monitor-your-server-using-grafana-influxdb-and-telegraf
mkdir -p $WORK_HOME/tgi-stack/appdata/influxdb
mkdir -p $WORK_HOME/tgi-stack/appdata/grafana
chown arbiter:root -R $WORK_HOME/tgi-stack/appdata/grafana
chmod 775 -R $WORK_HOME/tgi-stack/appdata/grafana




