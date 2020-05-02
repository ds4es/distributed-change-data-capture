.. A Working Apache Kafka Message Queue documentation master file, created by
   sphinx-quickstart on Fri Apr 24 16:21:56 2020.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Welcome to A Working Apache Kafka Message Queue's documentation!
================================================================

.. toctree::
   :maxdepth: 2
   :hidden:

   sqlserver-mysql


For the following instructions you will need 2 servers. Those instructions are for RHEL 8 / CentOS 8 ditributions and has been tested on DigitalOcean.

We recommend the use of SSH Keys and Passphrase for remote connection to your server. On Linux, you can create it with ssh-keygen (see `How To Set Up SSH Keys <https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys--2>`_ for details)


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
	wget https://ds4es.org/real-time-data-streaming-and-ingestion/_static/scripts/00_user_creation.sh
	chmod +x ./00_user_creation.sh
	./00_user_creation.sh user_name user_pw
	history -c

* ``user_name`` - your Linux user's username 
* ``user_pw`` - your Linux user's password 

Press Ctrl+D on Linux to log out as ``root`` and you will log back in under your newly created user.


Server 1: Setup a Kafka Broker and ZooKeeper
----------------------------------------------

**Requirements:** A minimum of 2GB RAM

Connect to your server as your new ``user_name`` through your terminal

.. code-block:: default

	ssh -i /path/to/private_key_file user_name@xxx.xxx.xxx.xxx

Setup Zookeeper and a Kafka broker

.. code-block:: default

	mkdir -p ~/scripts
	wget https://ds4es.org/real-time-data-streaming-and-ingestion/_static/scripts/01_zookeeper_kafka_broker_installation.sh -P ~/scripts
	chmod +x ~/scripts/01_zookeeper_kafka_broker_installation.sh  
	~/scripts/01_zookeeper_kafka_broker_installation.sh broker_ip_address broker_port

* ``broker_ip_address`` - your Kafka broker public ip address 
* ``broker_port`` - your Kafka broker port

If everything is working fine, 2 tmux detached sessions should have been started:

* zookeeper-server-start
* kafka-server-start

You can access 2 those tmux sessions respectively with:

.. code-block:: default

	tmux attach-session -t zookeeper-server-start

.. code-block:: default

	tmux attach-session -t kafka-server-start

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

	mkdir -p ~/scripts
	wget https://ds4es.org/real-time-data-streaming-and-ingestion/_static/scripts/02_producer_consumer_instance.sh -P ~/scripts
	chmod +x ~/scripts/02_producer_consumer_instance.sh  
	~/scripts/02_producer_consumer_instance.sh

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

	~/kafka/bin/kafka-topics.sh --describe --topic your_topic_name --zookeeper zookeeper_ip_address:zookeeper_port


Retrieve connectors

.. code-block:: default

	wget url_to/kafka-connect-jdbc-5.3.1.jar -P ~/kafka/libs/
	wget url_to/mysql-connector-java-8.0.17.jar -P ~/kafka/libs/

Start or restart Kafka server and Zookeeper server

Start a Connector
^^^^^^^^^^^^^^^^^

.. code-block:: default

	tmux new -s connector-start -d
	tmux send-keys "~/kafka/bin/connect-ditributed.sh ~/kafka/config/connect-distributed.properties" Enter 



References
----------

* [Excellent debezium tutorial](https://debezium.io/documentation/reference/tutorial.html)
* [Overview of Docker Compose](https://docs.docker.com/compose/)
* [debezium-examples repo on GitHub](https://github.com/debezium/debezium-examples/tree/master/tutorial#using-sql-server)
* [Querying Debezium Change Data Events With KSQL](https://debezium.io/blog/2018/05/24/querying-debezium-change-data-eEvents-with-ksql/)
* [Using Debezium With the Apicurio API and Schema Registry](https://debezium.io/blog/2020/04/09/using-debezium-wit-apicurio-api-schema-registry/)
* [Running Kafka in Production](https://docs.confluent.io/current/kafka/deployment.html)