Debezium tutorial
=================

Prerequisites :

* Install Docker
* Add your user to the docker group (to run commands without ``sudo``)

Docker essential commands
-------------------------

To detach the tty without exiting the shell, use the escape sequence ``Ctrl``+``P`` followed by ``Ctrl``+``Q``. 

List all the containers:

.. code-block:: default

	docker ps

To display this information vertically:

.. code-block:: default

	export FORMAT="\nID\t{{.ID}}\nIMAGE\t{{.Image}}\nCOMMAND\t{{.Command}}\nCREATED\t{{.RunningFor}}\nSTATUS\t{{.Status}}\nPORTS\t{{.Ports}}\nNAMES\t{{.Names}}\n"
	docker ps --format $FORMAT 

Access to a docker container terminal

.. code-block:: default

	docker exec -it docker_container_id bash

Check the Docker container OS

.. code-block:: default

	grep PRETTY_NAME /etc/os-release | sed 's/PRETTY_NAME=//g' | tr -d '="'


Reverse-engineer a Dockerfile from a Docker image

.. code-block:: default

	export argv="image_name"
	docker history --no-trunc $argv  | tac | tr -s ' ' | cut -d " " -f 5- | sed 's,^/bin/sh -c #(nop) ,,g' | sed 's,^/bin/sh -c,RUN,g' | sed 's, && ,\n  & ,g' | sed 's,\s*[0-9]*[\.]*[0-9]*\s*[kMG]*B\s*$,,g' | head -n -1

Debezium tutorial
-----------------

.. code-block:: default

	# Starting Zookeeper
	docker run -it --rm --name zookeeper -p 2181:2181 -p 2888:2888 -p 3888:3888 debezium/zookeeper:1.1

