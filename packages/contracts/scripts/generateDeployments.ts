import * as fs from 'fs'
import prettier from 'prettier'

function ensureDirectoryExistence(dirPath: string) {
    if (!fs.existsSync(dirPath)) {
        fs.mkdirSync(dirPath, { recursive: true })
    }
}

export function generateDeployments(networkName: string, chainId: string, addressess: Record<string, string>) {
    // this function will generate the deployments folder and the .chainId file from the artifacts folder
    const DEPLOYMENTS_DIR = './deployments'
    const ARTIFACTS_DIR = './artifacts/contracts'

    const TARGET_DIR = `${DEPLOYMENTS_DIR}/${networkName}`

    ensureDirectoryExistence(DEPLOYMENTS_DIR)

    if (!fs.existsSync(TARGET_DIR)) {
        fs.mkdirSync(TARGET_DIR)
    }

    const contractsFolders = fs.readdirSync(ARTIFACTS_DIR)
    for (const contractFolder of contractsFolders) {
        const contractFiles = fs.readdirSync(`${ARTIFACTS_DIR}/${contractFolder}`)
        for (const contractFile of contractFiles) {
            if (contractFile.endsWith('.json') && !contractFile.endsWith('.dbg.json')) {
                const contractName = contractFile
                const contractPath = `${ARTIFACTS_DIR}/${contractFolder}/${contractFile}`
                const contractContent = fs.readFileSync(contractPath).toString()
                const contractJson = JSON.parse(contractContent)
                const contractAddress = addressess[contractName.split('.')[0]]
                const contractAbi = contractJson.abi
                const contract = {
                    address: contractAddress,
                    abi: contractAbi,
                }
                const contractJsonString = JSON.stringify(contract, null, 2)
                fs.writeFileSync(`${TARGET_DIR}/${contractName}`, contractJsonString)
                fs.writeFileSync(`${TARGET_DIR}/.chainId`, chainId)
            }
        }
    }
}
