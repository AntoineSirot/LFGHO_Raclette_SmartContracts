pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

contract GHOStakingVault is ERC4626 {
    ERC20 public immutable GHO;

    constructor(
        ERC20 _GHO,
        string memory name_,
        string memory symbol_
    )
        ERC4626(_GHO) // GHO is the underlying asset
        ERC20(name_, symbol_) // F-GHO represented by this contract's ERC20 token
    {
        GHO = _GHO;
    }

    // Override totalAssets to return the total amount of GHO held by the contract
    function totalAssets() public view override returns (uint256) {
        return GHO.balanceOf(address(this));
    }

    // You may need to override other functions like convertToShares and convertToAssets
    // to ensure the 1:1 ratio is maintained. This depends on your specific requirements.
    // For example, a simple 1:1 ratio can be achieved by:
    function convertToShares(
        uint256 assets
    ) public view override returns (uint256) {
        return assets; // 1:1 ratio
    }

    function convertToAssets(
        uint256 shares
    ) public view override returns (uint256) {
        return shares; // 1:1 ratio
    }

    // Since the ERC4626 implementation handles the minting and burning of shares,
    // and the transfer of assets, you don't need to override _deposit and _withdraw
    // unless you have additional logic to implement.
}
