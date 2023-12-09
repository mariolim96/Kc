import { HardhatEthersSigner } from '@nomicfoundation/hardhat-ethers/signers'
import {
    Contract,
    ContractFactory,
    ContractTransaction,
    ContractTransactionReceipt,
    EventLog,
    keccak256,
    toUtf8Bytes,
} from 'ethers'
import { ethers, upgrades } from 'hardhat'

import type {
    CarbonOffsetFactory,
    CarbonOffsetFactory__factory,
    CarbonOffsetToken,
    CarbonOffsetToken__factory,
    CarbonProject,
    CarbonProject__factory,
    CarbonTokenizerContract,
    CarbonTokenizerContract__factory,
    ProjectVintages,
    ProjectVintages__factory,
    Registry,
    Registry__factory,
    RetirementCertificates,
    RetirementCertificates__factory,
} from '../typechain-types'
import type { ProjectDataStruct, ProjectDataStructOutput } from '../typechain-types/contracts/CarbonProject'
import type { VintageDataStruct } from '../typechain-types/contracts/Project.vintages.sol/ProjectVintages'

const assignRole = (role: string) => {
    return keccak256(toUtf8Bytes(role))
}
async function main() {
    let registry: Registry
    let registryFactory: ContractFactory<any[], Registry__factory>
    let ProjectVintages: ProjectVintages
    let ProjectVintagesFactory: ContractFactory<any[], ProjectVintages__factory>
    let CarbonProject: CarbonProject
    let CarbonProjectFactory: ContractFactory<any[], CarbonProject__factory>
    let retirementCertificates: RetirementCertificates
    let retirementCertificatesFactory: ContractFactory<any[], RetirementCertificates__factory>
    let carbonTokenizer: CarbonTokenizerContract
    let CarbonTokenizerFactory: ContractFactory<any[], CarbonTokenizerContract__factory>
    let receipt: ContractTransactionReceipt | null = null

    let addr1: HardhatEthersSigner
    let addr2: HardhatEthersSigner
    let addrs: HardhatEthersSigner[]
    // roles
    const tokenizerRole = assignRole('TOKENIZER_ROLE')
    const detokenizerRole = assignRole('DETOKENIZER_ROLE')

    ;[addr1, addr2] = await ethers.getSigners()
    // factory

    registryFactory = await ethers.getContractFactory<any[], Registry__factory>('Registry')
    registry = (await upgrades.deployProxy(registryFactory, [], {
        initializer: 'initialize',
        kind: 'uups',
    })) as Registry & Contract
    await registry.waitForDeployment()

    ProjectVintagesFactory = await ethers.getContractFactory<any[], ProjectVintages__factory>('ProjectVintages')
    ProjectVintages = (await upgrades.deployProxy(ProjectVintagesFactory, [], {
        initializer: 'initialize',
        kind: 'uups',
    })) as Contract & ProjectVintages
    await ProjectVintages.waitForDeployment()

    CarbonProjectFactory = await ethers.getContractFactory<any[], CarbonProject__factory>('CarbonProject')
    CarbonProject = (await upgrades.deployProxy(CarbonProjectFactory, [], {
        initializer: 'initialize',
        kind: 'uups',
    })) as Contract & CarbonProject
    await CarbonProject.waitForDeployment()

    CarbonTokenizerFactory = await ethers.getContractFactory<any[], CarbonTokenizerContract__factory>(
        'CarbonTokenizerContract'
    )

    carbonTokenizer = (await upgrades.deployProxy(
        CarbonTokenizerFactory,
        [addr1.address, addr1.address, addr1.address, addr1.address],
        {
            initializer: 'initialize',
            kind: 'uups',
        }
    )) as Contract & CarbonTokenizerContract

    retirementCertificatesFactory = await ethers.getContractFactory<any[], RetirementCertificates__factory>(
        'RetirementCertificates'
    )

    const co2TokenFactory = await ethers.getContractFactory<any[], CarbonOffsetToken__factory>('CarbonOffsetToken')
    const co2Token = (await upgrades.deployBeacon(co2TokenFactory)) as Contract & CarbonOffsetToken
    co2Token.waitForDeployment()

    const carbonOffsetTokenFactory = await ethers.getContractFactory<any[], CarbonOffsetFactory__factory>(
        'CarbonOffsetFactory'
    )
    const argsValues = [
        [addr1.address, addr1.address],
        [tokenizerRole, detokenizerRole],
    ]
    const carbonOffsetToken = (await upgrades.deployProxy(carbonOffsetTokenFactory, argsValues, {
        initializer: 'inizialize',
        kind: 'uups',
    })) as Contract & CarbonOffsetFactory
    await carbonOffsetToken.waitForDeployment()

    const registryAddress = await registry.getAddress()
    const projectAddress = await CarbonProject.getAddress()
    const vintageAddress = await ProjectVintages.getAddress()
    const co2TokenAddress = await co2Token.getAddress()
    const carbonOffsetTokenAddress = await carbonOffsetToken.getAddress()
    const carbonTokenizerAddress = await carbonTokenizer.getAddress()

    retirementCertificates = (await upgrades.deployProxy(retirementCertificatesFactory, [registryAddress, ''], {
        initializer: 'initialize',
        kind: 'uups',
    })) as Contract & RetirementCertificates
    await retirementCertificates.waitForDeployment()
    const retirementCertificatesAddress = await retirementCertificates.getAddress()
    console.log({
        registryAddress,
        projectAddress,
        vintageAddress,
        co2TokenAddress,
        carbonOffsetTokenAddress,
        retirementCertificatesAddress,
        carbonTokenizerAddress,
    })
    // Set Registry address
    await registry.setCarbonProjectVintagesAddress(vintageAddress)
    await registry.setCarbonProjectsAddress(projectAddress)
    await registry.setCarbonOffsetTokenFactoryAddress(carbonOffsetTokenAddress)
    await registry.setCarbonOffsetTokenAddress(co2TokenAddress)
    await registry.setRetirementCertificatesAddress(retirementCertificatesAddress)
    await registry.setCarbonTokenizerAddress(carbonTokenizerAddress)

    await carbonTokenizer.setCarbonRegistryAddress(registryAddress)
    await CarbonProject.setContractRegistry(registryAddress)
    await ProjectVintages.setRegistry(registryAddress)

    await carbonOffsetToken.setRegistry(registryAddress)
    await carbonOffsetToken.setBeacon(co2TokenAddress)

    await retirementCertificates.setMinValidRetirementAmount(ethers.parseEther('0.00001'))
    // add new project
    const project: ProjectDataStruct = {
        projectId: 'test project id',
        standard: 'test standard',
        methodology: 'test methodology',
        region: 'test region',
        storageMethod: 'test storage method',
        method: 'test method',
        emissionType: 'test emission type',
        category: 'test category',
        uri: 'test uri',
        beneficiary: addr1.address,
    }
    const projectOutput = Object.values(project)
    const transaction = await CarbonProject.addNewProject(
        addr1.address,
        project.projectId,
        project.standard,
        project.methodology,
        project.region,
        project.storageMethod,
        project.method,
        project.emissionType,
        project.category,
        project.uri,
        addr1.address
    )
    receipt = await transaction.wait()
    const filter = CarbonProject.filters.ProjectMinted()
    const events = await CarbonProject.queryFilter(filter, receipt?.blockNumber, receipt?.blockNumber)
    const args = events[0].args
    const vintage: VintageDataStruct = {
        projectTokenId: args[1],
        startTime: 1636422000,
        endTime: 1636512000,
        additionalCertification: 'test additional certification',
        uri: 'test uri',
        coBenefits: 'test co benefits',
        correspAdjustment: 'test corresp adjustments details',
        isCCPcompliant: true,
        isCorsiaCompliant: true,
        name: 'test name',
        registry: 'test registry',
        totalVintageQuantity: 1143551,
    }
    const vintageTransaction = await ProjectVintages.addNewVintage(addr1.address, vintage)
    receipt = await vintageTransaction.wait()
    const vintageFilter = ProjectVintages.filters.ProjectVintageMinted()
    const event = await ProjectVintages.queryFilter(vintageFilter, receipt?.blockHash, receipt?.blockNumber)
    // fractionalize vintage
    await carbonTokenizer.fractionalize(vintage.projectTokenId)
    const tokenDeployedAddress = await carbonOffsetToken.pvIdtoERC20(vintage.projectTokenId)
    const tokenInstance = (await ethers.getContractAt('CarbonOffsetToken', tokenDeployedAddress)) as CarbonOffsetToken &
        Contract
    await tokenInstance.retire(
        addr1.address,
        ethers.parseEther('0.1'),
        'retire entity string',
        addr1.address,
        'beneficiary string',
        'retirement message'
    )
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
