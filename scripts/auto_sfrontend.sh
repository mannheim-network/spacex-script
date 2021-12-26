#!/bin/bash

source /opt/mannheim-network/spacex-script/scripts/utils.sh

auto_sfrontend_main()
{
    log_info "Start sfrontend auto upgrade task."
    local rnd=$(rand 1 200)
    log_info "Random sleep $rnd s"
    sleep $rnd
    while :
    do
        sleep 900
        log_info "New check Round"

        upgrade_docker_image spacex-sfrontend $node_type
        if [ $? -ne 0 ]; then
            continue
        fi

        log_info "Found a new sfrontend version, ready to upgrade..."
        log_success "Image has been updated"

        check_docker_status spacex-sfrontend
        if [ $? -eq 1 ]; then
            log_info "Service spacex sfrontend is not started now"
            log_success "Update completed"
            continue
        fi

        docker-compose -f $composeyaml up -d spacex-sfrontend
        if [ $? -ne 0 ]; then
            log_err "Start spacex-sfrontend failed"
            continue
        fi

        log_success "spacex sfrontend service has been updated"
        log_success "Update completed"
    done
}

auto_sfrontend_main