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

public typealias ProductsRequestCompletionHandler = (_ success: Bool, _ products: [SKProduct]?) -> ()

class ProductHandler: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {

  override init() {
    super.init()
    SKPaymentQueue.default().add(self)
  }

  func paymentQueue(
    _ queue: SKPaymentQueue,
    updatedTransactions transactions: [SKPaymentTransaction]
  ) {
    for transaction in transactions {
      switch transaction.transactionState {
      case .purchased:
        complete(transaction: transaction)
        break
      case .failed:
        fail(transaction: transaction)
        break
      case .restored:
        restore(transaction: transaction)
        break
      case .deferred:
        break
      case .purchasing:
        break
      @unknown default:
        break
      }
    }
  }

  /// Finishes the purchasing process
  private func complete(transaction: SKPaymentTransaction) {
    print("completed purchase!")
    deliverPurchaseNotificationFor(identifier: transaction.payment.productIdentifier)
    SKPaymentQueue.default().finishTransaction(transaction)
  }

  /// Restores a previously purchased product
  private func restore(transaction: SKPaymentTransaction) {
    guard let productIdentifier = transaction.original?.payment.productIdentifier else {
      return
    }

    print("restore... \(productIdentifier)")
    deliverPurchaseNotificationFor(identifier: productIdentifier)
    SKPaymentQueue.default().finishTransaction(transaction)
  }

  /// Fails the purchasing process
  private func fail(transaction: SKPaymentTransaction) {
    print("fail...")
    if let transactionError = transaction.error as NSError? {
      if transactionError.code != SKError.paymentCancelled.rawValue {
        print("Transaction Error: \(String(describing: transaction.error?.localizedDescription))")
      }
    }

    SKPaymentQueue.default().finishTransaction(transaction)
  }

  /// Posts a notification stating purchase or restoration was succesful
  private func deliverPurchaseNotificationFor(identifier: String?) {
    guard let identifier = identifier else {
      return
    }

    //purchasedProductIdentifiers.insert(identifier)
    UserDefaults.standard.set(true, forKey: identifier)
    UserDefaults.standard.synchronize()
    NotificationCenter.default.post(
      name: NSNotification.Name(rawValue: "IAPHelperPurchaseNotification"),
      object: identifier
    )
  }

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

  /// Starts the purchasing process for a product
  func buyProduct(_ product: SKProduct) {
    print("Buying \(product.productIdentifier)...")
    let payment = SKPayment(product: product)
    SKPaymentQueue.default().add(payment)
  }
}
