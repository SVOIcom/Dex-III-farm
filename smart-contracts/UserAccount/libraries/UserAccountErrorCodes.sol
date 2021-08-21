pragma ton-solidity >= 0.39.0;

library UserAccountErrorCodes {
    uint8 constant ERROR_ONLY_OWNER = 100;
    uint8 constant ERROR_ONLY_KNOWN_FARM = 101;
    uint8 constant ERROR_ONLY_UNKNOWN_FARM = 102;
    uint8 constant ERROR_ONLY_KNOWN_TOKEN_ROOT = 103;
    uint8 constant ERROR_ONLY_ACTIVE_FARM = 104;
    uint8 constant ERROR_ZERO_ADDRESS = 105;
}