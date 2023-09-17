// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract Plan {
    struct AvailiblePlan {
        uint id;
        uint percent;
        uint minDeposit;
    }

    mapping(uint => AvailiblePlan) availiblePlans;
    uint[] availiblePlansID;

    function getPlan(uint planID) public view returns (AvailiblePlan memory) {
        require(
            planID != 0 && planID <= availiblePlansID.length,
            "invalid plan ID"
        );
        return availiblePlans[planID];
    }

    function getPlans() public view returns (AvailiblePlan[] memory plans) {
        plans = new AvailiblePlan[](availiblePlansID.length);
        for (uint index; index < availiblePlansID.length; index++) {
            plans[index] = getPlan(availiblePlansID[index]);
        }
        return plans;
    }

    function getPlansID() public view returns (uint[] memory) {
        return availiblePlansID;
    }
}
