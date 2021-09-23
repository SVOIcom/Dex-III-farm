const { loadDefaultContaracts } = require("../../utils/loadDefaultContract");
const { writeContractData } = require("../../utils/migration/manageContractData");
const { operationFlags } = require("../../utils/transferFlags");

async function main() {
    let contracts = await loadDefaultContaracts(false);

    contracts.userAccountContract.setKeyPair(contracts.msigWallet.keyPair);

    let userAccountDeployPayload = await contracts.farmContract.deployUserAccount({
        userAccountOwner: contracts.msigWallet.address
    });

    await contracts.msigWallet.transfer({
        destination: contracts.farmContract.address,
        value: contracts.locklift.utils.convertCrystal(2, 'nano'),
        flags: operationFlags.FEE_FROM_CONTRACT_BALANCE,
        bounce: false,
        payload: userAccountDeployPayload
    });

    let userAccountAddress = await contracts.farmContract.getUserAccountAddress({
        userAccountOwner: contracts.msigWallet.address
    });
    contracts.userAccountContract.setAddress(userAccountAddress);
    contracts.userAccountContract.setKeyPair(contracts.msigWallet.keyPair);

    writeContractData(contracts.userAccountContract, 'UserAccount.json');
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)