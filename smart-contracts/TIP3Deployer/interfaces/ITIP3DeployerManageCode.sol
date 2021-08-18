pragma ton-solidity >= 0.39.0;

interface ITIP3DeployerManageCode {
    function setTIP3RootContractCode(TvmCell rootContractCode_) external;

    function setTIP3WalletContractCode(TvmCell walletContractCode_) external;
}