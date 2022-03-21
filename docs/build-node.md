
## 1 Configure external source chain

The use of an external chain can make the miner node more lightweight, and it can also make multiple miners connect to the same watch chain node, thereby avoiding repeated chain synchronization to a certain extent. However, due to the single point of failure in this method, that is to say, the failure of the external source chain node will cause multiple miners to fail to report the workload, so please try to use a better network device or cloud server to start the external source chain. At the same time, do not connect too many miners to the same chain. It is recommended to have less than 10 miners, otherwise the workload may not be reported due to congested transactions.

### 1.1 Configure watch chain service

1. Machine selection

The requirements of the Watch machine are as follows:
- The machine running the watch does not require SGX
- 500GB solid state drive
- It is recommended to use a stable network with public IP and fixed ports, which will directly affect the workload report of miner nodes
- Install node
- Recommend cloud server

2. Generate docker compose file

```shell
sudo spacex tools watch-chain
```

Generate a "watch-chain.yaml" configuration file in the current directory

3. Start watch chain

Start:
```shell
sudo docker-compose -f watch-chain.yaml up -d
```

Monitor:
```shell
sudo docker logs spacex-watch
```

4. Matters needing attention

- You can edit the "watch-chain.yaml" file to customize the watcher node
- The watcher node can provide ws and rpc services, the default port is 30888, 19933, 19944, pay attention to open ports

### 1.2 Miner node use external source chain

Set up to connect to other chains,default is "ws://127.0.0.1:19944"

- Command
```shell
sudo spacex config conn-chain {ws}
```
- Instance

Set up a chain connected to "ws://7.7.7.7:19944"

```shell
sudo spacex config conn-chain ws://7.7.7.7:19944
```

**If it is a node that is already running, the node needs to be restarted for the configuration of the external source chain to take effect**