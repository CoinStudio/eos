#!/usr/bin/env bats
load test_helper

SCRIPT_LOCATION="scripts/eosio_build.bash"
TEST_LABEL="[eosio_build_amazonlinux]"

[[ $ARCH == "Linux" ]] || exit 0 # Skip if we're not on linux
( [[ $NAME == "Amazon Linux AMI" ]] || [[ $NAME == "Amazon Linux" ]] ) || exit 0 # Exit 0 is required for pipeline

# A helper function is available to show output and status: `debug`

@test "${TEST_LABEL} > Testing Options" {
    run bash -c "./$SCRIPT_LOCATION -y -P -i /newhome -b /boost_tmp"
    [[ ! -z $(echo "${output}" | grep "CMAKE_INSTALL_PREFIX='/newhome/eosio/${EOSIO_VERSION}") ]] || exit
    [[ ! -z $(echo "${output}" | grep "@ /boost_tmp") ]] || exit
    [[ ! -z $(echo "${output}" | grep "EOSIO has been successfully built") ]] || exit
}

@test "${TEST_LABEL} > Testing Prompts" {
    ## All yes pass
    run bash -c "printf \"y\n%.0s\" {1..100} | ./$SCRIPT_LOCATION -P"
    [[ ! -z $(echo "${output}" | grep "EOSIO has been successfully built") ]] || exit
    ## First no shows "aborting"  
    run bash -c "printf \"n\n%.0s\" {1..2} | ./$SCRIPT_LOCATION -P"
    [[ "${output##*$'\n'}" =~ "- User aborted installation of required dependencies." ]] || exit
}

@test "${TEST_LABEL} > Testing CMAKE Install" {
    export CMAKE="$HOME/cmake" # file just needs to exist
    touch $CMAKE
    run bash -c "printf \"y\n%.0s\" {1..100} | ./$SCRIPT_LOCATION -P"
    [[ ! -z $(echo "${output}" | grep "CMAKE found @ ${CMAKE}") ]] || exit
    rm -f $CMAKE
    export CMAKE=
    run bash -c "printf \"y\n%.0s\" {1..100} | ./$SCRIPT_LOCATION -P"
    [[ ! -z $(echo "${output}" | grep "Installing CMAKE") ]] || exit
}

@test "${TEST_LABEL} > Testing Executions" {
    run bash -c "printf \"y\n%.0s\" {1..100} | ./$SCRIPT_LOCATION -P"
    ### Make sure deps are loaded properly
    [[ ! -z $(echo "${output}" | grep "Starting EOSIO Dependency Install") ]] || exit
    [[ ! -z $(echo "${output}" | grep "Executing: /usr/bin/yum -y update") ]] || exit
    if $NAME == "Amazon Linux" ]]; then
        [[ ! -z $(echo "${output}" | grep "libstdc++.*found!") ]] || exit
    elif [[ $NAME == "Amazon Linux AMI" ]]; then
        [[ ! -z $(echo "${output}" | grep "make.*found!") ]] || exit
    fi
    [[ ! -z $(echo "${output}" | grep "sudo.*NOT.*found.") ]] || exit
    [[ ! -z $(echo "${output}" | grep "Installing CMAKE") ]] || exit
    [[ ! -z $(echo "${output}" | grep ${HOME}.*/src/boost) ]] || exit
    [[ ! -z $(echo "${output}" | grep "Starting EOSIO Build") ]] || exit
    [[ ! -z $(echo "${output}" | grep "make -j${CPU_CORES}") ]] || exit
}

@test "${TEST_LABEL} > Testing root user run" {
    run bash -c "printf \"y\n%.0s\" {1..100} | ./$SCRIPT_LOCATION -P"
    [[ ! -z $(echo "${output}" | grep "User: root") ]] || exit
    export CURRENT_USER=test
    run bash -c "printf \"y\n%.0s\" {1..100} | ./$SCRIPT_LOCATION -P"
    [[ ! -z $(echo "${output}" | grep "User: test") ]] || exit
}