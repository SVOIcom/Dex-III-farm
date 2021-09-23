const configuration = require("../../scripts.conf");
const { loadDefaultContaracts } = require("../../utils/loadDefaultContract");
const { operationFlags } = require("../../utils/transferFlags");

async function main() {
    let contracts = await loadDefaultContaracts(false);

    let userAccountContract = await contracts.locklift.factory.getContract('UserAccount', configuration.buildDirectory);

    let codeUploadPayload = await contracts.farmContract.setUserAccountCode({
        userAccountCode_: userAccountContract.code
    });

    await contracts.msigWallet.transfer({
        destination: contracts.farmContract.address,
        value: contracts.locklift.utils.convertCrystal(1, 'nano'),
        flags: operationFlags.FEE_FROM_CONTRACT_BALANCE,
        bounce: false,
        payload: codeUploadPayload
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