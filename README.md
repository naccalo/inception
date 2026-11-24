*This project has been created as part of the 42 curriculum by ignaccas.*

# Inception
## Description

The main goal of this project is to deploy a small infrastructure composed of three interconnected Docker containers inside a Virtual Machine.

The infrastructure consists of the following services:

- **NGINX:** Acts as the web server and the entry point to the infrastructure. It handles incoming HTTPS connections using TLS.
- **WordPress:** Provides the content management system and communicates with the database through PHP-FPM.
- **MariaDB:** Stores and manages the WordPress database.

The purpose of this project is to understand how Docker works and how containerized services communicate with each other. It also involves learning about Docker images, containers, networks, volumes, environment variables, and service orchestration using Docker Compose.

All services are built from custom Dockerfiles, following the requirements of the 42 Inception subject.

## Instructions

### Requirements

To run this project, you need:

- A Linux Virtual Machine.
- Docker Engine.
- Docker Compose plugin.
- Make.
- Root privileges or sudo access.

The Makefile acts as a bridge between the user and Docker Compose, simplifying the execution of common Docker commands.

### Available commands

Run the following commands from the root directory of the project.

**`make build`**

Builds all the Docker images defined in the Docker Compose configuration. Each service has its own Dockerfile, which contains the instructions required to create its corresponding image.

**`make up`**

Creates and starts the containers defined in the Docker Compose file. By default, the containers run in the foreground, displaying their logs directly in the terminal.

**`make upd`**

Creates and starts all containers in detached mode (`-d`). This allows the infrastructure to run in the background while keeping the terminal available.

**`make all`**

Builds the Docker images and starts the complete infrastructure. It combines the build and startup processes into a single command.

**`make down`**

Stops and removes the containers and the Docker network created by Docker Compose.

Persistent data stored in bind-mounted directories is not deleted.

**`make prune`**

Removes unused Docker resources to free up disk space. Depending on the Makefile implementation, this may include unused containers, networks, images, and build cache.

Use this command carefully, as pruning can affect resources outside this project.

## Resources

Several resources were consulted throughout the development of this project.

- **gmartin99 GitHub:** Used as a reference to understand the general structure and implementation of the Inception project.
- **Abdilah CH – Medium:** A guide to understanding and implementing Docker-based infrastructure.
- **Docker Documentation:** Official documentation for Docker Engine, Docker Compose, images, containers, networks, and volumes.
- **Gemini:** Used as an additional debugging and troubleshooting resource when certain technical issues could not be identified through conventional debugging.

The project was developed through experimentation, testing, and troubleshooting, with particular attention to understanding the underlying mechanisms instead of simply following existing implementations.

## Project Description

### Virtual Machine vs Docker

A Virtual Machine (VM) and a Docker container both provide isolated environments, but they work at different levels of the operating system.

A Virtual Machine virtualizes hardware through a hypervisor. Each VM runs its own operating system, including its own kernel, on top of the virtualized hardware.

Docker containers, on the other hand, use operating-system-level virtualization. They share the host machine's kernel while maintaining isolated environments for applications and their dependencies.

**Main differences:**

| Virtual Machine | Docker Container |
|---|---|
| Virtualizes hardware | Virtualizes the operating system environment |
| Runs its own OS and kernel | Shares the host kernel |
| Generally heavier | Generally lightweight |
| Requires more resources | Uses resources more efficiently |
| Boots an entire OS | Starts an isolated process |

In this project, the Virtual Machine provides the environment where Docker Engine runs. Docker then manages the three isolated services independently.

This separation makes it possible to develop, deploy, and maintain each service without installing all its dependencies directly into the Virtual Machine.

### Secrets vs Environment Variables

Environment variables and secrets are two different ways of providing configuration information to applications.

**Environment Variables**

Environment variables are values passed to a process through its execution environment. They are commonly used to configure applications without hardcoding configuration directly into the source code.

For example:
- Database host.
- Database name.
- Database username.
- Application configuration.

In Docker Compose, environment variables can be defined directly in the Compose file or loaded from an `.env` file.

**Secrets**

Secrets are designed to handle sensitive information, such as passwords, API keys, and certificates.

Instead of exposing sensitive values as ordinary environment variables, Docker secrets provide a mechanism to make them available to authorized services as files.

This reduces the risk of accidentally exposing credentials through process environments or configuration output.

**Main differences:**

| Environment Variables | Secrets |
|---|---|
| Used for general configuration | Designed for sensitive information |
| Passed through the process environment | Usually mounted as files |
| Can be visible through container inspection | Access can be restricted to specific services |
| Convenient for non-sensitive values | Better suited for credentials |

In this project, environment variables are used to configure the communication between WordPress and MariaDB, while sensitive credentials are handled through the project's secrets configuration.

It is important to understand that an `.env` file is not automatically a secure secret manager. It must be protected with appropriate filesystem permissions and excluded from version control.

### Docker Network vs Host Network

Docker provides different networking modes that determine how containers communicate with each other and with the outside world.

**Bridge Network**

A bridge network creates an isolated virtual network that allows containers to communicate with each other using their container names as hostnames.

This is the default networking approach used by Docker Compose for project services.

For example, WordPress can connect to MariaDB using its service name instead of having to know its IP address.

In this project, all three services are connected through a custom bridge network called `inception`.

This allows:
- NGINX to communicate with WordPress.
- WordPress to communicate with MariaDB.
- Internal communication without exposing every service directly to the host machine.

Only the necessary external port is published: HTTPS traffic on port 443.

**Host Network**

Host networking removes the network isolation between a container and the host machine.

A container using host networking shares the host's network namespace. This means it uses the host's network interfaces and ports directly.

For example, an application listening on port 443 inside the container would also occupy port 443 on the host.

**Main differences:**

| Bridge Network | Host Network |
|---|---|
| Provides network isolation | Shares the host network namespace |
| Containers communicate through the Docker network | Uses the host network interfaces |
| Supports container-name DNS resolution | Does not provide the same Compose service-name networking |
| Requires port publishing for external access | Uses host ports directly |

For this project, a custom bridge network is preferable because it provides isolation between the infrastructure and the host while allowing the services to communicate internally.

### Docker Volumes vs Bind Mounts

Containers are designed to be relatively ephemeral. Their writable filesystem can disappear when containers are removed or recreated.

To preserve important information, Docker provides persistent storage mechanisms.

Two common approaches are Docker volumes and bind mounts.

**Docker Volumes**

Docker volumes are managed directly by Docker.

They are stored in a location controlled by Docker and can be attached to containers whenever they are created.

Their main advantage is that Docker handles their lifecycle and storage management.

**Bind Mounts**

Bind mounts connect a specific directory or file from the host machine to a location inside a container.

This means that changes made inside the container are reflected in the corresponding host directory, and vice versa.

They are particularly useful when you want direct access to application files or persistent data from outside the container.

**Main differences:**

| Docker Volumes | Bind Mounts |
|---|---|
| Managed by Docker | Managed through host filesystem paths |
| Stored in Docker-managed directories | Stored at explicitly defined host paths |
| More portable between environments | Depends on host directory structure |
| Can be managed using Docker commands | Can be accessed directly from the host |

In this project, bind mounts are used to persist the data of both WordPress and MariaDB.

The following directories are mapped:

- MariaDB: `${DATA_PATH}/mariadb` → `/var/lib/mysql`
- WordPress: `${DATA_PATH}/wordpress` → `/var/www/html`

This ensures that database files and WordPress content remain available even when containers are stopped, removed, or recreated.

An important distinction is that `docker compose down` does not delete bind-mounted data. The information remains stored in the host directories, independently of the container lifecycle.

This separation between application containers and persistent data is essential to building a reliable Docker infrastructure.