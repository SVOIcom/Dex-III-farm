const configuration = require("../../scripts.conf");
const initializeLocklift = require("../../utils/initializeLocklift");
const { writeContractData, loadContractData } = require("../../utils/migration/manageContractData");
const { operationFlags } = require("../../utils/transferFlags");
const { MsigWallet, extendContractToWallet } = require("../../wallet/modules/walletWrapper");
const { extendContractToFarm, Farm } = require("../modules/extendContractToFarm");

async function main() {
    let locklift = await initializeLocklift(configuration.pathToLockliftConfig, configuration.network);

    /**
     * @type {MsigWallet}
     */
    let msigWallet = await loadContractData(locklift, configuration, `${configuration.network}_MsigWallet.json`);
    msigWallet = extendContractToWallet(msigWallet);
    /**
     * @type {Farm}
     */
    let farmContract = await loadContractData(locklift, configuration, `${configuration.network}_FarmContract.json`);
    farmContract = extendContractToFarm(farmContract);

    let userAccountContract = await locklift.factory.getContract('UserAccount', configuration.buildDirectory);

    let codeUploadPayload = await farmContract.setUserAccountCode({
        userAccountCode_: userAccountContract.code
    });

    console.log(await msigWallet.transfer({
        destination: farmContract.address,
        value: locklift.utils.convertCrystal(1, 'nano'),
        flags: operationFlags.FEE_FROM_CONTRACT_BALANCE,
        bounce: false,
        payload: codeUploadPayload
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