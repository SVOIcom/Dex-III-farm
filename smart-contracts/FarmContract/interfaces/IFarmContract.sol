pragma ton-solidity >= 0.43.0;

struct FarmInfo {
    address stackingTIP3Root;
    address rewardTIP3Root;
    address rewardTIP3Wallet;

    uint128 totalReward;
    uint128 totalPayout;
    uint128 totalStacked;

    uint64 startTime;
    uint64 finishTime;
    uint64 duration;
}

interface IFarmContract {
    function setUserAccountCode(TvmCell userAccountCode_) external;
    function startFarming(
        address stackingTIP3Address_, 
        address rewardTIP3Address_, 
        address rewardTIP3Wallet_, 
        uint128 totalReward,
        uint64 startTime_,
        uint64 finishTime_
    ) external;

    function tokensDepositedToFarm(address userAccountOwner, uint128 tokensDeposited, uint128 tokensAmount, uint64 lastRewardTime, address rewardWallet) external;

    function withdrawPendingReward(address userAccountOwner, uint128 tokenAmount, uint64 lastRewardTime, address rewardWallet) external;

    function withdrawWithPendingReward(address userAccountOwner, uint128 tokensToWithdraw, uint128 originalTokensAmount, uint64 lastRewardTime, address rewardWallet) external;

    function calculateReward(uint128 tokenAmount, uint64 lastRewardTime) external responsible returns(uint128);

    function deployUserAccount(address userAccountOwner) external;

    function getUserAccountAddress(address userAccountOwner) external responsilbe returns(address);

    function fetchInfo() external responsible returns(FarmInfo);
    
}