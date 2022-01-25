async function genSdatamanagerConfig(config, outputCfg) {
    const sdatamanagerConfig = {
      chain: {
        account: config.identity.backup.address,
        endPoint: config.api.ws
      },
      storage: {
        endPoint: "http://127.0.0.1:12222"
      },
      ipfs: {
        endPoint: "http://127.0.0.1:5001"
      },
      node: {
        role: config.node.sdatamanager
      },
      telemetry: {
        endPoint: "#####.#####"
      },
      dataDir: "/data",
      scheduler: {
        minSrdRatio: 30,
        strategy: {
          existedFilesWeight: 0,
          newFilesWeight: 100
        }
      }
    }
  
    return {
      config: sdatamanagerConfig,
      paths: [{
        required: true,
        path: '/opt/mannheimnetwork/data/sdatamanager',
      }],
    }
  }
  
  async function genSdatamanagerComposeConfig(config) {
    return {
      image: 'mannheimnetwork/spacex-sdatamanager:latest',
      network_mode: 'host',
      restart: 'unless-stopped',
      environment: {
        SDATAMANAGER_CONFIG: "/config/sdatamanager_config.json",
      },
      volumes: [
        './sdatamanager:/config',
        '/opt/mannheimnetwork/data/sdatamanager:/data'
      ],
      logging: {
        driver: "json-file",
        options: {
          "max-size": "500m"
        }
      },
    }
  }
  
  module.exports = {
    genSdatamanagerConfig,
    genSdatamanagerComposeConfig,
  }
  
