## InvestmentFirm

An investment smart contract that allowed user to invest in a plan and earn every hour, earned reward can be withdrawn at any time, the owner of the smart contract can tweak different part of the contract like setting referral level and reward. etc.

---

#### Features

* **Admin Functions** 
    : The owner (creator) of the smart contract can edit all the aspect of the smart contract including the specified below.

  - [x] Plan Creation
    > Owner can create new plans
  - [x] Plan Edition 
    > Edit plan detail like investment reward, reward interval, minimum deposit, and name.
  - [x] Referral Reward Setting
    > Set referral level, reward, continus reward *(meaning the referral of an investor will be rewarded for every investment made by the referree)*, reward once *(referral will be rewarded the first time the user makes an investment)*



* **User Function:**
    : These are the things an investor have control over

    - [x]  Investment
        > User can invest in availible plans
    - [x] Withdraw Investment Earning
        > Reward earned from investments can be withdrawn anything 
    - [x] End Investment
        > User can close an investment and remove all their invested coin at any time 


---


#### Advantages :+1:

* Offline Investment Reward  
    : Save us the stress to constantly monitor the blockchain with a background Daemon (or an oracle) to update the investor's investment reward.

    : We take the investment and calculate the earned reward based on the age of the investment and the percentage return of the invested plan.

    `((plan yearly return / 356) / 24) * (duration / 24) * invested amount = hourly reward` 

```Solidity

function calculateReward(
    uint amount,
    uint yearlyPercent,
    uint duration
) public pure returns (uint) {
    uint reward = ((yearlyPercent / 356) / 24) * (duration / 24) * amount;
    return reward - (reward % 1 hours);
}

function getInvestmentEarning(UserInvestment memory investment) public view returns (uint) {
    AvailiblePlan memory plan = getPlan(investment.planID);
    uint reward = calculateReward(
        investment.deposit,
        plan.percent,
        block.timestamp - investment.createdOn
    );
    return reward;
}
```


