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

rm -f bookmarx.tar
rm -f bookmarx.tar.bz2

# save the docker image to a tar file
docker save -o bookmarx.tar bookmarx

bzip2 bookmarx.tar

# upload the tar file to the server
scp bookmarx.tar.bz2 "${DEPLOY_USER}"@"${DEPLOY_HOST}":"${DEPLOY_DIR}"/bookmarx.tar.bz2

# run a script on the server to deploy the new version
# ensure that we don't keep running if any of the commands fail
ssh "${DEPLOY_USER}"@"${DEPLOY_HOST}" "RAILS_MASTER_KEY=$RAILS_MASTER_KEY" "DEPLOY_DIR=${DEPLOY_DIR}" 'bash -s' <<'EOF'
set -e
set -x
cd "${DEPLOY_DIR}"
rm -f bookmarx.tar
bunzip2 -f bookmarx.tar.bz2
docker load -i bookmarx.tar
# stop any old bookmarx container
docker stop bookmarx || true
docker rm bookmarx || true
# now run the image using regular docker
# listens to port 3001 on the host
docker run -d --name bookmarx -p 3001:3000 \
  -e RACK_ENV=production \
  -e RAILS_MASTER_KEY=$RAILS_MASTER_KEY \
 --log-driver json-file \
 --log-opt max-size=10m \
 --log-opt max-file=3 bookmarx
rm bookmarx.tar
# prune any unused docker images
docker system prune -f
EOF
