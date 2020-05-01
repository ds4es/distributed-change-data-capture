Up and running PostgreSQL replication with Debezium!
====================================================

Installing PostgreSQL on CentOS 8
---------------------------------

.. code-block:: default

	# Add PostgreSQL Repository
	sudo yum -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
	# Disable the built-in PostgreSQL module
	sudo dnf -qy module disable postgresql
	# Install both client and server packages
	sudo dnf -y install postgresql12 postgresql12-server
	# Initialize and start database service
	sudo /usr/pgsql-12/bin/postgresql-12-setup initdb
	# Start and enable the database server service.
	sudo systemctl enable --now postgresql-12


Set PostgreSQL admin user's password

.. code-block:: default

	sudo su - postgres -c 'psql -c "alter user postgres with password '\''my_strong_password'\''"'

Restart database service after committing the change.

.. code-block:: default

	sudo systemctl restart postgresql-12

Change PostgreSQL database encoding to UTF8	
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Check the database default encoding

.. code-block:: default

	sudo su - postgres -c 'psql postgres -c "SHOW SERVER_ENCODING"'

If UTF8 is not the default database encoding

.. code-block:: default


	sudo su - postgres -c 'psql -c "UPDATE pg_database SET datistemplate=FALSE WHERE datname='\''template1'\''"';

	sudo su - postgres -c 'psql -c "DROP DATABASE template1"';

	sudo su - postgres -c 'psql -c "CREATE DATABASE template1 WITH owner=postgres template=template0 encoding='\''UTF8'\''"';

	sudo su - postgres -c 'psql -c "UPDATE pg_database SET datistemplate=TRUE WHERE datname='\''template1'\''"';



Enable remote access (optional)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

First if you have a running Firewall service allow PostgreSQL service.

.. code-block:: default

	sudo firewall-cmd --add-service=postgresql --permanent
	sudo firewall-cmd --reload

Edit the file ``/var/lib/pgsql/12/data/postgresql.conf`` and set Listen address to your server IP address or ``*`` for all interfaces.

.. code-block:: default

	listen_addresses = '192.168.10.10'

Also set PostgreSQL to accept remote connections in ``/var/lib/pgsql/12/data/pg_hba.conf``


.. code-block:: default

	# Accept from anywhere
	# host all all 0.0.0.0/0 md5

	# Accept from trusted subnet
	host all all 192.168.18.0/24 md5


Load data
---------

.. code-block:: default

	sudo su - postgres -c 'createdb shakespeare'
	curl https://raw.githubusercontent.com/catherinedevlin/opensourceshakespeare/master/shakespeare.sql | sudo su - postgres -c 'psql shakespeare'

Setup the connector
-------------------

# Create a directory where to store connectors
sudo mkdir -p /usr/local/share/kafka/plugins
# Place your needed connectors in it
curl -s https://repo1.maven.org/maven2/io/debezium/debezium-connector-postgres/1.1.1.Final/debezium-connector-postgres-1.1.1.Final-plugin.tar.gz | sudo tar xvz -C /usr/local/share/kafka/plugins/debezium-connector-postgresql
# Declare this path in your worker configuration file
echo '
plugin.path=/opt/connectors
' | tee -a ~/kafka/config/connect-distributed.properties
# Restart your Kafka Connect process to pick up the new JARs
~/kafka/bin/connect-ditributed.sh ~/kafka/config/connect-distributed.properties
# export CLASSPATH=$CLASSPATH:/usr/local/share/kafka/plugins/debezium-connector-postgresql/*