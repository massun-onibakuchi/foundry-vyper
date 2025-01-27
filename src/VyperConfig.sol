// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

import {Vm} from "forge-std/Vm.sol";
import {strings} from "stringutils/strings.sol";

contract VyperConfig {
    using strings for *;

    /// @notice Initializes cheat codes in order to use ffi to compile Vyper contracts
    Vm public constant vm = Vm(address(bytes20(uint160(uint256(keccak256("hevm cheat code"))))));

    /// @notice arguments to append to the bytecode
    bytes public args;

    /// @notice value to deploy the contract with
    uint256 public value;

    /// @notice address that will be the `msg.sender` (op: caller) in the constructor
    /// @dev set to config address to ensure backwards compatibility
    address public deployer = address(this);

    /// @notice whether to broadcast the deployment tx
    bool public should_broadcast;

    /// @notice supported evm versions
    string public evm_version;

    /// @notice sets the arguments to be appended to the bytecode
    function with_args(bytes memory args_) public returns (VyperConfig) {
        args = args_;
        return this;
    }

    /// @notice sets the amount of wei to deploy the contract with
    function with_value(uint256 value_) public returns (VyperConfig) {
        value = value_;
        return this;
    }

    /// @notice sets the caller of the next deployment
    function with_deployer(address _deployer) public returns (VyperConfig) {
        deployer = _deployer;
        return this;
    }

    /// @notice sets the evm version to compile with
    function with_evm_version(string memory _evm_version) public returns (VyperConfig) {
        evm_version = _evm_version;
        return this;
    }

    /// @notice sets whether to broadcast the deployment
    function set_broadcast(bool broadcast) public returns (VyperConfig) {
        should_broadcast = broadcast;
        return this;
    }

    /// @notice Checks for vyper binary conflicts
    function package_check() public {
        string[] memory bincheck = new string[](1);
        bincheck[0] = "./lib/foundry-vyper/scripts/package_check.sh";
        bytes memory retData = vm.ffi(bincheck);
        bytes8 first_bytes = retData[0];
        bool decoded = first_bytes == bytes8(hex"01");
        require(decoded, "Invalid vyper. Run `pip install vyper` to fix.");
    }

    function bytes32ToString(bytes32 x) internal pure returns (string memory) {
        string memory result;
        for (uint256 j = 0; j < x.length; j++) {
            result = string.concat(result, string(abi.encodePacked((uint8(x[j]) % 26) + 97)));
        }
        return result;
    }

    function bytesToString(bytes memory data) public pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    /// @notice Get the evm version string | else return default ("shanghai")
    function get_evm_version() public view returns (string memory) {
        bytes32 _evm_version = bytes32(bytes(abi.encodePacked(evm_version)));
        if (_evm_version == bytes32(0x0)) {
            return "shanghai";
        }
        return evm_version;
    }

    /// @notice Get the creation bytecode of a contract
    function creation_code(string memory file, string memory code_format)
        public
        payable
        returns (bytes memory bytecode)
    {
        package_check();

        // Split the file into its parts
        strings.slice memory s = file.toSlice();
        strings.slice memory delim = "/".toSlice();
        string[] memory parts = new string[](s.count(delim) + 1);
        for (uint256 i = 0; i < parts.length; i++) {
            parts[i] = s.split(delim).toString();
        }

        // Get the system time with our script
        string[] memory time = new string[](1);
        time[0] = "./lib/foundry-vyper/scripts/rand_bytes.sh";
        bytes memory retData = vm.ffi(time);
        string memory rand_bytes = bytes32ToString(keccak256(abi.encode(bytes32(retData))));

        // Re-concatenate the file with a "__TEMP__" prefix
        string memory tempFile = parts[0];
        if (parts.length <= 1) {
            tempFile = string.concat("__TEMP__", rand_bytes, tempFile);
        } else {
            for (uint256 i = 1; i < parts.length - 1; i++) {
                tempFile = string.concat(tempFile, "/", parts[i]);
            }
            tempFile = string.concat(tempFile, "/", "__TEMP__", rand_bytes, parts[parts.length - 1]);
        }

        // Append the real code to the temp file
        string[] memory append_cmds = new string[](3);
        append_cmds[0] = "./lib/foundry-vyper/scripts/read_and_append.sh";
        append_cmds[1] = string.concat("src/", tempFile, ".vy");
        append_cmds[2] = string.concat("src/", file, ".vy");
        vm.ffi(append_cmds);

        /// Create a list of strings with the commands necessary to compile Vyper contracts
        string[] memory cmds = new string[](6);

        cmds[0] = "vyper";
        cmds[1] = string(string.concat("src/", tempFile, ".vy"));
        cmds[2] = "-f";
        cmds[3] = code_format;
        cmds[4] = "--evm-version";
        cmds[5] = get_evm_version();

        /// @notice compile the Vyper contract and return the bytecode
        bytecode = vm.ffi(cmds);

        // Clean up temp files
        string[] memory cleanup = new string[](2);
        cleanup[0] = "rm";
        cleanup[1] = string.concat("src/", tempFile, ".vy");

        // set `msg.sender` for upcoming create context
        vm.prank(deployer);

        vm.ffi(cleanup);
    }

    /// @notice Get the creation bytecode of a contract
    function creation_code(string memory file) public payable returns (bytes memory bytecode) {
        bytecode = creation_code(file, "bytecode");
    }

    /// @notice get creation code of a contract plus encoded arguments
    function creation_code_with_args(string memory file)
        public
        payable
        returns (bytes memory bytecode)
    {
        bytecode = creation_code(file);
        return bytes.concat(bytecode, args);
    }

    /// @notice Deploy the Contract
    function deploy(string memory file) public payable returns (address) {
        bytes memory concatenated = creation_code_with_args(file);

        /// @notice deploy the bytecode with the create instruction
        address deployedAddress;
        if (should_broadcast) vm.broadcast();
        assembly {
            let val := sload(value.slot)
            deployedAddress := create(val, add(concatenated, 0x20), mload(concatenated))
        }

        /// @notice check that the deployment was successful
        require(deployedAddress != address(0), "VyperDeployer could not deploy contract");

        /// @notice return the address that the contract was deployed to
        return deployedAddress;
    }

    /// @notice Deploy the Contract
    function deploy_blueprint(string memory file) public payable returns (address) {
        bytes memory bytecode_blueprint = creation_code(file, "blueprint_bytecode");

        /// @notice deploy the bytecode with the create instruction
        address deployedAddress;
        if (should_broadcast) vm.broadcast();
        assembly {
            let val := sload(value.slot)
            deployedAddress := create(val, add(bytecode_blueprint, 0x20), mload(bytecode_blueprint))
        }

        /// @notice check that the deployment was successful
        require(deployedAddress != address(0), "VyperDeployer could not deploy contract");

        /// @notice return the address that the contract was deployed to
        return deployedAddress;
    }
}
