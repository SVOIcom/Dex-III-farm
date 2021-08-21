const configuration = require("../../scripts.conf");
const initializeLocklift = require("../../utils/initializeLocklift");
const { loadContractData } = require("../../utils/migration/manageContractData");
const { operationFlags } = require("../../utils/transferFlags");
const { MsigWallet, extendContractToWallet } = require("../../wallet/modules/walletWrapper");
const { Farm, extendContractToFarm } = require("../modules/extendContractToFarm");
const { farmingParameters } = require("../modules/farmParameters");

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

    let startFarmPayload = await farmContract.startFarming(farmingParameters);

    console.log(await msigWallet.transfer({
        destination: farmContract.address,
        value: locklift.utils.convertCrystal(2, 'nano'),
        flags: operationFlags.FEE_FROM_CONTRACT_BALANCE,
        bounce: false,
        payload: startFarmPayload
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