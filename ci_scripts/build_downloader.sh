#!/usr/bin/env bash
test -n "${VERBOSE}" && set -x

usage()
{
    test -n "${*}" && echo "${*}"

    cat <<END_USAGE
Usage: ${0} {options}
    where {options} include:
    --verbose-build
        verbose docker build using plain progress output
    --no-cache
        no docker cache
    --no-build-kit
        build without using build-kit
    --help
        Display general usage information
END_USAGE
    exit 99
}

_totalStart=$( date '+%s' )
_resultsFile="/tmp/$$.results"
DOCKER_BUILDKIT=1
while ! test -z "${1}" ; do
    case "${1}" in
        --no-build-kit)
            DOCKER_BUILDKIT=0
            ;;
        --no-cache)
            noCache="--no-cache"
            ;;
        --verbose-build)
            progress="--progress plain"
            ;;
        --help)
            usage
            ;;
        *)
            usage "Unrecognized option"
            ;;
    esac
    shift
done

if test -z "${CI_COMMIT_REF_NAME}" ;then
    # shellcheck disable=SC2046 
    CI_PROJECT_DIR="$( cd $( dirname "${0}" )/.. || exit 97 ; pwd )"
    test -z "${CI_PROJECT_DIR}" && echo "Invalid call to dirname ${0}" && exit 97
fi
CI_SCRIPTS_DIR="${CI_PROJECT_DIR}/ci_scripts"
# shellcheck source=./ci_tools.lib.sh
. "${CI_SCRIPTS_DIR}/ci_tools.lib.sh"

banner "Building pingdownloader"
printf '%-45s|%10s|%7s\n' " IMAGE" " DURATION" " RESULT" > ${_resultsFile}
_start=$( date '+%s' )
DOCKER_BUILDKIT=${DOCKER_BUILDKIT} docker \
    image build \
    ${noCache} ${progress} \
    -t ${FOUNDATION_REGISTRY}/pingdownloader:${ciTag} \
    pingdownloader
_returnCode=${?}
_stop=$( date '+%s' )
_duration=$(( _stop - _start ))
if test ${_returnCode} -ne 0 ;
then
    returnCode=${_returnCode}
    _result="FAIL"
else
    _result="PASS"
fi
append_status "${_resultsFile}" ${_result} '%-44s|%10s|%7s' " pingdownloader" " ${_duration}" " ${_result}"

cat ${_resultsFile}
rm ${_resultsFile}
_totalStop=$( date '+%s' )
_totalDuration=$(( _totalStop - _totalStart ))
echo "Total duration: ${_totalDuration}s"
exit ${returnCode}