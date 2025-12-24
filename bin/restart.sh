#! /bin/bash

SCRIPT_DIR=$(dirname "$0")

# load the deployment environment variables
# Needed are: DEPLOY_USER, DEPLOY_HOST, DEPLOY_DIR
# shellcheck source=deploy_env.sh
. "${SCRIPT_DIR}"/../config/deploy_env.sh


RAILS_MASTER_KEY=$(cat "${SCRIPT_DIR}"/../config/master.key)
export RAILS_MASTER_KEY

# run a script on the server to deploy the new version
# ensure that we don't keep running if any of the commands fail
ssh "${DEPLOY_USER}"@"${DEPLOY_HOST}" \
  "RAILS_MASTER_KEY=$RAILS_MASTER_KEY" \
  "DEPLOY_DIR=${DEPLOY_DIR}" \
  "APP_NAME=${APP_NAME}" \
'bash -s' <<'EOF'
set -e
set -x
cd "${DEPLOY_DIR}"
# stop any old "${APP_NAME}" container
docker stop "${APP_NAME}" || true
docker rm "${APP_NAME}" || true
# now run the image using regular docker
# listens to port 3001 on the host
docker run -d --name "${APP_NAME}" -p 3001:3000 \
  -e RACK_ENV=production \
  --restart=unless-stopped \
  -e RAILS_MASTER_KEY=$RAILS_MASTER_KEY \
  -v "${DEPLOY_DIR}/storage:/rails/storage" \
  -v "${DEPLOY_DIR}/tmp:/rails/tmp" \
 --log-driver json-file \
 --log-opt max-size=10m \
 --log-opt max-file=3 "${APP_NAME}"
EOF
