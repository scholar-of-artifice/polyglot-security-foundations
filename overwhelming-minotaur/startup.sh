#!/bin/sh

# start vault agent in the background
echo "🕵️ starting Vault agent"

vault agent -config=agent-config.hcl -exit-after-auth=false &

echo "⏱️ waiting on certificates"
until [ -f /app/certs/identity.pem ]; do 
    echo "..."
    sleep 1
done

echo "✅ complete: certificates found!"

echo "🚀 starting overwhelming-minotaur"

exec ./overwhelming-minotaur
