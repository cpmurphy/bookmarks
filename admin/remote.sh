#! /bin/bash

set -e

SCRIPT_DIR=$(dirname "$0")

# load the deployment environment variables
# Needed are: DEPLOY_USER, DEPLOY_HOST, DEPLOY_DIR
# shellcheck source=deploy_env.sh
. "${SCRIPT_DIR}"/../config/deploy_env.sh

# Function to show usage
usage() {
  echo "Usage: $0 [command]"
  echo "Commands:"
  echo "  bash        - Start a bash shell in the container (default)"
  echo "  console     - Start a Rails console"
  echo "  dbconsole   - Start a database console"
  echo "  logs        - Show container logs"
  exit 1
}

# Get the command (default to bash)
CMD=${1:-bash}

case $CMD in
  bash)
    ssh -t "${DEPLOY_USER}"@"${DEPLOY_HOST}" "cd ${DEPLOY_DIR} && docker exec -it ${APP_NAME} bash"
    ;;
  console)
    ssh -t "${DEPLOY_USER}"@"${DEPLOY_HOST}" "cd ${DEPLOY_DIR} && docker exec -it ${APP_NAME} bin/rails console"
    ;;
  dbconsole)
    ssh -t "${DEPLOY_USER}"@"${DEPLOY_HOST}" "cd ${DEPLOY_DIR} && docker exec -it ${APP_NAME} bin/rails dbconsole"
    ;;
  logs)
    ssh -t "${DEPLOY_USER}"@"${DEPLOY_HOST}" "cd ${DEPLOY_DIR} && docker logs -f ${APP_NAME}"
    ;;
  *)
    usage
    ;;
esac
