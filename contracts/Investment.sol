// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Plan.sol";
import "./Referral.sol";
import "./Utils.sol";

contract Investment is Plan, Referral, Utils {
    event WithdrawReward(
        address indexed investor,
        address indexed to,
        uint amount
    );

    error InvestmentAlreadyClosed(uint investmentID);
    error InvestedAmountIsTooSmall(uint investedAmount, uint minInvestment);
    error CoinInActiveTrade(uint contractBalance, uint withdrawAmount);
    error AddressNotAllowed(address walletAddrss);
    error InvestmentEarningsTooLow(uint amount, uint earnings);
    error OwnerOnly();

    event CloseInvestment(address indexed investor, uint investmentID);

    struct UserInvestment {
        uint id;
        uint planID;
        uint deposit;
        uint createdOn;
        uint closedOn;
        bool isActive;
        uint withdrawnAmount;
        uint earnings;
    }

    struct User {
        uint[] investmentsID;
        uint referralReward;
        uint totalWithdrawn;
        uint totalInvested;
        uint activeInvestments;
        uint closedInvestments;
    }

    mapping(address => User) users;
    mapping(address => mapping(uint => UserInvestment)) usersInvestments;

    function getUserInvestmentsID(
        address investor
    ) public view returns (uint[] memory) {
        return users[investor].investmentsID;
    }

    function getInvestments(
        address investor
    ) external view returns (UserInvestment[] memory userInvestments) {
        userInvestments = new UserInvestment[](
            users[investor].investmentsID.length
        );
        for (
            uint index;
            index < users[investor].investmentsID.length;
            index++
        ) {
            userInvestments[index] = getInvestment(
                investor,
                users[investor].investmentsID[index]
            );
            userInvestments[index].earnings = getInvestmentEarning(
                userInvestments[index]
            );
        }
        return userInvestments;
    }

    function getInvestment(
        address investor,
        uint investmentID
    ) public view returns (UserInvestment memory) {
        /*
        return user investment
        revert if the investment ID passed is not valid
        */
        uint invesmentCounts = users[investor].investmentsID.length;
        require(investmentID > 0, "invalid investmentID");
        require(investmentID <= invesmentCounts, "invalid investmentID");
        return usersInvestments[investor][investmentID];
    }

    // Calculate user earning based on the invested amount
    // and the invested duration without writing to the smart
    // contract, else we will have to set up a background daemon
    // to auto update the earning which will waste gas fee for no reason.
    function getInvestmentEarning(
        UserInvestment memory investment
    ) public view returns (uint) {
        AvailiblePlan memory plan = getPlan(investment.planID);
        uint reward = calculateReward(
            investment.deposit,
            plan.percent,
            block.timestamp - investment.createdOn
        );
        return reward;
    }

    // user will able to invest in any of the availible plan, this function
    // will also take in the referral for the person investing (optional),
    // and reward the referral if the investor is new to the platform, else
    // we know the the person have previously invested and no need to reward
    // the referral.
    function invest(uint planID, address referral) public payable {
        AvailiblePlan memory plan = getPlan(planID);
        if (msg.value < plan.minDeposit)
            revert InvestedAmountIsTooSmall({
                investedAmount: msg.value,
                minInvestment: plan.minDeposit
            });
        // create new ID for the the new investment by getting all user investments
        // count and add 1 to it
        uint newInvestmentID = users[msg.sender].investmentsID.length + 1;

        // save the investment
        usersInvestments[msg.sender][newInvestmentID] = UserInvestment({
            id: newInvestmentID,
            planID: planID,
            deposit: msg.value,
            createdOn: block.timestamp,
            closedOn: 0,
            isActive: true,
            withdrawnAmount: 0,
            earnings: 0
        });
        // send the investment ID
        users[msg.sender].investmentsID.push(newInvestmentID);
        users[msg.sender].totalInvested += msg.value;

        // check continous referral is open, then reward the referral for every investment
        // made by the investor, else check if reward once is enable and reward the referral
        // for newly register investor.

        if (referrals[msg.sender].created) return;
        referrals[msg.sender].created = true;
        if (referral == address(0) || referral == msg.sender) return;

        referrals[msg.sender].referral = referral;
        rewardReferral(referral);
    }

    function _withdrawEarning(
        address investor,
        address to,
        uint investmentID,
        uint amount
    ) internal {
        // check if the contract balance is enough to complete the requested
        // withdraw and continue, else revert transaction

        uint contractBalance = address(this).balance;
        if (contractBalance < amount)
            revert CoinInActiveTrade({
                contractBalance: contractBalance,
                withdrawAmount: amount
            });

        usersInvestments[investor][investmentID].withdrawnAmount += amount;
        users[investor].totalWithdrawn += amount;

        emit WithdrawReward(investor, to, amount);
        payable(to).transfer(amount);
    }

    // user can withdraw their investment earning to any wallet
    // this function will get the investment earning with the function that
    // calculate the reward based on the duration of the investment and the amount
    function withdrawReward(uint investmentID, uint amount, address to) public {
        // investor is not allowed to withdraw to genesis address
        if (to == address(0)) revert AddressNotAllowed(to);
        UserInvestment memory investment = getInvestment(
            msg.sender,
            investmentID
        );
        uint investmentEarning = getInvestmentEarning(investment) -
            investment.withdrawnAmount;

        // get investment earning and remove the investors' previous withdrawal total
        // to get the current amount the investor can withdraw and check it the amount
        // is up to the amount the investor is trying to withdraw before proceeding, or revert
        if (investmentEarning < amount)
            revert InvestmentEarningsTooLow(amount, investmentEarning);

        _withdrawEarning(msg.sender, to, investmentID, amount);
    }

    // close active investment and return investor deposit and earnings
    function closeInvestment(uint investmentID) public {
        UserInvestment memory userInvestment = getInvestment(
            msg.sender,
            investmentID
        );

        // check if investor already ended this investment
        if (!userInvestment.isActive)
            revert InvestmentAlreadyClosed(investmentID);

        // close early incase user recall the function
        usersInvestments[msg.sender][investmentID].isActive = false;

        uint investmentEarning = getInvestmentEarning(userInvestment);
        uint leftEarning = investmentEarning - userInvestment.withdrawnAmount;
        uint totalToWithdraw = leftEarning + userInvestment.deposit;
        uint contractBalance = address(this).balance;

        // check if the smart contract balance is enough to close this investment
        // and repay user earning and deposit
        if (contractBalance < totalToWithdraw)
            revert CoinInActiveTrade({
                contractBalance: contractBalance,
                withdrawAmount: totalToWithdraw
            });

        // remove user earning before closing investment
        if (leftEarning > 0) {
            _withdrawEarning(msg.sender, msg.sender, investmentID, leftEarning);
        }
        emit CloseInvestment(msg.sender, investmentID);
        payable(msg.sender).transfer(userInvestment.deposit);
    }

    receive() external payable {}
}
