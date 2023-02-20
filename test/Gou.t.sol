// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

import {IERC20} from "huffmate/tokens/interfaces/IERC20.sol";

contract GouTest is Test {
    IERC20 gouTokenErc20;
    Gou gouToken;
    address mockGouToken;

    address constant deployer = address(0xCEF);

    function setUp() public {
        // Read ERC20.huff
        string memory erc20_wapper = vm.readFile(
            "lib/huffmate/src/tokens/ERC20.huff"
        );

        // Deploy Gou Token inheriting ERC20.huff
        vm.startPrank(deployer);
        mockGouToken = HuffDeployer
            .config()
            .with_code(erc20_wapper)
            .with_args(bytes.concat(abi.encode(deployer), abi.encode(0x12)))
            .deploy("Gou");

        gouToken = Gou(mockGouToken);
        gouTokenErc20 = IERC20(mockGouToken);

        vm.stopPrank();
    }

    function testMetaData() public {
        assertEq("Ghost of Uchiha", gouTokenErc20.name());
        assertEq(50000 ether, gouTokenErc20.totalSupply());
        assertEq(18, gouTokenErc20.decimals());
    }

    function testOwner() public {
        assertEq(deployer, gouToken.owner());
    }

    function testSetOwner() public {
        vm.startPrank(deployer);
        address newOwner = address(0xBed);
        gouToken.setOwner(newOwner);

        assertEq(newOwner, gouToken.owner());
        vm.stopPrank();
    }

    function testMintAndBurn() public {
        vm.startPrank(deployer);
        // Mint some GOU
        gouToken.mint(10000 ether);
        assertEq(60000 ether, gouTokenErc20.totalSupply());

        // Burn some GOU
        gouToken.burn(20000 ether);
        assertEq(40000 ether, gouTokenErc20.totalSupply());
        vm.stopPrank();
    }

    function testClaimableAmount() public {
        assertEq(100 ether, gouToken.getClaimableAmount());

        vm.startPrank(deployer);
        gouToken.claimableAmount(50 ether);
        vm.stopPrank();
        assertEq(50 ether, gouToken.getClaimableAmount());
    }

    function testWlAddress() public {
        vm.startPrank(deployer);
        gouToken.whitelistAddress();

        vm.stopPrank();
    }

    function testClaim() public {
        vm.startPrank(address(0xBed));
        gouToken.whitelistAddress();
        gouToken.claim();
        assertEq(100 ether, gouTokenErc20.balanceOf(address(0xBed)));
        assertEq(49900 ether, gouTokenErc20.balanceOf(mockGouToken));
        vm.stopPrank();
    }
}

interface Gou {
    function mint(uint256) external;

    function burn(uint256) external;

    function whitelistAddress() external;

    function claim() external;

    function claimableAmount(uint256) external;

    function setOwner(address) external;

    function getClaimableAmount() external returns (uint256);

    function owner() external returns (address);
}
