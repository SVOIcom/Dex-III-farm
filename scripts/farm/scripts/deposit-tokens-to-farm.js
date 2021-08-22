const configuration = require("../../scripts.conf");
const { loadDefaultContaracts } = require("../../utils/loadDefaultContract");
const { loadContractData } = require("../../utils/migration/manageContractData");
const { operationFlags } = require("../../utils/transferFlags");
const { extendContractToTIP3Wallet, TIP3Wallet } = require("../../wallet/modules/tip3WalletWrapper");
const { userParams } = require("../modules/userFarmParameters");


async function main() {
    let contracts = loadDefaultContaracts();

    /**
     * @type {TIP3Wallet}
     */
    let tip3WalletContract = await loadContractData(contracts.locklift, configuration, `${configuration.network}_StackingWallet.json`);
    tip3WalletContract = extendContractToTIP3Wallet(tip3WalletContract);

    let farmPayload = await contracts.userAccountContract.createPayload({
        farm: contracts.farmContract.address
    });

    let userAccountInfo = await contracts.userAccountContract.getUserFarmInfo({
        farm: contracts.farmContract.address
    });

    let stackingWalletAddress = userAccountInfo.stackingTIP3Wallet;

    let tip3Payload = await tip3WalletContract.transfer({
        to: stackingWalletAddress,
        tokens: userParams.tokensToTransfer,
        grams: 0,
        send_gas_to: contracts.msigWallet.address,
        notify_receiver: true,
        payload: farmPayload
    });

    await contracts.msigWallet.transfer({
        destination: tip3WalletContract.address,
        value: contracts.locklift.utils.convertCrystal(1, 'nano'),
        flags: operationFlags.FEE_FROM_CONTRACT_BALANCE,
        bounce: true,
        payload: tip3Payload
    });

    console.log(await userAccountContract.getUserFarmInfo({
        farm: contracts.farmContract.address
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