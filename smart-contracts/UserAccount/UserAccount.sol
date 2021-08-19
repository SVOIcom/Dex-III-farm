pragma ton-solidity >= 0.43.0;

import './interfaces/IUserAccount.sol';

import '../FarmContract/interfaces/IFarmContract.sol';

import '../utils/TIP3/interfaces/ITokensReceivedCallback.sol';
import '../utils/TIP3/interfaces/ITONTokenWallet.sol';


// TODO: защита от преждевременного стейка
// TODO: деплой кошелька для приёма токенов

/**
 * Процесс деплоя:
 * Создание контракта (constructor)
 */

 /**
  * Процесс входа в фармилку:
  * Запрос информации о фармилке
  * Запись инофрмации о фармилке
  * Деплой пустого кошелька для приёма платежей пользователя
  * Настройка кошелька -> запрет на переводы без notify_receiver
  */

contract UserAccount is ITokensReceivedCallback {

    address static owner;

    mapping (address => UserFarmInfo) farmInfo;
    mapping (address => address) knownTokenRoots;

    // Service value
    TvmCell empty;

    constructor() public {
        tvm.accept();
    }

    function enterFarm(address farm, address stackingTIP3UserWallet, address rewardTIP3) external onlyOwner {
        farmInfo[farm] = UserFarmInfo(0, 0, address.makeAddrStd(0, 0), stackingTIP3UserWallet, address.makeAddrStd(0, 0), rewardTIP3, 0, 0);
        IFarmContract(farm).fetchInfo{
            flags: 64,
            callback: receiveFarmInfo
        }();
    }

    function receiveFarmInfo(FarmInfo farmInfo_) external onlyKnownFarm(msg.sender) {
        address farm = msg.sender;
        farmInfo[farm].stackingTIP3WalletRoot = farmInfo_.stackingTIP3WalletRoot;
        farmInfo[farm].start = farmInfo_.startTime;
        farmInfo[farm].finish = farmInfo_.finishTime;
        knownTokenRoots[farmInfo._stackingTIP3Root] = farm;
        IRootTokenContract(farmInfo_.stackingTIP3WalletRoot).deployEmptyWallet{
            value: 0.8 ton
            callback: receiveTIP3Address
        }(
            0.4 ton,
            0,
            address(this),
            owner
        );
    }

    function receiveTIP3Address(address stackingTIP3Wallet) external onlyKnownTokenRoot {
        tmv.accept();
        farmInfo[farm].stackingTIP3Wallet = stackingTIP3Wallet;
        ITONTokenWallet(stackingTIP3Wallet).setReceivedCallback{
            value: 0.1 ton,
            flags: 1
        }(
            address(this),
            false
        );
    }

    function tokensReceivedCallback(
        address token_wallet,
        address token_root,
        uint128 amount,
        uint256 sender_public_key,
        address sender_address,
        address sender_wallet,
        address original_gas_to,
        uint128 updated_balance,
        TvmCell payload
    ) external override {
        TvmSlice s = payload.toSlice();
        address farm = s.decode(address);

        bool messageIsCorrect = 
            msg.sender == farmInfo[farm].stackingTIP3Wallet && 
            sender_wallet == farmInfo[farm].stackingTIP3UserWallet &&
            farmInfo.exists(farm) &&
            farmInfo[farm].start <= uint64(now);

        if (!messageIsCorrect) {
            ITONTokenWallet(msg.sender).transfer {
                value: 64
            }(
                sender_wallet,
                amount,
                0,
                original_gas_to,
                true,
                payload
            );
        } else {
            farmInfo[farm].tokensAmount = farmInfo[farm].tokensAmount + amount;

            IFarmContract(farm).tokensDepositedToFarm{
                flags: 64
            }(owner, tokensAmount, farmInfo[farm].tokens, farmInfo[farm].lastRewardTime, farmInfo[farm].rewardTIP3);    
        }
    }

    function withdrawPendingReward(address farm) external onlyOwner {
        IFarmContract(farm).withdrawPendingReward(owner, farmInfo[farm].tokensAmount, farmInfo[farm].lastRewardTime, farmInfo[farm].rewardTIP3);
    }

    function withdrawPartWithPendingReward(address farm, uint128 tokensToWithdraw) external onlyOwner onlyKnownFarm(farm) onlyActiveFarm(farm) {
        farmInfo[farm].tokensAmount = farmInfo[farm].tokensAmount - tokensToWithdraw;
        
        ITONTokenWallet(farmInfo[farm].stackingTIP3UserWallet).transfer{
            value: 0.15 ton
        }(
            farmInfo[farm].stackingTIP3UserWallet,
            tokensToWithdraw,
            0,
            owner,
            true,
            empty
        );

        IFarmContract(farm).withdrawWithPendingReward{
            flags: 64
        }(owner, tokensToWithdraw, farmInfo[farm].tokensAmount, farmInfo[farm].lastRewardTime, farmInfo[farm].rewardTIP3);
    };

    function withdrawAllWithPendingReward(address farm) external onlyOwner onlyKnownFarm(farm) onlyActiveFarm(farm) {
        require(msg.sender == owner);
        uint128 tokensToWithdraw = farmInfo[farm].tokensAmount;
        farmInfo[farm].tokensAmount = 0;

        ITONTokenWallet(farmInfo[farm].stackingTIP3UserWallet).transfer{
            value: 0.15 ton
        }(
            farmInfo[farm].stackingTIP3UserWallet,
            tokensToWithdraw,
            0,
            owner,
            true,
            empty
        );

        IFarmContract(farm).withdrawAllWithPendingReward{
            flags: 64
        }(owner, tokensToWithdraw, farmInfo[farm].lastRewardTime, farmInfo[farm].rewardTIP3);
    }

    function updateRewardTime(uint64 lastRewardTime) external onlyKnownFarm(msg.sender) {
        farmInfo[msg.sender].lastRewardTime = lastRewardTime;
        address(owner).transfer({flags: 64});
    }

    function createPayload(address farm) external responsible onlyKnownFarm(farm) returns(TvmCell) {
        TvmBuilder builder;
        builder.store(farm);
        return builder.toCell();
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    } 

    modifier onlyKnownFarm(address farm) {
        require(farmInfo.exists(farm));
        _;
    }

    modifier onlyKnownTokenRoot() {
        require(knownTokenRoots.exists(msg.sender));
        _;
    }

    modifier onlyActiveFarm(address farm) {
        require(farmInfo[farm].start <= uint64(now));
        _;
    }
}