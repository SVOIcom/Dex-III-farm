const { loadDefaultContaracts } = require("../../utils/loadDefaultContract");
const { operationFlags } = require("../../utils/transferFlags");
const { userParams } = require("../modules/userFarmParameters");

async function main() {
    let contracts = await loadDefaultContaracts();

    let enterFarmPayload = await contracts.userAccountContract.enterFarm({
        farm: contracts.farmContract.address,
        stackingTIP3UserWallet: userParams.stackingTIP3Wallet,
        rewardTIP3Wallet: userParams.rewardTIP3Wallet
    });

    await contracts.msigWallet.transfer({
        destination: contracts.userAccountContract.address,
        value: contracts.locklift.utils.convertCrystal(1, 'nano'),
        flags: operationFlags.FEE_FROM_CONTRACT_BALANCE,
        bounce: true,
        payload: enterFarmPayload
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