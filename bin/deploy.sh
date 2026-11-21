#! /bin/bash

set -e
set -x

if [ -n "$(git status -s)" ]; then
  echo "Uncommitted changes found! Aborting."
  exit 1
fi

SCRIPT_DIR=$(dirname "$0")

# load the deployment environment variables
# Needed are: DEPLOY_USER, DEPLOY_HOST, DEPLOY_DIR
# shellcheck source=deploy_env.sh
. "${SCRIPT_DIR}"/../config/deploy_env.sh


RAILS_MASTER_KEY=$(cat "${SCRIPT_DIR}"/../config/master.key)
export RAILS_MASTER_KEY

rake
bin/rails db:test:prepare test:system

rake -f Rakefile.mine docker_build

rm -f "${APP_NAME}".tar
rm -f "${APP_NAME}".tar.bz2

# save the container image to a tar file
podman save -o "${APP_NAME}".tar "${APP_NAME}"

bzip2 "${APP_NAME}".tar

ssh "${DEPLOY_USER}"@"${DEPLOY_HOST}" "mkdir -p ${DEPLOY_DIR}"
# upload the tar file to the server
scp "${APP_NAME}".tar.bz2 "${DEPLOY_USER}"@"${DEPLOY_HOST}":"${DEPLOY_DIR}"/"${APP_NAME}".tar.bz2

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
mkdir -p storage
mkdir -p tmp
chown apps:apps storage tmp
rm -f "${APP_NAME}".tar
bunzip2 -f "${APP_NAME}".tar.bz2
podman load -i "${APP_NAME}".tar
# run the new image, replacing any existing "${APP_NAME}" container
# listens to port 3001 on the host
podman run -d --replace --name "${APP_NAME}" -p 127.0.0.1:3001:3000 \
  -e RACK_ENV=production \
  --restart=unless-stopped \
  --userns=keep-id:uid=1000,gid=1000 \
  -e RAILS_MASTER_KEY=$RAILS_MASTER_KEY \
  -v "${DEPLOY_DIR}/storage:/rails/storage" \
  -v "${DEPLOY_DIR}/tmp:/rails/tmp" \
 --log-driver json-file \
 --log-opt max-size=10m \
 --log-opt max-file=3 "${APP_NAME}"
rm "${APP_NAME}".tar
# prune any unused images
podman system prune -f
EOF
