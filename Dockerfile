# Use an official Node.js runtime as a parent image (Choose a recent LTS version)
# Alpine Linux is used for a smaller image size
FROM node:lts-alpine

# Set the working directory inside the container
WORKDIR /app

# Install git, which is needed to clone the repository
# Combine update and install in one layer to reduce image size
RUN apk update && apk add --no-cache git bash

# Argument to specify the branch (defaulting to 'release')
ARG SILLY_BRANCH=release
ENV SILLY_BRANCH=${SILLY_BRANCH}

# Clone the specified branch of the SillyTavern repository into the working directory
# Use --single-branch and --depth 1 for a faster, smaller clone
RUN git clone https://github.com/SillyTavern/SillyTavern.git --branch ${SILLY_BRANCH} --single-branch --depth 1 .

# The start.sh script might install further dependencies (like Python packages if needed)
# Ensure the start script is executable
RUN chmod +x start.sh

# Expose the default port SillyTavern runs on
EXPOSE 8000

# Command to run when the container starts
# Uses bash explicitly as requested in the manual steps
CMD ["bash", "start.sh"]