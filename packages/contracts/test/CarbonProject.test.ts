// import all from '@nomicfoundation/hardhat-toolbox'
import { HardhatEthersSigner } from '@nomicfoundation/hardhat-ethers/signers'
import { expect } from 'chai'
import { Contract, ContractFactory } from 'ethers'
import { ethers, upgrades } from 'hardhat'

import type { CarbonProject, CarbonProject__factory } from '../typechain-types'
import type { ProjectDataStruct, ProjectDataStructOutput } from '../typechain-types/contracts/CarbonProject'

describe('CarbonProject', async () => {
    let CarbonProject: CarbonProject
    let CarbonProjectFactory: ContractFactory<any[], CarbonProject__factory>
    let addr1: HardhatEthersSigner
    let addr2: HardhatEthersSigner
    let addrs: HardhatEthersSigner[]
    beforeEach(async () => {
        ;[addr1, addr2, ...addrs] = await ethers.getSigners()
        CarbonProjectFactory = await ethers.getContractFactory<any[], CarbonProject__factory>('CarbonProject')
        CarbonProject = (await upgrades.deployProxy(CarbonProjectFactory, {
            initializer: 'initialize',
            kind: 'uups',
        })) as Contract & CarbonProject
        CarbonProject.waitForDeployment()
    })
    it('Should set the right owner', async () => {
        expect(await CarbonProject.owner()).to.equal(addr1.address)
        // expect(await CarbonProject.version()).to.equal('1.0')
    })
    it('should set Registry address', async function () {
        const regAddress = '0x1234567890123456789012345678901234567890'
        await CarbonProject.setContractRegistry(regAddress)
        const registryAddress = await CarbonProject.contractRegistry()
        expect(registryAddress).to.equal(regAddress)
    })
    it('should add a project', async function () {
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
        const receipt = await transaction.wait()
        const filter = CarbonProject.filters.ProjectMinted()
        const events = await CarbonProject.queryFilter(filter, receipt?.blockNumber, receipt?.blockNumber)
        const args = events[0].args
        console.log('args:', args)
        expect(args[0]).to.equal(project.beneficiary)
        // expect(args[1]).to.equal(project.projectId)
        const res = await CarbonProject.isValidProjectTokenId(args[1])
        expect(res).to.equal(true)
        const currProject = await CarbonProject.getProjectDataByTokenId(args[1])
        expect(projectOutput).to.deep.equal(currProject)
    })
})
