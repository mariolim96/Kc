// import all from '@nomicfoundation/hardhat-toolbox'
import { HardhatEthersSigner } from '@nomicfoundation/hardhat-ethers/signers'
import { expect } from 'chai'
import { Contract, ContractFactory } from 'ethers'
import hre, { ethers, upgrades } from 'hardhat'

import { Registry, Registry__factory } from '../typechain-types'

describe('Registry', async () => {
    let registry: Registry
    let registryFactory: ContractFactory<any[], Registry__factory>
    let addr1: HardhatEthersSigner
    let addr2: HardhatEthersSigner
    let addrs: HardhatEthersSigner[]

    describe('Deployment', () => {
        beforeEach(async () => {
            ;[addr1, addr2, ...addrs] = await ethers.getSigners()
            registryFactory = await ethers.getContractFactory<any[], Registry__factory>('Registry')
            registry = (await upgrades.deployProxy(registryFactory, {
                initializer: 'initialize',
                kind: 'uups',
            })) as Registry & Contract
            registry.waitForDeployment()
        })

        it('Should set the right owner', async () => {
            expect(await registry.owner()).to.equal(addr1.address)
            expect(await registry.version()).to.equal('1.0')
        })
        it('should set Carbon Projects address', async function () {
            const newAddress = '0x1234567890123456789012345678901234567890'
            await registry.setCarbonProjectsAddress(newAddress)
            const carbonProjectsAddress = await registry.carbonProjectsAddress()
            expect(carbonProjectsAddress).to.equal(newAddress)
        })
    })

    // describe('should set ')
})
