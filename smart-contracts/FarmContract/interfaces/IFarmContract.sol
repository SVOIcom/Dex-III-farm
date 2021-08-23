pragma ton-solidity >= 0.43.0;

struct FarmInfo {
    address stackingTIP3Root;
    address rewardTIP3Root;
    address rewardTIP3Wallet;

    uint256 rewardPerTokenSum;
    uint128 totalReward;
    uint128 totalPayout;
    uint128 totalStacked;

    uint64 startTime;
    uint64 finishTime;
    uint64 duration;
    uint64 lastRPTSupdate;
}

interface IFarmContract {
    function setUserAccountCode(TvmCell userAccountCode_) external;

    function startFarming(
        address stackingTIP3Address, 
        address rewardTIP3Address, 
        uint128 totalReward,
        uint64 startTime,
        uint64 finishTime
    ) external;

    function tokensDepositedToFarm(
        address userAccountOwner, 
        uint128 tokensDeposited, 
        uint128 tokensAmount, 
        uint128 pendingReward,
        uint256 rewardPerTokenSum
    ) external;

    function withdrawPendingReward(
        address userAccountOwner, 
        uint128 tokenAmount, 
        uint128 pendingReward,
        uint256 rewardPerTokenSum
    ) external;
    
    function withdrawWithPendingReward(
        address userAccountOwner, 
        uint128 tokensToWithdraw, 
        uint128 originalTokensAmount, 
        uint128 pendingReward, 
        uint256 rewardPerTokenSum
    ) external;

    function updateUserReward(
        address userAccountOwner,
        uint128 tokenAmount,
        uint128 pendingReward,
        uint256 rewardPerTokenSum
    ) external;

    function calculateReward(
        uint128 tokenAmount,
        uint128 pendingReward, 
        uint256 rewardPerTokenSum
    ) external responsible returns(uint128);

    function payoutReward(
        address userAccountOwner,
        address rewardTIP3Wallet,
        uint128 userReward
    ) external;

    function deployUserAccount(address userAccountOwner) external;
    
    function endFarming(
        address sendTokensTo
    ) external;

    function getUserAccountAddress(address userAccountOwner) external responsible returns(address);

    function fetchInfo() external responsible returns(FarmInfo);
}