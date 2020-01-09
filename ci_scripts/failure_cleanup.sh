#!/usr/bin/env bash
product="${1}"

if test ! -z "${CI_COMMIT_REF_NAME}" ; then
  . ${CI_PROJECT_DIR}/ci_scripts/ci_tools.lib.sh
else 
  # shellcheck source=~/projects/devops/pingidentity-docker-builds/ci_scripts/ci_tools.lib.sh
  HERE=$(cd $(dirname ${0});pwd)
  . ${HERE}/ci_tools.lib.sh
fi

images="$(gcloud container images list --repository=gcr.io/ping-identity)"
for image in ${images:5} ; do
  echo "RUNNING FOR IMAGE: $image"
  tags=$(gcloud container images list-tags $image --format="value(tags)" --filter=TAGS:"${ciTag}" | sed -e 's/,/ /g' )
  for tag in $tags ; do
    echo "RUNNING FOR TAG: $tag"
    gcloud container images untag "$image:$tag" --quiet
  done
  digests="$(gcloud container images list-tags $image --filter='-tags:*'  --format='get(digest)' --limit=1000)"
  for digest in $digests ; do
    echo "RUNNING FOR DIGEST: $digest"
    gcloud container images delete $image@$digest --quiet
  done
done