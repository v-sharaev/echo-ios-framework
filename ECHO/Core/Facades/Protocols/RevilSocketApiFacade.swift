//
//  RevilSocketApiFacade.swift
//  ECHO
//
//  Created by Fedorenko Nikita on 13.07.2018.
//  Copyright © 2018 PixelPlex. All rights reserved.
//

protocol RevialApiFacade {
    
    init(socketCore: SocketCoreComponent,
         options: APIOption,
         services: RevialFacadeServices)
    
    func revilApi(completion: @escaping Completion<Bool>)
}