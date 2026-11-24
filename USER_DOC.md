# User Documentation

## Description

This document explains how to use and manage the Inception infrastructure.

The project provides a small web infrastructure composed of three Docker containers:

- **NGINX:** Handles incoming HTTPS connections and acts as the entry point to the website.
- **WordPress:** Provides the website and its administration interface.
- **MariaDB:** Stores the information and database required by WordPress.

The services communicate through an internal Docker network. Only NGINX exposes a port to the outside, using HTTPS on port 443.

No previous Docker knowledge is required to follow these instructions.

## Starting and Stopping the Project

The project includes a Makefile that simplifies the management of the infrastructure.

Open a terminal in the root directory of the project.

**Start the infrastructure**

```bash
make up
```

This command starts the containers in the foreground.

Alternatively, use:

```bash
make upd
```

This starts the containers in detached mode, allowing them to run in the background.

**Stop the infrastructure**

```bash
make down
```

This stops and removes the containers and their Docker network.

Your website files and database information remain stored on the host machine. Stopping the containers does not delete this information.

**Build and start everything**

```bash
make all
```

This command builds the required Docker images and starts the infrastructure.

## Accessing the Website

The website is accessible through the domain configured in the `.env` file.

The infrastructure uses HTTPS, so the website must be accessed through port 443.

Open your browser and navigate to:

```text
https://YOUR_DOMAIN
```

Replace `YOUR_DOMAIN` with the value assigned to `DOMAIN_NAME` in the `.env` file.

If the domain is not configured locally, you may need to add an entry to your `/etc/hosts` file:

```text
127.0.0.1 YOUR_DOMAIN
```

This makes the configured domain point to your local Virtual Machine.

Since the project uses a locally generated TLS certificate, your browser may display a security warning. This is expected when the certificate is not signed by a trusted Certificate Authority.

## WordPress Administration

WordPress provides an administration panel where you can manage the website, create posts, install themes and plugins, and manage users.

To access the administration panel, navigate to:

```text
https://YOUR_DOMAIN/wp-admin
```

Enter the administrator username and password configured during the WordPress installation.

Once authenticated, you will have access to the WordPress dashboard.

## Credentials Management

The infrastructure requires credentials to establish communication between WordPress and MariaDB, as well as administrator credentials for WordPress.

These credentials are configured through the project's environment configuration and secret files.

The main WordPress configuration variables include:

- `WP_ADMIN_USER`: WordPress administrator username.
- `WP_ADMIN_PASSWORD`: WordPress administrator password.
- `WP_ADMIN_EMAIL`: WordPress administrator email.
- `DB_USER`: MariaDB application username.
- `DB_PASSWORD`: MariaDB application password.

The database name used by WordPress is `wordpress`, and its database host is `mariadb`.

Sensitive information should never be shared publicly or committed to a Git repository.

If you need to change a password, update the corresponding configuration and make sure the application and database credentials remain synchronized.

For security reasons, do not share administrator credentials with other users.

## Checking the Infrastructure

If the website is not accessible, the first step is to check whether all containers are running correctly.

**Check running containers**

```bash
docker ps
```

This displays the containers currently running on the system.

You should find the NGINX, WordPress and MariaDB services.

**Check container logs**

```bash
docker compose -f ./srcs/docker-compose.yml logs
```

To inspect a specific service:

```bash
docker compose -f ./srcs/docker-compose.yml logs nginx
docker compose -f ./srcs/docker-compose.yml logs wordpress
docker compose -f ./srcs/docker-compose.yml logs mariadb
```

Logs are useful for identifying configuration errors, connection problems and service startup failures.

**Check container status**

```bash
docker compose -f ./srcs/docker-compose.yml ps
```

This displays the status of the services managed by Docker Compose.

**Check database access**

You can verify that MariaDB is working by accessing its container:

```bash
docker compose -f ./srcs/docker-compose.yml exec mariadb mariadb -u root -p -e "SHOW DATABASES;"
```

Enter the MariaDB root password when requested.

The WordPress database should appear in the results.

## Persistent Data

The project uses bind mounts to keep important information outside the containers.

The persistent information includes:

- WordPress files and website content.
- MariaDB database files.

These files are stored in directories on the host machine, configured through the `DATA_PATH` variable.

Removing or recreating containers does not automatically delete this information.

This means that the website and its database should remain available after restarting the infrastructure.