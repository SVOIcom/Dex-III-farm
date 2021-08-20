pragma ton-solidity >= 0.43.0;

struct UserFarmInfo {
    uint128 stackedTokens;
    uint128 pendingReward;
    uint128 rewardPerTokenSum;

    address stackingTIP3Wallet;
    address stackingTIP3UserWallet;
    address stackingTIP3Root;
    address rewardTIP3Wallet;

    uint64 start;
    uint64 finish;
}

interface IUserAccount {
    function enterFarm(
        address farm, 
        address stackingTIP3UserWallet, 
        address rewardTIP3Wallet
    ) external;

    function withdrawPendingReward(
        address farm
    ) external;

    function withdrawPartWithPendingReward(
        address farm, 
        uint128 tokensToWithdraw
    ) external;

    function withdrawAllWithPendingReward(
        address farm
    ) external;

    function updateReward(
        address farm
    ) external;

    function udpateRewardInfo(
        uint128 userReward, 
        uint128 rewardPerTokenSum
    ) external;

    function getUserFarmInfo(
        address farm
    ) external responsible returns (UserFarmInfo);

    function getAllUserFarmInfo() external responsible returns (mapping(address => UserFarmInfo));

    function createPayload(
        address farm
    ) external responsible returns(TvmCell);
}