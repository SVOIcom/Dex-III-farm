const { loadDefaultContaracts } = require("../../utils/loadDefaultContract");
const { operationFlags } = require("../../utils/transferFlags");

async function main() {
    let contracts = loadDefaultContaracts();

    let enterFarmPayload = await contracts.userAccountContract.enterFarm({
        farm: contracts.farmContract.address,
        stackingTIP3UserWallet: '0:b82108b18f6e7f04633ea66602505b4bf4106f380156d3185437667bd104ff18',
        rewardTIP3Wallet: '0:8e97c6ad4738c2ffa42b54523f080b067be2ad8f31517952c49806e12ff67196'
    });

    await contracts.msigWallet.transfer({
        destination: contracts.userAccountContract.address,
        value: contracts.locklift.utils.convertCrystal(3, 'nano'),
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