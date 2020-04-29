.. A Working Apache Kafka Message Queue documentation master file, created by
   sphinx-quickstart on Fri Apr 24 16:21:56 2020.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Welcome to A Working Apache Kafka Message Queue's documentation!
================================================================

.. toctree::
   :maxdepth: 2
   :caption: Contents:


For the following instructions you will need 2 servers. Those instructions are for RHEL 8 / CentOS 8 ditributions and has been tested on DigitalOcean.

*We recommend the use of SSH Keys and Passphrase for remote connection to your server. On Linux, you can create it with ssh-keygen (see https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys--2 for details)*


First connection to any of your server
--------------------------------------

* Create a new user with root privileges 
* Disable ssh connexion for the root user

Connect to your server as ``root`` through your terminal

.. code-block:: default

	ssh -i /path/to/private_key_file root@xxx.xxx.xxx.xxx


We have prepared a script to easier your task so that you only have to get it execute with your desired ``user_name`` and ``user_pw``

.. code-block:: default
	
	dnf install wget -y
	wget https://ds4es.org/distributed-change-data-capture/_static/scripts/00_user_creation.sh
	chmod +x ./00_user_creation.sh
	./00_user_creation.sh user_name user_pw
	history -c

Press Ctrl+D on Linux to log out as ``root`` and you will log back in under your newly created user.


Server 1: Setup a Kafka Broker and ZooKeeper
----------------------------------------------

**Requirements:** A minimum of 2GB RAM

Connect to your server as your new ``user_name`` through your terminal

.. code-block:: default

	ssh -i /path/to/private_key_file user_name@xxx.xxx.xxx.xxx

Setup Zookeeper and a Kafka broker

.. code-block:: default

	mkdir -p ~/Scripts
	wget https://ds4es.org/distributed-change-data-capture/_static/scripts/01_zookeeper_kafka_broker_installation.sh -P ~/Scripts
	chmod +x ~/Scripts/01_zookeeper_kafka_broker_installation.sh  
	~/Scripts/01_zookeeper_kafka_broker_installation.sh broker_ip_address broker_port

If everything is working fine, 2 tmux detached sessions should have been started:

* zookeeper-server-start
* kafka-server-start

You can access 2 those tmux sessions respectively with:
* ``tmux attach-session -t zookeeper-server-start``
* ``tmux attach-session -t kafka-server-start``

(Ctrl+B, D to detach from the current tmux session)


Server 2: Setup a Kafka Client
------------------------------

We can distinguish 2 types of Kafka client :

* Producer: Creates a record and publishes it to the broker.
* Consumer: Consumes records from the broker.

Connect to your 2nd server the ``user_name`` set through your terminal

.. code-block:: default

	ssh -i /path/to/private_key_file user_name@xxx.xxx.xxx.xxx

Setup a Kafka Client

.. code-block:: default

	mkdir -p ~/Scripts
	wget https://ds4es.org/distributed-change-data-capture/_static/scripts/02_producer_consumer_instance.sh -P ~/Scripts
	chmod +x ~/Scripts/02_producer_consumer_instance.sh  
	~/Scripts/02_producer_consumer_instance.sh

Start a Kafka producer
^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: default

	~/kafka/bin/kafka-console-producer.sh --broker-list kafka_broker_ip_address:broker_port --topic your_topic_name

Start a Kafka consumer
^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: default

	~/kafka/bin/kafka-console-consumer.sh --bootstrap-server kafka_broker_ip_address:broker_port --topic your_topic_name --from-beginning

Commands
--------

List of all topics

.. code-block:: default

	~/kafka/bin/kafka-topics.sh --list --zookeeper zookeeper_ip_address:zookeeper_port

Create a topic

.. code-block:: default

	~/kafka/bin/kafka-topics.sh --create --zookeeper zookeeper_ip_address:zookeeper_port --replication-factor 1 --partitions 100 --topic your_topic_name

Delete a topic

.. code-block:: default

	~/kafka/bin/kafka-topics.sh --zookeeper zookeeper_ip_address:zookeeper_port --delete --topic your_topic_name

See the information about a topic.

.. code-block:: default

	~/kafka/bin/kafka-topics.sh --describe --topic your_topic_namee --zookeeper zookeeper_ip_address:zookeeper_port


Test with MySQL Server
----------------------

Retrieve Kafka JDBC Connect and MySQL Connector Jars

.. code-block:: default

	wget url_to/kafka-connect-jdbc-5.3.1.jar -P ~/kafka/libs/
	wget url_to/mysql-connector-java-8.0.17.jar -P ~/kafka/libs/

Start or restart Kafka server and Zookeeper server

Start Connector

.. code-block:: default

	tmux new -s connector-start -d
	tmux send-keys "~/kafka/bin/connect-ditributed.sh ~/kafka/config/connect-distributed.properties" Enter 

Install MySQL Server

.. code-block:: default

	sudo dnf install mysql-server
	sudo systemctl start mysqld
	sudo systemctl list-units | grep -E 'mysqld.service'

Login to MySQL

.. code-block:: default

	sudo mysql


Create and fill a table

.. code-block:: sql

	CREATE DATABASE IF NOT EXISTS movies;
	USE movies;

	CREATE TABLE Members (
	  membership_number INT AUTO_INCREMENT PRIMARY KEY,
	  full_names VARCHAR(150) NOT NULL ,
	  gender VARCHAR(6) ,
	  date_of_birth DATE ,
	  physical_address VARCHAR(255) ,
	  postal_address VARCHAR(255) ,
	  contact_number VARCHAR(75) ,
	  email VARCHAR(255),
	  modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);


	INSERT INTO Members(full_names,gender,physical_address,contact_number) VALUES ('Leonard Hofstadter','Male','Woodcrest','0845738767');  

	INSERT INTO Members(full_names,gender,physical_address,contact_number) VALUES ('Sheldon Cooper','Male','Woodcrest', '0976736763'); 

	INSERT INTO Members(full_names,gender,physical_address,contact_number)VALUES ('0938867763','Male','Rajesh Koothrappali','Woodcrest');   

	INSERT INTO Members(full_names,date_of_birth,gender,physical_address,contact_number) VALUES ('Leslie Winkle','1984-02-14','Male','Woodcrest', '0987636553');  

	INSERT INTO Members VALUES (9,'Howard Wolowitz','Male','1981-08-24','SouthPark','P.O. Box 4563', '0987786553', 'lwolowitz[at]email.me', CURRENT_TIMESTAMP);

	SELECT * FROM Members;

Launch jdbc source connector

.. code-block:: default

	curl -X POST -H "Content-Type: application/json" --data '{
		"name": "jdbc-source-connector",
		"config": {
		"connector.class": "io.confluent.connect.jdbc.JdbcSourceConnector",
		"tasks.max": 2,
		"connection.url": "jdbc:mysql://localhost:3306/movies",
		"connection.user": "xxxxxx",
		"connection.password": "xxxxxx",
		"mode": "incrementing",
		"table.whitelist": "Members",
		"incrementing.column.name": "membership_number",
		"timestamp.column.name": "modified", 
		"poll.interval.ms": 1000
		}
	}' http://xxx.xxx.xxx.xxx:8083/connectors



SUITE
-----

* [Streaming data from PostgreSQL to Kafka using Debezium](https://medium.com/@tilakpatidar/streaming-data-from-postgresql-to-kafka-using-debezium-a14a2644906d)
* https://kafka.apache.org/documentation.html#connect_running
* https://debezium.io/documentation/reference/install.html

Source
------

* https://dzone.com/articles/kafka-producer-and-consumer-example