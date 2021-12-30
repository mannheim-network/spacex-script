async function genSfrontendConfig(config, outputCfg) {
    const sfrontendConfig = {
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
        role: config.node.sfrontend
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
      config: sfrontendConfig,
      paths: [{
        required: true,
        path: '/opt/mannheim-network/data/sfrontend',
      }],
    }
  }
  
  async function genSfrontendComposeConfig(config) {
    return {
      image: 'mannheim-network/spacex-sfrontend:latest',
      network_mode: 'host',
      restart: 'unless-stopped',
      environment: {
        SFRONTEND_CONFIG: "/config/sfrontend_config.json",
      },
      volumes: [
        './sfrontend:/config',
        '/opt/mannheim-network/data/sfrontend:/data'
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
    genSfrontendConfig,
    genSfrontendComposeConfig,
  }
  
