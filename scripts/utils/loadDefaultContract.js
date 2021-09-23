const { Farm, extendContractToFarm } = require("../farm/modules/extendContractToFarm");
const { UserAccount, extendContractToUserAccount } = require("../farm/modules/extendContractToUser");
const { MsigWallet, extendContractToWallet } = require("../wallet/modules/walletWrapper");

const { loadContractData } = require("./migration/manageContractData");

const initializeLocklift = require("./initializeLocklift");
const configuration = require("../scripts.conf");
const { Locklift } = require("locklift/locklift");

/**
 * @typedef {Object} DefaultContracts
 * @property {Locklift} locklift
 * @property {MsigWallet} msigWallet
 * @property {Farm} farmContract
 * @property {UserAccount} userAccountContract
 */

/**
 * @param {Boolean} userAccountContractExist
 * @returns {Promise<DefaultContracts>}
 */
async function loadDefaultContaracts(userAccountContractExist = true) {

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
    let userAccountContract;
    if (userAccountContractExist) {
        userAccountContract = await loadContractData(locklift, configuration, `${configuration.network}_UserAccount.json`);
    } else {
        userAccountContract = await locklift.factory.getContract('UserAccount', configuration.buildDirectory);
    }
    userAccountContract = extendContractToUserAccount(userAccountContract);

    return {
        locklift,
        msigWallet,
        farmContract,
        userAccountContract
    };
}

module.exports = {
    loadDefaultContaracts
}