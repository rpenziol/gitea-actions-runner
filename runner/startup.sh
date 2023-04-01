#!/bin/bash
source logger.sh

RUNNER_ASSETS_DIR=${RUNNER_ASSETS_DIR:-/runnertmp}

# Let GitHub runner execute these hooks. These environment variables are used by GitHub's Runner as described here
# https://github.com/actions/runner/blob/main/docs/adrs/1751-runner-job-hooks.md
# Scripts referenced in the ACTIONS_RUNNER_HOOK_ environment variables must end in .sh or .ps1
# for it to become a valid hook script, otherwise GitHub will fail to run the hook
export ACTIONS_RUNNER_HOOK_JOB_STARTED=/etc/arc/hooks/job-started.sh
export ACTIONS_RUNNER_HOOK_JOB_COMPLETED=/etc/arc/hooks/job-completed.sh

if [ -n "${STARTUP_DELAY_IN_SECONDS}" ]; then
  log.notice "Delaying startup by ${STARTUP_DELAY_IN_SECONDS} seconds"
  sleep "${STARTUP_DELAY_IN_SECONDS}"
fi

# Hack due to the DinD volumes
if [ -z "${UNITTEST:-}" ] && [ -e ./externalstmp ]; then
  mkdir -p ./externals
  mv ./externalstmp/* ./externals/
fi

WAIT_FOR_DOCKER_SECONDS=${WAIT_FOR_DOCKER_SECONDS:-120}
if [[ "${DISABLE_WAIT_FOR_DOCKER}" != "true" ]] && [[ "${DOCKER_ENABLED}" == "true" ]]; then
    log.debug 'Docker enabled runner detected and Docker daemon wait is enabled'
    log.debug "Waiting until Docker is available or the timeout of ${WAIT_FOR_DOCKER_SECONDS} seconds is reached"
    if ! timeout "${WAIT_FOR_DOCKER_SECONDS}s" bash -c 'until docker ps ;do sleep 1; done'; then
      log.notice "Docker has not become available within ${WAIT_FOR_DOCKER_SECONDS} seconds. Exiting with status 1."
      exit 1
    fi
else
  log.notice 'Docker wait check skipped. Either Docker is disabled or the wait is disabled, continuing with entrypoint'
fi

# Docker ignores PAM and thus never loads the system environment variables that
# are meant to be set in every environment of every user. We emulate the PAM
# behavior by reading the environment variables without interpreting them.
#
# https://github.com/actions/actions-runner-controller/issues/1135
# https://github.com/actions/runner/issues/1703

# /etc/environment may not exist when running unit tests depending on the platform being used
# (e.g. Mac OS) so we just skip the mapping entirely
if [ -z "${UNITTEST:-}" ]; then
  mapfile -t env </etc/environment
fi

log.notice "WARNING LATEST TAG HAS BEEN DEPRECATED. SEE GITHUB ISSUE FOR DETAILS:"
log.notice "https://github.com/actions/actions-runner-controller/issues/2056"

update-status "Idle"
exec env -- "${env[@]}" ./runner daemon
