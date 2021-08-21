const configuration = require("../../scripts.conf");
const initializeLocklift = require('../../utils/initializeLocklift');
const { loadContractData, writeContractData } = require('../../utils/migration/manageContractData');

async function main() {

    let locklift = await initializeLocklift(configuration.pathToLockliftConfig, configuration.network);

    let msigWallet = await loadContractData(locklift, configuration, `${configuration.network}_MsigWallet.json`);

    let farmContract = await locklift.factory.getContract('FarmContract', configuration.buildDirectory);
    farmContract.setKeyPair(msigWallet.keyPair);

    await locklift.giver.deployContract({
        contract: farmContract,
        constructorParams: {
            ownerAddress: msigWallet.address
        },
        initParams: {
            uniqueID: 0
        },
        keyPair: msigWallet.keyPair
    });

    writeContractData(farmContract, 'FarmContract.json');
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)