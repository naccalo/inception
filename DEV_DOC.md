# Developer Documentation

## Description

This document provides the technical information required to understand, configure and maintain the Inception infrastructure.

The project is built using Docker and Docker Compose. Each service runs inside its own container and is configured through individual Dockerfiles and environment variables.

The infrastructure consists of:

- NGINX: Web server and HTTPS entry point.
- WordPress: Website and PHP-FPM application.
- MariaDB: Relational database management system.

The services communicate through a custom Docker bridge network called `inception`.

## Environment Setup

### Prerequisites

Before starting development, make sure the following tools are installed on your Virtual Machine:

- Docker Engine.
- Docker Compose plugin.
- Make.
- Git.
- A Linux environment with sudo privileges.

You can verify the installation with:

```bash
docker --version
docker compose version
make --version
```

### Project Structure

The project follows a structure where each service has its own configuration and Dockerfile.

```text
folder/
│
├── Makefile
├── .env
│
└── srcs/
    ├── docker-compose.yml
    │
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   └── conf/
        │
        ├── wordpress/
        │   ├── Dockerfile
        │   └── tools/
        │
        └── mariadb/
            └── Dockerfile
```

The exact contents of each service directory depend on its implementation.

Each Dockerfile defines the image configuration and installation steps required by its corresponding service.

The Docker Compose file connects the different services and defines their networks, volumes, environment variables and startup configuration.

## Configuration Files

### Environment Variables

The `.env` file contains configuration values shared with Docker Compose.

Among the most important variables are:

- `DOMAIN_NAME`: Domain used to access the website.
- `DATA_PATH`: Host directory where persistent data is stored.
- Database configuration variables.
- WordPress administrator configuration variables.

The WordPress application uses the following database configuration:

```text
DB_HOST=mariadb
DB_NAME=wordpress
DB_USER=db_user
DB_PASSWORD=...
```

The database hostname is `mariadb` because Docker Compose provides internal DNS resolution between services.

This means that WordPress does not need to know the database container's IP address.

Before deploying the infrastructure, check that all required variables and secret files exist and that their names match the references used by the Dockerfiles and Compose configuration.

## Building and Launching the Infrastructure

The Makefile simplifies the interaction with Docker Compose.

The following commands are available from the project root directory.

**Build images**

```bash
make build
```

Builds the custom Docker images for the different services.

**Start containers**

```bash
make up
```

Creates and starts the containers in the foreground.

**Start in detached mode**

```bash
make upd
```

Starts the infrastructure in the background.

**Build and start**

```bash
make all
```

Builds the images and starts the complete infrastructure.

**Stop containers**

```bash
make down
```

Stops and removes containers and the associated Docker network.

**Remove containers and Docker volumes**

```bash
make downv
```

Removes containers, networks and Docker-managed volumes associated with the project.

**Clean unused Docker resources**

```bash
make prune
```

Removes unused Docker resources according to the pruning command configured in the Makefile.

Be careful when using this command, as it can affect resources outside the project.

### Docker Compose Commands

The Makefile is convenient for everyday use, but Docker Compose also provides direct control over the infrastructure.

All commands below assume that the Compose file is located at `./srcs/docker-compose.yml`.

**Build services**

```bash
docker compose -f ./srcs/docker-compose.yml build
```

**Start services**

```bash
docker compose -f ./srcs/docker-compose.yml up -d
```

**Stop services**

```bash
docker compose -f ./srcs/docker-compose.yml down
```

**Display running services**

```bash
docker compose -f ./srcs/docker-compose.yml ps
```

**Display logs**

```bash
docker compose -f ./srcs/docker-compose.yml logs -f
```

**Access a container**

```bash
docker compose -f ./srcs/docker-compose.yml exec wordpress bash
```

The same approach can be used to access NGINX or MariaDB.

**Inspect container configuration**

```bash
docker inspect CONTAINER_NAME
```

This provides information about the container, including its network configuration, mounts and environment.

## Container and Volume Management

### Container Management

Containers are instances of Docker images.

Each service has its own container, allowing it to run independently from the others.

To list all containers, including stopped ones:

```bash
docker ps -a
```

To restart a specific service:

```bash
docker compose -f ./srcs/docker-compose.yml restart SERVICE_NAME
```

To rebuild and recreate a specific service:

```bash
docker compose -f ./srcs/docker-compose.yml up -d --build SERVICE_NAME
```

Container logs are particularly useful during development:

```bash
docker compose -f ./srcs/docker-compose.yml logs -f SERVICE_NAME
```

### Image Management

Images contain the application and its dependencies.

To list available images:

```bash
docker images
```

To remove an image:

```bash
docker rmi IMAGE_NAME
```

An image cannot be removed while it is still being used by an existing container.

### Network Management

The project uses a custom bridge network called `inception`.

This network allows the containers to communicate internally through their service names.

To list Docker networks:

```bash
docker network ls
```

To inspect the project network:

```bash
docker network inspect inception
```

The network is created and managed through Docker Compose.

## Data Storage and Persistence

### Bind Mount Configuration

Persistent data is essential because containers can be removed and recreated during development.

The project uses bind mounts to store important information directly on the host filesystem.

The location is configured through the `DATA_PATH` environment variable.

Two directories are mapped:

| Service | Host directory | Container directory |
|---|---|---|
| MariaDB | `${DATA_PATH}/mariadb` | `/var/lib/mysql` |
| WordPress | `${DATA_PATH}/wordpress` | `/var/www/html` |

**MariaDB**

The `/var/lib/mysql` directory contains the database files.

Keeping this directory outside the container ensures that database information survives container removal.

**WordPress**

The `/var/www/html` directory contains the WordPress installation, themes, plugins, uploads and other website files.

The bind mount ensures that changes made to the website remain available after recreating the container.

### Checking Persistence

You can verify that the bind mounts are correctly configured using:

```bash
docker inspect mariadb --format '{{range .Mounts}}{{println .Type .Source "->" .Destination}}{{end}}'
```

This displays the mount type, host directory and destination inside the container.

To verify database persistence, follow these steps:

1. Start the infrastructure.
2. Create a database or insert some test information.
3. Stop and remove the containers.

```bash
docker compose -f ./srcs/docker-compose.yml down
```

4. Start the infrastructure again.

```bash
docker compose -f ./srcs/docker-compose.yml up -d
```

5. Access MariaDB and verify that the information is still available.

```bash
docker compose -f ./srcs/docker-compose.yml exec mariadb mariadb -u root -p -e "SHOW DATABASES;"
```

If the database remains available, the persistence configuration is working correctly.

**Important:** `docker compose down` does not remove bind-mounted directories. However, manually deleting the host directories will permanently remove the corresponding data.

## WordPress Administration and Debugging

WordPress is installed and configured through its container initialization process.

The application communicates with MariaDB using the database variables defined in the environment configuration.

WP-CLI can be used to manage the WordPress installation directly from the container.

For example, to list registered users:

```bash
docker compose -f ./srcs/docker-compose.yml exec wordpress \
wp --path=/var/www/html user list --allow-root
```

To change a user's password:

```bash
docker compose -f ./srcs/docker-compose.yml exec wordpress \
wp --path=/var/www/html user update USERNAME --user_pass='NEW_PASSWORD' --allow-root
```

Replace `USERNAME` with the corresponding WordPress username.

### Troubleshooting

When a service fails to start, check its logs first.

```bash
docker compose -f ./srcs/docker-compose.yml logs nginx
docker compose -f ./srcs/docker-compose.yml logs wordpress
docker compose -f ./srcs/docker-compose.yml logs mariadb
```

Some common problems include:

- Incorrect environment variables.
- Missing or incorrectly configured secrets.
- Database connection failures.
- Incorrect file permissions.
- Invalid NGINX configuration.
- Problems with TLS certificates.
- Incorrect bind mount paths.

Always check the service logs and container configuration before rebuilding the entire infrastructure.

## Final Notes

The main objective of this project is to maintain a clear separation between services, configuration and persistent data.

Each container should have a specific responsibility, and communication should happen through the internal Docker network.

By keeping application data outside the containers, the infrastructure can be rebuilt and restarted without losing important information.

This approach makes the project easier to maintain, debug and extend.