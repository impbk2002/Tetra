//
//  ManagedUnfairLock.swift
//  
//
//  Created by pbk on 2022/12/14.
//

import Foundation
import os

@available(iOS, deprecated: 16.0, renamed: "OSAllocatedUnfairLock")
@available(tvOS, deprecated: 16.0, renamed: "OSAllocatedUnfairLock")
@available(macCatalyst, deprecated: 16.0, renamed: "OSAllocatedUnfairLock")
@available(watchOS, deprecated: 9.0, renamed: "OSAllocatedUnfairLock")
@available(macOS, deprecated: 13.0, renamed: "OSAllocatedUnfairLock")
public struct ManagedUnfairLock<State>: @unchecked Sendable {
    
    private let __lock:ManagedBuffer<State,os_unfair_lock>
    
    /// Initialize an SwiftUnfairLock with a non-sendable lock-protected
    /// `initialState`.
    ///
    /// By initializing with a non-sendable type, the owner of this structure
    /// must ensure the Sendable contract is upheld manually.
    /// Non-sendable content from `State` should not be allowed
    /// to escape from the lock.
    ///
    /// - Parameter initialState: An initial value to store that will be
    ///  protected under the lock.
    ///
    public init(uncheckedState initialState: State) {
        __lock = .create(minimumCapacity: 1) { buffer in
            buffer.withUnsafeMutablePointerToElements{ $0.initialize(to: .init()) }
            return initialState
        }
    }
    
    ///  Perform a closure while holding this lock.
    ///  This method does not enforce sendability requirement
    ///  on closure body and its return type.
    ///  The caller of this method is responsible for ensuring references
    ///   to non-sendables from closure uphold the Sendability contract.
    ///
    /// - Parameter body: A closure to invoke while holding this lock.
    /// - Returns: The return value of `body`.
    /// - Throws: Anything thrown by `body`.
    ///
    public func withLockUnchecked<R>(_ body: (inout State) throws -> R) rethrows -> R {
        try __lock.withUnsafeMutablePointers{ state, lock in
            os_unfair_lock_lock(lock)
            defer { os_unfair_lock_unlock(lock) }
            return try body(&state.pointee)
        }
    }
    
    ///  Perform a sendable closure while holding this lock.
    ///
    ///
    /// - Parameter body: A sendable closure to invoke while holding this lock.
    /// - Returns: The sendable return value of `body`.
    /// - Throws: Anything thrown by `body`.
    ///
    public func withLock<R>(_ body: @Sendable (inout State) throws -> R) rethrows -> R where R : Sendable {
        try withLockUnchecked(body)
    }
    
    ///  Attempt to acquire the lock, if successful, perform a closure while
    ///  holding the lock.
    ///  This method does not enforce sendability requirement
    ///  on closure body and its return type.
    ///  The caller of this method is responsible for ensuring references
    ///   to non-sendables from closure uphold the Sendability contract.
    ///
    /// - Parameter body: A closure to invoke while holding this lock.
    /// - Returns: If the lock is acquired, the result of `body`.
    ///            If the lock is not acquired, nil.
    /// - Throws: Anything thrown by `body`.
    ///
    public func withLockIfAvailableUnchecked<R>(_ body: (inout State) throws -> R) rethrows -> R? {
        try __lock.withUnsafeMutablePointers{ state, lock in
            guard os_unfair_lock_trylock(lock) else { return nil }
            defer { os_unfair_lock_unlock(lock) }
            return try body(&state.pointee)
        }
    }
    
    ///  Attempt to acquire the lock, if successful, perform a sendable closure while
    ///  holding the lock.
    ///
    /// - Parameter body: A closure to invoke while holding this lock.
    /// - Returns: If the lock is acquired, the result of `body`.
    ///            If the lock is not acquired, nil.
    /// - Throws: Anything thrown by `body`.
    ///
    public func withLockIfAvailable<R>(_ body: @Sendable (inout State) throws -> R) rethrows -> R? where R : Sendable {
        try withLockIfAvailableUnchecked(body)
    }

    @frozen
    public enum Ownership: Sendable, Hashable {
        case owner
        case notOwner
    }
    
    /// Check a precondition about whether the calling thread is the lock owner.
    ///
    /// - Parameter condition: An `Ownership` statement to check for the
    /// current context.
    /// - If the lock is currently owned by the calling thread:
    ///   - `.owner` - returns
    ///   - `.notOwner` - asserts and terminates the process
    /// - If the lock is unlocked or owned by a different thread:
    ///   - `.owner` - asserts and terminates the process
    ///   - `.notOwner` - returns
    ///
    public func precondition(_ condition: Ownership) {
        __lock.withUnsafeMutablePointerToElements {
            switch condition {
            case .notOwner:
                os_unfair_lock_assert_not_owner($0)
            case .owner:
                os_unfair_lock_assert_owner($0)
            }
        }
    }
    
}


public extension ManagedUnfairLock where State == Void {
    
    /// Initialize an SwiftUnfairLock with no protected state.
    init() {
        __lock = .create(minimumCapacity: 1) { buffer in
            buffer.withUnsafeMutablePointerToElements{ $0.initialize(to: .init()) }
        }
    }
    
    /// Acquire this lock.
    @_unavailableFromAsync(message: "Use async-safe scoped locking instead")
    func lock() {
        __lock.withUnsafeMutablePointerToElements {
            os_unfair_lock_lock($0)
        }
    }
    
    /// Unlock this lock.
    @_unavailableFromAsync(message: "Use async-safe scoped locking instead")
    func unlock() {
        __lock.withUnsafeMutablePointerToElements{ os_unfair_lock_unlock($0) }
    }
    
    ///  Perform a sendable closure while holding this lock.
    ///
    /// - Parameter body: A sendable closure to invoke while holding this lock.
    /// - Returns: The return value of `body`.
    /// - Throws: Anything thrown by `body`.
    ///
    func withLock<R>(_ body: @Sendable () throws -> R) rethrows -> R where R : Sendable {
        try withLockUnchecked(body)
    }
    
    ///  Perform a closure while holding this lock.
    ///  This method does not enforce sendability requirement
    ///  on closure body and its return type.
    ///  The caller of this method is responsible for ensuring references
    ///   to non-sendables from closure uphold the Sendability contract.
    ///
    /// - Parameter body: A closure to invoke while holding this lock.
    /// - Returns: The return value of `body`.
    /// - Throws: Anything thrown by `body`.
    ///
    func withLockUnchecked<R>(_ body: () throws -> R) rethrows -> R {
        try __lock.withUnsafeMutablePointerToElements { lock in
            os_unfair_lock_lock(lock)
            defer { os_unfair_lock_unlock(lock) }
            return try body()
        }
    }
    
    /// Attempt to acquire the lock if it is not already locked.
    ///
    /// - Returns: `true` if the lock was succesfully locked, and
    ///  `false` if the lock attempt failed.
    @available(*, noasync, message: "Use async-safe scoped locking instead")
     func lockIfAvailable() -> Bool {
        __lock.withUnsafeMutablePointerToElements { os_unfair_lock_trylock($0) }
    }
    
    ///  Attempt to acquire the lock, if successful, perform a sendable closure while
    ///  holding the lock.
    ///
    /// - Parameter body: A sendable closure to invoke while holding this lock.
    /// - Returns: If the lock is acquired, the result of `body`.
    ///            If the lock is not acquired, nil.
    /// - Throws: Anything thrown by `body`.
    ///
    func withLockIfAvailable<R>(_ body: @Sendable () throws -> R) rethrows -> R? where R : Sendable {
        try withLockIfAvailableUnchecked(body)
    }
    
    ///  Attempt to acquire the lock, if successful, perform a closure while
    ///  holding the lock.
    ///  This method does not enforce sendability requirement
    ///  on closure body and its return type.
    ///  The caller of this method is responsible for ensuring references
    ///   to non-sendables from closure uphold the Sendability contract.
    ///
    /// - Parameter body: A closure to invoke while holding this lock.
    /// - Returns: If the lock is acquired, the result of `body`.
    ///            If the lock is not acquired, nil.
    /// - Throws: Anything thrown by `body`.
    ///
    func withLockIfAvailableUnchecked<R>(_ body: () throws -> R) rethrows -> R? {
        try __lock.withUnsafeMutablePointerToElements{ lock in
            guard os_unfair_lock_trylock(lock) else { return nil }
            defer { os_unfair_lock_unlock(lock) }
            return try body()
        }
    }
    
}

public extension ManagedUnfairLock {
    
    /// Initialize an SwiftUnfairLock with a lock-protected sendable
    /// `initialState`.
    /// - Parameter initialState: An initial value to store that will be
    ///   protected under the lock.
    init(initialState: State) where State:Sendable {
        __lock = .create(minimumCapacity: 1) { buffer in
            buffer.withUnsafeMutablePointerToElements{ $0.initialize(to: .init()) }
            return initialState
        }
    }
    
}

@usableFromInline
internal protocol UnfairStateLock<State>: Sendable {
    
    associatedtype State
    
    func withLock<R>(_ body: @Sendable (inout State) throws -> R) rethrows -> R where R : Sendable
    
    func withLockUnchecked<R>(_ body: (inout State) throws -> R) rethrows -> R
   
    func withLockIfAvailableUnchecked<R>(_ body: (inout State) throws -> R) rethrows -> R?
        
    init(uncheckedState initialState: State)
    
    func withLockIfAvailable<R>(_ body: @Sendable (inout State) throws -> R) rethrows -> R? where R: Sendable
    
}

@usableFromInline
internal protocol UnfairLockProtocol: Sendable {
    
    init()
    
    @_unavailableFromAsync(message: "Use async-safe scoped locking instead")
    func lock()
    
    @_unavailableFromAsync(message: "Use async-safe scoped locking instead")
    func unlock()
    
    func withLockUnchecked<R>(_ body: () throws -> R) rethrows -> R
    
    func withLock<R>(_ body: @Sendable () throws -> R) rethrows -> R where R : Sendable
    
}

@available(iOS 16.0, tvOS 16.0, macOS 13.0, macCatalyst 16.0, watchOS 9.0, *)
extension OSAllocatedUnfairLock: UnfairStateLock {}
@available(iOS 16.0, tvOS 16.0, macOS 13.0, macCatalyst 16.0, watchOS 9.0, *)
extension OSAllocatedUnfairLock<Void>: UnfairLockProtocol {}
extension ManagedUnfairLock: UnfairStateLock {}
extension ManagedUnfairLock<Void>: UnfairLockProtocol {}

@usableFromInline
internal func createUncheckedStateLock<State>(uncheckedState initialState:State) -> some UnfairStateLock<State> {
    if #available(iOS 16.0, tvOS 16.0, macCatalyst 16.0, watchOS 9.0, macOS 13.0, *) {
        return OSAllocatedUnfairLock(uncheckedState: initialState)
    } else {
        return ManagedUnfairLock(uncheckedState: initialState)
    }
}

@usableFromInline
internal func createCheckedStateLock<State:Sendable>(checkedState initialState:State) -> some UnfairStateLock<State> {
    if #available(iOS 16.0, tvOS 16.0, macCatalyst 16.0, watchOS 9.0, macOS 13.0, *) {
        return OSAllocatedUnfairLock(initialState: initialState)
    } else {
        return ManagedUnfairLock(initialState: initialState)
    }
}

@usableFromInline
internal func createUnfairLock() -> some UnfairLockProtocol {
    if #available(iOS 16.0, tvOS 16.0, macCatalyst 16.0, watchOS 9.0, macOS 13.0, *) {
        return OSAllocatedUnfairLock()
    } else {
        return ManagedUnfairLock()
    }
}
