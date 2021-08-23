const Contract = require("locklift/locklift/contract");
const { encodeMessageBody } = require("../../utils/utils");
/**
 * @name Farm
 * @class
 * @classdesc Interface for Farm contract
 * @augments Contract
 */
class Farm extends Contract {

    /**
     * Set user account code to farm contract
     * @param {Object} params
     * @param {String} params.userAccountCode_ 
     * @returns {Promise<Object>}
     */
    async setUserAccountCode({ userAccountCode_ }) {}

    /**
     * Initialize farming
     * @param {Object} params
     * @param {String} params.stackingTIP3Address
     * @param {String} params.rewardTIP3Address
     * @param {String} params.totalReward
     * @param {String} params.startTime
     * @param {String} params.finishTime
     * @returns {Promise<Object>}
     */
    async startFarming({ stackingTIP3Address, rewardTIP3Address, totalReward, startTime, finishTime }) {}

    /**
     * Calculate reward for user
     * @param {Object} params
     * @param {String} params.tokenAmount
     * @param {String} params.pendingReward
     * @param {String} params.rewardPerTokenSum
     * @returns {Promise<Object>}
     */
    async calculateReward({ tokenAmount, pendingReward, rewardPerTokenSum }) {}

    /**
     * Deploy user account
     * @param {Object} params
     * @param {String} params.userAccountOwner 
     * @returns {Promise<Object>}
     */
    async deployUserAccount({ userAccountOwner }) {}

    /**
     * Destroy farm
     * @param {Object} params 
     * @param {String} params.sendTokensTo
     */
    async endFarming({ sendTokensTo }) {}

    /**
     * Get user account address if userAccountOwner address is known
     * @param {Object} params
     * @param {String} params.userAccountOwner 
     * @returns {Promise<Object>}
     */
    async getUserAccountAddress({ userAccountOwner }) {}

    /**
     * Fetch information from farm contract about current farm status
     * @returns {Promise<Object>}
     */
    async fetchInfo() {}
}


/**
 * Extend contract to Farm contract
 * @param {Contract} contract 
 * @returns {Farm}
 */
function extendContractToFarm(contract) {
    contract.setUserAccountCode = async function({ userAccountCode_ }) {
        return await encodeMessageBody({
            contract: contract,
            functionName: 'setUserAccountCode',
            input: {
                userAccountCode_: userAccountCode_
            }
        });
    }

    contract.startFarming = async function({ stackingTIP3Address, rewardTIP3Address, totalReward, startTime, finishTime }) {
        return await encodeMessageBody({
            contract: contract,
            functionName: 'startFarming',
            input: {
                stackingTIP3Address: stackingTIP3Address,
                rewardTIP3Address: rewardTIP3Address,
                totalReward: totalReward,
                startTime: startTime,
                finishTime: finishTime
            }
        });
    }

    contract.calculateReward = async function({ tokenAmount, pendingReward, rewardPerTokenSum }) {
        return await contract.call({
            method: 'calculateReward',
            params: {
                tokenAmount: tokenAmount,
                pendingReward: pendingReward,
                rewardPerTokenSum: rewardPerTokenSum
            },
            keyPair: contract.keyPair
        });
    }

    contract.deployUserAccount = async function({ userAccountOwner }) {
        return await encodeMessageBody({
            contract: contract,
            functionName: 'deployUserAccount',
            input: {
                userAccountOwner: userAccountOwner
            }
        });
    }

    contract.endFarming = async function({ sendTokensTo }) {
        return await encodeMessageBody({
            contract: contract,
            functionName: 'endFarming',
            input: {
                sendTokensTo: sendTokensTo
            }
        });
    }

    contract.getUserAccountAddress = async function({ userAccountOwner }) {
        return await contract.call({
            method: 'getUserAccountAddress',
            params: {
                userAccountOwner: userAccountOwner
            },
            keyPair: contract.keyPair
        });
    }

    contract.fetchInfo = async function() {
        return await contract.call({
            method: 'fetchInfo',
            params: {},
            keyPair: contract.keyPair
        });
    }

    return contract;
}

module.exports = {
    Farm,
    extendContractToFarm
}