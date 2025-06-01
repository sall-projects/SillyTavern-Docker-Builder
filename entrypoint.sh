#!/bin/sh

if [ ! -e "config/config.yaml" ]; then
    echo "Resource not found, copying from defaults: config.yaml"
    cp -r "default/config.yaml" "config/config.yaml"
fi

# Inject User Password in config.yml
sed -i -E "s/password:.*/password:${ST_PASSWORD}/" config/config.yaml

# Execute postinstall to auto-populate config.yaml with missing values
npm run postinstall

# Start the server
exec node server.js --listen "$@"