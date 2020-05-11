password=$1

set -e

sudo dnf install mysql-server -y
sudo systemctl start mysqld
sudo systemctl list-units | grep -E 'mysqld.service'

# Add the Microsoft SQL Server 2019 repository 
sudo curl https://packages.microsoft.com/config/rhel/8/mssql-server-2019.repo -o /etc/yum.repos.d/mssql-server-2019.repo 
sudo curl https://packages.microsoft.com/config/rhel/8/prod.repo -o /etc/yum.repos.d/msprod.repo
# Install MS SQL server
sudo dnf install mssql-server -y 
# Install SQL Server command-line tools
sudo ACCEPT_EULA="Y" dnf install mssql-tools unixODBC-devel -y 
# Confirm installation
rpm -qi mssql-server
# Initialize MS SQL Database Engine
# For more options: https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-configure-environment-variables?view=sql-server-ver15
sudo ACCEPT_EULA="Y" MSSQL_PID="Developer" MSSQL_SA_PASSWORD="${password}" /opt/mssql/bin/mssql-conf setup
# Add /opt/mssql/bin/ to your $PATH variable
echo 'export PATH=$PATH:/opt/mssql/bin:/opt/mssql-tools/bin' | sudo tee /etc/profile.d/mssql.sh
# Source the file to start MS SQL
source /etc/profile.d/mssql.sh

# Download a database script
mkdir -p ~/Downloads
curl -s https://ds4es.org/real-time-data-streaming-and-ingestion/_static/scripts/sql/bike_stores_sample_database.sql -o ~/Downloads/bike_stores_sample_database.sql
# Execute
sqlcmd -S 127.0.0.1 -U SA -P ${password} -Q "CREATE DATABASE BikeStores"
sqlcmd -S 127.0.0.1 -U SA -P ${password} -d BikeStores -i ~/Downloads/bike_stores_sample_database.sql


# Install needed packages
sudo dnf install java-11-openjdk tmux -y
# Create a directory called kafka and change to this directory
mkdir -p ~/kafka
# Download and extract the Kafka binaries in /home/${kafka_user_name}/kafka
curl -s https://downloads.apache.org/kafka/2.5.0/kafka_2.13-2.5.0.tgz | tar -xvz --strip 1 -C ~/kafka
# Download and extract Debezium SQL Server plugins
sudo mkdir -p /usr/local/share/kafka/plugins/debezium-connector-sqlserver
curl -s https://repo1.maven.org/maven2/io/debezium/debezium-connector-sqlserver/1.1.1.Final/debezium-connector-sqlserver-1.1.1.Final-plugin.tar.gz | sudo tar -xvz -C /usr/local/share/kafka/plugins/debezium-connector-sqlserver
# Download and extract Debezium MySQL plugins
sudo mkdir /usr/local/share/kafka/plugins/debezium-connector-mysql
curl -s https://repo1.maven.org/maven2/io/debezium/debezium-connector-mysql/1.1.1.Final/debezium-connector-mysql-1.1.1.Final-plugin.tar.gz | sudo tar -xvz -C /usr/local/share/kafka/plugins/debezium-connector-mysql
# Add the below jars to CLASSPATH
export CLASSPATH=$CLASSPATH:/usr/local/share/kafka/plugins/debezium-connector-sqlserver/*
# export CLASSPATH=$CLASSPATH:/usr/local/share/kafka/plugins/debezium-connector-mysql/*
export CLASSPATH=$CLASSPATH:$HOME/kafka/libs/*


tmux new -s zookeeper-server-start -d
tmux send-keys "~/kafka/bin/zookeeper-server-start.sh ~/kafka/config/zookeeper.properties" Enter

# Start Kafka server in a tmux session
tmux new -s kafka-server-start -d
tmux send-keys "~/kafka/bin/kafka-server-start.sh ~/kafka/config/server.properties" Enter


${sqlserver_user}

echo "
offset.storage.file.filename=/tmp/connect.offsets
bootstrap.servers=${hostname}:9092
offset.flush.interval.ms=10000
rest.port=10082
rest.host.name=${hostname}
rest.advertised.port=10082
rest.advertised.host.name=${hostname}
internal.key.converter=org.apache.kafka.connect.json.JsonConverter
internal.value.converter=org.apache.kafka.connect.json.JsonConverter
internal.key.converter.schemas.enable=false
internal.value.converter.schemas.enable=false
key.converter=org.apache.kafka.connect.json.JsonConverter
value.converter=org.apache.kafka.connect.json.JsonConverter
plugin.path=/usr/local/share/kafka/plugins
" | tee ~/kafka/config/worker.properties


echo "
name=sqlservercon
connector.class=io.debezium.connector.sqlserver.SqlServerConnector
database.hostname=${sqlserver_port}
database.port=${sqlserver_port}
database.user=${sqlserver_user}
database.password=${sqlserver_password}
database.dbname=${sqlserver_database_name}
database.server.name=${assign_any_name}
table.whitelist=${tablename}
database.history.kafka.bootstrap.servers=${hostname}:9092
database.history.kafka.topic=oldhisotry_tpc
transforms=route
transforms.route.type=org.apache.kafka.connect.transforms.RegexRouter
transforms.route.regex=([^.]+)\\.([^.]+)\\.([^.]+)
transforms.route.replacement=$3
" | tee ~/kafka/config/sqlserver.properties



echo "name=jdbc-sink
connector.class=io.confluent.connect.jdbc.JdbcSinkConnector
tasks.max=1
topics=${sqlserver_whitelist_table_name}
connection.url=jdbc:mysql://${mysql_host}:3306/${schema}?user=${username}&password=${password}
transforms=unwrap
transforms.unwrap.type=io.debezium.transforms.UnwrapFromEnvelope
auto.create=true
insert.mode=upsert
pk.fields=${primary_key_column}
pk.mode=record_value
table.name.format=${mysql_schema}.${table_name}
" | tee ~/kafka/config/sink.properties