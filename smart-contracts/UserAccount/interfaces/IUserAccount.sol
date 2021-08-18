pragma ton-solidity >= 0.43.0;

struct UserFarmInfo {
    address tokenAmount;
    uint64 lastRewardTime;
    address stackingTIP3;
    address rewardTIP3;
}

interface IUserAccount {
    function enterFarm(address farm, address stackingTIP3, address rewardTIP3) external;

    function getInfo(address farm) external responsible returns (uint128 balance, uint64 lastRewardTime, address stackingTIP3, address rewardTIP3);

    function addTokens(uint128 tokensToAdd, uint64 currentTime) external returns (address owner, uint128 originalAmountOfTokens, address rewardTIP3, uint64 lastRewardTime);
    function removeTokens(uint256 tokens, uint64 bcTime) external;
    function setRewardTime(uint64 time) external;
}