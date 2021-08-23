const { loadDefaultContaracts } = require("../../utils/loadDefaultContract");
const { operationFlags } = require("../../utils/transferFlags");

async function main() {
    let contracts = await loadDefaultContaracts();

    console.log(await contracts.userAccountContract.getUserFarmInfo({
        farm: contracts.farmContract.address
    }));

    let withdrawAllTokensPayload = await contracts.userAccountContract.withdrawAllWithPendingReward({
        farm: contracts.farmContract.address
    });

    await contracts.msigWallet.transfer({
        destination: contracts.userAccountContract.address,
        value: contracts.locklift.utils.convertCrystal(1, 'nano'),
        flags: operationFlags.FEE_FROM_CONTRACT_BALANCE,
        bounce: true,
        payload: withdrawAllTokensPayload,
    });
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)