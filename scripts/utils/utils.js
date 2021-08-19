const { abiContract, signerNone } = require("@tonclient/core")
const Contract = require("locklift/locklift/contract")

/**
 * Encode message body
 * @param {Object} encodeMessageBodyParameters
 * @param {Contract} encodeMessageBodyParameters.contract 
 * @param {String} encodeMessageBodyParameters.functionName 
 * @param {JSON} encodeMessageBodyParameters.input 
 * @returns 
 */
async function encodeMessageBody({
    contract,
    functionName,
    input
}) {
    return (await contract.locklift.ton.client.abi.encode_message_body({
        abi: abiContract(contract.abi),
        call_set: {
            function_name: functionName,
            input: input
        },
        is_internal: true,
        signer: signerNone()
    })).body;
}

function describeTransaction(tx) {
    let description = '';
    description += `Tx ${tx.compute.success == true ? 'success':'fail'}\n`;
    description += `Fees: ${tx.fees.total_account_fees}`;
    return description;
}

const stringToBytesArray = (dataString) => {
    return Buffer.from(dataString).toString('hex')
};

module.exports = {
    encodeMessageBody,
    describeTransaction,
    stringToBytesArray
}