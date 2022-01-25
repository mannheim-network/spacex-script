#!/bin/bash

source /opt/mannheimnetwork/spacex-script/scripts/utils.sh

auto_sdatamanager_main()
{
    log_info "Start sdatamanager auto upgrade task."
    local rnd=$(rand 1 200)
    log_info "Random sleep $rnd s"
    sleep $rnd
    while :
    do
        sleep 900
        log_info "New check Round"

        upgrade_docker_image spacex-sdatamanager $node_type
        if [ $? -ne 0 ]; then
            continue
        fi

        log_info "Found a new sdatamanager version, ready to upgrade..."
        log_success "Image has been updated"

        check_docker_status spacex-sdatamanager
        if [ $? -eq 1 ]; then
            log_info "Service spacex sdatamanager is not started now"
            log_success "Update completed"
            continue
        fi

        docker-compose -f $composeyaml up -d spacex-sdatamanager
        if [ $? -ne 0 ]; then
            log_err "Start spacex-sdatamanager failed"
            continue
        fi

        log_success "spacex sdatamanager service has been updated"
        log_success "Update completed"
    done
}

auto_sdatamanager_main