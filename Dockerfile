FROM ghcr.io/sillytavern/sillytavern@sha256:a1a5e38aa03a331d8c46d98b0501e25fe7c07820de27de6396f5894bd9405c73

# Copy your custom entrypoint script into the container
COPY docker-entrypoint.sh /home/node/app/docker-entrypoint.sh

# Make sure the script is executable and has Unix line endings
RUN chmod +x /home/node/app/docker-entrypoint.sh && \
    dos2unix /home/node/app/docker-entrypoint.sh

# Use tini for signal handling (just like original)
ENTRYPOINT ["tini", "--", "./docker-entrypoint.sh"]
