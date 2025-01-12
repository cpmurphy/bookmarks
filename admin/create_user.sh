#!/bin/bash

set -e

SCRIPT_DIR=$(dirname "$0")

# load the deployment environment variables
# shellcheck source=deploy_env.sh
. "${SCRIPT_DIR}"/../config/deploy_env.sh

# Function to show usage
usage() {
  echo "Usage: $0 [username] [email] [password]"
  echo "Creates a new Rails user. If username/email/password are not provided,"
  echo "they will be prompted for interactively."
  exit 1
}

# Function to get password with confirmation
get_password() {
  while true; do
    echo -n "Enter password: "
    read -rs PASSWORD
    echo
    echo -n "Confirm password: "
    read -rs PASSWORD2
    echo

    if [ "$PASSWORD" = "$PASSWORD2" ]; then
      break
    else
      echo "Passwords don't match. Please try again."
    fi
  done
}

# Get username either from argument or prompt
if [ -n "$1" ]; then
  USERNAME="$1"
else
  echo -n "Enter username: "
  read -r USERNAME
fi

# Get email either from argument or prompt
if [ -n "$2" ]; then
  EMAIL="$2"
else
  echo -n "Enter email: "
  read -r EMAIL
fi

# Get password either from argument or prompt with confirmation
if [ -n "$3" ]; then
  PASSWORD="$3"
else
  get_password
fi

# Create the Rails command
RAILS_CMD=$(cat <<EOF
begin
  if User.exists?(username: "$USERNAME")
    puts "Error: User '$USERNAME' already exists"
    exit 1
  end

  user = User.new(
    username: "$USERNAME",
    email_address: "$EMAIL",
    password: "$PASSWORD"
  )

  if user.save
    puts "User '$USERNAME' created successfully"
  else
    puts "Error creating user:"
    puts user.errors.full_messages
    exit 1
  end
rescue => e
  puts "Error: #{e.message}"
  exit 1
end
EOF
)

echo "Creating user '$USERNAME' with email '$EMAIL' and a password"

# Execute the Rails command on the remote server
ssh -t "${DEPLOY_USER}"@"${DEPLOY_HOST}" "cd ${DEPLOY_DIR} && docker exec -i ${APP_NAME} bin/rails runner '$RAILS_CMD'"
