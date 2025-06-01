# Use a specific LTS Node.js and Alpine version for reproducibility
# Check Docker Hub for the latest supported Alpine version for node:lts if desired
FROM node:lts-alpine3.20

# --- Configuration Arguments ---

# Define the application home directory
ARG APP_HOME=/home/node/app

# Define the default SillyTavern branch to clone
ARG SILLY_BRANCH=release

# --- Environment Variables ---

# Set Node.js environment to production for potential optimizations
ENV NODE_ENV=production

# --- System Setup ---

# Install necessary system dependencies:
# git: needed to clone the repository
# bash: needed to run start.sh
# tini: a lightweight init system for proper signal handling & zombie reaping
RUN apk update && apk add --no-cache \
    git \
    bash \
    tini

# Set the working directory inside the container
# Use the user provided by the base node image ('node')
WORKDIR ${APP_HOME}

# --- Application Code ---

# Clone the specified branch of the SillyTavern repository into the working directory
# Use --single-branch and --depth 1 for a faster, smaller clone
RUN echo "*** Cloning SillyTavern branch: ${SILLY_BRANCH} ***" && \
    git clone https://github.com/SillyTavern/SillyTavern.git --branch ${SILLY_BRANCH} --single-branch --depth 1 . && \
    # Configure Git safe directory immediately after cloning for the WORKDIR
    # This might be needed if start.sh runs git commands later
    git config --global --add safe.directory ${APP_HOME}

# --- Custom Configuration ---

# Copy your custom default configuration from the build context.
# This will overwrite any 'config.yaml' cloned from the repo, applying your overlay.
# Assumes SillyTavern reads 'config.yaml' from its root directory.
# Uses --chown to ensure the config file is owned by the 'node' user.
COPY --chown=node:node default-config.yaml ${APP_HOME}/default/config.yaml
COPY --chown=node:node default-config.yaml ${APP_HOME}/config.yaml

# --- Permissions and Execution Setup ---

# Ensure the start script cloned from the repo is executable
RUN chmod +x start.sh

# Change ownership of the entire application directory to the 'node' user
# This allows start.sh (and node/npm processes it runs) to write files if needed
# Do this *after* all file operations as root are complete
RUN chown -R node:node ${APP_HOME}

# Switch to the non-root 'node' user provided by the base image
USER node

# --- Container Runtime ---

# Expose the default port SillyTavern runs on
EXPOSE 8000

COPY --chown=node:node ./entrypoint.sh ${APP_HOME}/entrypoint.sh

# Set the entrypoint to use 'tini' as the init process (PID 1)
# Tini will launch and manage the 'bash start.sh' command
# This ensures proper signal handling (e.g., for graceful shutdown)
ENTRYPOINT ["/sbin/tini", "--", "./entrypoint.sh"]
