const { loadDefaultContaracts } = require("../../utils/loadDefaultContract");
const { operationFlags } = require("../../utils/transferFlags");
const { farmingParameters } = require("../modules/farmParameters");

async function main() {
    let contracts = await loadDefaultContaracts(false);

    let startFarmPayload = await contracts.farmContract.startFarming(farmingParameters);

    await contracts.msigWallet.transfer({
        destination: contracts.farmContract.address,
        value: contracts.locklift.utils.convertCrystal(2, 'nano'),
        flags: operationFlags.FEE_FROM_CONTRACT_BALANCE,
        bounce: false,
        payload: startFarmPayload
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