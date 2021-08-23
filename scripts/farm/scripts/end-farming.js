const { loadDefaultContaracts } = require("../../utils/loadDefaultContract");
const { operationFlags } = require("../../utils/transferFlags");
const { userParams } = require("../modules/userFarmParameters");

async function main() {
    let contracts = await loadDefaultContaracts();

    let endFarmingPayload = await contracts.farmContract.endFarming({
        sendTokensTo: userParams.rewardTIP3Wallet
    });

    console.log(await contracts.msigWallet.transfer({
        destination: contracts.farmContract.address,
        value: contracts.locklift.utils.convertCrystal(1, 'nano'),
        flags: operationFlags.FEE_FROM_CONTRACT_BALANCE,
        bounce: false,
        payload: endFarmingPayload
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