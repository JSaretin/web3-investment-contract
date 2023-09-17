// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Plan.sol";

contract Admin is Plan {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "!owner");
        _;
    }

    function _setPlan(uint planID, uint percent, uint minDeposit) internal {
        availiblePlans[planID] = AvailiblePlan({
            id: planID,
            percent: percent,
            minDeposit: minDeposit
        });
    }

    function createPlan(uint percent, uint minDeposit) public onlyOwner {
        uint newPlanID = availiblePlansID.length + 1;
        _setPlan(newPlanID, percent, minDeposit);
        availiblePlansID.push(newPlanID);
    }

    function editPlan(
        uint planID,
        uint percent,
        uint minDeposit
    ) public onlyOwner {
        getPlan(planID); // check if the plan exist or revert if otherwise
        _setPlan(planID, percent, minDeposit);
    }

    function deletePlan(uint planID) public onlyOwner {}
}
