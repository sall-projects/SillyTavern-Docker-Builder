FROM ghcr.io/sillytavern/sillytavern@sha256:013118f22a04181467a33e3ad58ef17643df2d5920e05c4416d5dd258c48f10c

# Copy your custom entrypoint script into the container
COPY docker-entrypoint.sh /home/node/app/docker-entrypoint.sh

# Make sure the script is executable and has Unix line endings
RUN chmod +x /home/node/app/docker-entrypoint.sh && \
    dos2unix /home/node/app/docker-entrypoint.sh

# Use tini for signal handling (just like original)
ENTRYPOINT ["tini", "--", "./docker-entrypoint.sh"]