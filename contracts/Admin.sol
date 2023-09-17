// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Plan.sol";
import {Investment} from "./Investment.sol";

contract Admin is Plan, Investment {
    address public owner;

    constructor() {}

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

    function _setReferralLevel(uint levelID, uint reward) internal {
        referralReward[levelID] = reward;
    }

    function addReferralLevel(uint reward) public onlyOwner {
        uint newLevelID = referralLevel.length;
        _setReferralLevel(newLevelID, reward);
        referralLevel.push(newLevelID);
    }

    function updateReferralLevel(uint levelID, uint reward) public onlyOwner {
        _setReferralLevel(levelID, reward);
    }

    function setPauseAll(bool status) public onlyOwner {
        setting.pauseAll = status;
    }

    function setPauseWithdraw(bool status) public onlyOwner {
        setting.pauseWithdraw = status;
    }

    function setPauseDeposit(bool status) public onlyOwner {
        setting.pauseDeposit = status;
    }

    function setRewardReferralOnce(bool status) public onlyOwner {
        setting.rewardReferralOnce = status;
    }

    function setReferralContiniousReward(bool status) public onlyOwner {
        setting.referralContiniousReward = status;
    }

    function updateSetting(
        bool _referralContiniousReward,
        bool _rewardReferralOnce,
        bool _pauseAll,
        bool _pauseWithdraw,
        bool _pauseDeposit
    ) public onlyOwner {
        setting = Setting({
            referralContiniousReward: _referralContiniousReward,
            rewardReferralOnce: _rewardReferralOnce,
            pauseAll: _pauseAll,
            pauseWithdraw: _pauseWithdraw,
            pauseDeposit: _pauseDeposit
        });
    }
}
