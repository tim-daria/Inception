# USER_DOC — User Documentation

## What does this stack provide?

**Inception** is a self-hosted WordPress website. It is made of three services, each running in its own Docker container:

| Service    | What it does for you                                      |
|------------|-----------------------------------------------------------|
| **Nginx**      | Web server. Accepts your HTTPS requests on port 443 and forwards them. |
| **WordPress**  | The website itself: posts, pages, comments, users (runs PHP). |
| **MariaDB**    | The database: stores all posts, users and site settings.  |


## Starting and stopping the project

From the repository root:

```sh
make start    # start the website (on the very first run it also builds the images)
make stop     # stop everything; the website is offline, all your data is kept
make down     # stop and remove the containers; all your data is kept
```

After `make start`, wait about 10–30 seconds: on the very first launch the database and WordPress are initialized, and nginx needs a moment to start.

## Accessing the website and the administration panel

- **Website:** open `https://dtimofee.42.fr` in a browser. The browser will show a certificate warning — this is normal (the certificate is self-signed). Click "Advanced" → "Proceed".
- **Admin panel:** go to `https://dtimofee.42.fr/wp-login.php` and log in. After login you land in `/wp-admin`.
- The domain must point to this machine (see the *Instructions* section of the README: an entry in `/etc/hosts`).

## Credentials

| Login    | Role                                        | Password file                 |
|----------|---------------------------------------------|-------------------------------|
| `boss`   | administrator (full access)                 | `secrets/admin_password.txt`  |
| `editor` | author (creates and manages their own posts)| `secrets/user_password.txt`   |

- The files in `secrets/` are **not** committed to git. They must exist before the first start; see the README for how to create them.
- **Change a password** (for your own account): in the admin panel, *Users → Profile → New Password → Update*.
- **Lost all passwords?** The easiest fix is a full re-initialization, which recreates the users from the files in `secrets/`:
  ```sh
  make re
  ```
  ⚠️ This erases all website content (posts, pages) and starts from a fresh WordPress.

## Checking that the services are running correctly

1. **Browser test:** `https://dtimofee.42.fr` opens the website (HTTP 200).
2. **Quick check from the terminal:**
   ```sh
   curl -kI https://dtimofee.42.fr | head -1     # expect: HTTP/2 200
   ```
3. **Containers:** all three should be in state `Up`:
   ```sh
   docker ps
   ```
4. **If something is wrong**, look at the logs:
   ```sh
   docker logs nginx        # or: wordpress, mariadb
   ```
