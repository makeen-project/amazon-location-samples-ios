//
//  AlertPresenter.swift
//  LocationServices
//
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

import UIKit
import SwiftUI

class AlertModel {
    var title: String
    var message: String
    var cancelButtonTitle: String?
    var okButtonTitle: String
    var okHandler: (()->())?
    
    
    init(title: String = NSLocalizedString("Error", comment: ""), message: String = "", cancelButton: String? = NSLocalizedString("Cancel", comment: ""), okButton: String = NSLocalizedString("Ok", comment: ""), okHandler: (()->())? = nil) {
        self.title = title
        self.message = message
        self.cancelButtonTitle = cancelButton
        self.okButtonTitle = okButton
        self.okHandler = okHandler
    }
}

protocol AlertPresentable {
    func showAlert(_ model: AlertModel)
}

extension AlertPresentable {
    func showAlert(_ model: AlertModel) {
        Alert(title: Text(model.title), message: Text(model.message), dismissButton: .default(Text( model.okButtonTitle)) { model.okHandler?() })
    }
}
