const _ = require('lodash')
const { getSharedChainConfig } = require('./chain-config.gen')

async function genStorageConfig(config, outputCfg) {
  var dataPaths = []

  for (i = 1; i <= 128; i++) {
    dataPaths.push("/opt/mannheim-network/disks/" + i)
  }

  const sworkerConfig = {
    base_path: "/opt/mannheim-network/data/storage",
    base_url: "http://127.0.0.1:12222/api/v0",
    chain: getSharedChainConfig(config),
    data_path: dataPaths,
    ipfs_url: "http://127.0.0.1:5001/api/v0",
  }
  return {
    config: storageConfig,
    paths: [{
      required: true,
      path: '/opt/mannheim-network/data/storage',
    }, {
      required: true,
      path: '/opt/mannheim-network/disks',
    }],
  }
}

async function genStorageComposeConfig(config) {
  let tempVolumes = [
    '/opt/mannheim-network/data/storage:/opt/mannheim-network/data/storage',
    '/opt/mannheim-network/disks:/opt/mannheim-network/disks',
    './storage:/config'
  ]

  return {
    image: 'mannheim-network/spacex-storage:latest',
    network_mode: 'host',
    devices: [
      '/dev/isgx:/dev/isgx'
    ],
    volumes: tempVolumes,
    environment: {
      ARGS: '-c /config/storage_config.json $EX_STORAGE_ARGS',
    },
    logging: {
      driver: "json-file",
      options: {
        "max-size": "500m"
      }
    },
  }
}

module.exports = {
  genStorageConfig,
  genStorageComposeConfig,
}
