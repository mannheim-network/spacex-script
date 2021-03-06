#!/bin/bash

source /opt/mannheimworld/spacex-script/scripts/utils.sh

config_help()
{
cat << EOF
Spacex config usage:
    help                                  show help information
    show                                  show configurations
    set                                   set and generate new configurations
    generate                              generate new configurations
    chain-port {port}                     set chain port and generate new configuration, default is 30888
    conn-chain {ws}                       set conneted chain ws and generate new configuration, default is ws://127.0.0.1:19944
EOF
}

config_show()
{
    cat $configfile  | sed 's#isolation#bridge#g' | sed -e 's#owner#guardian#g' | sed -e 's#member#miner#g'
}

config_set_all()
{
    local chain_name=""
    read -p "Enter spacex script name (default:spacex-script): " chain_name
    chain_name=`echo "$chain_name"`
    if [ x"$chain_name" == x"" ]; then
        chain_name="spacex-script"
    fi
    local tt=$(rand 100000 999999)
    chain_name="$chain_name-$tt"
    sed -i "22c \\  name: \"$chain_name\"" $configfile &>/dev/null
    log_success "Set spacex script name: '$chain_name' successfully"

    local mode=""
    while true
    do
        read -p "Enter spacex script mode from 'bridge/guardian/miner' (default:bridge): " mode
        mode=`echo "$mode"`
        if [ x"$mode" == x"" ]; then
            mode="bridge"
            break
        elif [ x"$mode" == x"bridge" ] || [ x"$mode" == x"guardian" ] || [ x"$mode" == x"miner" ]; then
            break
        else
            log_err "Input error, please input bridge/guardian/miner"
        fi
    done

    if [ x"$mode" == x"bridge" ]; then
        mode="isolation"
    fi

    if [ x"$mode" == x"guardian" ]; then
        mode="owner"
    fi

    if [ x"$mode" == x"miner" ]; then
        mode="member"
    fi


    if [ x"$mode" == x"owner" ]; then
        sed -i '4c \\  chain: "authority"' $configfile &>/dev/null
        sed -i '6c \\  storage: "disable"' $configfile &>/dev/null
        sed -i '8c \\  sdatamanager: "disable"' $configfile &>/dev/null
        sed -i '10c \\  ipfs: "disable"' $configfile &>/dev/null
        local old_mode=`cat $basedir/etc/mode.conf`
        sed -i 's/'$old_mode'/'$mode'/g' $basedir/etc/mode.conf
        log_success "Set spacex script mode: guardian successfully"
        log_success "Set configurations successfully"
        config_generate
        return
    elif [ x"$mode" == x"isolation" ]; then
        sed -i '4c \\  chain: "authority"' $configfile &>/dev/null
        sed -i '6c \\  storage: "enable"' $configfile &>/dev/null
        sed -i '8c \\  sdatamanager: "'$mode'"' $configfile &>/dev/null
        sed -i '10c \\  ipfs: "enable"' $configfile &>/dev/null
        log_success "Set spacex script mode: bridge successfully"
    else
        sed -i '4c \\  chain: "full"' $configfile &>/dev/null
        sed -i '6c \\  storage: "enable"' $configfile &>/dev/null
        sed -i '8c \\  sdatamanager: "'$mode'"' $configfile &>/dev/null
        sed -i '10c \\  ipfs: "enable"' $configfile &>/dev/null
        log_success "Set spacex script mode: miner successfully"
    fi

    local old_mode=`cat $basedir/etc/mode.conf`
    sed -i 's/'$old_mode'/'$mode'/g' $basedir/etc/mode.conf

    local identity_backup=""
    while true
    do
        if [ x"$mode" == x"member" ]; then
            read -p "Enter the backup of miner account: " identity_backup
        else
            read -p "Enter the backup of miner account: " identity_backup
        fi

        identity_backup=`echo "$identity_backup"`
        if [ x"$identity_backup" != x"" ]; then
            break
        else
            log_err "Input error, backup can't be empty"
        fi
    done
    sed -i "15c \\  backup: '$identity_backup'" $configfile &>/dev/null
    log_success "Set backup successfully"

    local identity_password=""
    while true
    do
        if [ x"$mode" == x"member" ]; then
            read -p "Enter the password of miner account: " identity_password
        else
            read -p "Enter the password of miner account: " identity_password
        fi

        identity_password=`echo "$identity_password"`
        if [ x"$identity_password" != x"" ]; then
            break
        else
            log_err "Input error, password can't be empty"
        fi
    done
    sed -i '17c \\  password: "'$identity_password'"' $configfile &>/dev/null

    log_success "Set password successfully"
    log_success "Set configurations successfully"

    # Generate configurations
    config_generate
}

config_conn_chain()
{
    if [ x"$1" = x"" ]; then
        log_err "Please give conneted chain ws."
        config_help
        return 1
    fi

    sed -i '28c \\  ws: "'$1'"' $configfile &>/dev/null
    log_success "Set connected chain ws '$1' successfully"
    config_generate
}

config_chain_port()
{
    if [ x"$1" = x"" ]; then
        log_err "Please give right chain port."
        config_help
        return 1
    fi
    sed -i "24c \\  port: '$1'" $configfile &>/dev/null
    log_success "Set chain port '$1' successfully"
    config_generate
}

config_generate()
{
    log_info "Start generate configurations and docker compose file"
    local cg_image="mannheimworld/config-generator:latest"

    if [ ! -f "$configfile" ]; then
        log_err "config.yaml doesn't exists!"
        exit 1
    fi

    rm -rf $builddir
    mkdir -p $builddir

    cp -f $configfile $builddir/
    local cidfile=`mktemp`
    rm $cidfile
    docker run --cidfile $cidfile -i --workdir /opt/output -v $builddir:/opt/output $cg_image node /opt/app/index.js
    local res="$?"
    local cid=`cat $cidfile`
    docker rm $cid

    if [ "$res" -ne "0" ]; then
        log_err "Failed to generate application configs, please check your config.yaml"
        exit 1
    fi

<<'COMMENT'
invalid_paths=0
while IFS= read -r line || [ -n "$line" ]; do
    mark=${line:0:1}
    path=${line:2}
    if [ ! -e "$path" ]; then
        if [ "$mark" == "|" ]; then
            log_warn "$path doesn't exist!"
        elif [ "$mark" == "+" ]; then
            log_err "$path doesn't exist!"
            invalid_paths=1
        fi
    fi
done <$builddir/.tmp/.paths

if [ $invalid_paths -ne "0" ]; then
    log_err "some paths is not valid, please check your config!"
    exit 1
fi

COMMENT

    rm -f $builddir/config.yaml
    cp -r $builddir/.tmp/* $builddir/
    rm -rf $builddir/.tmp
    chown -R root:root $builddir
    chmod -R 0600 $builddir
    chmod 0600 $configfile

    log_success "Configurations generated at: $builddir"
}

config()
{
    case "$1" in
        show)
            config_show
            ;;
        set)
            config_set_all
            ;;
        conn-chain)
            shift
            config_conn_chain $@
            ;;
        chain-port)
            shift
            config_chain_port $@
            ;;
        generate)
            config_generate
            ;;
        *)
            config_help
    esac
}
