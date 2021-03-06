#!/usr/bin/env sh
#
# Ping Identity DevOps - Docker Build Hooks
#
${VERBOSE} && set -x

# shellcheck source=../../../../pingcommon/opt/staging/hooks/pingcommon.lib.sh
. "${HOOKS_DIR}/pingcommon.lib.sh"

# shellcheck source=../../../../pingdatacommon/opt/staging/hooks/pingdata.lib.sh
test -f "${HOOKS_DIR}/pingdata.lib.sh" && . "${HOOKS_DIR}/pingdata.lib.sh"

# Move license to current location
# cp "${LICENSE_DIR}/${LICENSE_FILE_NAME}" .

_build_info="${SERVER_ROOT_DIR}/build-info.txt"

is_81ga() {
  test -f "${_build_info}" \
    && awk \
'BEGIN {maj=0;min=0;ga=0}
$1=="Major" && $3=="8" {maj=1}
$1=="Minor" && $3=="1" {min=1}
$2=="Qualifier:" && $3=="-GA" {ga=1}
END {if (maj && min && ga) {exit 0} else {exit 1}}' \
    "${_build_info}"
}

is_gte_82() {
  test -f "${_build_info}" \
    && awk \
'BEGIN {major_gt=0;major_eq=0;minor_ge=0}
$1=="Major" && $3>8 {major_gt=1}
$1=="Major" && $3==8 {major_eq=1}
$1=="Minor" && $3>=2 {minor_ge=1}
END {if (major_eq && minor_ge || major_gt) {exit 0} else {exit 1}}' \
  "${_build_info}"
}

# shellcheck disable=SC2039,SC2086
if ! test -f "${SERVER_ROOT_DIR}/config/configuration.yml" ;
then

  # shellcheck disable=SC2046
  if is_81ga ;
  then
    "${SERVER_ROOT_DIR}"/bin/setup demo \
        --licenseKeyFile "${LICENSE_DIR}/${LICENSE_FILE_NAME}" \
        --dbAdminUsername "${PING_DB_ADMIN_USERNAME:-sa}" \
        --dbAdminPassword "${PING_DB_ADMIN_PASSWORD:-Symphonic2014!}" \
        --port ${HTTPS_PORT} \
        --hostname "${REST_API_HOSTNAME}" \
        --generateSelfSignedCertificate \
        --decisionPointSharedSecret "${DECISION_POINT_SHARED_SECRET}" \
        2>&1
  else
    "${SERVER_ROOT_DIR}"/bin/setup demo \
        --licenseKeyFile "${LICENSE_DIR}/${LICENSE_FILE_NAME}" \
        --port ${HTTPS_PORT} \
        --hostname "${REST_API_HOSTNAME}" \
        --generateSelfSignedCertificate \
        --decisionPointSharedSecret "${DECISION_POINT_SHARED_SECRET}" \
        2>&1
  fi

  # shellcheck disable=SC2046
  if is_gte_82 ;
  then
    rm "${SERVER_ROOT_DIR}"/bin/start-server-pre-82
  else
    mv "${SERVER_ROOT_DIR}"/bin/start-server-pre-82 \
      "${SERVER_ROOT_DIR}"/bin/start-server
  fi
fi
