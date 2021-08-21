const configuration = require("../../scripts.conf");
const initializeLocklift = require("../../utils/initializeLocklift");
const { loadContractData, writeContractData } = require("../../utils/migration/manageContractData");
const { operationFlags } = require("../../utils/transferFlags");
const { extendContractToWallet, MsigWallet } = require("../../wallet/modules/walletWrapper");
const { extendContractToFarm, Farm } = require("../modules/extendContractToFarm");
const { UserAccount, extendContractToUserAccount } = require("../modules/extendContractToUser");

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

    /**
     * @type {UserAccount}
     */
    let userAccountContract = await locklift.factory.getContract('UserAccount', configuration.buildDirectory);
    userAccountContract = extendContractToUserAccount(userAccountContract);
    userAccountContract.setKeyPair(msigWallet.keyPair);

    let userAccountDeployPayload = await farmContract.deployUserAccount({
        userAccountOwner: msigWallet.address
    });

    await msigWallet.transfer({
        destination: farmContract.address,
        value: locklift.utils.convertCrystal(2, 'nano'),
        flags: operationFlags.FEE_FROM_CONTRACT_BALANCE,
        bounce: false,
        payload: userAccountDeployPayload
    });

    let userAccountAddress = await farmContract.getUserAccountAddress({
        userAccountOwner: msigWallet.address
    });
    userAccountContract.setAddress(userAccountAddress);
    userAccountContract.setKeyPair(msigWallet.keyPair);

    writeContractData(userAccountContract, 'AccountContract.json');
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)