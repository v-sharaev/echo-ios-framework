//
//  SubscriptionFacade.swift
//  ECHO
//
//  Created by Fedorenko Nikita on 10.07.2018.
//  Copyright © 2018 PixelPlex. All rights reserved.
//

/**
    The interface of the class that allows you to receive notification about the change account.
 */
public protocol SubscribeAccountDelegate: class {
    func didUpdateAccount(userAccount: UserAccount)
}

/**
 The interface of the class that allows you to receive notification about the change dynamic global properties.
 */
public protocol SubscribeDynamicGlobalPropertiesDelegate: class {
    func didUpdateDynamicGlobalProperties(dynamicGlobalProperties: DynamicGlobalProperties)
}

/**
 The interface of the class that allows you to receive notification about the create new block
 */
public protocol SubscribeBlockDelegate: class {
    func didCreateBlock(block: Block)
}

/**
    A class interface that allows you to track the change to an account
 */
public protocol SubscriptionFacade {
/**
     Adding a listener to the account change
     
     - Parameter nameOrId: Name or id of the account for which the subscription will be changed
     - Parameter delegate: The class that will receive account notifications
     
     - Remark:
     Delegate must be a class
 */
    func subscribeToAccount(nameOrId: String, delegate: SubscribeAccountDelegate)
    
/**
    Removing a listener to the account change

    - Parameter nameOrId: Name or id of the account for which the subscription will be changed
    - Parameter delegate: The class that receive account notifications
 */
    func unsubscribeToAccount(nameOrId: String, delegate: SubscribeAccountDelegate)
    
/**
     Adding a listener to the dynamic global properties change
     
     - Parameter delegate: The class that receive change notifications
 */
    func subscribeToDynamicGlobalProperties(delegate: SubscribeDynamicGlobalPropertiesDelegate)
    
/**
     Removing a listener to the dynamic global properties change
 */
    func unsubscribeToDynamicGlobalProperties()
    
/**
     Adding a listener to the block create
     
     - Parameter delegate: The class that receive create notifications
 */
    func subscribeToBlock(delegate: SubscribeBlockDelegate)
    
/**
     Removing a listener to the block create
 */
    func unsubscribeToBlock()
    
/**
     Removing all listeners to the account change
 */
    func unsubscribeAll()
}
