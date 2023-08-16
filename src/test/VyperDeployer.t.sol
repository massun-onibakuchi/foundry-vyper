// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.7.0 <0.9.0;

import "forge-std/Test.sol";

import {VyperConfig} from "../VyperConfig.sol";
import {VyperDeployer} from "../VyperDeployer.sol";
import {INumber} from "./interfaces/INumber.sol";
import {IConstructor} from "./interfaces/IConstructor.sol";
import {IRememberCreator} from "./interfaces/IRememberCreator.sol";

contract VyperDeployerTest is Test {
    INumber number;
    IConstructor structor;

    event ArgumentsUpdated(address indexed one, uint256 indexed two);

    function setUp() public {
        number = INumber(VyperDeployer.deploy("test/contracts/Number"));

        // Backwards-compatible Constructor creation
        vm.recordLogs();
        structor = IConstructor(
            VyperDeployer.deploy_with_args(
                "test/contracts/Constructor",
                bytes.concat(
                    abi.encode(address(0x420)),
                    abi.encode(uint256(0x420))
                )
            )
        );
        Vm.Log[] memory entries = vm.getRecordedLogs();

        assertEq(entries.length, 1);
        assertEq(entries[0].topics.length, 3);
        assertEq(
            entries[0].topics[0],
            bytes32(uint256(keccak256("ArgumentsUpdated(address,uint256)")))
        );
        assertEq(
            entries[0].topics[1],
            bytes32(uint256(uint160(address(0x420))))
        );
        assertEq(entries[0].topics[2], bytes32(uint256(0x420)));
    }

    function testChaining() public {}

    function testChaining_Create2() public {}

    function testArgOne() public {
        assertEq(address(0x420), structor.getArgOne());
    }

    function testArgTwo() public {
        assertEq(uint256(0x420), structor.getArgTwo());
    }

    function testBytecode() public {
        // vyper -f bytecode_runtime --evm-version shanghai src/test/contracts/Number.vy
        bytes memory b = bytes(
            hex"6003361161000c57610048565b5f3560e01c3461004c57633fb5c1cb8118610030576024361061004c576004355f55005b63f2c9ecd88118610046575f5460405260206040f35b505b5f5ffd5b5f80fda165767970657283000309000b"
        );
        assertEq(getCode(address(number)), b);
    }

    function testWithValueDeployment() public {
        // uint256 value = 1 ether;
        // VyperDeployer.config().with_value(value).deploy{value: value}(
        //     "test/contracts/ConstructorNeedsValue"
        // );
    }

    function testWithValueDeployment_Create2() public {
        // uint256 value = 1 ether;
        // VyperDeployer.config_with_create_2(1).with_value(value).deploy{
        //     value: value
        // }("test/contracts/ConstructorNeedsValue");
    }

    function getCode(address who) internal view returns (bytes memory o_code) {
        /// @solidity memory-safe-assembly
        assembly {
            // retrieve the size of the code, this needs assembly
            let size := extcodesize(who)
            // allocate output byte array - this could also be done without assembly
            // by using o_code = new bytes(size)
            o_code := mload(0x40)
            // new "memory end" including padding
            mstore(
                0x40,
                add(o_code, and(add(add(size, 0x20), 0x1f), not(0x1f)))
            )
            // store length in memory
            mstore(o_code, size)
            // actually retrieve the code, this needs assembly
            extcodecopy(who, add(o_code, 0x20), 0, size)
        }
    }

    function testSet(uint256 num) public {
        number.setNumber(num);
        assertEq(num, number.getNumber());
    }

    function testConstructorDefaultCaller() public {
        // HuffConfig config = VyperDeployer.config();
        // IRememberCreator rememberer = IRememberCreator(
        //     config.deploy("test/contracts/RememberCreator")
        // );
        // assertEq(rememberer.CREATOR(), address(config));
    }

    function runTestConstructorCaller(address deployer) public {
        // IRememberCreator rememberer = IRememberCreator(
        //     VyperDeployer.config().with_deployer(deployer).deploy(
        //         "test/contracts/RememberCreator"
        //     )
        // );
        // assertEq(rememberer.CREATOR(), deployer);
    }

    // @dev fuzzed test too slow, random examples and address(0) chosen
    function testConstructorCaller() public {
        // runTestConstructorCaller(
        //     address(uint160(uint256(keccak256("random addr 1"))))
        // );
        // runTestConstructorCaller(
        //     address(uint160(uint256(keccak256("random addr 2"))))
        // );
        // runTestConstructorCaller(address(0));
        // runTestConstructorCaller(address(uint160(0x1000)));
    }

    /// @dev test that compilation is different with new evm versions
    function testSettingEVMVersion() public {
        // /// expected bytecode for EVM version "paris"
        // bytes memory expectedParis = hex"6000";
        // HuffConfig config = VyperDeployer.config().with_evm_version("paris");
        // address withParis = config.deploy("test/contracts/EVMVersionCheck");

        // bytes memory parisBytecode = withParis.code;
        // assertEq(parisBytecode, expectedParis);

        // /// expected bytecode for EVM version "shanghai" | default
        // bytes memory expectedShanghai = hex"5f";
        // HuffConfig shanghaiConfig = VyperDeployer.config().with_evm_version(
        //     "shanghai"
        // );
        // address withShanghai = shanghaiConfig.deploy(
        //     "test/contracts/EVMVersionCheck"
        // );
        // bytes memory shanghaiBytecode = withShanghai.code;
        // assertEq(shanghaiBytecode, expectedShanghai);

        // /// Default should be shanghai (latest)
        // HuffConfig defaultConfig = VyperDeployer.config().with_evm_version("");
        // address withDefault = defaultConfig.deploy(
        //     "test/contracts/EVMVersionCheck"
        // );

        // bytes memory defaultBytecode = withDefault.code;
        // assertEq(defaultBytecode, expectedShanghai);
    }
}
