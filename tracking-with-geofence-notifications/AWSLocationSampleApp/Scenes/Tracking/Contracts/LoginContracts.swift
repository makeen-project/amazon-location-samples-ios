//
//  LoginContracts.swift
//  LocationServices
//
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

import Foundation


protocol LoginViewModelProtocol: AnyObject {
    var delegate: LoginViewModelOutputDelegate? { get set }
    func connectAWS(identityPoolId: String?, userPoolId: String?, userPoolClientId: String?, userDomain: String?, websocketUrl: String?)
    func hasLocalUser() -> Bool
    func isSignedIn() -> Bool
    func disconnectAWS()
    func login()
    func logout()
}

protocol LoginViewModelOutputDelegate: AnyObject, AlertPresentable {
    func cloudConnectionCompleted()
    func cloudConnectionDisconnected()
    
    func loginCompleted()
    func logoutCompleted()
    func identityPoolIdValidationSucceed()
}
