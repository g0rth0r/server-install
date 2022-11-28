#!/bin/bash
#exec 3>&1 4>&2
#trap 'exec 2>&4 1>&3' 0 1 2 3
#exec 1>log.out 2>&1

OLD_IP=192.168.2.20

wait_key (){ read -p "Press enter to continue"; }

# INITIAL UPDATES and CORE PACKAGE 
echo "[*] Updating  System"
wait_key
apt update && apt upgrade -f -y --force-yes
echo "[*] Installing SSH and git"
wait_key
apt install -y openssh-server git cifs-utils 
sleep 5
systemctl status sshd
systemctl enable --now sshd

# USER and GROUPS
echo "[*] Creating user and groups"
wait_key
id -u arbiter &>/dev/null || useradd -m arbiter
id -u vpn &>/dev/null || useradd -m vpn
groupadd -f -g 1003 archive
usermod -a -G archive arbiter
usermod -a -G archive vpn
echo "Set password for arbiter"
passwd arbiter

# Save the main user home directory
GUEST_HOME=$(su -c 'echo $HOME' arbiter)

echo "Set password for vpn"
passwd vpn


# Create mount point and mount SMB 
echo "[*] Creating mount points and SMB credential file"
mkdir /mnt/archive /mnt/beta
chown -R arbiter:archive /mnt/archive
chown -R arbiter:archive /mnt/beta
echo -en 'username=xxxxxx\npassword=xxxxxx\n' >/root/.smbcredentials
chmod 400 /root/.smbcredentials
echo "[!] Edit your credentials in the file..."
wait_key
nano /root/.smbcredentials
sudo mount -t cifs -o rw,vers=3.0,credentials=/root/.smbcredentials //192.168.2.20/archive /mnt/archive
sudo mount -t cifs -o rw,vers=3.0,credentials=/root/.smbcredentials //192.168.2.20/beta /mnt/beta
 

#DOCKER and PORTAINER
echo "[*] Installing Docker and Portainer"
wait_key
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

# Clone the stacks and folder
echo "[*] Cloning Portainer Stacks"
wait_key
su -c 'git -C ~ clone https://github.com/g0rth0r/portainer-stacks.git' arbiter

# OTHER PACKAGES
echo "[*] Installing other packages"
wait_key
apt install -y samba ffmpeg lvm2 smartmontools rsync openvpn neofetch

# Install for YT-DLP
echo "[*] Installing Youtube-DL"
wait_key
curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
chmod a+rx /usr/local/bin/yt-dlp  # Make executable


# TELEGRAPH GRAPHANA INFLIXDB STACK
# https://www.linuxserver.io/blog/2017-11-25-how-to-monitor-your-server-using-grafana-influxdb-and-telegraf
echo "[*] Setting up permisison for Grafana"
wait_key
chown arbiter:root -R $GUEST_HOME/portainer-stacks/tgi-stack/grafana
chmod 775 -R $GUEST_HOME/portainer-stacks/tgi-stack/grafana
# Telegraph Install
echo "[*] Installing Telegraph"
curl -sL https://repos.influxdata.com/influxdb.key | sudo apt-key add -
echo "deb https://repos.influxdata.com/debian stretch stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
apt update && apt install -y telegraf

#install a few sensors
apt install hddtemp lm-sensors
systemctl restart telegraf
systemctl status telegraf

# CUSTOM SCRIPTS
echo "[*] Cloning and install custom scripts"
su -c 'git -C ~ clone https://github.com/g0rth0r/useful-scripts.git' arbiter
su -c 'mkdir ~/bin' arbiter
chmod +x $GUEST_HOME/useful-scripts/install.sh
cd $GUEST_HOME/useful-scripts
su -c '/bin/bash ~/useful-scripts/install.sh' arbiter
#Backup script
git -C ~ clone https://github.com/g0rth0r/backup-sync.git
cd $GUEST_HOME

# Crontabs
echo "[*] Loading new cron files" 
wait_key
su -c "crontab $GUEST_HOME/useful-scripts/os-files/pi-cron" arbiter
su -c "crontab $GUEST_HOME/useful-scripts/os-files/vpn-cron" vpn
crontab $GUEST_HOME/useful-scripts/os-files/root-cron
