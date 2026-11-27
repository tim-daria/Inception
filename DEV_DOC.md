# DEV_DOC — Developer Documentation

## Prerequisites

- Docker Engine (or Docker Desktop) with the **Compose v2** plugin (`docker compose version`)
- GNU Make
- git


## Repository layout

```
Inception/
├── Makefile                     # start / build / stop / down / fclean / re
├── README.md  USER_DOC.md  DEV_DOC.md
├── secrets/                     # passwords — git-ignored, never commit
│   ├── db_password.txt          #   MariaDB password for wpuser
│   ├── db_root_password.txt     #   MariaDB root password
│   ├── admin_password.txt       #   WordPress admin (boss) password
│   └── user_password.txt        #   WordPress author (editor) password
└── srcs/
    ├── docker-compose.yml       # 3 services, bridge network, named volumes, secrets
    ├── .env                     # non-secret configuration — git-ignored
    └── requirements/
        ├── mariadb/   Dockerfile, conf/99-custom.cnf, tools/init.sh
        ├── wordpress/ Dockerfile, conf/www.conf,        tools/init.sh
        └── nginx/     Dockerfile, conf/site.template,   tools/init.sh
```

## Setting up the environment from scratch

1. Clone the repository.
2. Create the four secret files (any strong passwords):
   ```sh
   mkdir -p secrets
   echo "..." > secrets/db_password.txt
   echo "..." > secrets/db_root_password.txt
   echo "..." > secrets/admin_password.txt
   echo "..." > secrets/user_password.txt
   ```
3. Create `srcs/.env` (non-secret configuration):
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
4. Point the domain to this machine: `sudo sh -c 'echo "127.0.0.1 dtimofee.42.fr" >> /etc/hosts'`
5. `make start`

## Build and launch

- `make start` = `make build` + `docker compose up -d`: images are built first, then the containers start.
- What happens on the **first** launch only:
  - `mariadb/tools/init.sh` — initializes the data directory, creates the `wp` database and the `wpuser` account, sets the root password.
  - `wordpress/tools/init.sh` — waits for MariaDB, downloads WordPress via WP-CLI, writes `wp-config.php`, installs the core and creates the `boss` (administrator) and `editor` (author) users.
  - `nginx/tools/init.sh` — generates a self-signed TLS certificate for `DOMAIN_NAME` and renders `site.conf` from the template.
- To rebuild after changing a Dockerfile or an init script: `make build` (or `make re` for a full reset).

### Custom ports (optional)

Two ports can be reconfigured from `srcs/.env`; both default to the subject-standard values:

| Variable | Default | What it drives |
|---|---|---|
| `NGINX_PORT` | `443` | the published host port, nginx `listen`, and the WordPress `siteurl`/`home` (so WP does not redirect visitors to the wrong port) |
| `WP_PORT` | `9000` | the php-fpm listen port inside the WordPress container and nginx `fastcgi_pass` (internal only, never published to the host) |
| `DB_PORT` | `3306` | the MariaDB listen port (`99-custom.cnf`) and the WordPress `DB_HOST` in `wp-config.php` (internal only) |

## Managing containers and volumes

```sh
# containers
docker ps                                  # status of the stack
docker logs -f wordpress                   # follow logs
docker compose -f srcs/docker-compose.yml ps

# volumes
docker volume ls                           # srcs_mariadb-data, srcs_wordpress-data
docker volume inspect srcs_mariadb-data    # driver, options, host path

# peek inside the running stack
docker exec wordpress wp post list --allow-root
docker exec mariadb mariadb -u wpuser -p"$(cat secrets/db_password.txt)" wp \
    -e "SELECT ID, user_login FROM wp_users;"
```

## Where data is stored and how it persists

Two **named volumes** are declared in `docker-compose.yml`:

| Volume              | Mounted in the container | Host path                   |
|---------------------|--------------------------|-----------------------------|
| `srcs_mariadb-data` | `/var/lib/mysql`         | `~/data/mariadb`            |
| `srcs_wordpress-data` | `/var/www/html`         | `~/data/wordpress`          |

`~` is the current user's home: `/home/dtimofee/data` on the 42 machine. You can override the location with `make start DATA_DIR=/some/path`.

**Persists through:** `make stop`, `make down`, container recreation, image rebuilds, host reboots — the data is plain files on the host, outside the containers.
**Destroyed only by:** `make fclean`.

Verify persistence any time:

```sh
ls ~/data/mariadb/wp/          # InnoDB table files
docker exec wordpress wp post list --allow-root
```

## Troubleshooting

| Symptom | Fix |
|---|---|
| `dtimofee.42.fr` does not resolve | add the `/etc/hosts` entry (see setup step 4) |
| "Volume … doesn't match configuration" prompt | compose config changed after the volume was created; answer `y` (data is re-initialized) or run `make re` |
| Container restarts / errors | `docker logs <name>`, then check `srcs/.env` and `secrets/` |
| Need a completely fresh state | `make re` |
