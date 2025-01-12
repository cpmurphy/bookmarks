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

rake -f Rakefile.mine docker_build

rm -f "${APP_NAME}".tar
rm -f "${APP_NAME}".tar.bz2

# save the docker image to a tar file
docker save -o "${APP_NAME}".tar "${APP_NAME}"

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
chown rails:rails storage tmp
rm -f "${APP_NAME}".tar
bunzip2 -f "${APP_NAME}".tar.bz2
docker load -i "${APP_NAME}".tar
# stop any old "${APP_NAME}" container
docker stop "${APP_NAME}" || true
docker rm "${APP_NAME}" || true
# now run the image using regular docker
# listens to port 3001 on the host
docker run -d --name "${APP_NAME}" -p 3001:3000 \
  -e RACK_ENV=production \
  -e RAILS_MASTER_KEY=$RAILS_MASTER_KEY \
  -v "${DEPLOY_DIR}/storage:/rails/storage" \
  -v "${DEPLOY_DIR}/tmp:/rails/tmp" \
 --log-driver json-file \
 --log-opt max-size=10m \
 --log-opt max-file=3 "${APP_NAME}"
rm "${APP_NAME}".tar
# prune any unused docker images
docker system prune -f
EOF
