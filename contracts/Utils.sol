// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract Utils {
    function calculateReward(
        uint amount,
        uint yearlyPercent,
        uint duration
    ) public pure returns (uint) {
        uint secRemain = duration % (60 * 60);
        duration = duration - secRemain;
        return (amount * yearlyPercent * duration) / (100 * 60 * 60 * 24 * 365);
    }
}
