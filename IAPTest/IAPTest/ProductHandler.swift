//
//  ProductHandler.swift
//  IAPTest
//
//  Created by Matthias Zarzecki on 29.05.22.
//

import StoreKit

/// Alias for completionHandler that is given to ProductHandler
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

    setupObserver()
  }

  private func setupObserver() {
    // Add observer, so that observing functions will be called
    SKPaymentQueue.default().add(self)
  }

  // MARK: - Public Functions

  /// Fetches products from store or configuration file
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

  /// Starts the purchasing process for a product
  public func buyProduct(_ product: SKProduct) {
    print("Buying \(product.productIdentifier)...")
    let payment = SKPayment(product: product)
    SKPaymentQueue.default().add(payment)
  }

  /// Restores previous purchases
  public func restorePurchases() {
    SKPaymentQueue.default().restoreCompletedTransactions()
  }
}

// MARK: - SKProductsRequestDelegate

extension ProductHandler: SKProductsRequestDelegate {
  /// Gets called on succesful product request
  internal func productsRequest(
    _ request: SKProductsRequest,
    didReceive response: SKProductsResponse
  ) {
    DispatchQueue.main.async {
      print("Count: \(response.products.count)")
      self.completionHandler?(true, response.products)
    }
  }

  /// Gets called when product loading from store fails
  internal func request(
    _ request: SKRequest,
    didFailWithError error: Error
  ) {
    print("Failed to load list of products. Error: \(error.localizedDescription)")
    completionHandler?(false, nil)
  }
}

// MARK: - SKPaymentTransactionObserver

extension ProductHandler: SKPaymentTransactionObserver {
  /// Gets called when a payment transaction is happening
  internal func paymentQueue(
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
