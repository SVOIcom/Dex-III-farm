const Contract = require("locklift/locklift/contract");
const { encodeMessageBody } = require("../../utils/utils");


class UserAccount extends Contract {
    /**
     * Enter farm contract
     * @param {Object} params 
     * @param {String} params.farm
     * @param {String} params.stackingTIP3UserWallet
     * @param {String} params.rewardTIP3
     */
    async enterFarm({ farm, stackingTIP3UserWallet, rewardTIP3Wallet }) {}

    /**
     * Withdraw pending reward without removing stack
     * @param {Object} params
     * @param {String} params.farm 
     */
    async withdrawPendingReward({ farm }) {}

    /**
     * Withdraw pending reward with part of stack
     * @param {Object} params
     * @param {String} params.farm
     * @param {String} params.tokensToWithdraw
     */
    async withdrawPartWithPendingReward({ farm, tokensToWithdraw }) {}

    /**
     * Withdraw pending reward with all stack
     * @param {Object} params 
     * @param {String} params.farm
     */
    async withdrawAllWithPendingReward({ farm }) {}

    /**
     * Update reward info
     * @param {Object} params 
     * @param {String} params.farm
     */
    async updateReward({ farm }) {}

    /**
     * Get information about user's farm info
     * @param {Object} params 
     * @param {String} params.farm
     */
    async getUserFarmInfo({ farm }) {}

    async getAllUserFarmInfo() {}

    /**
     * Create payload for entering farm
     * @param {Object} params 
     * @param {String} params.farm
     */
    async createPayload({ farm }) {}
}

/**
 * Extend Contract object to UserAccount class
 * @param {Contract} contract 
 * @returns {UserAccount}
 */
function extendContractToUserAccount(contract) {

    contract.enterFarm = async function({ farm, stackingTIP3UserWallet, rewardTIP3Wallet }) {
        return await encodeMessageBody({
            contract: contract,
            functionName: 'enterFarm',
            input: {
                farm: farm,
                stackingTIP3UserWallet: stackingTIP3UserWallet,
                rewardTIP3Wallet: rewardTIP3Wallet
            }
        });
    }

    contract.withdrawPendingReward = async function({ farm }) {
        return await encodeMessageBody({
            contract: contract,
            functionName: 'withdrawPendingReward',
            input: {
                farm: farm
            }
        });
    }

    contract.withdrawPartWithPendingReward = async function({ farm, tokensToWithdraw }) {
        return await encodeMessageBody({
            contract: contract,
            functionName: 'withdrawPartWithPendignReward',
            input: {
                farm: farm,
                tokensToWithdraw: tokensToWithdraw
            }
        });
    }

    contract.withdrawAllWithPendingReward = async function({ farm }) {
        return await encodeMessageBody({
            contract: contract,
            functionName: 'withdrawAllWithPendingReward',
            input: {
                farm: farm
            }
        });
    }

    contract.updateReward = async function({ farm }) {
        return await encodeMessageBody({
            contract: contract,
            functionName: 'updateReward',
            input: {
                farm: farm
            }
        });
    }

    contract.getUserFarmInfo = async function({ farm }) {
        return await contract.call({
            method: 'getUserFarmInfo',
            params: {
                farm: farm
            },
            keyPair: contract.keyPair
        });
    }

    contract.getAllUserFarmInfo = async function() {
        return await contract.call({
            method: 'getAllUserFarmInfo',
            params: {},
            keyPair: contract.keyPair
        });
    }

    return contract;
}

module.exports = {
    UserAccount,
    extendContractToUserAccount
}