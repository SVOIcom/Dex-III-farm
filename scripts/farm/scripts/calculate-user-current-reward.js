const { loadDefaultContaracts } = require("../../utils/loadDefaultContract");

async function main() {
    let contracts = await loadDefaultContaracts();

    let userInfo = await contracts.userAccountContract.getUserFarmInfo({
        farm: contracts.farmContract.address
    });

    console.log(await contracts.farmContract.calculateReward({
        tokenAmount: String(userInfo.stackedTokens),
        pendingReward: String(userInfo.pendingReward),
        rewardPerTokenSum: String(userInfo.rewardPerTokenSum)
    }));
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)