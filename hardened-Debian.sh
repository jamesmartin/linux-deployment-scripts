#!/bin/bash
#
#
#<UDF name="ssuser" Label="Sudo user username?" example="username" />
#<UDF name="sspassword" Label="Sudo user password?" example="strongPassword" />
#<UDF name="sspubkey" Label="SSH pubkey (installed for root and sudo user)?" example="ssh-rsa ..." />

# initial needfuls
apt-get -o Acquire::ForceIPv4=true update
# console-setup = derp
DEBIAN_FRONTEND=noninteractive apt-get -o Acquire::ForceIPv4=true -y upgrade

# set up user 
adduser $SSUSER --disabled-password --gecos "" && \
echo "$SSUSER:$SSPASSWORD" | chpasswd
adduser $SSUSER sudo

# set up ssh pubkey
# for x in... loop doesn't work here, sadly
echo Setting up ssh pubkeys...
mkdir -p /root/.ssh
mkdir -p /home/$SSUSER/.ssh
echo "$SSPUBKEY" >> /root/.ssh/authorized_keys
echo "$SSPUBKEY" >> /home/$SSUSER/.ssh/authorized_keys
chmod -R 700 /root/.ssh
chmod -R 700 /home/${SSUSER}/.ssh
chown -R ${SSUSER}:${SSUSER} /home/${SSUSER}/.ssh
echo ...done

# disable password and root over ssh
echo Disabling passwords and root login over ssh...
sed -i -e "s/PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config
sed -i -e "s/#PermitRootLogin no/PermitRootLogin no/" /etc/ssh/sshd_config
sed -i -e "s/PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config
sed -i -e "s/#PasswordAuthentication no/PasswordAuthentication no/" /etc/ssh/sshd_config
echo Restarting sshd...
systemctl restart sshd
echo ...done

#set up fail2ban
echo Setting up fail2ban...
apt-get -o Acquire::ForceIPv4=true install -y fail2ban
cd /etc/fail2ban
cp fail2ban.conf fail2ban.local
cp jail.conf jail.local
systemctl enable fail2ban
systemctl start fail2ban
echo ...done

# setup ufw
ufw default deny incoming
ufw allow ssh
systemctl enable ufw
systemctl start ufw

echo All finished! Rebooting...
(sleep 5; reboot) &
