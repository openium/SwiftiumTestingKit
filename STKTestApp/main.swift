//
//  main.swift
//  STKTestApp
//
//  Created by Richard Bergoin on 19/09/2018.
//  Copyright © 2018 Openium. All rights reserved.
//

import UIKit

let appDelegateClass: AnyClass = NSClassFromString("STKTestAppTests.TestingAppDelegate") ?? AppDelegate.self
let argv = UnsafeMutableRawPointer(CommandLine.unsafeArgv).bindMemory(to: UnsafeMutablePointer<Int8>.self, capacity: Int(CommandLine.argc))
UIApplicationMain(CommandLine.argc,
                  CommandLine.unsafeArgv,
                  nil,
                  NSStringFromClass(appDelegateClass))
