#!/bin/bash

source /opt/mannheim-network/spacex-script/scripts/utils.sh

version()
{
    printf "Node version: ${node_version}\n"
    printf "Node network: ${node_type}\n"
    local mode=`cat $basedir/etc/mode.conf`
    printf "Node mode: ${mode}\n"
    inner_storage_version
    inner_docker_version
}

inner_storage_version()
{
    local storage_config_file=$builddir/storage/storage_config.json
    if [ ! -f "$storage_config_file" ]; then
        return
    fi

    storage_base_url=`cat $storage_config_file | jq .base_url`

    if [ x"$storage_base_url" = x"" ]; then
        return
    fi

    storage_base_url=`echo "$storage_base_url" | sed -e 's/^"//' -e 's/"$//'`

    local id_info=`curl --max-time 30 $storage_base_url/enclave/id_info 2>/dev/null`
    if [ x"$id_info" = x"" ]; then
        return
    fi
    printf "Storage version:\n${id_info}\n"
}

inner_docker_version()
{
    local chain_image=(`docker images | grep '^\b'mannheim-network/spacex'\b ' | grep 'latest'`)
    chain_image=${chain_image[2]}

    local storage_image=(`docker images | grep '^\b'mannheim-network/spacex-storage'\b ' | grep 'latest'`)
    storage_image=${storage_image[2]}

    local cgen_image=(`docker images | grep '^\b'mannheim-network/config-generator'\b ' | grep 'latest'`)
    cgen_image=${cgen_image[2]}

    local ipfs_image=(`docker images | grep '^\b'mannheim-network/go-ipfs'\b ' | grep 'latest'`)
    ipfs_image=${ipfs_image[2]}

    local api_image=(`docker images | grep '^\b'mannheim-network/spacex-api'\b ' | grep 'latest'`)
    api_image=${api_image[2]}

    local sdatamanager_image=(`docker images | grep '^\b'mannheim-network/spacex-sdatamanager'\b ' | grep 'latest'`)
    sdatamanager_image=${sdatamanager_image[2]}

    printf "Docker images:\n"
    printf "  Chain: ${chain_image}\n"
    printf "  Storage: ${storage_image}\n"
    printf "  C-gen: ${cgen_image}\n"
    printf "  IPFS: ${ipfs_image}\n"
    printf "  API: ${api_image}\n"
    printf "  Sdatamanager: ${sdatamanager_image}\n"
}
