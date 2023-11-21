// import all from '@nomicfoundation/hardhat-toolbox'
import { HardhatEthersSigner } from '@nomicfoundation/hardhat-ethers/signers'
import { expect } from 'chai'
import { Contract, ContractFactory } from 'ethers'
import { ethers, upgrades } from 'hardhat'

import type { ProjectVintages, ProjectVintages__factory, ProjectVintagesStorage } from '../typechain-types'
import type { ProjectDataStruct, ProjectDataStructOutput } from '../typechain-types/contracts/CarbonProject'
import type { VintageDataStruct } from '../typechain-types/contracts/Project.vintages.sol/ProjectVintages'

describe('ProjectVintages', async () => {
    let addr1: HardhatEthersSigner
    let addr2: HardhatEthersSigner
    let addrs: HardhatEthersSigner[]
    let ProjectVintages: ProjectVintages
    let ProjectVintagesFactory: ContractFactory<any[], ProjectVintages__factory>
    beforeEach(async () => {
        ;[addr1, addr2, ...addrs] = await ethers.getSigners()
        ProjectVintagesFactory = await ethers.getContractFactory<any[], ProjectVintages__factory>('ProjectVintages')
        // deploy proxy
        ProjectVintages = (await upgrades.deployProxy(ProjectVintagesFactory, {
            initializer: 'initialize',
            kind: 'uups',
        })) as Contract & ProjectVintages
        ProjectVintages.waitForDeployment()
    })
    it('Should set the right owner', async () => {
        expect(await ProjectVintages.owner()).to.equal(addr1.address)
    })
    it('should return the version', async function () {
        const version = await ProjectVintages.VERSION()
        expect(version).to.equal('1.0')
    })
    // it('should add a new vintage', async function () {
    //     const vintage: VintageDataStruct = {
    //         projectTokenId: 1,
    //         startTime: 1636422000,
    //         endTime: 1636512000,
    //         additionalCertification: 'test additional certification',
    //         uri: 'test uri',
    //         coBenefits: 'test co benefits',
    //         correspAdjustment: 'test corresp adjustments details',
    //         isCCPcompliant: true,
    //         isCorsiaCompliant: true,
    //         name: 'test name',
    //         registry: 'test registry',
    //         totalVintageQuantity: 1143551,
    //     }

    // const transaction = await ProjectVintages.addNewVintage(
    //     addr1.address, // replace with the address you want to use
    //     vintage // replace with the vintage data
    // )
    // const receipt = await transaction.wait()
    // const filter = ProjectVintages.filters.ProjectVintageMinted()
    // const event = await ProjectVintages.queryFilter(filter, receipt?.blockHash, receipt?.blockNumber)
    // const eventArgs = event[0].args
    // expect(eventArgs.projectTokenId).to.equal(vintage.projectTokenId)
    // expect(eventArgs.startTime).to.equal(vintage.startTime)
    // // expect(eventArgs.endTime).to.equal(vintage.endTime)
    // const currentVintage = await ProjectVintages.getProjectVintageDataByTokenId(vintage.projectTokenId)
    // expect(currentVintage.projectTokenId).to.equal(vintage.projectTokenId)
    // })
})

// describe("ProjectVintages", function () {
//     let owner;
//     let manager;
//     let otherAddress;
//     let projectVintages;

//     beforeEach(async function () {
//       [owner, manager, otherAddress] = await ethers.getSigners();

//       const ProjectVintages = await ethers.getContractFactory("ProjectVintages");
//       projectVintages = await ProjectVintages.deploy();
//       await projectVintages.deployed();

//       // Grant the manager role to 'manager' account
//       await projectVintages.grantRole(
//         await projectVintages.MANAGER_ROLE(),
//         manager.address
//       );
//     });

//     it("should allow adding a new vintage by a manager", async function () {
//       const startTime = 1636422000; // Replace with your desired timestamp
//       const endTime = 1636512000; // Replace with your desired timestamp
//       const projectTokenId = 1; // Replace with a valid project token ID

//       await expect(() =>
//         projectVintages.addNewVintage(
//           owner.address,
//           {
//             projectTokenId,
//             startTime,
//             endTime,
//             otherAttributes: "otherAttributes", // Replace with actual attributes
//           }
//         )
//       ).to.changeTokenBalance(owner, 1);

//       // Check if the vintage data has been added successfully
//       const tokenId = 1; // Adjust this according to your test case
//       const vintageData = await projectVintages.getProjectVintageDataByTokenId(
//         tokenId
//       );

//       expect(vintageData.projectTokenId).to.equal(projectTokenId);
//       expect(vintageData.startTime).to.equal(startTime);
//       expect(vintageData.endTime).to.equal(endTime);
//     });

//     it("should not allow adding a vintage with invalid start time", async function () {
//       const invalidStartTime = 1636422000; // Replace with an invalid start time
//       const endTime = 1636512000; // Replace with your desired timestamp
//       const projectTokenId = 1; // Replace with a valid project token ID

//       await expect(
//         projectVintages.addNewVintage(
//           owner.address,
//           {
//             projectTokenId,
//             startTime: invalidStartTime,
//             endTime,
//             otherAttributes: "otherAttributes", // Replace with actual attributes
//           }
//         )
//       ).to.be.revertedWith("Error: vintage startTime must be less than endTime");
//     });

//     // Add more test cases for other contract functions as needed

//   });
