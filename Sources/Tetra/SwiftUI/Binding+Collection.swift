//
//  Binding+Collection.swift
//  
//
//  Created by pbk on 2022/12/19.
//

import Foundation
import SwiftUI

@available(watchOS, deprecated: 8.0, message: "use Binding<MutableCollection> itself as Collection")
@available(macOS, deprecated: 12.0, message: "use Binding<MutableCollection> itself as Collection")
@available(macCatalyst, deprecated: 15.0, message: "use Binding<MutableCollection> itself as Collection")
@available(tvOS, deprecated: 15.0, message: "use Binding<MutableCollection> itself as Collection")
public extension Binding where Value: MutableCollection {
    
    @inlinable
    var collection:BindingCollection<Value> {
        return .init(binding: self)
    }
    
}

@available(watchOS, deprecated: 8.0, message: "use Binding<MutableCollection> itself as Collection")
@available(macOS, deprecated: 12.0, message: "use Binding<MutableCollection> itself as Collection")
@available(macCatalyst, deprecated: 15.0, message: "use Binding<MutableCollection> itself as Collection")
@available(tvOS, deprecated: 15.0, message: "use Binding<MutableCollection> itself as Collection")
@available(iOS, deprecated: 15.0, message: "use Binding<MutableCollection> itself as Collection")
public struct BindingCollection<T:MutableCollection>: Collection {
    
    @usableFromInline
    @Binding var collection:T
    
    public typealias Element = Binding<T.Element>
    public typealias Index = T.Index
    
    @inlinable
    public subscript(position: T.Index) -> Binding<T.Element> {
        if #available(iOS 15.0, tvOS 15.0, macCatalyst 15.0, macOS 12.0, watchOS 8.0, *) {
            return binding[position]
        } else {
            return .init {
                binding.wrappedValue[position]
            } set: { newValue, transaction in
                withTransaction(transaction) {
                    binding.wrappedValue[position] = newValue
                }
            }

        }
    }
    
    @usableFromInline
    internal var binding:Binding<T> { $collection }
    
    @inlinable
    public var startIndex: T.Index {
        if #available(iOS 15.0, tvOS 15.0, macCatalyst 15.0, macOS 12.0, watchOS 8.0, *) {
            return binding.startIndex
        } else {
            return collection.startIndex
        }
    }
    
    @inlinable
    public var endIndex: T.Index {
        if #available(iOS 15.0, tvOS 15.0, macCatalyst 15.0, macOS 12.0, watchOS 8.0, *) {
            return binding.endIndex
        } else {
            return collection.endIndex
        }
    }
    
    @inlinable
    public func index(after i: T.Index) -> T.Index {
        if #available(iOS 15.0, tvOS 15.0, macCatalyst 15.0, macOS 12.0, watchOS 8.0, *) {
            return binding.index(after: i)
        } else {
            return collection.index(after: i)
        }
    }
    
    @inlinable
    public func index(before i: T.Index) -> T.Index where T: BidirectionalCollection {
        if #available(iOS 15.0, tvOS 15.0, macCatalyst 15.0, macOS 12.0, watchOS 8.0, *) {
            return binding.index(before: i)
        } else {
            return collection.index(before: i)
        }
    }

}

extension BindingCollection: BidirectionalCollection where T: BidirectionalCollection { }
extension BindingCollection: RandomAccessCollection where T: RandomAccessCollection { }

public extension BindingCollection {
    
    init(binding: Binding<T>) {
        self.init(collection: binding)
    }
    
}

