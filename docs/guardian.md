## 1. Overview

### 1.1 Node Responsibility

The Guardian node is the initiator of and in charge of the Group, participating in block generation. Effective storage of the Member can be clustered on the Guardian to participate in the block generation competition. Meantime, the organizers of the Guardian node are accountable for the Group's strategy of receiving meaningful files to improve the Group's overall competitiveness. Since the Guardian node itself does not store files, support for SGX is not necessary. The Guardian node account is connected to block node through the session key. 

## 2. Ready to Deploy

> Note: The account of Spacex mainnet starting with the letter 'c'.

### 2.1 Create your Accounts

The Guardian node participates in the block generation competition. It needs to create accounts and be bonded to the Controller&Stash account group. 

Notices:

* The account should be unique and cannot be any other account for Guardian, Miner or Bridge;
* Be sure to reserve a small number of HEIMs not locked in the Controller&Stash for sending transactions (about 1 HEIM).

### 2.2 Create and manager group

#### 2.2.1 Create group

> The account to create the Group must be a bound Stash account

Enter Spacex APPS, select 'Benefit', click on 'Create group',select the Guardian **Stash account**, click on 'Create', enter the password of the stash account and click on 'Sign and Submit' to send the transaction and create Group.

#### 2.2.2 Lockup HEIM to reduce the fee of the work report

**The work report in mainnet requires handling fees.** Under normal circumstances, each Member will perform 24 workload reporting transactions per day, which brings a lot of handling fees. For this reason, the Spacex network provides a Benefit module that exempts workload reporting fees. Group guardians can reduce or waive member handling fees by locking HEIMs. **Each Member** needs to lock 18HEIM for fee reduction. However, considering the unstable reporting of workload, it is recommended to lock 24HEIM~30HEIM to ensure that the fee is completely free. For example, suppose your Group is ready to have 6 Members ready to join, then lock 30*6=180HEIM

Enter [Spacex APPS](http://rubik.mannheim.world/#/explorer), select 'Account', select the 'Benefit' module, find the group created before, and click 'Increase lockup'.

Enter the number of HEIMs that **need to be added**, and sign the transaction.

### 2.3 Download Spacex Node Package

a. Download

```plain
wget https://github.com/mannheim-network/spacex-script/archive/refs/heads/testnet.zip
```
b. Unzip
```plain
tar -xvf testnet.zip
```
c. Go to package directory
```plain
cd spacex-script-testnet
```

### 2.4 Install Spacex Service

Notice:

* The program will be installed under /opt/mannheimworld, please make sure this path is mounted with more than 250G of SSD space;

* If you have run a previous Spacex testnet program on this device, you need to close the previous Spacex Node and clear the data before this installation. For details, please refer to section 6.2;

* The installation process will involve the download of dependencies and docker images, which is time-consuming. Meantime, it may fail due to network problems. If it happens, please repeat the process until the installation is all complete.

Installation:

```plain
sudo ./install.sh
```
## 3. Node Configuration

### 3.1 Edit Config File

Execute the following command to edit the node configuration file:

```plain
sudo spacex config set
```
### 3.2 Change Node Name

Follow the prompts to enter the name of your node, and press Enter to end.

### 3.3 Choose Mode

Follow the prompts to enter a node mode 'guardian', and press Enter to end.

### 3.4 Review the Configuration (Optional)

Execute following command to view the configuration file:

```plain
sudo spacex config show
```
## 4. Start Node

### 4.1 Preparation

To start with, you need to ensure that the following ports are not occupied: 30888, 19944, and 19933.

Then open the P2P port:

```plain
sudo ufw allow 30888
```
### 4.2 Start

```plain
sudo spacex start 
```
### 4.3 Check Running Status

```plain
sudo spacex logs chain
```
As detailed below, all is ready for synchronizing blocks. 

## 5. Blockchain Validate

### 5.1 Get session key

Please wait for the chain to synchronize to the latest block height, and execute the following command:

```plain
sudo spacex tools rotate-keys
```
Copy the session key as shown below:

### 5.2  Set session key

Enter [SPACEX APPs](http://rubik.mannheim.world/#/explorer), click on "Staking" button under "Network" in the navigation bar, and go to "Account action". Click on "Session Key".
Fill in the sessionkey you have copied, and click on “Set session key”.

### 5.3 Be a Validator/Candidate

> Becoming a validator needs to shoulder the responsibility of maintaining the network, a large-scale disconnection will result in a certain degree of punishment (up to 7% of the effective pledge amount)

Under "Network->Staking->Account action" page, Please click on "validate" button.

After one era, you can find your account listed in the "Staking" or "Waiting" list, which means you have completed all the steps.

## 6. Restart and Uninstall

### 6.1 Restart

If the device or Spacex node related programs need to be somehow restarted, please refer to the following steps. 

**Please note**: This section only concerns restarting steps of Spacex nodes, not including the basic software and hardware environment settings and inspection related information, such as hard disk mounting, IPFS configurations, etc. Please ensure that the hardware and software configuration is correct, and perform the following steps:

```plain
sudo spacex reload
```
### 6.2 Uninstall and Data Cleanup

If you have run a previous version of Spacex test chain, or if you want to redeploy your current node, you need to clear data from three sources:

* Delete basic Spacex files under /opt/mannheimworld/data
* Clean node data under /opt/mannheimworld/spacex-script by executing:

```plain
sudo /opt/mannheimworld/spacex-script/scripts/uninstall.sh
```