//
//  DatabaseApiServiceImp.swift
//  ECHO
//
//  Created by Fedorenko Nikita on 18.07.2018.
//

/**
     Implementation of [DatabaseApiService](DatabaseApiService)

     Encapsulates logic of preparing API calls to [SocketCoreComponent](SocketCoreComponent)
 */
final class DatabaseApiServiceImp: DatabaseApiService, ApiIdentifireHolder {
    
    var apiIdentifire: Int = 0
    let socketCore: SocketCoreComponent
    
    required init(socketCore: SocketCoreComponent) {
        self.socketCore = socketCore
    }
    
    func getBlockData(completion: @escaping Completion<BlockData>) {
        
        let operation = BlockDataSocketOperation(method: .call, operationId: socketCore.nextOperationId(), apiId: apiIdentifire) { (result) in
            switch result {
            case .success(let dynamicProperties):
                
                let headBlockId = dynamicProperties.headBlockId
                let headBlockNumber = dynamicProperties.headBlockNumber
                
                let dateFormatter = DateFormatter()
                dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                dateFormatter.dateFormat = Settings.defaultDateFormat
                
                let date = dateFormatter.date(from: dynamicProperties.time)
                let interval = date?.timeIntervalSince1970 ?? 0
                let expirationTime = Int(interval) + Transaction.defaultExpirationTime

                let blockData = BlockData(headBlockNumber: headBlockNumber, headBlockId: headBlockId, relativeExpiration: expirationTime)
                let result = Result<BlockData, ECHOError>(value: blockData)
                completion(result)
            case .failure(let error):
                let result = Result<BlockData, ECHOError>(error: error)
                completion(result)
            }
        }
        
        socketCore.send(operation: operation)
    }
    
    func getBlock(blockNumber: Int, completion:@escaping Completion<Block>) {
        
        let operation = GetBlockSocketOperation(method: .call,
                                                operationId: socketCore.nextOperationId(),
                                                apiId: apiIdentifire,
                                                blockNumber: blockNumber,
                                                completion: completion)
        
        socketCore.send(operation: operation)
    }
    
    func getChainId(completion: @escaping Completion<String>) {
        
        let operation = GetChainIdSocketOperation(method: .call,
                                                  operationId: socketCore.nextOperationId(),
                                                  apiId: apiIdentifire,
                                                  completion: completion)
        
        socketCore.send(operation: operation)
    }
    
    func getFullAccount(nameOrIds: [String], shoudSubscribe: Bool, completion: @escaping Completion<[String: UserAccount]>) {
        
        let operation = FullAccountSocketOperation(method: .call,
                                                   operationId: socketCore.nextOperationId(),
                                                   apiId: apiIdentifire,
                                                   accountsIds: nameOrIds,
                                                   shoudSubscribe: shoudSubscribe,
                                                   completion: completion)
        
        socketCore.send(operation: operation)
    }
    
    func getRequiredFees(operations: [BaseOperation], asset: Asset, completion: @escaping Completion<[AssetAmount]>) {
        
        let operation = RequiredFeeSocketOperation(method: .call,
                                                   operationId: socketCore.nextOperationId(),
                                                   apiId: apiIdentifire,
                                                   operations: operations,
                                                   asset: asset,
                                                   completion: completion)
        
        socketCore.send(operation: operation)
    }
    
    func setSubscribeCallback(completion: @escaping Completion<Bool>) {
        let operation = SetSubscribeCallbackSocketOperation(method: .call,
                                                            operationId: socketCore.nextOperationId(),
                                                            apiId: apiIdentifire,
                                                            needClearFilter: false,
                                                            completion: completion)
        socketCore.send(operation: operation)
    }
}
