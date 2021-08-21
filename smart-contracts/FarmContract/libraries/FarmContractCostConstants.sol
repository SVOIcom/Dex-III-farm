pragma ton-solidity >= 0.39.0;

library FarmContractCostConstants {
    uint128 constant updateUserInfo = 0.1 ton;
    uint128 constant sendToDeployTIP3Wallet = 0.6 ton;
    uint128 constant deployTIP3Wallet = 0.4 ton;
    uint128 constant sendToGetAddress = 0.2 ton;
    uint128 constant deployUserAccount = 1 ton;
}