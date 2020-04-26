user_name=$1
user_pw=$2

# Create a new user
useradd -p $(openssl passwd -1 ${user_pw}) ${user_name}

# Grant root privileges
usermod -aG wheel $user_name

# Copy the ssh public key to the new user repo
cp -R /root/.ssh "/home/$user_name/.ssh"

# Give the ownership to the new user 
chown -R ${user_name}:${user_name} "/home/$user_name/.ssh"

# Disable ssh connexion for the root user
sed -i "s/PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config

# Restart ssh service
systemctl restart sshd