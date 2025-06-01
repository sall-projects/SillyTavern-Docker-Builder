#!/bin/sh

CONFIG_FILE="config/config.yaml"
DEFAULT_CONFIG_FILE="default/config.yaml"

# 1. Ensure config.yaml exists, copying from default if not
if [ ! -e "$CONFIG_FILE" ]; then
    echo "Config file not found at $CONFIG_FILE, copying from $DEFAULT_CONFIG_FILE"
    # Ensure target directory exists
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cp "$DEFAULT_CONFIG_FILE" "$CONFIG_FILE"
else
    echo "Config file found at $CONFIG_FILE."
fi

# 2. Execute postinstall to auto-populate/update config.yaml with defaults and structure
# This should happen BEFORE custom injections to ensure keys exist.
echo "Running postinstall to ensure config structure..."
npm run postinstall
echo "Postinstall complete."

# 3. Inject configurations from environment variables using sed
echo "Injecting configurations from environment variables..."

# Helper function for sed replacement (handles keys with potential leading spaces)
# Usage: inject_value "yaml_key" "$ENV_VARIABLE_VALUE" ["quote_value"]
# If "quote_value" is "quote", the value will be double-quoted. Otherwise, inserted as is.
inject_value() {
    local key_to_replace="$1"
    local new_value="$2"
    local quote_opt="$3"
    local sed_expression

    if [ -z "$new_value" ]; then
        # Don't attempt to inject if the environment variable is empty or unset
        echo "Skipping injection for $key_to_replace: environment variable not set or empty."
        return
    fi

    echo "Attempting to inject value for $key_to_replace..."

    if [ "$quote_opt" = "quote" ]; then
        # For string values that need to be quoted
        # Captures leading spaces (group 1) and key (group 2) to preserve indentation.
        sed_expression="s/^([[:space:]]*)(${key_to_replace}:).*/\1\2 \"${new_value}\"/"
    else
        # For boolean or numeric values that should not be quoted
        # Captures leading spaces (group 1) and key (group 2) to preserve indentation.
        sed_expression="s/^([[:space:]]*)(${key_to_replace}:).*/\1\2 ${new_value}/"
    fi

    # Check if the key exists before attempting to replace
    if grep -qE "^[[:space:]]*${key_to_replace}:" "$CONFIG_FILE"; then
        sed -i -E "$sed_expression" "$CONFIG_FILE"
        echo "Injected $key_to_replace: $new_value"
    else
        echo "Warning: Key '$key_to_replace' not found in $CONFIG_FILE. Cannot inject value."
    fi
}

# --- Define your environment variables and corresponding YAML keys here ---

# Example: Server Port (Number - no quotes)
if [ -n "$ST_PORT" ]; then
    inject_value "port" "$ST_PORT"
fi

# Example: Listen flag (Boolean - no quotes)
# Ensure ST_LISTEN is set to 'true' or 'false' (lowercase, as YAML expects)
if [ -n "$ST_LISTEN" ]; then
    inject_value "listen" "$ST_LISTEN"
fi

# Example: Whitelist Mode (Boolean)
if [ -n "$ST_WHITELIST_MODE" ]; then
    inject_value "whitelistMode" "$ST_WHITELIST_MODE"
fi

# Example: Control Basic Authentication Mode directly (Boolean)
if [ -n "$ST_BASIC_AUTH_MODE" ]; then
    # Ensure ST_BASIC_AUTH_MODE is set to 'true' or 'false' (lowercase)
    echo "Injecting ST_BASIC_AUTH_MODE as $ST_BASIC_AUTH_MODE..."
    inject_value "basicAuthMode" "$ST_BASIC_AUTH_MODE"
fi

# Example: Basic Auth Username (String)
if [ -n "$ST_BASIC_AUTH_USERNAME" ]; then
    if grep -qE "^[[:space:]]*basicAuthUser:" "$CONFIG_FILE"; then
        echo "Attempting to inject ST_BASIC_AUTH_USERNAME into basicAuthUser block..."
        # Corrected sed command to preserve indentation for username
        sed -i -E "/^[[:space:]]*basicAuthUser:/,/^[^[:space:]]/ s/^([[:space:]]*)(username:).*/\1\2 \"${ST_BASIC_AUTH_USERNAME}\"/" "$CONFIG_FILE"
        # Check if it actually changed, grep for the new value using fixed string search
        if grep -A 1 "basicAuthUser:" "$CONFIG_FILE" | grep -qF "username: \"${ST_BASIC_AUTH_USERNAME}\""; then
            echo "Injected ST_BASIC_AUTH_USERNAME for basicAuthUser.username"
        else
            echo "Warning: Could not verify injection of ST_BASIC_AUTH_USERNAME or key was not found/updated under basicAuthUser."
        fi
    else
        echo "Warning: 'basicAuthUser:' block not found. Cannot inject ST_BASIC_AUTH_USERNAME."
    fi
fi

# Example: Basic Auth Password (String) for basicAuthUser.password
if [ -n "$ST_BASIC_AUTH_PASSWORD" ]; then
    if grep -qE "^[[:space:]]*basicAuthUser:" "$CONFIG_FILE"; then
        echo "Attempting to inject ST_BASIC_AUTH_PASSWORD into basicAuthUser block..."
        # Corrected sed command to preserve indentation for password
        sed -i -E "/^[[:space:]]*basicAuthUser:/,/^[^[:space:]]/ s/^([[:space:]]*)(password:).*/\1\2 \"${ST_BASIC_AUTH_PASSWORD}\"/" "$CONFIG_FILE"
        # Check if it actually changed, grep for the new value using fixed string search
        if grep -A 2 "basicAuthUser:" "$CONFIG_FILE" | grep -qF "password: \"${ST_BASIC_AUTH_PASSWORD}\""; then
            echo "Injected ST_BASIC_AUTH_PASSWORD for basicAuthUser.password"
        else
            echo "Warning: Could not verify injection of ST_BASIC_AUTH_PASSWORD or key was not found/updated under basicAuthUser."
        fi
    else
        echo "Warning: 'basicAuthUser:' block not found. Cannot inject ST_BASIC_AUTH_PASSWORD."
    fi
fi

echo "Configuration injection phase complete."

# Optional: Output the modified config for debugging (especially during development)
echo "--- Current config.yaml after injections ---"
cat "$CONFIG_FILE"
echo "-------------------------------------------"

# 4. Start the server
echo "Starting server with command: node server.js --listen $@"
exec node server.js --listen "$@"