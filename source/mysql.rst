Replicate SQL Server CDC changes to MySql in real-time
======================================================
Source: https://medium.com/@gvsbharish/real-time-sql-server-cdc-changes-to-mysql-using-debezium-kafka-connect-without-docker-1317804efe59

Installing MySQL on CentOS 8 / RHEL 8
-------------------------------------

Install MySQL Server

.. code-block:: default

	sudo dnf install mysql-server
	sudo systemctl start mysqld
	sudo systemctl list-units | grep -E 'mysqld.service'

To login to MySQL

.. code-block:: default

	sudo mysql


Installing Microsoft SQL Server 2019 on CentOS 8 / RHEL 8
---------------------------------------------------------
Source: https://computingforgeeks.com/how-to-install-microsoft-sql-server-on-rhel-centos/

.. code-block:: default

	# Add the Microsoft SQL Server 2019 repository 
	sudo curl https://packages.microsoft.com/config/rhel/8/mssql-server-2019.repo -o /etc/yum.repos.d/mssql-server-2019.repo 
	sudo  curl https://packages.microsoft.com/config/rhel/8/prod.repo -o /etc/yum.repos.d/msprod.repo
	# Install MS SQL server
	sudo dnf -y install mssql-server
	# Install SQL Server command-line tools
	sudo yum -y install mssql-tools unixODBC-devel
	# Confirm installation
	rpm -qi mssql-server
	# Initialize MS SQL Database Engine
	sudo /opt/mssql/bin/mssql-conf setup
	# Add /opt/mssql/bin/ to your $PATH variable
	echo 'export PATH=$PATH:/opt/mssql/bin:/opt/mssql-tools/bin' | sudo tee /etc/profile.d/mssql.sh
	# Source the file to start MS SQL
	source /etc/profile.d/mssql.sh


Enable remote access (optional)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
If you have an active Firewalld service, allow SQL Server ports for remote hosts to connect:

.. code-block:: default

	sudo  firewall-cmd --add-port=1433/tcp --permanent
	sudo firewall-cmd --reload


Test SQL Server
^^^^^^^^^^^^^^^

.. code-block:: default

	# Connect to the SQL Server
	sqlcmd -S localhost -U SA
	# Show Database users
	select name from sysusers;









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

Or from a script: ``https://github.com/edent/Open-Source-Shakespeare``