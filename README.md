# Spacex node
Official spacex node service for running Mannheim protocol.

## Preparation work
- Hardware requirements: 

  CPU must contain **SGX module**, and make sure the SGX function is turned on in the bios

- Operating system requirements:

  Ubuntu 16.04/18.04/20.04
  
- Other configurations

  - **Secure Boot** in BIOS needs to be turned off

## Install dependencies

### Install spacex service
```shell
sudo ./install.sh # Use 'sudo ./install.sh --registry cn' to accelerate installation in some areas
```

### Modify config.yaml
```shell
sudo spacex config set
```

### Run service

- Please make sure the following ports are not occupied before starting：
  - 30888 19933 19944 (for spacex chain)
  - 56666 (for spacex API)
  - 12222 (for spacex storage)
  - 5001 4001 37773 (for IPFS)

```shell
sudo spacex help
sudo spacex start
sudo spacex status
```

### Stop service

```shell
sudo spacex stop
```

## License

[GPL v3](LICENSE)
