#!/bin/sh

# start vault agent in the background
echo "🕵️ starting Vault agent"

vault agent -config=agent-config.hcl -exit-after-auth=false &

echo "⏱️ waiting on certificates"
until [ -f /app/certs/siege-leviathan.pem ]; do 
    echo "..."
    sleep 1
done

echo "✅ complete: certificates found!"

echo "🚀 starting siege-leviathan"

exec uvicorn main:app --host 0.0.0.0 --port 8003
