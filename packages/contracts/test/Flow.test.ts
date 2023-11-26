// import all from '@nomicfoundation/hardhat-toolbox'
import exp from 'constants'
import { HardhatEthersSigner } from '@nomicfoundation/hardhat-ethers/signers'
import { expect } from 'chai'
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
    ProjectVintages,
    ProjectVintages__factory,
    Registry,
    Registry__factory,
} from '../typechain-types'
import type { ProjectDataStruct, ProjectDataStructOutput } from '../typechain-types/contracts/CarbonProject'
import type { VintageDataStruct } from '../typechain-types/contracts/Project.vintages.sol/ProjectVintages'

describe('flow', async () => {
    it('should add a new project and a new vintage linked to the project', async function () {
        let registry: Registry
        let registryFactory: ContractFactory<any[], Registry__factory>
        let ProjectVintages: ProjectVintages
        let ProjectVintagesFactory: ContractFactory<any[], ProjectVintages__factory>
        let CarbonProject: CarbonProject
        let CarbonProjectFactory: ContractFactory<any[], CarbonProject__factory>

        let receipt: ContractTransactionReceipt | null = null

        let addr1: HardhatEthersSigner
        let addr2: HardhatEthersSigner
        let addrs: HardhatEthersSigner[]
        ;[addr1, addr2, ...addrs] = await ethers.getSigners()

        // factories
        registryFactory = await ethers.getContractFactory<any[], Registry__factory>('Registry')
        registry = (await upgrades.deployProxy(registryFactory, [], {
            initializer: 'initialize',
            kind: 'uups',
        })) as Registry & Contract
        registry.waitForDeployment()

        ProjectVintagesFactory = await ethers.getContractFactory<any[], ProjectVintages__factory>('ProjectVintages')
        ProjectVintages = (await upgrades.deployProxy(ProjectVintagesFactory, [], {
            initializer: 'initialize',
            kind: 'uups',
        })) as Contract & ProjectVintages
        ProjectVintages.waitForDeployment()

        CarbonProjectFactory = await ethers.getContractFactory<any[], CarbonProject__factory>('CarbonProject')
        CarbonProject = (await upgrades.deployProxy(CarbonProjectFactory, [], {
            initializer: 'initialize',
            kind: 'uups',
        })) as Contract & CarbonProject
        CarbonProject.waitForDeployment()

        const co2TokenFactory = await ethers.getContractFactory<any[], CarbonOffsetToken__factory>('CarbonOffsetToken')
        const co2Token = (await upgrades.deployBeacon(co2TokenFactory)) as Contract & CarbonOffsetToken
        co2Token.waitForDeployment()

        const carbonOffsetTokenFactory = await ethers.getContractFactory<any[], CarbonOffsetFactory__factory>(
            'CarbonOffsetFactory'
        )
        const assignRole = (role: string) => {
            return keccak256(toUtf8Bytes(role))
        }

        const tokenizerRole = assignRole('TOKENIZER_ROLE')
        console.log('tokenizerRole:', tokenizerRole)
        const detokenizerRole = assignRole('DETOKENIZER_ROLE')
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
        console.log({
            registryAddress,
            projectAddress,
            vintageAddress,
            co2TokenAddress,
            carbonOffsetTokenAddress,
        })

        // Set Registry address
        await registry.setCarbonProjectVintagesAddress(vintageAddress)
        await registry.setCarbonProjectsAddress(projectAddress)
        await CarbonProject.setContractRegistry(registryAddress)
        await ProjectVintages.setRegistry(registryAddress)
        await carbonOffsetToken.setRegistry(registryAddress)
        await carbonOffsetToken.setBeacon(co2TokenAddress)
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
        console.log('args:', args)
        expect(args[0]).to.equal(project.beneficiary)
        const res = await CarbonProject.isValidProjectTokenId(args[1])
        expect(res).to.equal(true)
        const currProject = await CarbonProject.getProjectDataByTokenId(args[1])
        expect(projectOutput).to.deep.equal(currProject)
        // add new vintage linked to project
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
        const eventArgs = event[0].args
        expect(eventArgs.projectTokenId).to.equal(vintage.projectTokenId)
        expect(eventArgs.startTime).to.equal(vintage.startTime)
        const currentVintage = await ProjectVintages.getProjectVintageDataByTokenId(vintage.projectTokenId)
        expect(currentVintage.projectTokenId).to.equal(vintage.projectTokenId)
        // add new carbon offset token linked to vintage
        const carbonTransaction = await carbonOffsetToken.deployFromVintage(vintage.projectTokenId)
        receipt = await carbonTransaction.wait()
        const carbonFilter = carbonOffsetToken.filters.TokenCreated()
        const carbonEvent = await carbonOffsetToken.queryFilter(carbonFilter, receipt?.blockHash, receipt?.blockNumber)
        const carbonEventArgs = (carbonEvent[0] as EventLog).args
        expect(await registry.projectVintageERC20Registry(carbonEventArgs[1])).to.equal(true)
    })
})
