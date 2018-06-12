//
//  HomeDataService.swift
//  Network
//
//  Created by Fabio Ferrero on 17/05/2018.
//  Copyright © 2018 Fabio Ferrero. All rights reserved.
//

import Foundation

final class MockedDataService {
    
    private let repository: Repository = MockRepository()
    
    struct FakeService: Service {
        typealias Input = String
        typealias Output = String
        
        static var url: String = ""
    }
    
    private func fakeService(completion: @escaping () -> Void)  {
        
        let request = Request<FakeService>(payload: "mockRequest")
        
        repository.perform(request) { response in
            completion()
        }
    }
    
    func login(start: () -> Void, completion: @escaping () -> Void) {
        start()
        fakeService {
            completion()
        }
    }
    
    func logout(start: () -> Void, completion: @escaping () -> Void) {
        start()
        fakeService {
            completion()
        }
    }
    
    func getHome(start: () -> Void, completion: @escaping () -> Void) {
        start()
        fakeService {
            completion()
        }
    }
    
    func getCards(start: () -> Void, completion: @escaping () -> Void) {
        start()
        fakeService {
            completion()
        }
    }
}
