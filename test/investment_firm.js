const InvestmentFirm = artifacts.require("InvestmentFirm");

contract("InvestmentFirm", function (accounts) {
  it("can calculate reward", async function () {
    const contract = await InvestmentFirm.deployed();
    const data = {
      deposit: 1,
      percent: 20,
      time: 60 * 60 * 24 * 365, // reward for one year is 0.2 if 1 ETH is invested
    };
    let reward = await contract.calculateReward(
      web3.utils.toWei(data.deposit.toString(), "ether"),
      data.percent,
      data.time
    );
    assert.equal(
      Number(web3.utils.fromWei(reward, "ether")),
      (data.deposit * data.percent * data.time) / (100 * 60 * 60 * 24 * 365)
    );

    reward = await contract.calculateReward(
      web3.utils.toWei(data.deposit.toString(), "ether"),
      data.percent,
      data.time + 60 * 30
    );
    assert.equal(
      Number(web3.utils.fromWei(reward, "ether")),
      (data.deposit * data.percent * data.time) / (100 * 60 * 60 * 24 * 365),
      "expected reward not rounded"
    );
  });

  it("admin: can create plan", async function () {
    const contract = await InvestmentFirm.deployed();
    const plans = [
      { percent: 20, minDeposit: 1 },
      { percent: 10, minDeposit: 0.2 },
    ];
    for (const plan of plans) {
      await contract.createPlan(
        web3.utils.toWei(plan.percent.toString(), "ether"),
        web3.utils.toWei(plan.minDeposit.toString(), "ether"),
        { from: accounts[0] }
      );
    }
    const avaliblePlans = await contract.getPlans();
    assert.equal(avaliblePlans.length, 2);
  });

  it("user can invest", async function () {
    const contract = await InvestmentFirm.deployed();

    await contract.invest(1, accounts[2], {
      from: accounts[1],
      value: web3.utils.toWei("1", "ether"),
    });

    await contract.invest(2, accounts[2], {
      from: accounts[1],
      value: web3.utils.toWei("2", "ether"),
    });

    const investments = await contract.getInvestments(accounts[1]);
    assert.equal(investments.length, 2);
    const investment1 = await contract.getInvestment(accounts[1], 1);
    const investment2 = await contract.getInvestment(accounts[1], 2);

    assert.equal(investments[0].id, investment1.id, "id did not match");
    assert.equal(Number(web3.utils.fromWei(investment1.deposit, "ether")), 1);
    assert.equal(Number(web3.utils.fromWei(investment2.deposit, "ether")), 2);
  });

  it("user can withdraw earning", async function () {
    const contract = await InvestmentFirm.deployed();

    let investment = await contract.getInvestment(accounts[1], 1);

    assert.equal(Number(web3.utils.fromWei(investment.deposit, "ether")), 1);
    assert.isTrue(investment.isActive);

    web3.currentProvider.send(
      {
        jsonrpc: "2.0",
        method: "evm_increaseTime",
        params: 60 * 60 * 24 * 365, // one year, reward should be 0.2 ETH
        id: new Date().getTime(),
      },
      function (err, result) {}
    );

    const earning = await contract.getInvestmentEarning(investment);

    assert.equal(
      Number(await web3.utils.fromWei(earning, "ether")),
      0.2,
      "year reward supposed to be 0.2 ETH"
    );

    const accountBalance = await web3.eth.getBalance(accounts[5]);

    await contract.withdrawReward(1, earning, accounts[5], {
      from: accounts[1],
    });

    assert.equal(
      Number(web3.utils.fromWei(accountBalance, "ether")) + 0.2,
      Number(
        web3.utils.fromWei(await web3.eth.getBalance(accounts[5]), "ether")
      ),
      "coin not withdrawn"
    );
  });

  it("user can end investment if there enough coin", async function () {
    const contract = await InvestmentFirm.deployed();

    await contract.invest(1, accounts[1], {
      from: accounts[4],
      value: web3.utils.toWei("10", "ether"),
    });

    let investment = await contract.getInvestment(accounts[1], 1);
    assert.isTrue(investment.isActive);

    await contract.closeInvestment(1, {
      from: accounts[1],
    });

    investment = await contract.getInvestment(accounts[1], 1);
    assert.isNotTrue(investment.isActive);
  });
});
