// import all from '@nomicfoundation/hardhat-toolbox'
import { HardhatEthersSigner } from '@nomicfoundation/hardhat-ethers/signers'
import { expect } from 'chai'
import hre, { ethers, upgrades } from 'hardhat'

import { Registry, Registry__factory } from '../typechain-types'

describe('Registry', () => {
    let registry: Registry
    let registryFactory: Registry__factory
    let addr1: HardhatEthersSigner
    let addr2: HardhatEthersSigner
    let addrs: HardhatEthersSigner[]

    beforeEach(async () => {
        // registry = await ethers.deployContract('Registry', [addr1.address])
        // console.log('Registry deployed to:', await registry.owner())
    })

    describe('Deployment', () => {
        it('Should set the right owner', async () => {
            ;[addr1, addr2, ...addrs] = await ethers.getSigners()
            const registryFactory = await ethers.getContractFactory<any[], Registry__factory>('Registry')
            const registry = await upgrades.deployProxy(registryFactory, [], {
                initializer: 'initialize',
                kind: 'uups',
            })
            await registry.deployed()
            console.log('Registry deployed to:', registry.address)
            expect(await registry.owner()).to.equal(addr1.address)
        })
        // it('should set Carbon Projects address', async function () {
        //     const newAddress = '0x1234567890123456789012345678901234567890'
        //     await registry.setCarbonProjectsAddress(newAddress)
        //     const carbonProjectsAddress = await registry.carbonProjectsAddress()
        //     expect(carbonProjectsAddress).to.equal(newAddress)
        // })
    })

    // describe('should set ')
})
