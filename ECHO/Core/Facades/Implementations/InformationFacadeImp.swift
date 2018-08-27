//
//  InformationFacadeImp.swift
//  BitcoinKit
//
//  Created by Fedorenko Nikita on 19.07.2018.
//

struct InformationFacadeServices {
    var databaseService: DatabaseApiService
    var historyService: AccountHistoryApiService
}

class InformationFacadeImp: InformationFacade, ECHOQueueble {
    
    var queues: [ECHOQueue]
    let services: InformationFacadeServices
    
    init(services: InformationFacadeServices) {
        self.services = services
        self.queues = [ECHOQueue]()
    }
    
    func getAccount(nameOrID: String, completion: @escaping Completion<Account>) {
        
        services.databaseService.getFullAccount(nameOrIds: [nameOrID], shoudSubscribe: false) { (result) in
            switch result {
            case .success(let userAccounts):
                
                guard let account = userAccounts.first else {
                    let result = Result<Account, ECHOError>(error: ECHOError.resultNotFound)
                    completion(result)
                    return
                }
                
                let result = Result<Account, ECHOError>(value: account.account)
                completion(result)
            case .failure(let error):
                let result = Result<Account, ECHOError>(error: error)
                completion(result)
            }
        }
    }
    
    func isAccountReserved(nameOrID: String, completion: @escaping Completion<Bool>) {
        
        services.databaseService.getFullAccount(nameOrIds: [nameOrID], shoudSubscribe: false) { (result) in
            switch result {
            case .success(let accounts):
                let result = Result<Bool, ECHOError>(value: accounts.count > 0)
                completion(result)
            case .failure(_):
                let result = Result<Bool, ECHOError>(value: false)
                completion(result)
            }
        }
    }
    
    func getBalance(nameOrID: String, asset: String?, completion: @escaping Completion<[AccountBalance]>) {
        
        services.databaseService.getFullAccount(nameOrIds: [nameOrID], shoudSubscribe: false) { (result) in
            switch result {
            case .success(let userAccounts):
                
                let balances: [AccountBalance]

                guard let account = userAccounts.first else {
                    let result = Result<[AccountBalance], ECHOError>(error: ECHOError.resultNotFound)
                    completion(result)
                    return
                }
                
                if let asset = asset {
                    balances = account.balances.filter {$0.assetType == asset }
                } else {
                    balances =  account.balances
                }
                
                let result = Result<[AccountBalance], ECHOError>(value: balances)
                completion(result)
            case .failure(let error):
                let result = Result<[AccountBalance], ECHOError>(error: error)
                completion(result)
            }
        }
    }
    
    // MARK: History
    
    enum AccountHistoryResultsKeys: String {
        case accountId
        case historyItems
        case findedBlockNums
        case loadedBlocks
        case findedAccountIds
        case loadedAccounts
    }
    
    func getAccountHistroy(nameOrID: String, startId: String, stopId: String, limit: Int, completion: @escaping Completion<[HistoryItem]>) {
        
        let accountHistoryQueue = ECHOQueue()
        addQueue(accountHistoryQueue)
        
        let getAccountOperation = createGetAccountOperation(accountHistoryQueue, nameOrID, completion)
        let getHistoryOperation = createGetHistoryOperation(accountHistoryQueue,
                                                            startId: startId, stopId: stopId, limit: limit,
                                                            completion: completion)
        let getBlocksOperation = createGetBlocksOperation(accountHistoryQueue, completion)
        let getAccountsOperation = createGetAccountsOperation(accountHistoryQueue, completion)
        let mergeBlocksToHistoryOperation = createMergeBlocksInHistoryOperation(accountHistoryQueue, completion)
        let mergeAccountsToHistoryOperation = createMergeAccountsInHistoryOperation(accountHistoryQueue, completion)
        let completionOperation = createHistoryComletionOperation(accountHistoryQueue, completion)
        let lastOperation = createLastOperation(queue: accountHistoryQueue)
        
        accountHistoryQueue.addOperation(getAccountOperation)
        accountHistoryQueue.addOperation(getHistoryOperation)
        accountHistoryQueue.addOperation(getBlocksOperation)
        accountHistoryQueue.addOperation(getAccountsOperation)
        accountHistoryQueue.addOperation(mergeBlocksToHistoryOperation)
        accountHistoryQueue.addOperation(mergeAccountsToHistoryOperation)
        accountHistoryQueue.addOperation(completionOperation)
        accountHistoryQueue.addOperation(lastOperation)
    }
    
    func createGetAccountOperation(_ queue: ECHOQueue, _ nameOrID: String, _ completion: @escaping Completion<[HistoryItem]>) -> Operation {
        
        let getAccountOperation = BlockOperation()
        
        getAccountOperation.addExecutionBlock { [weak getAccountOperation, weak self, weak queue] in
            
            guard getAccountOperation?.isCancelled == false else { return }
            
            self?.getAccount(nameOrID: nameOrID, completion: { (result) in
                switch result {
                case .success(let account):
                    queue?.saveValue(account.id, forKey: AccountHistoryResultsKeys.accountId.rawValue)
                case .failure(let error):
                    queue?.cancelAllOperations()
                    let result = Result<[HistoryItem], ECHOError>(error: error)
                    completion(result)
                }
                
                queue?.startNextOperation()
            })
            
            queue?.waitStartNextOperation()
        }
        
        return getAccountOperation
    }
    
    func createGetHistoryOperation(_ queue: ECHOQueue,
                                   startId: String, stopId: String, limit: Int,
                                   completion: @escaping Completion<[HistoryItem]>) -> Operation {
        
        let getHistoryOperation = BlockOperation()
        
        getHistoryOperation.addExecutionBlock { [weak getHistoryOperation, weak self, weak queue] in
            
            guard getHistoryOperation?.isCancelled == false else { return }
            guard let accountId: String = queue?.getValue(AccountHistoryResultsKeys.accountId.rawValue) else { return }
            
            self?.services.historyService.getAccountHistory(id: accountId, startId: startId, stopId: stopId, limit: limit, completion: { (result) in
                switch result {
                case .success(let historyItems):
                    queue?.saveValue(historyItems, forKey: AccountHistoryResultsKeys.historyItems.rawValue)
                    if let findedData = self?.findDataToLoadFromHistoryItems(historyItems) {
                        queue?.saveValue(findedData.blockNums, forKey: AccountHistoryResultsKeys.findedBlockNums.rawValue)
                        queue?.saveValue(findedData.accountIds, forKey: AccountHistoryResultsKeys.findedAccountIds.rawValue)
                    }
                case .failure(let error):
                    queue?.cancelAllOperations()
                    let result = Result<[HistoryItem], ECHOError>(error: error)
                    completion(result)
                }
                
                queue?.startNextOperation()
            })
            
            queue?.waitStartNextOperation()
        }
        
        return getHistoryOperation
    }
    
    func createGetBlocksOperation(_ queue: ECHOQueue, _ completion: @escaping Completion<[HistoryItem]>) -> Operation {
        
        let getBlockOperation = BlockOperation()
        
        getBlockOperation.addExecutionBlock { [weak getBlockOperation, weak self, weak queue] in
            
            guard let findedBlockNums: Set<Int> = queue?.getValue(AccountHistoryResultsKeys.findedBlockNums.rawValue) else { return }
            let blockNumberCounts = findedBlockNums.count
            
            for _ in 0..<blockNumberCounts {
                
                guard getBlockOperation?.isCancelled == false else { return }
                guard var findedBlockNums: Set<Int> = queue?.getValue(AccountHistoryResultsKeys.findedBlockNums.rawValue) else { return }
                guard let blockNumber: Int = findedBlockNums.first else { return }
                
                self?.services.databaseService.getBlock(blockNumber: blockNumber, completion: { (result) in
                    switch result {
                    case .success(let block):
                        findedBlockNums.removeFirst()
                        queue?.saveValue(findedBlockNums, forKey: AccountHistoryResultsKeys.findedBlockNums.rawValue)
                        
                        if var loadedBlocks: [Int: Block] = queue?.getValue(AccountHistoryResultsKeys.loadedBlocks.rawValue) {
                            loadedBlocks[blockNumber] = block
                            queue?.saveValue(loadedBlocks, forKey: AccountHistoryResultsKeys.loadedBlocks.rawValue)
                        } else {
                            let loadedBlocks = [blockNumber: block]
                            queue?.saveValue(loadedBlocks, forKey: AccountHistoryResultsKeys.loadedBlocks.rawValue)
                        }
                        
                    case .failure(let error):
                        queue?.cancelAllOperations()
                        let result = Result<[HistoryItem], ECHOError>(error: error)
                        completion(result)
                    }
                    
                    queue?.startNextOperation()
                })
                
                queue?.waitStartNextOperation()
            }
        }
        
        return getBlockOperation
    }
    
    func createGetAccountsOperation(_ queue: ECHOQueue, _ completion: @escaping Completion<[HistoryItem]>) -> Operation {
        
        let getAccountsOperation = BlockOperation()
        
        getAccountsOperation.addExecutionBlock { [weak getAccountsOperation, weak queue, weak self] in
            
            guard getAccountsOperation?.isCancelled == false else { return }
            guard let accountsId: Set<String> = queue?.getValue(AccountHistoryResultsKeys.findedAccountIds.rawValue) else { return }
            
            let accountsIdArray = accountsId.map { $0 }
            
            self?.services.databaseService.getFullAccount(nameOrIds: accountsIdArray, shoudSubscribe: false, completion: { (result) in
                switch result {
                case .success(let accounts):
                    queue?.saveValue(accounts, forKey: AccountHistoryResultsKeys.loadedAccounts.rawValue)
                case .failure(let error):
                    queue?.cancelAllOperations()
                    let result = Result<[HistoryItem], ECHOError>(error: error)
                    completion(result)
                }
                
                queue?.startNextOperation()
            })
            
            queue?.waitStartNextOperation()
        }
        
        return getAccountsOperation
    }
    
    func createMergeBlocksInHistoryOperation(_ queue: ECHOQueue, _ completion: @escaping Completion<[HistoryItem]>) -> Operation {
        
        let mergeBlocksInHistoryOperation = BlockOperation()
        
        mergeBlocksInHistoryOperation.addExecutionBlock { [weak mergeBlocksInHistoryOperation, weak queue] in
            
            guard mergeBlocksInHistoryOperation?.isCancelled == false else { return }
            guard var history: [HistoryItem] = queue?.getValue(AccountHistoryResultsKeys.historyItems.rawValue) else { return }
            guard let blocks: [Int: Block] = queue?.getValue(AccountHistoryResultsKeys.loadedBlocks.rawValue) else { return }
            
            for index in 0..<history.count {
                
                var historyItem = history[index]
                
                guard let findedBlock = blocks[historyItem.blockNum] else { continue }
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                historyItem.timestamp = dateFormatter.date(from: findedBlock.timestamp)
                
                history[index] = historyItem
            }
            
            queue?.saveValue(history, forKey: AccountHistoryResultsKeys.historyItems.rawValue)
        }
        
        return mergeBlocksInHistoryOperation
    }
    
    func createMergeAccountsInHistoryOperation(_ queue: ECHOQueue, _ completion: @escaping Completion<[HistoryItem]>) -> Operation {
        
        let mergeAccountsInHistoryOperation = BlockOperation()
        
        mergeAccountsInHistoryOperation.addExecutionBlock { [weak mergeAccountsInHistoryOperation, weak self, weak queue] in
            
            guard mergeAccountsInHistoryOperation?.isCancelled == false else { return }
            guard var history: [HistoryItem] = queue?.getValue(AccountHistoryResultsKeys.historyItems.rawValue) else { return }
            guard let accounts: [UserAccount] = queue?.getValue(AccountHistoryResultsKeys.loadedAccounts.rawValue) else { return }
            
            for index in 0..<history.count {
                
                var historyItem = history[index]
                guard let operation = historyItem.operation else { continue }
            
                if var operation = operation as? TransferOperation {
                    let fromAccount = self?.findAccountIn(accounts, accountId: operation.from.id)
                    let toAccount = self?.findAccountIn(accounts, accountId: operation.to.id)
                    operation.changeAccounts(from: fromAccount, to: toAccount)
                    historyItem.operation = operation
                }
                
                if var operation = operation as? AccountUpdateOperation {
                    let account = self?.findAccountIn(accounts, accountId: operation.account.id)
                    operation.changeAccount(account)
                    historyItem.operation = operation
                }
                
                if var operation = operation as? CreateAssetOperation {
                    if let id = operation.asset.issuer?.id {
                        let issuer = self?.findAccountIn(accounts, accountId: id)
                        operation.changeIssuer(issuer)
                        historyItem.operation = operation
                    }
                }
                
                if var operation = operation as? IssueAssetOperation {
                    let issuer = self?.findAccountIn(accounts, accountId: operation.issuer.id)
                    let issuerToAccount = self?.findAccountIn(accounts, accountId: operation.issueToAccount.id)
                    operation.changeAccounts(issuer: issuer, issueToAccount: issuerToAccount)
                    historyItem.operation = operation
                }
                
                history[index] = historyItem
            }
            
            queue?.saveValue(history, forKey: AccountHistoryResultsKeys.historyItems.rawValue)
        }
        
        return mergeAccountsInHistoryOperation
    }
    
    func createHistoryComletionOperation(_ queue: ECHOQueue, _ completion: @escaping Completion<[HistoryItem]>) -> Operation {
        
        let historyComletionOperation = BlockOperation()
        
        historyComletionOperation.addExecutionBlock { [weak historyComletionOperation, weak queue] in
            
            guard historyComletionOperation?.isCancelled == false else { return }
            guard let history: [HistoryItem] = queue?.getValue(AccountHistoryResultsKeys.historyItems.rawValue) else { return }
            
            let result = Result<[HistoryItem], ECHOError>(value: history)
            completion(result)
        }
        
        return historyComletionOperation
    }
    
    func findAccountIn(_ array: [UserAccount], accountId: String) -> Account? {
        
        return array.first(where: {
            return $0.account.id == accountId
        })?.account
    }
    
    func findDataToLoadFromHistoryItems(_ items: [HistoryItem]) -> (blockNums: Set<Int>, accountIds: Set<String>) {
        
        let blockNums = fingBlockNumsFromHistoryItems(items)
        let accountIds = findAccountsIds(items)
        return (blockNums, accountIds)
    }
    
    func fingBlockNumsFromHistoryItems(_ items: [HistoryItem]) -> Set<Int> {
        
        var blocksNums = Set<Int>()
        items.forEach {
            blocksNums.insert($0.blockNum)
        }
    
        return blocksNums
    }
    
    func findAccountsIds(_ items: [HistoryItem]) -> Set<String> {
        
        var accountsIds = Set<String>()
        
        items.forEach {
            
            guard let operation = $0.operation else {
                return
            }
            
            if let operation = operation as? TransferOperation {
                accountsIds.insert(operation.from.id)
                accountsIds.insert(operation.to.id)
                return
            }
            
            if let operation = operation as? AccountUpdateOperation {
                accountsIds.insert(operation.account.id)
                return
            }
            
            if let operation = operation as? CreateAssetOperation {
                if let id = operation.asset.issuer?.id {
                    accountsIds.insert(id)
                    return
                }
            }
            
            if let operation = operation as? IssueAssetOperation {
                accountsIds.insert(operation.issuer.id)
                accountsIds.insert(operation.issueToAccount.id)
                return
            }
        }
        
        return accountsIds
    }
}
