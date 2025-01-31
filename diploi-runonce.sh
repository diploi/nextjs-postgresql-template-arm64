#!/bin/sh

progress() {
  current_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local action="$1"
  echo "🟩 $current_date $action"
}

# Perform tasks at controller pod startup
progress "Runonce started";

# Set accepted ssh key(s)
mkdir -p /root/.ssh;
chmod 0700 /root/.ssh;
cat /etc/ssh/internal_ssh_host_rsa.pub > /root/.ssh/authorized_keys;

cd /app;

# Seems that this is first run in devel instance
# Intialize persistant storage
if [ ! "$(ls -A /app)" ]; then

  echo "Empty /app, assuming development instance setup was intended";

  # Make /app default folder  
  echo "cd /app;" >> /root/.bashrc

  # Generate root ssh key
  ssh-keygen -A;

  progress "Pulling code";
  
  git init;
  git config credential.helper '!diploi-credential-helper';
  git remote add --fetch origin $REPOSITORY_URL;
  git checkout -f $REPOSITORY_BRANCH;
  git remote set-url origin "$REPOSITORY_URL";
  git config --unset credential.helper;
  
  # Configure the SQLTools VSCode extension
  # TODO: How to update these if env changes?
  cat > /app/.vscode/settings.json << EOL
{
  "sqltools.connections": [
    {
      "previewLimit": 50,
      "server": "$POSTGRES_HOST",
      "port": $POSTGRES_PORT,
      "driver": "PostgreSQL",
      "name": "PostgreSQL",
      "database": "$POSTGRES_DB",
      "username": "$POSTGRES_USER",
      "password": "$POSTGRES_PASSWORD",
    }
  ]
}
EOL

  progress "Installing";
  npm install;

fi

# Update internal ca certificate
update-ca-certificates

# Make all special env variables available in ssh also (ssh will wipe out env by default)
env >> /etc/environment

# Seed database
# NOTE! Not ideal, this assumes postgres starts faster than app container
node /app/lib/seedDatabase.js

# Now that everything is initialized, start all services
supervisorctl start www

progress "Runonce done";

exit 0;
