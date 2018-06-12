//
//  MockRepository.swift
//  Network
//
//  Created by Fabio Ferrero on 17/05/2018.
//  Copyright © 2018 Fabio Ferrero. All rights reserved.
//

import Foundation

final class MockRepository: Repository {
    
    private var job: DispatchWorkItem = DispatchWorkItem(block: {})
    
    func perform<S: Service>(_ request: Request<S>, onCompletion: @escaping (Response<S.Output>) -> Void) {
        
        let randomDelay = Int(arc4random_uniform(2)) + 1
        let response: S.Output = try! JSONDecoder().decode(S.Output.self, from: Data())
        
        job = DispatchWorkItem(block: {
            DispatchQueue.main.async {
                onCompletion(Response.OK(response: response))
            }
        })
        
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + .seconds(randomDelay) , execute: job)
    }
}
