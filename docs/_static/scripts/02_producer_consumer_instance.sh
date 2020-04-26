set -e

# Install prerequisites package
sudo dnf install java-11-openjdk wget tmux -y

# Download the Kafka binaries in /home/${kafka_user_name}/Downloads
wget -P ~/Downloads https://downloads.apache.org/kafka/2.5.0/kafka_2.13-2.5.0.tgz
# Create a directory called kafka and change to this directory
mkdir ~/kafka
# Extract the archive in it
tar -xvzf ~/Downloads/kafka_2.13-2.5.0.tgz --strip 1 -C ~/kafka
# To allow us to delete Kafka topics
echo "delete.topic.enable = true" | tee -a ~/kafka/config/server.properties