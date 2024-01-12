import { join } from 'path'
import dotenv from 'dotenv'
import { HardhatUserConfig } from 'hardhat/config'

import '@nomicfoundation/hardhat-toolbox'
import '@nomicfoundation/hardhat-ethers'
import '@openzeppelin/hardhat-upgrades'

dotenv.config() // project root
dotenv.config({ path: join(process.cwd(), '../../.env') }) // workspace root
const etherscanApiKey = process.env.ETHERSCAN_API_KEY ?? ''
if (!etherscanApiKey) {
    console.warn('ETHERSCAN_API_KEY not found in .env file. Will skip Etherscan verification')
}

const account = process.env.ACCOUNT ?? ''
if (!account) {
    console.warn('ACCOUNT not found in .env file. Will skip Etherscan verification')
}

const deployerKey = process.env.DEPLOYER_KEY ?? ''
if (!deployerKey) {
    console.warn('DEPLOYER_KEY not found in .env file. Running with default config')
}

const config: HardhatUserConfig = {
    solidity: {
        version: '0.8.20',
        settings: {
            optimizer: {
                enabled: true,
                runs: 200,
            },
        },
    },
    paths: {
        sources: './contracts',
        artifacts: './artifacts',
    },
    etherscan: {
        apiKey: {
            mainnet: etherscanApiKey,
            sepolia: etherscanApiKey,
            //   polygonMumbai: polygonApiKey,
        },
    },

    networks: {
        hardhat: {
            chainId: 31337,
        },
        localhost: {
            chainId: 31337,
            url: 'http://127.0.0.1:8545',
        },

        sepolia: {
            chainId: 11155111,
            url: 'https://rpc.sepolia.org/',
            accounts: [deployerKey, account],
        },
    },
    typechain: {
        outDir: 'typechain-types',
        target: 'ethers-v6',
    },
}

// // console.log("DEPLOYER_KEY", process.env);

// // const polygonApiKey = process.env.POLYSCAN_API_KEY ?? "";
// // if (!polygonApiKey) {
// //   console.warn("POLYSCAN_API_KEY not found in .env file. Will skip Etherscan verification");
// // }

// const config: HardhatUserConfig = {
//   solidity: "0.8.20",
//   defaultNetwork: "hardhat",

//   networks: {

//     // mumbai: {
//     //   chainId: 80001,
//     //   url: "https://rpc-mumbai.maticvigil.com/",
//     //   accounts: [deployerKey as string],
//     // },
//   },
// };

export default config
