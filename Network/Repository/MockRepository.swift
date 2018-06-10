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
    
    func perform(request: Request, completion: @escaping ((Response) -> Void)) {
        
        let randomDelay = Int(arc4random_uniform(2)) + 1
        
        job = DispatchWorkItem(block: {
            DispatchQueue.main.async {
                completion(Response(data: Data()))
            }
        })
        
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + .seconds(randomDelay) , execute: job)
    }
}
