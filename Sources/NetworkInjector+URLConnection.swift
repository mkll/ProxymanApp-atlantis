//
//  NetworkInjector+URLConnection.swift
//  atlantis
//
//  Created by Nghia Tran on 10/24/20.
//  Copyright © 2020 Proxyman. All rights reserved.
//

import Foundation

extension NetworkInjector {

    /// https://developer.apple.com/documentation/foundation/nsurlconnectiondatadelegate/1407728-connection?language=objc
    func _swizzleConnectionDidReceiveResponse(anyClass: AnyClass) {
        //
        // Have to explicitly tell the compiler which func
        // because there are two different objc methods, but different argments
        // It causes the bug: Ambiguous use of 'connection(_:didReceive:)'
        //
        let selector : Selector = #selector((NSURLConnectionDataDelegate.connection(_:didReceive:)!)
            as (NSURLConnectionDataDelegate) -> (NSURLConnection, URLResponse) -> Void)

        guard let method = class_getInstanceMethod(anyClass, selector),
            anyClass.instancesRespond(to: selector) else {
            return
        }

        typealias NewClosureType =  @convention(c) (AnyObject, Selector, AnyObject, AnyObject) -> Void
        let originalImp: IMP = method_getImplementation(method)
        let block: @convention(block) (AnyObject, AnyObject, AnyObject) -> Void = {[weak self] (me, connection, response) in

            // call the original
            let original: NewClosureType = unsafeBitCast(originalImp, to: NewClosureType.self)
            original(me, selector, connection, response)

            // Safe-check
            if let connection = connection as? NSURLConnection, let response = response as? URLResponse {
                self?.delegate?.injectorConnectionDidReceive(connection: connection, response: response)
            } else {
                assertionFailure("Could not get data from _swizzleConnectionDidReceiveResponse. It might causes due to the latest iOS changes. Please contact the author!")
            }
        }

        // Start method swizzling
        method_setImplementation(method, imp_implementationWithBlock(block))
    }
}
