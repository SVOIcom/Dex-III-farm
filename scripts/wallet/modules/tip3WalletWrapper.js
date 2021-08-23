const Contract = require('locklift/locklift/contract');
const { encodeMessageBody } = require('../../utils/utils');

class TIP3Wallet extends Contract {
    /**
     * 
     * @param {Object} params
     * @param {String} params.to
     * @param {String} params.tokens
     * @param {String} params.grams
     * @param {String} params.send_gas_to
     * @param {String} params.notify_receiver
     * @param {String} params.payload 
     */
    async transfer({ to, tokens, grams, send_gas_to, notify_receiver, payload }) {}
}

/**
 * @param {Contract}
 * @returns {TIP3Wallet}
 */
function extendContractToTIP3Wallet(contract) {

    contract.transfer = async function({ to, tokens, grams, send_gas_to, notify_receiver, payload }) {
        return await encodeMessageBody({
            contract: contract,
            functionName: 'transfer',
            input: {
                to,
                tokens,
                grams,
                send_gas_to,
                notify_receiver,
                payload
            }
        });
    }

    return contract;
}

module.exports = {
    TIP3Wallet,
    extendContractToTIP3Wallet
}