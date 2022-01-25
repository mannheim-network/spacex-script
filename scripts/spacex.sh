#!/bin/bash

source /opt/mannheim-network/spacex-script/scripts/utils.sh
source /opt/mannheim-network/spacex-script/scripts/version.sh
source /opt/mannheim-network/spacex-script/scripts/config.sh
source /opt/mannheim-network/spacex-script/scripts/tools.sh
export EX_STORAGE_ARGS=''


start()
{
    if [ ! -f "$composeyaml" ]; then
        log_err "No configuration file, please set config"
        exit 1
    fi

    if [ x"$1" = x"" ]; then
        log_info "Start spacex"

        if [ -f "$builddir/api/api_config.json" ]; then
            local chain_ws_url=`cat $builddir/api/api_config.json | jq .chain_ws_url`
            if [ x"$chain_ws_url" == x"\"ws://127.0.0.1:19944\"" ]; then
                start_chain
                if [ $? -ne 0 ]; then
                    docker-compose -f $composeyaml down
                    exit 1
                fi
            else
                log_info "API will connect to other chain: ${chain_ws_url}"
            fi
        else
            start_chain
            if [ $? -ne 0 ]; then
                docker-compose -f $composeyaml down
                exit 1
            fi
        fi

        start_storage
        if [ $? -ne 0 ]; then
            docker-compose -f $composeyaml down
            exit 1
        fi

        start_api
        if [ $? -ne 0 ]; then
            docker-compose -f $composeyaml down
            exit 1
        fi

        start_sdatamanager
        if [ $? -ne 0 ]; then
            docker-compose -f $composeyaml down
            exit 1
        fi

        start_ipfs
        if [ $? -ne 0 ]; then
            docker-compose -f $composeyaml down
            exit 1
        fi

        log_success "Start spacex success"
        return 0
    fi

    if [ x"$1" = x"chain" ]; then
        log_info "Start chain service"
        start_chain
        if [ $? -ne 0 ]; then
            exit 1
        fi
        log_success "Start chain service success"
        return 0
    fi

    if [ x"$1" = x"api" ]; then
        log_info "Start api service"
        start_api
        if [ $? -ne 0 ]; then
            exit 1
        fi
        log_success "Start api service success"
        return 0
    fi

    if [ x"$1" = x"storage" ]; then
        log_info "Start storage service"
        shift
        start_storage $@
        if [ $? -ne 0 ]; then
            exit 1
        fi
        log_success "Start storage service success"
        return 0
    fi

    if [ x"$1" = x"sdatamanager" ]; then
        log_info "Start sdatamanager service"
        start_sdatamanager
        if [ $? -ne 0 ]; then
            exit 1
        fi
        log_success "Start sdatamanager service success"
        return 0
    fi

    if [ x"$1" = x"ipfs" ]; then
        log_info "Start ipfs service"
        start_ipfs
        if [ $? -ne 0 ]; then
            exit 1
        fi
        log_success "Start ipfs service success"
        return 0
    fi

    help
    return 1
}

stop()
{
    if [ x"$1" = x"" ]; then
        log_info "Stop spacex"
        stop_chain
        stop_sdatamanager
        stop_api
        stop_storage
        stop_ipfs
        log_success "Stop spacex success"
        return 0
    fi

    if [ x"$1" = x"chain" ]; then
        log_info "Stop chain service"
        stop_chain
        log_success "Stop chain service success"
        return 0
    fi

    if [ x"$1" = x"api" ]; then
        log_info "Stop api service"
        stop_api
        log_success "Stop api service success"
        return 0
    fi

    if [ x"$1" = x"storage" ]; then
        log_info "Stop storage service"
        stop_storage
        log_success "Stop storage service success"
        return 0
    fi

    if [ x"$1" = x"sdatamanager" ]; then
        log_info "Cannot stop the sdatamanager service alone, this will affect your benefits"
        return 0
    fi

    if [ x"$1" = x"ipfs" ]; then
        log_info "Stop ipfs service"
        stop_ipfs
        log_success "Stop ipfs service success"
        return 0
    fi

    help
    return 1
}

start_chain()
{
    if [ ! -f "$composeyaml" ]; then
        log_err "No configuration file, please set config"
        return 1
    fi

    check_docker_status spacex
    if [ $? -eq 0 ]; then
        return 0
    fi

    local config_file=$builddir/chain/chain_config.json
    if [ x"$config_file" = x"" ]; then
        log_err "Please give right chain config file"
        return 1
    fi

    local chain_port=`cat $config_file | jq .port`

    if [ x"$chain_port" = x"" ] || [ x"$chain_port" = x"null" ]; then
        chain_port=30888
    fi

    if [ $chain_port -lt 0 ] || [ $chain_port -gt 65535 ]; then
        log_err "The range of chain port is 0 ~ 65535"
        return 1
    fi

    local res=0
    check_port $chain_port
    res=$(($?|$res))
    check_port 19933
    res=$(($?|$res))
    check_port 19944
    res=$(($?|$res))
    if [ $res -ne 0 ]; then
        return 1
    fi

    docker-compose -f $composeyaml up -d spacex
    if [ $? -ne 0 ]; then
        log_err "Start spacex-api failed"
        return 1
    fi
    return 0
}

stop_chain()
{
    check_docker_status spacex
    if [ $? -ne 1 ]; then
        log_info "Stopping spacex chain service"
        docker stop spacex &>/dev/null
        docker rm spacex &>/dev/null
    fi
    return 0
}


### start storage ###
start_storage()
{
    if [ ! -f "$composeyaml" ]; then
        log_err "No configuration file, please set config"
        return 1
    fi

    if [ -d "$builddir/storage" ]; then
        local a_or_b=`cat $basedir/etc/storage.ab`
        check_docker_status spacex-storage-$a_or_b
        if [ $? -eq 0 ]; then
            return 0
        fi

        check_port 12222
        if [ $? -ne 0 ]; then
            return 1
        fi

        if [ -f "$scriptdir/install_sgx.sh" ]; then
            $scriptdir/install_sgx.sh
            if [ $? -ne 0 ]; then
                log_err "Install sgx dirver failed"
                return 1
            fi
        fi

        if [ ! -e "/dev/isgx" ]; then
            log_err "Your device can't install sgx dirver, please check your CPU and BIOS to determine if they support SGX."
            return 1
        fi
        EX_STORAGE_ARGS=$@ docker-compose -f $composeyaml up -d spacex-storage-$a_or_b
        if [ $? -ne 0 ]; then
            log_err "Start spacex-storage-$a_or_b failed"
            return 1
        fi
    fi
    return 0
}

stop_storage()
{
    check_docker_status spacex-storage-a
    if [ $? -ne 1 ]; then
        log_info "Stopping spacex storage A service"
        docker stop spacex-storage-a &>/dev/null
        docker rm spacex-storage-a &>/dev/null
    fi

    check_docker_status spacex-storage-b
    if [ $? -ne 1 ]; then
        log_info "Stopping spacex storage B service"
        docker stop spacex-storage-b &>/dev/null
        docker rm spacex-storage-b &>/dev/null
    fi

    return 0
}

start_api()
{
    if [ ! -f "$composeyaml" ]; then
        log_err "No configuration file, please set config"
        return 1
    fi

    if [ -d "$builddir/storage" ]; then
        check_docker_status spacex-api
        if [ $? -eq 0 ]; then
            return 0
        fi

        check_port 56666
        if [ $? -ne 0 ]; then
            return 1
        fi

        docker-compose -f $composeyaml up -d spacex-api
        if [ $? -ne 0 ]; then
            log_err "Start spacex-api failed"
            return 1
        fi
    fi
    return 0
}

stop_api()
{
    check_docker_status spacex-api
    if [ $? -ne 1 ]; then
        log_info "Stopping spacex API service"
        docker stop spacex-api &>/dev/null
        docker rm spacex-api &>/dev/null
    fi
    return 0
}

start_sdatamanager()
{
    if [ ! -f "$composeyaml" ]; then
        log_err "No configuration file, please set config"
        return 1
    fi

    if [ -d "$builddir/sdatamanager" ]; then
        check_docker_status spacex-sdatamanager
        if [ $? -eq 0 ]; then
            return 0
        fi

        docker-compose -f $composeyaml up -d spacex-sdatamanager
        if [ $? -ne 0 ]; then
            log_err "Start spacex-sdatamanager failed"
            return 1
        fi

        local upgrade_pid=$(ps -ef | grep "/opt/mannheim-network/spacex-script/scripts/auto_sdatamanager.sh" | grep -v grep | awk '{print $2}')
        if [ x"$upgrade_pid" != x"" ]; then
            kill -9 $upgrade_pid
        fi

        if [ -f "$scriptdir/auto_sdatamanager.sh" ]; then
            nohup $scriptdir/auto_sdatamanager.sh &>$basedir/auto_sdatamanager.log &
            if [ $? -ne 0 ]; then
                log_err "Start spacex-sdatamanager upgrade failed"
                return 1
            fi
        fi
    fi
    return 0
}

stop_sdatamanager()
{
    local upgrade_pid=$(ps -ef | grep "/opt/mannheim-network/spacex-script/scripts/auto_sdatamanager.sh" | grep -v grep | awk '{print $2}')
	if [ x"$upgrade_pid" != x"" ]; then
		kill -9 $upgrade_pid
	fi

    check_docker_status spacex-sdatamanager
    if [ $? -ne 1 ]; then
        log_info "Stopping spacex sdatamanager service"
        docker stop spacex-sdatamanager &>/dev/null
        docker rm spacex-sdatamanager &>/dev/null
    fi
    return 0
}

start_ipfs()
{
    if [ ! -f "$composeyaml" ]; then
        log_err "No configuration file, please set config"
        return 1
    fi

    if [ -d "$builddir/ipfs" ]; then
        check_docker_status ipfs
        if [ $? -eq 0 ]; then
            return 0
        fi

        local res=0
        check_port 4001
        res=$(($?|$res))
        check_port 5001
        res=$(($?|$res))
        check_port 37773
        res=$(($?|$res))
        if [ $res -ne 0 ]; then
            return 1
        fi

        docker-compose -f $composeyaml up -d ipfs
        if [ $? -ne 0 ]; then
            log_err "Start ipfs failed"
            return 1
        fi
    fi
    return 0
}

stop_ipfs()
{
    check_docker_status ipfs
    if [ $? -ne 1 ]; then
        log_info "Stopping ipfs service"
        docker stop ipfs &>/dev/null
        docker rm ipfs &>/dev/null
    fi
    return 0
}





reload() {
    if [ x"$1" = x"" ]; then
        log_info "Reload all service"
        stop
        start
        log_success "Reload all service success"
        return 0
    fi

    if [ x"$1" = x"chain" ]; then
        log_info "Reload chain service"

        stop_chain
        start_chain

        log_success "Reload chain service success"
        return 0
    fi

    if [ x"$1" = x"api" ]; then
        log_info "Reload api service"

        stop_api
        start_api

        log_success "Reload api service success"
        return 0
    fi

    if [ x"$1" = x"storage" ]; then
        log_info "Reload storage service"

        stop_storage
        shift
        start_storage $@

        log_success "Reload storage service success"
        return 0
    fi

    if [ x"$1" = x"sdatamanager" ]; then
        log_info "Reload sdatamanager service"

        stop_sdatamanager
        start_sdatamanager

        log_success "Reload sdatamanager service success"
        return 0
    fi

    if [ x"$1" = x"ipfs" ]; then
        log_info "Reload ipfs service"

        stop_ipfs
        start_ipfs

        log_success "Reload ipfs service success"
        return 0
    fi

    help
    return 1
}

########################################logs################################################

logs_help()
{
cat << EOF
Usage: spacex logs [OPTIONS] {chain|api|storage|storage-a|storage-b|sdatamanager|ipfs}

Fetch the logs of a service

Options:
      --details        Show extra details provided to logs
  -f, --follow         Follow log output
      --since string   Show logs since timestamp (e.g. 2012-01-02T13:23:37) or relative (e.g. 42m for 42 minutes)
      --tail string    Number of lines to show from the end of the logs (default "all")
  -t, --timestamps     Show timestamps
      --until string   Show logs before a timestamp (e.g. 2012-01-02T13:23:37) or relative (e.g. 42m for 42 minutes)
EOF
}

logs()
{
    local name="${!#}"
    local array=( "$@" )
    local logs_help_flag=0
    unset "array[${#array[@]}-1]"

    if [ x"$name" == x"chain" ]; then
        check_docker_status spacex
        if [ $? -eq 1 ]; then
            log_info "Service spacex chain is not started now"
            return 0
        fi
        docker logs ${array[@]} -f spacex
        logs_help_flag=$?
    elif [ x"$name" == x"api" ]; then
        check_docker_status spacex-api
        if [ $? -eq 1 ]; then
            log_info "Service spacex API is not started now"
            return 0
        fi
        docker logs ${array[@]} -f spacex-api
        logs_help_flag=$?
    elif [ x"$name" == x"storage" ]; then
        local a_or_b=`cat $basedir/etc/storage.ab`
        check_docker_status spacex-storage-$a_or_b
        if [ $? -eq 1 ]; then
            log_info "Service spacex storage is not started now"
            return 0
        fi
        docker logs ${array[@]} -f spacex-storage-$a_or_b
        logs_help_flag=$?
    elif [ x"$name" == x"ipfs" ]; then
        check_docker_status ipfs
        if [ $? -eq 1 ]; then
            log_info "Service ipfs is not started now"
            return 0
        fi
        docker logs ${array[@]} -f ipfs
        logs_help_flag=$?
    elif [ x"$name" == x"sdatamanager" ]; then
        check_docker_status spacex-sdatamanager
        if [ $? -eq 1 ]; then
            log_info "Service spacex sdatamanager is not started now"
            return 0
        fi
        docker logs ${array[@]} -f spacex-sdatamanager
        logs_help_flag=$?
    elif [ x"$name" == x"storage-a" ]; then
        check_docker_status spacex-storage-a
        if [ $? -eq 1 ]; then
            log_info "Service spacex storage-a is not started now"
            return 0
        fi
        docker logs ${array[@]} -f spacex-storage-a
        logs_help_flag=$?
    elif [ x"$name" == x"storage-b" ]; then
        check_docker_status spacex-storage-b
        if [ $? -eq 1 ]; then
            log_info "Service spacex storage-b is not started now"
            return 0
        fi
        docker logs ${array[@]} -f spacex-storage-b
        logs_help_flag=$?
    elif [ x"$name" == x"sdatamanager-upshell" ]; then
		local upgrade_pid=$(ps -ef | grep "/opt/mannheim-network/spacex-script/scripts/auto_sdatamanager.sh" | grep -v grep | awk '{print $2}')
		if [ x"$upgrade_pid" == x"" ]; then
			log_info "Service spacex sdatamanager upgrade shell is not started now"
			return 0
		fi
		tail -f $basedir/auto_sdatamanager.log
    else
        logs_help
        return 1
    fi

    if [ $logs_help_flag -ne 0 ]; then
        logs_help
        return 1
    fi
}


#######################################status################################################

status()
{
    if [ x"$1" == x"chain" ]; then
        chain_status
    elif [ x"$1" == x"api" ]; then
        api_status
    elif [ x"$1" == x"storage" ]; then
        storage_status
    elif [ x"$1" == x"sdatamanager" ]; then
        sdatamanager_status
    elif [ x"$1" == x"ipfs" ]; then
        ipfs_status
    elif [ x"$1" == x"" ]; then
        all_status
    else
        help
    fi
}

all_status()
{
    local chain_status="stop"
    local api_status="stop"
    local storage_status="stop"
    local sdatamanager_status="stop"
    local ipfs_status="stop"

    check_docker_status spacex
    local res=$?
    if [ $res -eq 0 ]; then
        chain_status="running"
    elif [ $res -eq 2 ]; then
        chain_status="exited"
    fi

    check_docker_status spacex-api
    res=$?
    if [ $res -eq 0 ]; then
        api_status="running"
    elif [ $res -eq 2 ]; then
        api_status="exited"
    fi

    local a_or_b=`cat $basedir/etc/storage.ab`
    check_docker_status spacex-storage-$a_or_b
    res=$?
    if [ $res -eq 0 ]; then
        storage_status="running"
    elif [ $res -eq 2 ]; then
        storage_status="exited"
    fi

    check_docker_status spacex-sdatamanager
    res=$?
    if [ $res -eq 0 ]; then
        sdatamanager_status="running"
    elif [ $res -eq 2 ]; then
        sdatamanager_status="exited"
    fi

    check_docker_status ipfs
    res=$?
    if [ $res -eq 0 ]; then
        ipfs_status="running"
    elif [ $res -eq 2 ]; then
        ipfs_status="exited"
    fi

cat << EOF
-----------------------------------------
    Service                    Status
-----------------------------------------
    chain                      ${chain_status}
    api                        ${api_status}
    storage                    ${storage_status}
    sdatamanager                   ${sdatamanager_status}
    ipfs                       ${ipfs_status}
-----------------------------------------
EOF
}

chain_status()
{
    local chain_status="stop"

    check_docker_status spacex
    local res=$?
    if [ $res -eq 0 ]; then
        chain_status="running"
    elif [ $res -eq 2 ]; then
        chain_status="exited"
    fi

cat << EOF
-----------------------------------------
    Service                    Status
-----------------------------------------
    chain                      ${chain_status}
-----------------------------------------
EOF
}

api_status()
{
    local api_status="stop"

    check_docker_status spacex-api
    res=$?
    if [ $res -eq 0 ]; then
        api_status="running"
    elif [ $res -eq 2 ]; then
        api_status="exited"
    fi

cat << EOF
-----------------------------------------
    Service                    Status
-----------------------------------------
    api                        ${api_status}
-----------------------------------------
EOF
}

storage_status()
{
    local storage_a_status="stop"
    local storage_b_status="stop"
    local a_or_b=`cat $basedir/etc/storage.ab`

    check_docker_status spacex-storage-a
    local res=$?
    if [ $res -eq 0 ]; then
        storage_a_status="running"
    elif [ $res -eq 2 ]; then
        storage_a_status="exited"
    fi

    check_docker_status spacex-storage-b
    res=$?
    if [ $res -eq 0 ]; then
        storage_b_status="running"
    elif [ $res -eq 2 ]; then
        storage_b_status="exited"
    fi

cat << EOF
-----------------------------------------
    Service                    Status
-----------------------------------------
    storage-a                  ${storage_a_status}
    storage-b                  ${storage_b_status}
    main-progress              ${a_or_b}
-----------------------------------------
EOF
}

sdatamanager_status()
{
    local sdatamanager_status="stop"
    local upgrade_shell_status="stop"

    check_docker_status spacex-sdatamanager
    res=$?
    if [ $res -eq 0 ]; then
        sdatamanager_status="running"
    elif [ $res -eq 2 ]; then
        sdatamanager_status="exited"
    fi

    local upgrade_pid=$(ps -ef | grep "/opt/mannheim-network/spacex-script/scripts/auto_sdatamanager.sh" | grep -v grep | awk '{print $2}')
	if [ x"$upgrade_pid" != x"" ]; then
		upgrade_shell_status="running->${upgrade_pid}"
	fi


cat << EOF
-----------------------------------------
    Service                    Status
-----------------------------------------
    sdatamanager                   ${sdatamanager_status}
    upgrade-shell              ${upgrade_shell_status}
-----------------------------------------
EOF
}

ipfs_status()
{
    local ipfs_status="stop"

    check_docker_status ipfs
    res=$?
    if [ $res -eq 0 ]; then
        ipfs_status="running"
    elif [ $res -eq 2 ]; then
        ipfs_status="exited"
    fi

cat << EOF
-----------------------------------------
    Service                    Status
-----------------------------------------
    ipfs                       ${ipfs_status}
-----------------------------------------
EOF
}

######################################main entrance############################################

help()
{
cat << EOF
Usage:
    help                                                             show help information
    version                                                          show version

    start {chain|api|storage|sdatamanager|ipfs}                          start all spacex service
    stop {chain|api|storage|sdatamanager|ipfs}                           stop all spacex service or stop one service

    status {chain|api|storage|sdatamanager|ipfs}                         check status or reload one service status
    reload {chain|api|storage|sdatamanager|ipfs}                         reload all service or reload one service
    logs {chain|api|storage|storage-a|storage-b|sdatamanager|ipfs}       track service logs, ctrl-c to exit. use 'spacex logs help' for more details

    tools {...}                                                      use 'spacex tools help' for more details
    config {...}                                                     configuration operations, use 'spacex config help' for more details
EOF
}

case "$1" in
    version)
        version
        ;;
    start)
        shift
        start $@
        ;;
    stop)
        stop $2
        ;;
    reload)
        shift
        reload $@
        ;;
    status)
        status $2
        ;;
    logs)
        shift
        logs $@
        ;;
    config)
        shift
        config $@
        ;;
    tools)
        shift
        tools $@
        ;;
    *)
        help
esac
exit 0
