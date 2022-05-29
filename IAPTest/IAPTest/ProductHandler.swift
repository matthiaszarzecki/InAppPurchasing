//
//  ProductHandler.swift
//  IAPTest
//
//  Created by Matthias Zarzecki on 29.05.22.
//

import StoreKit

public typealias ProductsRequestCompletionHandler = (_ success: Bool, _ products: [SKProduct]?) -> ()

enum Product: String, CaseIterable {
  case removeAds = "com.myapp.removeAds"
  case unlockEverything = "com.myapp.unlockEverything"
  case getGems = "com.myapp.getGems"
}

class ProductHandler: NSObject {
  /// The function that returns the gotten products when fetching.
  /// Gets set when calling fetchProducts, and then actually called
  /// when products are returned.
  private var completionHandler: ProductsRequestCompletionHandler?

  override init() {
    super.init()

    // Add observer, so that observing functions will be called
    SKPaymentQueue.default().add(self)
  }

  /// Fetches products from store or configuration
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
}

extension ProductHandler: SKProductsRequestDelegate {
  /// Gets called on succesful product request
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

extension ProductHandler: SKPaymentTransactionObserver {
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
}
