broker_ip_address=$1
broker_port=$2

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

# Start Zookeeper server in a tmux session
tmux new -s zookeeper-server-start -d
tmux send-keys "~/kafka/bin/zookeeper-server-start.sh ~/kafka/config/zookeeper.properties" Enter

# Hostname and port the broker will advertise to producers and consumers. If not set,
# it uses the value for "listeners" if configured.  Otherwise, it will use the value
# returned from java.net.InetAddress.getCanonicalHostName().
echo "
advertised.listeners=PLAINTEXT://${broker_ip_address}:${broker_port}
" | tee -a ~/kafka/config/server.properties

# Start Kafka server in a tmux session
tmux new -s kafka-server-start -d
tmux send-keys "~/kafka/bin/kafka-server-start.sh ~/kafka/config/server.properties" Enter
