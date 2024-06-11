#!/usr/bin/env bash
set -Eeuo pipefail

if [[ -d "/datadrive" ]]
then
  echo "Worker is already running"
  exit 1
fi

printf "\nSetting up disk\n"
# pick up the disk identified by LUN specified in the template
disk_record=$(lsblk -o HCTL,NAME | grep ":10")
disk_name=$(printf "%s" "$disk_record" | gawk 'match($0, /([a-z]+)/, a) {print a[1]}')
printf "\nDisk name: %s" "$disk_name\n"

sudo parted "/dev/$disk_name" --script mklabel gpt mkpart xfspart xfs 0% 100%
part_name=$(printf '%s1' "$disk_name")
sudo mkfs.xfs -f "/dev/$part_name"
sudo partprobe "/dev/$part_name"

block_record=$(sudo blkid | grep "xfs")
uuid=$(printf "%s" "$block_record" | gawk 'match($0, /UUID="([a-zA-Z0-9\-]*)"/, a) {print a[1]}')
printf "UUID=%s /datadrive xfs defaults,nofail 0 2\n" "$uuid"| sudo tee -a /etc/fstab
sudo mkdir /datadrive
sudo mount /datadrive

# Install docker https://docs.docker.com/engine/install/ubuntu/
printf "\nInstalling docker\n"
sudo apt-get update -qq

sudo apt-get install -y -qq \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common \
    unzip

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io

# Setup docker https://docs.docker.com/engine/install/linux-postinstall/
#sudo groupadd docker
sudo usermod -aG docker testadmin
printf "{\"data-root\": \"/datadrive/docker\"}" | sudo tee -a /etc/docker/daemon.json

printf "\nInstall docker compose\n"
# https://docs.docker.com/compose/install/
sudo curl -f -s -L "https://github.com/docker/compose/releases/download/v2.27.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Enable Swap limit capabilities
#https://docs.docker.com/engine/install/linux-postinstall/#your-kernel-does-not-support-cgroup-swap-limit-capabilities

printf "\nGRUB_CMDLINE_LINUX=\"cgroup_enable=memory swapaccount=1\"\n" | sudo tee -a /etc/default/grub
sudo update-grub

printf "\nSetting up agent\n"
cd /home/testadmin
curl -s https://vstsagentpackage.azureedge.net/agent/3.240.1/vsts-agent-linux-x64-3.240.1.tar.gz -o agent.tar.gz
mkdir azagent && cd azagent
tar zxvf ./../agent.tar.gz > /dev/null
rm ../agent.tar.gz
sudo chown testadmin /home/testadmin/azagent/
printf "/home/testadmin/azagent/config.sh --replace --acceptTeeEula --unattended --url https://dev.azure.com/keboola-dev/ --auth pat --token $PAT_TOKEN --pool $POOL_NAME --agent $WORKER_NAME --work /datadrive/_work" > /home/testadmin/azagent/wrap.sh
sudo chmod a+x /home/testadmin/azagent/wrap.sh
runuser -l testadmin -c '/home/testadmin/azagent/wrap.sh'
sudo mkdir /datadrive/_work
sudo chown testadmin /datadrive/_work
sudo /home/testadmin/azagent/svc.sh install

printf "\nFinished successfully\n"
sudo shutdown -r +1 "Rebooting."
