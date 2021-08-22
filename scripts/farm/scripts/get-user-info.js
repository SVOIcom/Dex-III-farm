const configuration = require("../../scripts.conf");
const { loadDefaultContaracts } = require("../../utils/loadDefaultContract");
const { loadContractData } = require("../../utils/migration/manageContractData");

async function main() {
    let contracts = await loadDefaultContaracts();

    console.log(await contracts.userAccountContract.call({
        method: 'getAllUserFarmInfo',
        params: {},
        keyPair: userAccountContract.keyPair
    }));

    console.log(await contracts.userAccountContract.getUserFarmInfo({
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