const { loadDefaultContaracts } = require("../../utils/loadDefaultContract");
const { operationFlags } = require("../../utils/transferFlags");

async function main() {
    let contracts = await loadDefaultContaracts();

    console.log(await contracts.userAccountContract.getUserFarmInfo({
        farm: contracts.farmContract.address
    }));

    let rewardWithdrawPayload = await contracts.userAccountContract.withdrawPendingReward({
        farm: contracts.farmContract.address
    });

    await contracts.msigWallet.transfer({
        destination: contracts.userAccountContract.address,
        value: contracts.locklift.utils.convertCrystal(1, 'nano'),
        flags: operationFlags.FEE_FROM_CONTRACT_BALANCE,
        bounce: false,
        payload: rewardWithdrawPayload
    });

    console.log(await contracts.userAccountContract.getUserFarmInfo({
        farm: contracts.farmContract.address
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