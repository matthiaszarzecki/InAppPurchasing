//
//  ContentView.swift
//  IAPTest
//
//  Created by Matthias Zarzecki on 27.05.22.
//

import StoreKit
import SwiftUI

struct ContentView: View {
  @State private var models: [SKProduct] = []

  let productHandler = ProductHandler()

  var body: some View {
    VStack {
      Button(
        action: {
          print("Requested Products")
          productHandler.fetchProducts(
            completion: { success, products in
              if success, let unwrappedProducts = products {
                self.models = unwrappedProducts
              }
            }
          )
        },
        label: {
          Text("Get Products")
            .padding()
        }
      )

      ForEach(models, id: \.self) { model in
        Button(
          action: {
            productHandler.buyProduct(model)
          },
          label: {
            Text("\(model.localizedTitle): \(model.localizedDescription), \(model.price)\(model.priceLocale.currencySymbol ?? "")")
              .padding()
          }
        )
      }
    }

  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
