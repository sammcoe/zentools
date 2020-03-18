//
//  HostingController.swift
//  Zentools
//
//  Created by Samuel Coe on 3/13/20.
//  Copyright © 2020 Samuel Coe. All rights reserved.
//

import SwiftUI

class ZentoolsHostingController: NSHostingController<PreferencesView> {
      @objc required dynamic init?(coder: NSCoder) {
          super.init(coder: coder, rootView: PreferencesView())
      }
}
