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
        # This regex tries to match 'key: existing_value' possibly with leading spaces
        # and replaces 'existing_value' with the new quoted value.
        # It captures the key part (e.g., "password:") to preserve it.
        sed_expression="s/^[[:space:]]*(${key_to_replace}:).*/\1 \"${new_value}\"/"
    else
        # For boolean or numeric values that should not be quoted
        sed_expression="s/^[[:space:]]*(${key_to_replace}:).*/\1 ${new_value}/"
    fi

    # Check if the key exists before attempting to replace
    if grep -qE "^[[:space:]]*${key_to_replace}:" "$CONFIG_FILE"; then
        sed -i -E "$sed_expression" "$CONFIG_FILE"
        echo "Injected $key_to_replace: $new_value"
    else
        echo "Warning: Key '$key_to_replace' not found in $CONFIG_FILE. Cannot inject value."
        # Optionally, you could append the key-value pair if it's missing,
        # but that's safer with tools like yq.
        # echo "$key_to_replace: \"$new_value\"" >> "$CONFIG_FILE" # Be careful with indentation and structure
    fi
}

# --- Define your environment variables and corresponding YAML keys here ---

# Example: Password (String - requires quoting)
if [ -n "$ST_PASSWORD" ]; then
    inject_value "password" "$ST_PASSWORD" "quote"
fi

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

# Example: Basic Auth Username (String)
if [ -n "$ST_BASIC_AUTH_USERNAME" ]; then
    # This targets 'username:' under 'basicAuthUser:'.
    # sed is line-based, so for nested keys, you make assumptions about structure
    # or use more complex sed commands (or a better tool like yq).
    # This simple version assumes 'username:' is unique enough or you accept the first match.
    # For a more robust nested update with sed, it's tricky.
    # A common pattern for simple nested key like '  username: value'
    # Note: The key for inject_value here includes the typical leading spaces
    # if you want to target an indented key specifically.
    # However, the inject_value function's regex `^[[:space:]]*` already handles arbitrary leading spaces.
    # So, for 'basicAuthUser: username:', you'd ideally target 'username' within the 'basicAuthUser' block.
    # The current inject_value function is best for top-level or uniquely named keys.

    # If 'username' is unique enough across the file for this purpose:
    # inject_value "username" "$ST_BASIC_AUTH_USERNAME" "quote"

    # For truly nested structures with sed, it becomes complex. Example for basicAuthUser.username:
    # This assumes 'username:' is directly under a line containing 'basicAuthUser:'
    # and that 'username:' appears after 'basicAuthUser:'.
    if grep -qE "^[[:space:]]*basicAuthUser:" "$CONFIG_FILE"; then
        echo "Attempting to inject ST_BASIC_AUTH_USERNAME into basicAuthUser block..."
        # This sed command operates on the block starting with basicAuthUser
        # until the next line that is not indented (or end of file)
        sed -i -E "/^[[:space:]]*basicAuthUser:/,/^[^[:space:]]/ s/^[[:space:]]*(username:).*/\1 \"${ST_BASIC_AUTH_USERNAME}\"/" "$CONFIG_FILE"
        # Check if it actually changed, grep for the new value
        if grep -A 1 "basicAuthUser:" "$CONFIG_FILE" | grep -q "username: \"${ST_BASIC_AUTH_USERNAME}\""; then
             echo "Injected ST_BASIC_AUTH_USERNAME for basicAuthUser.username"
        else
             echo "Warning: Could not verify injection of ST_BASIC_AUTH_USERNAME or key was not found under basicAuthUser."
        fi
    else
        echo "Warning: 'basicAuthUser:' block not found. Cannot inject ST_BASIC_AUTH_USERNAME."
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