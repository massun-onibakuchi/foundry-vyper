// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

import {Vm} from "forge-std/Vm.sol";
import {VyperConfig} from "./VyperConfig.sol";

library VyperDeployer {
    /// @notice Create a new vyper config
    function config() public returns (VyperConfig) {
        return new VyperConfig();
    }

    // @notice Deterministically create a new vyper config using create2 and a salt
    function config_with_create_2(uint256 salt) public returns (VyperConfig) {
        return new VyperConfig{salt: bytes32(salt)}();
    }

    // @notice Get the address of a VyperConfig deployed with config_with_create_2
    function get_config_with_create_2(uint256 salt) public view returns (address) {
        return address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            bytes32(salt),
                            keccak256(type(VyperConfig).creationCode)
                        )
                    )
                )
            )
        );
    }

    /// @notice Compiles a Vyper contract and returns the address that the contract was deployeod to
    /// @param fileName - The file name of the Vyper contract. For example, the file name for "SimpleStore.vy" is "SimpleStore"
    /// @return The address that the contract was deployed to
    function deploy(string memory fileName) internal returns (address) {
        return config().deploy(fileName);
    }

    /// @notice Compiles a Vyper contract and returns the address that the contract was deployeod to
    /// @param fileName - The file name of the Vyper contract. For example, the file name for "SimpleStore.vy" is "SimpleStore"
    /// @return The address that the contract was deployed to
    function broadcast(string memory fileName) internal returns (address) {
        return config().set_broadcast(true).deploy(fileName);
    }

    /// @notice Compiles a Vyper contract and returns the address that the contract was deployeod to
    /// @param fileName - The file name of the Vyper contract. For example, the file name for "SimpleStore.vy" is "SimpleStore"
    /// @param value - Value to deploy with
    /// @return The address that the contract was deployed to
    function deploy_with_value(string memory fileName, uint256 value) internal returns (address) {
        return config().with_value(value).deploy(fileName);
    }

    /// @notice Compiles a Vyper contract and returns the address that the contract was deployeod to
    /// @param fileName - The file name of the Vyper contract. For example, the file name for "SimpleStore.vy" is "SimpleStore"
    /// @param value - Value to deploy with
    /// @return The address that the contract was deployed to
    function broadcast_with_value(string memory fileName, uint256 value)
        internal
        returns (address)
    {
        return config().set_broadcast(true).with_value(value).deploy(fileName);
    }

    /// @notice Compiles a Vyper contract and returns the address that the contract was deployeod to
    /// @param fileName - The file name of the Vyper contract. For example, the file name for "SimpleStore.vy" is "SimpleStore"
    /// @param args - Constructor Args to append to the bytecode
    /// @return The address that the contract was deployed to
    function deploy_with_args(string memory fileName, bytes memory args)
        internal
        returns (address)
    {
        return config().with_args(args).deploy(fileName);
    }

    /// @notice Compiles a Vyper contract and returns the address that the contract was deployeod to
    /// @param fileName - The file name of the Vyper contract. For example, the file name for "SimpleStore.vy" is "SimpleStore"
    /// @param args - Constructor Args to append to the bytecode
    /// @return The address that the contract was deployed to
    function broadcast_with_args(string memory fileName, bytes memory args)
        internal
        returns (address)
    {
        return config().set_broadcast(true).with_args(args).deploy(fileName);
    }

    /// @notice Compiles a Vyper contract as blueprint and returns the address that the contract was deployeod to
    /// @param fileName - The file name of the Vyper contract. For example, the file name for "SimpleStore.vy" is "SimpleStore"
    /// @return The address that the contract was deployed to
    function deploy_blueprint(string memory fileName) internal returns (address) {
        return config().deploy_blueprint(fileName);
    }
}
