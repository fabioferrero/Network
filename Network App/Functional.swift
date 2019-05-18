//
//  Functional.swift
//  Network App
//
//  Created by Fabio Ferrero on 18/05/2019.
//  Copyright © 2019 Fabio Ferrero. All rights reserved.
//

import Foundation

/// Turns an (A) -> B function into a () -> B function,
/// by using a constant value for A.
func combine<A, B>(_ value: A, with closure: @escaping (A) -> B) -> () -> B {
    return { closure(value) }
}

/// Turns an (A) -> B and a (B) -> C function into a
/// (A) -> C function, by chaining them together.
func chain<A, B, C>(_ inner: @escaping (A) -> B, to outer: @escaping (B) -> C) -> (A) -> C {
    return { outer(inner($0)) }
}

/// Turns an (A) -> B and a (B) -> () -> C (a.k.a. instance methods) function into a
/// (A) -> C function, by chaining them together.
func chain<A, B, C>(_ inner: @escaping (A) -> B, to outer: @escaping (B) -> () -> C) -> (A) -> C {
    return { outer(inner($0))() }
}
