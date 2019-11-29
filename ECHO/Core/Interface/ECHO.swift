//
//  ECHO.swift
//  ECHO
//
//  Created by Fedorenko Nikita on 10.07.2018.
//  Copyright © 2018 PixelPlex. All rights reserved.
//

/// All facades in framework
public typealias InterfaceFacades = AuthentificationFacade
    & InformationFacade
    & SubscriptionFacade
    & FeeFacade
    & TransactionFacade
    & AssetsFacade
    & ContractsFacade
    & CustomOperationsFacade
    & EthFacade
    & BtcFacade

public protocol Startable {
    func start(completion: @escaping Completion<Bool>)
}

/**
     This is an  entry point of library.
 
     ## Important Notes ##
     1. All functions provided by the library are enclosed in this class.
     2. It is possible to replace standard classes of work with cryptography and a socket
     3. Modification of the library parameters is done using the **Settings** class in the constructor of the class
 */
// swiftlint:disable function_body_length
// swiftlint:disable type_body_length
final public class ECHO: InterfaceFacades, Startable {
    
    let revealFacade: RevealApiFacade
    let subscriptionFacade: SubscriptionFacade
    let informationFacade: InformationFacade
    let authentificationFacade: AuthentificationFacade
    let feeFacade: FeeFacade
    let transactionFacade: TransactionFacade
    let assetsFacade: AssetsFacade
    let contractsFacade: ContractsFacade
    let customOperationsFacade: CustomOperationsFacade
    let ethFacade: EthFacade
    let btcFacade: BtcFacade

    public init(settings: Settings) {

        let noticeEventProxy = NoticeEventProxyImp()
        let socketCore = SocketCoreComponentImp(messanger: settings.socketMessenger,
                                                url: settings.network.url,
                                                noticeUpdateHandler: noticeEventProxy,
                                                socketQueue: settings.workingQueue,
                                                timeout: settings.socketRequestsTimeout)
        
        let databaseService = DatabaseApiServiceImp(socketCore: socketCore)
        let cryptoService = CryptoApiServiceImp(socketCore: socketCore)
        let networkBroadcastService = NetworkBroadcastApiServiceImp(socketCore: socketCore)
        let historyService = AccountHistoryApiServiceImp(socketCore: socketCore)
        let networkNodesService = NetworkNodesApiServiceImp(socketCore: socketCore)
        let registrationService = RegistrationApiServiceImp(socketCore: socketCore)
        
        let revealServices = RevealFacadeServices(databaseService: databaseService,
                                                  cryptoService: cryptoService,
                                                  historyService: historyService,
                                                  networkBroadcastService: networkBroadcastService,
                                                  networkNodesService: networkNodesService,
                                                  registrationService: registrationService)
        revealFacade = RevealFacadeImp(socketCore: socketCore,
                                      options: settings.apiOptions,
                                      services: revealServices)
        
        let authServices = AuthentificationFacadeServices(databaseService: databaseService, networkBroadcastService: networkBroadcastService)
        authentificationFacade = AuthentificationFacadeImp(services: authServices, cryptoCore: settings.cryproComponent, network: settings.network)
        
        let informationServices = InformationFacadeServices(databaseService: databaseService,
                                                            historyService: historyService,
                                                            registrationService: registrationService)
        informationFacade = InformationFacadeImp(services: informationServices,
                                                 network: settings.network,
                                                 cryptoCore: settings.cryproComponent,
                                                 noticeDelegateHandler: noticeEventProxy)
        
        let subscriptionServices = SubscriptionServices(databaseService: databaseService)
        subscriptionFacade = SubscriptionFacadeImp(services: subscriptionServices,
                                                   noticeDelegateHandler: noticeEventProxy)
        
        let feeServices = FeeFacadeServices(databaseService: databaseService)
        feeFacade = FeeFacadeImp(services: feeServices,
                                 cryptoCore: settings.cryproComponent,
                                 network: settings.network,
                                 abiCoderCore: settings.abiCoderComponent,
                                 settings: settings)
        
        let transactoinServices = TransactionFacadeServices(databaseService: databaseService, networkBroadcastService: networkBroadcastService)
        transactionFacade = TransactionFacadeImp(services: transactoinServices,
                                                 cryptoCore: settings.cryproComponent,
                                                 network: settings.network,
                                                 noticeDelegateHandler: noticeEventProxy)
        
        let assetsServices = AssetsServices(databaseService: databaseService, networkBroadcastService: networkBroadcastService)
        assetsFacade = AssetsFacadeImp(services: assetsServices, cryptoCore: settings.cryproComponent, network: settings.network)
        
        let contractsServices = ContractsFacadeServices(databaseService: databaseService, networkBroadcastService: networkBroadcastService)
        contractsFacade = ContractsFacadeImp(services: contractsServices,
                                             cryptoCore: settings.cryproComponent,
                                             network: settings.network,
                                             abiCoder: settings.abiCoderComponent,
                                             noticeDelegateHandler: noticeEventProxy,
                                             settings: settings)
        
        let ethFacadeServices = EthFacadeServices(databaseService: databaseService, networkBroadcastService: networkBroadcastService)
        
        ethFacade = EthFacadeImp(services: ethFacadeServices,
                                 cryptoCore: settings.cryproComponent,
                                 network: settings.network,
                                 noticeDelegateHandler: noticeEventProxy)
        
        let btcFacadeServices = BtcFacadeServices(databaseService: databaseService, networkBroadcastService: networkBroadcastService)
        
        btcFacade = BtcFacadeImp(services: btcFacadeServices,
                                 cryptoCore: settings.cryproComponent,
                                 network: settings.network,
                                 noticeDelegateHandler: noticeEventProxy)
        
        let customOperationsServices = CustomOperationsFacadeServices(databaseService: databaseService,
                                                                      cryptoService: cryptoService,
                                                                      networkBroadcastService: networkBroadcastService,
                                                                      historyService: historyService,
                                                                      networkNodesService: networkNodesService,
                                                                      registrationService: registrationService)
        customOperationsFacade = CustomOperationsFacadeImp(services: customOperationsServices)
    }
    
/**
     Starts socket connection, connects to blockchain apis
 */
    public func start(completion: @escaping Completion<Bool>) {
        
        revealFacade.revealApi { [weak self] (result) in
            switch result {
            case .success(_):
                self?.subscriptionFacade.setSubscribeCallback(completion: completion )
            case .failure(_):
                completion(result)
            }
        }
    }
    
    // MARK: SubscriptionFacade
    
    public func setSubscribeCallback(completion: @escaping Completion<Bool>) {
        subscriptionFacade.setSubscribeCallback(completion: completion)
    }
    
    public func subscribeToAccount(nameOrId: String, delegate: SubscribeAccountDelegate) {
        subscriptionFacade.subscribeToAccount(nameOrId: nameOrId, delegate: delegate)
    }
    
    public func unsubscribeToAccount(nameOrId: String, delegate: SubscribeAccountDelegate) {
        subscriptionFacade.unsubscribeToAccount(nameOrId: nameOrId, delegate: delegate)
    }
    
    public func subscribeToDynamicGlobalProperties(delegate: SubscribeDynamicGlobalPropertiesDelegate) {
        subscriptionFacade.subscribeToDynamicGlobalProperties(delegate: delegate)
    }
    
    public func unsubscribeToDynamicGlobalProperties() {
        subscriptionFacade.unsubscribeToDynamicGlobalProperties()
    }
    
    public func subscribeToBlock(delegate: SubscribeBlockDelegate) {
        subscriptionFacade.subscribeToBlock(delegate: delegate)
    }
    
    public func unsubscribeToBlock() {
        subscriptionFacade.unsubscribeToBlock()
    }
    
    public func subscribeContracts(contractsIds: [String], delegate: SubscribeContractsDelegate) {
        subscriptionFacade.subscribeContracts(contractsIds: contractsIds, delegate: delegate)
    }
    
    public func unsubscribeToContracts(contractIds: [String], delegate: SubscribeContractsDelegate) {
        subscriptionFacade.unsubscribeToContracts(contractIds: contractIds, delegate: delegate)
    }
    
    public func subscribeToContractLogs(contractId: String, delegate: SubscribeContractLogsDelegate) {
        subscriptionFacade.subscribeToContractLogs(contractId: contractId, delegate: delegate)
    }
    
    public func unsubscribeToContractLogs(contractId: String, delegate: SubscribeContractLogsDelegate) {
        subscriptionFacade.subscribeToContractLogs(contractId: contractId, delegate: delegate)
    }
    
    public func unsubscribeAll() {
        subscriptionFacade.unsubscribeAll()
    }
    
    // MARK: AuthentificationFacade
    
    public func generateRandomWIF() -> String {
        return authentificationFacade.generateRandomWIF()
    }
    
    public func isOwnedBy(name: String, wif: String, completion: @escaping Completion<UserAccount>) {
        authentificationFacade.isOwnedBy(name: name, wif: wif, completion: completion)
    }
    
    public func isOwnedBy(wif: String, completion: @escaping Completion<[UserAccount]>) {
        authentificationFacade.isOwnedBy(wif: wif, completion: completion)
    }
    
    public func changeKeys(oldWIF: String, newWIF: String, name: String, completion: @escaping Completion<Bool>) {
        authentificationFacade.changeKeys(oldWIF: oldWIF, newWIF: newWIF, name: name, completion: completion)
    }
    
    // MARK: InformationFacade
    
    public func getObjects<T>(type: T.Type, objectsIds: [String], completion: @escaping (Result<[T], ECHOError>) -> Void) where T: Decodable {
        informationFacade.getObjects(type: type, objectsIds: objectsIds, completion: completion)
    }
    
    public func getBlock(blockNumber: Int, completion: @escaping Completion<Block>) {
        informationFacade.getBlock(blockNumber: blockNumber, completion: completion)
    }
    
    public func registerAccount(name: String, wif: String, completion: @escaping Completion<Bool>, noticeHandler: NoticeHandler?) {
        informationFacade.registerAccount(name: name, wif: wif, completion: completion, noticeHandler: noticeHandler)
    }
    
    public func getAccount(nameOrID: String, completion: @escaping Completion<Account>) {
        informationFacade.getAccount(nameOrID: nameOrID, completion: completion)
    }
    
    public func isAccountReserved(nameOrID: String, completion: @escaping Completion<Bool>) {
        informationFacade.isAccountReserved(nameOrID: nameOrID, completion: completion)
    }
    
    public func getBalance(nameOrID: String, asset: String?, completion: @escaping Completion<[AccountBalance]>) {
        informationFacade.getBalance(nameOrID: nameOrID, asset: asset, completion: completion)
    }
    
    public func getAccountHistroy(nameOrID: String, startId: String, stopId: String, limit: Int, completion: @escaping Completion<[HistoryItem]>) {
        informationFacade.getAccountHistroy(nameOrID: nameOrID, startId: startId, stopId: stopId, limit: limit, completion: completion)
    }
    
    public func getGlobalProperties(completion: @escaping Completion<GlobalProperties>) {
        informationFacade.getGlobalProperties(completion: completion)
    }

    // MARK: FeeFacade
    
    public func getFeeForTransferOperation(fromNameOrId: String,
                                           toNameOrId: String,
                                           amount: UInt,
                                           asset: String,
                                           assetForFee: String?,
                                           completion: @escaping Completion<AssetAmount>) {
        
        feeFacade.getFeeForTransferOperation(fromNameOrId: fromNameOrId,
                                             toNameOrId: toNameOrId,
                                             amount: amount,
                                             asset: asset,
                                             assetForFee: assetForFee,
                                             completion: completion)
    }
    
    public func getFeeForCreateContract(registrarNameOrId: String,
                                        wif: String,
                                        assetId: String,
                                        amount: UInt?,
                                        assetForFee: String?,
                                        byteCode: String,
                                        supportedAssetId: String?,
                                        ethAccuracy: Bool,
                                        completion: @escaping Completion<AssetAmount>) {
        
        feeFacade.getFeeForCreateContract(registrarNameOrId: registrarNameOrId,
                                          wif: wif,
                                          assetId: assetId,
                                          amount: amount,
                                          assetForFee: assetForFee,
                                          byteCode: byteCode,
                                          supportedAssetId: supportedAssetId,
                                          ethAccuracy: ethAccuracy,
                                          completion: completion)
    }
    
    public func getFeeForCreateContract(registrarNameOrId: String,
                                        wif: String,
                                        assetId: String,
                                        amount: UInt?,
                                        assetForFee: String?,
                                        byteCode: String,
                                        supportedAssetId: String?,
                                        ethAccuracy: Bool,
                                        parameters: [AbiTypeValueInputModel]?,
                                        completion: @escaping Completion<AssetAmount>) {
        
        feeFacade.getFeeForCreateContract(registrarNameOrId: registrarNameOrId,
                                          wif: wif,
                                          assetId: assetId,
                                          amount: amount,
                                          assetForFee: assetForFee,
                                          byteCode: byteCode,
                                          supportedAssetId: supportedAssetId,
                                          ethAccuracy: ethAccuracy,
                                          parameters: parameters,
                                          completion: completion)
    }
    
    public func getFeeForCallContractOperation(registrarNameOrId: String,
                                               assetId: String,
                                               amount: UInt?,
                                               assetForFee: String?,
                                               contratId: String,
                                               methodName: String,
                                               methodParams: [AbiTypeValueInputModel],
                                               completion: @escaping Completion<CallContractFee>) {
        
        feeFacade.getFeeForCallContractOperation(registrarNameOrId: registrarNameOrId,
                                                 assetId: assetId,
                                                 amount: amount,
                                                 assetForFee: assetForFee,
                                                 contratId: contratId,
                                                 methodName: methodName,
                                                 methodParams: methodParams,
                                                 completion: completion)
    }
    
    public func getFeeForCallContractOperation(registrarNameOrId: String,
                                               assetId: String,
                                               amount: UInt?,
                                               assetForFee: String?,
                                               contratId: String,
                                               byteCode: String,
                                               completion: @escaping Completion<CallContractFee>) {
        
        feeFacade.getFeeForCallContractOperation(registrarNameOrId: registrarNameOrId,
                                                 assetId: assetId,
                                                 amount: amount,
                                                 assetForFee: assetForFee,
                                                 contratId: contratId,
                                                 byteCode: byteCode,
                                                 completion: completion)
    }
    
    // MARK: TransactionFacade
    
    public func sendTransferOperation(fromNameOrId: String,
                                      wif: String,
                                      toNameOrId: String,
                                      amount: UInt,
                                      asset: String,
                                      assetForFee: String?,
                                      completion: @escaping Completion<Bool>,
                                      noticeHandler: NoticeHandler?) {
        
        transactionFacade.sendTransferOperation(fromNameOrId: fromNameOrId,
                                                wif: wif,
                                                toNameOrId: toNameOrId,
                                                amount: amount,
                                                asset: asset,
                                                assetForFee: assetForFee,
                                                completion: completion, noticeHandler: noticeHandler)
    }
    
    // MARK: AssetsFacade

    public func createAsset(nameOrId: String,
                            wif: String,
                            asset: Asset,
                            completion: @escaping Completion<Bool>) {
        
        assetsFacade.createAsset(nameOrId: nameOrId, wif: wif, asset: asset, completion: completion)
    }
    
    public func issueAsset(issuerNameOrId: String,
                           wif: String,
                           asset: String,
                           amount: UInt,
                           destinationIdOrName: String,
                           completion: @escaping Completion<Bool>) {
        
        assetsFacade.issueAsset(issuerNameOrId: issuerNameOrId,
                                wif: wif,
                                asset: asset,
                                amount: amount,
                                destinationIdOrName: destinationIdOrName,
                                completion: completion)
    }
    
    public func listAssets(lowerBound: String,
                           limit: Int,
                           completion: @escaping Completion<[Asset]>) {
        
        assetsFacade.listAssets(lowerBound: lowerBound, limit: limit, completion: completion)
    }
    
    public func getAsset(assetIds: [String],
                         completion: @escaping Completion<[Asset]>) {
        
        assetsFacade.getAsset(assetIds: assetIds, completion: completion)
    }
    
    // MARK: ContractsFacade
    
    public func getContractResult(contractResultId: String, completion: @escaping Completion<ContractResultEnum>) {
        
        contractsFacade.getContractResult(contractResultId: contractResultId, completion: completion)
    }
    
    public func getContractLogs(contractId: String, fromBlock: Int, toBlock: Int, completion: @escaping Completion<[ContractLogEnum]>) {
        
        contractsFacade.getContractLogs(contractId: contractId, fromBlock: fromBlock, toBlock: toBlock, completion: completion)
    }
    
    public func getContracts(contractIds: [String], completion: @escaping Completion<[ContractInfo]>) {
        
        contractsFacade.getContracts(contractIds: contractIds, completion: completion)
    }
    
    public func getContract(contractId: String, completion: @escaping Completion<ContractStructEnum>) {
        
        contractsFacade.getContract(contractId: contractId, completion: completion)
    }
    
    public func createContract(registrarNameOrId: String,
                               wif: String,
                               assetId: String,
                               amount: UInt?,
                               assetForFee: String?,
                               byteCode: String,
                               supportedAssetId: String?,
                               ethAccuracy: Bool,
                               parameters: [AbiTypeValueInputModel]?,
                               completion: @escaping Completion<Bool>,
                               noticeHandler: NoticeHandler?) {
        
        contractsFacade.createContract(registrarNameOrId: registrarNameOrId,
                                       wif: wif,
                                       assetId: assetId,
                                       amount: amount,
                                       assetForFee: assetForFee,
                                       byteCode: byteCode,
                                       supportedAssetId: supportedAssetId,
                                       ethAccuracy: ethAccuracy,
                                       parameters: parameters,
                                       completion: completion,
                                       noticeHandler: noticeHandler)
    }
    
    public func createContract(registrarNameOrId: String,
                               wif: String,
                               assetId: String,
                               amount: UInt?,
                               assetForFee: String?,
                               byteCode: String,
                               supportedAssetId: String?,
                               ethAccuracy: Bool,
                               completion: @escaping Completion<Bool>,
                               noticeHandler: NoticeHandler?) {
        
        contractsFacade.createContract(registrarNameOrId: registrarNameOrId,
                                       wif: wif,
                                       assetId: assetId,
                                       amount: amount,
                                       assetForFee: assetForFee,
                                       byteCode: byteCode,
                                       supportedAssetId: supportedAssetId,
                                       ethAccuracy: ethAccuracy,
                                       completion: completion,
                                       noticeHandler: noticeHandler)
    }
    
    public func callContract(registrarNameOrId: String,
                             wif: String,
                             assetId: String,
                             amount: UInt?,
                             assetForFee: String?,
                             contratId: String,
                             methodName: String,
                             methodParams: [AbiTypeValueInputModel],
                             completion: @escaping Completion<Bool>,
                             noticeHandler: NoticeHandler?) {
        
        contractsFacade.callContract(registrarNameOrId: registrarNameOrId,
                                     wif: wif,
                                     assetId: assetId,
                                     amount: amount,
                                     assetForFee: assetForFee,
                                     contratId: contratId,
                                     methodName: methodName,
                                     methodParams: methodParams,
                                     completion: completion,
                                     noticeHandler: noticeHandler)
    }
    
    public func callContract(registrarNameOrId: String,
                             wif: String,
                             assetId: String,
                             amount: UInt?,
                             assetForFee: String?,
                             contratId: String,
                             byteCode: String,
                             completion: @escaping Completion<Bool>,
                             noticeHandler: NoticeHandler?) {
        
        contractsFacade.callContract(registrarNameOrId: registrarNameOrId,
                                     wif: wif,
                                     assetId: assetId,
                                     amount: amount,
                                     assetForFee: assetForFee,
                                     contratId: contratId,
                                     byteCode: byteCode,
                                     completion: completion,
                                     noticeHandler: noticeHandler)
    }
    
    public func queryContract(registrarNameOrId: String,
                              amount: UInt,
                              assetId: String,
                              contratId: String,
                              methodName: String,
                              methodParams: [AbiTypeValueInputModel],
                              completion: @escaping Completion<String>) {
        
        contractsFacade.queryContract(registrarNameOrId: registrarNameOrId,
                                      amount: amount,
                                      assetId: assetId,
                                      contratId: contratId,
                                      methodName: methodName,
                                      methodParams: methodParams,
                                      completion: completion)
    }
    
    public func queryContract(registrarNameOrId: String,
                              amount: UInt,
                              assetId: String,
                              contratId: String,
                              byteCode: String,
                              completion: @escaping Completion<String>) {
        
        contractsFacade.queryContract(registrarNameOrId: registrarNameOrId,
                                      amount: amount,
                                      assetId: assetId,
                                      contratId: contratId,
                                      byteCode: byteCode,
                                      completion: completion)
    }
    
    // MARK: EthFacade
    
    public func generateEthAddress(nameOrId: String,
                                   wif: String,
                                   assetForFee: String?,
                                   completion: @escaping Completion<Bool>,
                                   noticeHandler: NoticeHandler?) {
        
        ethFacade.generateEthAddress(nameOrId: nameOrId,
                                     wif: wif,
                                     assetForFee: assetForFee,
                                     completion: completion,
                                     noticeHandler: noticeHandler)
    }
    
    public func getEthAddress(nameOrId: String, completion: @escaping Completion<EthAddress?>) {
        
        ethFacade.getEthAddress(nameOrId: nameOrId, completion: completion)
    }
    
    public func withdrawalEth(nameOrId: String,
                              wif: String,
                              toEthAddress: String,
                              amount: UInt,
                              assetForFee: String?,
                              completion: @escaping Completion<Bool>,
                              noticeHandler: NoticeHandler?) {
        
        ethFacade.withdrawalEth(nameOrId: nameOrId,
                                wif: wif,
                                toEthAddress: toEthAddress,
                                amount: amount,
                                assetForFee: assetForFee,
                                completion: completion,
                                noticeHandler: noticeHandler)
    }
    
    public func getEthAccountDeposits(nameOrId: String, completion: @escaping Completion<[EthDeposit]>) {
        
        ethFacade.getEthAccountDeposits(nameOrId: nameOrId, completion: completion)
    }
    
    public func getEthAccountWithdrawals(nameOrId: String, completion: @escaping Completion<[EthWithdrawal]>) {
        
        ethFacade.getEthAccountWithdrawals(nameOrId: nameOrId, completion: completion)
    }
    
    // MARK: BtcFacade
    
    public func generateBtcAddress(nameOrId: String,
                                   wif: String,
                                   backupAddress: String,
                                   assetForFee: String?,
                                   completion: @escaping Completion<Bool>,
                                   noticeHandler: NoticeHandler?) {
        
        btcFacade.generateBtcAddress(nameOrId: nameOrId,
                                     wif: wif,
                                     backupAddress: backupAddress,
                                     assetForFee: assetForFee,
                                     completion: completion,
                                     noticeHandler: noticeHandler)
    }
    
    public func getBtcAddress(nameOrId: String, completion: @escaping Completion<BtcAddress?>) {
        
        btcFacade.getBtcAddress(nameOrId: nameOrId, completion: completion)
    }
    
    public func withdrawalBtc(nameOrId: String,
                              wif: String,
                              toBtcAddress: String,
                              amount: UInt,
                              assetForFee: String?,
                              completion: @escaping Completion<Bool>,
                              noticeHandler: NoticeHandler?) {
        
        btcFacade.withdrawalBtc(nameOrId: nameOrId,
                                wif: wif,
                                toBtcAddress: toBtcAddress,
                                amount: amount,
                                assetForFee: assetForFee,
                                completion: completion,
                                noticeHandler: noticeHandler)
    }
    
    public func getBtcAccountDeposits(nameOrId: String, completion: @escaping Completion<[BtcDeposit]>) {
        
        btcFacade.getBtcAccountDeposits(nameOrId: nameOrId, completion: completion)
    }
    
    public func getBtcAccountWithdrawals(nameOrId: String, completion: @escaping Completion<[BtcWithdrawal]>) {
        
        btcFacade.getBtcAccountWithdrawals(nameOrId: nameOrId, completion: completion)
    }
    
    // MARK: CustomOperationsFacade
    
    public func sendCustomOperation(operation: CustomSocketOperation, for specificAPI: API) {
        
        customOperationsFacade.sendCustomOperation(operation: operation, for: specificAPI)
    }
}
// swiftlint:enable function_body_length
// swiftlint:enable type_body_length
