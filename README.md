<p align="center">
  <a>
    <img src="https://ipfs.io/ipfs/QmXHwxSJEMhdDR1UFtkEiUM9bv3Wd731FjhTVKjN2SY19V?filename=spacex_icon.png" alt="Mannheim"/ width="30%" height="30%">
  </a>
</p>

<h1 align="center">RUBIK</h1>

The repo of spacex-script used to automate processes to configure and run Mannheim testnet **RUBIK**, the script is a list of commands that are executed by spacex program.

# 🚀Getting Started
Official Guardian/Miner Node service for running Mannheim protocol.

## 🧰Preparation work

| Requirements          |                                                              |
| --------------------- | ------------------------------------------------------------ |
| ⚙️Hardware             | CPU must contain **SGX module**, and make sure the SGX function is turned on in the bios |
| ⚙️Operating system     | Ubuntu 16.04/18.04/20.04                                     |
| ⚙️Other configurations | **Secure Boot** in BIOS needs to be turned off               |



## 🛠️Install dependencies

### Install Rubik service
```shell
sudo ./install.sh # Use 'sudo ./install.sh --registry cn' to accelerate installation in some areas
```

### Modify config.yaml
```shell
sudo spacex config set
```

### Run service

- Please make sure the following ports are not occupied before starting：
  - 30888 19933 19944 (for chain )
  - 56666 (for rubik API)
  - 12222 (for rubik storage)
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

### 🛡️How to become a guardian?

The Guardian node is the initiator of and in charge of the Group, participating in block generation. Effective storage of the miner can be clustered on the Guardian to participate in the block generation competition. Meantime, the organizers of the Guardians are accountable for the Group's strategy of receiving meaningful files to improve the Group's overall competitiveness. Since the Guardian node itself does not store files, support for SGX is not necessary. 

For details, please refer to [this page](docs/guardian.md).

### 💎How to become a miner?

The Miner node acts as the storage provider in Group. There can be multiple Miner nodes in a Group, and their effective storage can be clustered on Owner to participate in block generation competition. Since Miner nodes store files and perform trusted quantification, support for SGX is necessary. The Miner node is connected to its account through configuring backup files.

For details, please refer to [this page](docs/miner.md).

## License

[GPL v3](LICENSE)
