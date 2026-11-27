*This project has been created as part of the 42 curriculum by dtimofee.*

## Description

**Inception** is a WordPress website deployed with Docker. The stack consists of three containers: a **MariaDB** database, **WordPress** (PHP-FPM) and an **Nginx** reverse proxy that serves the site over HTTPS (port 443) at `dtimofee.42.fr`.

```
            :443
internet ────> nginx ──> wordpress (php-fpm :9000) ──> mariadb (:3306)
                  └────────── isolated bridge network ──────────┘
```

- **nginx** — terminates TLS (a self-signed certificate is generated at startup), serves the site and forwards PHP requests to WordPress.
- **wordpress** — WordPress core, configured and installed via WP-CLI on first start. Two users are created: `boss` (administrator) and `editor` (author).
- **mariadb** — creates the `wp` database and the `wpuser` account on first start.
- Persistent data (database files, WordPress files) lives in two **named volumes** whose data is stored on the host in `~/data/mariadb` and `~/data/wordpress` — i.e. `/home/dtimofee/data` on the 42 machine.
- All passwords are passed to the containers as **Docker secrets** (files in `secrets/`); non-sensitive configuration (domain, usernames, DB name) is in `srcs/.env`.

### Design choices and comparisons

**Virtual machines vs Docker.** A VM emulates a full OS: each one costs several GB and boots in minutes. A container shares the host kernel, starts in seconds and uses only the space it needs. For a web stack like this Docker is the right tool; a VM would only be needed to isolate the kernel or emulate hardware.

**Secrets vs environment variables.** Environment variables are visible in the container configuration (`docker inspect`), in the process environment and easily leak into shell history and logs. Docker secrets are files with restricted permissions, mounted only into the containers that need them; the password is read once at startup and is never part of the process environment. That is why all passwords here are secrets, and only non-sensitive values are in `.env`.

**Docker network vs host network.** With host networking the containers share the host's network interface: there is no isolation, ports can collide with host services, and Docker Desktop on macOS does not support host networking at all. Here an isolated bridge network `internal-network` is used instead: containers resolve each other by name (Docker DNS: `mariadb`, `wordpress`, `nginx`), and only nginx's port 443 is published to the host.

**Docker volumes vs bind mounts.** A bind mount hard-codes a host path inside the service definition. A named volume is managed by Docker, travels with the compose project, and is easy to inspect, back up and remove. The subject requires named volumes, so two of them are declared in `docker-compose.yml` and configured with `driver_opts` so that their data ends up in `/home/dtimofee/data` on the host.

## Instructions

Prerequisite: Docker (Docker Desktop, or the Docker engine + compose plugin).

1. Create the secret files (they are git-ignored, never commit them):
   ```sh
   mkdir -p secrets
   echo "your-db-password"      > secrets/db_password.txt
   echo "your-db-root-password" > secrets/db_root_password.txt
   echo "your-admin-password"   > secrets/admin_password.txt
   echo "your-user-password"    > secrets/user_password.txt
   ```
2. Create `srcs/.env`:
   ```
   DOMAIN_NAME=dtimofee.42.fr
   MYSQL_USER=wpuser
   MYSQL_DATABASE=wp
   MYSQL_HOST=mariadb
   WP_TITLE=Inception
   WP_ADMIN_USER=boss
   WP_ADMIN_EMAIL=boss@dtimofee.42.fr
   WP_USER=editor
   WP_USER_EMAIL=user@dtimofee.42.fr
   ```
   (Optional) to serve the site on a non-standard port instead of 443, add `NGINX_PORT=<port>` — the subject expects the standard 443.
3. Make the domain point to this machine (on the 42 machine use its LAN IP instead of 127.0.0.1):
   ```sh
   sudo sh -c 'echo "127.0.0.1 dtimofee.42.fr" >> /etc/hosts'
   ```
4. Build and start the stack:
   ```sh
   make start
   ```
5. Open `https://dtimofee.42.fr` in a browser (accept the self-signed certificate warning). Log in with `boss` (administrator) or `editor` (author); the passwords are the ones from step 1.

### Make targets

| Target         | What it does                                             |
|----------------|----------------------------------------------------------|
| `make start`   | builds the images (cached) and starts the stack (default)|
| `make build`   | builds the images only                                   |
| `make stop`    | stops the containers, data is kept                       |
| `make down`    | removes containers and the network, data is kept         |
| `make fclean`  | removes containers, volumes and images, deletes `~/data` |
| `make re`      | `fclean` + `start` — a completely fresh stack            |

Persistent data is stored in `~/data/mariadb` and `~/data/wordpress` (`/home/dtimofee/data/...` on the 42 machine) and survives `make down` / container restarts.

## Resources

- Docker Compose: https://docs.docker.com/compose/
- Compose secrets: https://docs.docker.com/compose/secrets/
- Docker volumes: https://docs.docker.com/engine/storage/volumes/
- Docker networking: https://docs.docker.com/engine/network/
- WordPress: https://wordpress.org/ · WP-CLI: https://developer.wordpress.org/cli/
- MariaDB documentation: https://mariadb.com/kb/
- Nginx documentation: https://nginx.org/en/docs/

**AI usage:** an AI assistant was used to debug the Docker setup, to adjust the `Makefile` and `docker-compose.yml` for local development, and to proof-read this README.
