//
//  HomeDataService.swift
//  Network
//
//  Created by Fabio Ferrero on 17/05/2018.
//  Copyright © 2018 Fabio Ferrero. All rights reserved.
//

import Foundation

final class FakeDataService {
    
    private let repository: Repository
    
    init(repository: Repository) {
        self.repository = repository
    }
    
    private func fakeService(completion: @escaping () -> Void)  {
        
        let request = Request(parameters: [:])
        
        repository.perform(request: request) { repsonse in
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
