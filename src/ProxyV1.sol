// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "../../lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title Proxy for MarketPlace NFT -
 * @author 0xkerobyte
 * @notice This smart contract is used as a UUPS Proxy (ERC1967Proxy) to connect your implementation securely and faster than transparent proxies.
 */
contract ProxyV1 is ERC1967Proxy {
    /**
     * @notice Initializes the upgradeable proxy with an initial implementation specified by `implementation`.
     * @param implementation,
     * @param data,
     * If `_data` is nonempty, it's used as data in a delegate call to `implementation`. This will typically be an
     * encoded function call, and allows initializing the storage of the proxy like a Solidity constructor.
     * Requirements:
     * - If `data` is empty, `msg.value` must be zero.
     */

    constructor(
        address implementation,
        bytes memory data
    ) ERC1967Proxy(implementation, data) {}

    /**
     * @notice Returns the implementation/contract address the proxy is pointing
     * @return Implementation address
     */

    function getImplementation() external view returns (address) {
        return _implementation();
    }

    receive() external payable {}
}
