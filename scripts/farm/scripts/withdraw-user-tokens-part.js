const { loadDefaultContaracts } = require("../../utils/loadDefaultContract");
const { operationFlags } = require("../../utils/transferFlags");
const { userParams } = require("../modules/userFarmParameters");

async function main() {
    let contracts = await loadDefaultContaracts();

    let withdrawPayload = await contracts.userAccountContract.withdrawPartWithPendingReward({
        farm: contracts.farmContract.address,
        tokensToWithdraw: userParams.tokensForPartWithdraw
    });

    await contracts.msigWallet.transfer({
        destination: contracts.userAccountContract.address,
        value: contracts.locklift.utils.convertCrystal(1, 'nano'),
        flags: operationFlags.FEE_FROM_CONTRACT_BALANCE,
        bounce: false,
        payload: withdrawPayload
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