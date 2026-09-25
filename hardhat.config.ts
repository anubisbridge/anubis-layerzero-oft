import "@nomiclabs/hardhat-ethers";

export default {
  solidity: {
    version: "0.8.22",
    settings: {
      optimizer: { enabled: true, runs: 200 }
    }
  }
};
