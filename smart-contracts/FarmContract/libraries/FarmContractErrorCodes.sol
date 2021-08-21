pragma ton-solidity >= 0.39.0;

library FarmContractErrorCodes {
    uint8 constant ERROR_ONLY_OWNER = 100;
    uint8 constant ERROR_ONLY_REWARD_TIP3_ROOT = 101;
    uint8 constant ERROR_INVALID_USER_ACCOUNT = 102;
    uint8 constant ERROR_ONLY_ACTIVE_FARM = 103;
    uint8 constant ERROR_ONLY_INACTIVE_FARM = 104;
}
