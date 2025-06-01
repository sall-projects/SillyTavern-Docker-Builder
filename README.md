# Custom SillyTavern Docker

Runs SillyTavern with runtime configuration via environment variables. This setup uses the official SillyTavern base image and a custom `docker-entrypoint.sh` script to modify `config.yaml` on startup.

## Quick Start

**1. Prerequisites:**
* Docker installed.
* `Dockerfile` and your custom `docker-entrypoint.sh` in the current directory.

**2. Build the Image:**
```bash
docker build -t my-sillytavern .
```

**3. Run the Container:**
This example runs SillyTavern on port 8000, sets a password, and uses local directories for persistent data.

```bash
# Create local directories for persistent data if they don't exist
mkdir -p ./my_sillytavern_config ./my_sillytavern_data ./my_sillytavern_plugins ./my_sillytavern_extensions

docker run -d \
  -p 8000:8000 \
  -v ./my_sillytavern_config:/home/node/app/config \
  -v ./my_sillytavern_data:/home/node/app/data \
  -v ./my_sillytavern_plugins:/home/node/app/plugins \
  -v ./my_sillytavern_extensions:/home/node/app/public/scripts/extensions/third-party \
  -e ST_PORT="8000" \
  -e ST_LISTEN="true" \
  -e ST_PASSWORD="YourSecurePassword123" \
  --name sillytavern-app \
  my-sillytavern
```
Access SillyTavern at `http://localhost:8000`.

## Configuration via Environment Variables

The `docker-entrypoint.sh` script modifies `/home/node/app/config/config.yaml` using environment variables you provide when running the container.

**Key Environment Variable Examples:**

* **`ST_PORT`**: Sets the server port.
    * Example: `-e ST_PORT="8080"` (remember to update `-p` mapping accordingly, e.g., `-p 8080:8080`)
* **`ST_LISTEN`**: Set to `true` to make the server listen on network interfaces (e.g., for access from other devices).
    * Example: `-e ST_LISTEN="true"`
* **`ST_PASSWORD`**: Sets the password for `basicAuthUser` and enables `basicAuthMode`.
    * Example: `-e ST_PASSWORD="a_strong_password"`
* **`ST_BASIC_AUTH_USERNAME`**: Sets the username for `basicAuthUser`.
    * Example: `-e ST_BASIC_AUTH_USERNAME="admin"`
* **`ST_WHITELIST_MODE`**: Toggles `whitelistMode` (`true` or `false`).
    * Example: `-e ST_WHITELIST_MODE="false"`
* **`ST_BASIC_AUTH_MODE`**: Directly controls the `basicAuthMode` setting in `config.yaml`. Set this to `true` to enable basic authentication or `false` to disable it.
    * Example to enable: `-e ST_BASIC_AUTH_MODE="true"`
    * Example to disable: `-e ST_BASIC_AUTH_MODE="false"`

Refer to your `docker-entrypoint.sh` script for the full list of supported variables and their exact behavior. Boolean values should typically be `true` or `false` (lowercase strings).

## Persistent Data

To ensure your SillyTavern data and customizations persist across container restarts, mount the following volumes:

* **`./config:/home/node/app/config`**: Contains `config.yaml` and other core configurations.
* **`./data:/home/node/app/data`**: SillyTavern's primary data directory (chats, characters, user settings, lorebooks, etc.).
* **`./plugins:/home/node/app/plugins`**: For custom server-side plugins.
* **`./extensions:/home/node/app/public/scripts/extensions/third-party`**: For third-party client-side UI extensions.

Replace `./config`, `./data`, etc., with the actual paths to your desired local directories (e.g., `./my_sillytavern_config`).