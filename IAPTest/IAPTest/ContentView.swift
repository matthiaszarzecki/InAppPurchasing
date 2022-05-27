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
        Text(model.description)
      }
    }

  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}

public typealias ProductsRequestCompletionHandler = (_ success: Bool, _ products: [SKProduct]?) -> ()

class ProductHandler: NSObject, SKProductsRequestDelegate {
  /// The function that returns the gotten products when fetching.
  /// Gets set when calling fetchProducts, and then actually called
  /// when products are returned.
  private var completionHandler: ProductsRequestCompletionHandler?

  enum Product: String, CaseIterable {
    case removeAds = "com.myapp.removeAds"
    case unlockEverything = "com.myapp.unlockEverything"
    case getGems = "com.myapp.getGems"
  }

  public func fetchProducts(
    completion: @escaping ProductsRequestCompletionHandler
  ) {
    let request = SKProductsRequest(
      productIdentifiers: Set(
        Product.allCases.compactMap{ $0.rawValue }
      )
    )

    completionHandler = completion

    request.delegate = self
    request.start()
  }

  /// Gets called on succesful request
  func productsRequest(
    _ request: SKProductsRequest,
    didReceive response: SKProductsResponse
  ) {
    DispatchQueue.main.async {
      print("Count: \(response.products.count)")
      self.completionHandler?(true, response.products)
    }
  }
}
