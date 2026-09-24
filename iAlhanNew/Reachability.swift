//
//  InternetReacheability.swift
//  iAlhan
//
//  Created by Sidarous, Arsani on 3/30/17.
//  Copyright © 2017 alhan.org. All rights reserved.
//

import Foundation
import Network

public final class Reachability {
    private static let monitor: NWPathMonitor = {
        let monitor = NWPathMonitor()
        monitor.start(queue: DispatchQueue(label: "org.alhan.reachability"))
        return monitor
    }()

    class func isConnectedToNetwork() -> Bool {
        monitor.currentPath.status == .satisfied
    }
}
