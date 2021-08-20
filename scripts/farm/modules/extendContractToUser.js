const Contract = require("locklift/locklift/contract");
const { encodeMessageBody } = require("../../utils/utils");


class UserAccount extends Contract {
    async enterFarm({ farm, stackingTIP3UserWallet, rewardTIP3 }) {}

    async withdrawPendingReward({ farm }) {}

    async withdrawPartWithPendingReward({ farm, tokensToWithdraw }) {}

    async withdrawAllWithPendingReward({ farm }) {}

    async createPayload({ farm }) {}
}

/**
 * 
 * @param {Contract} contract 
 * @returns {UserAccount}
 */
function extendContractToUserAccount(contract) {

}