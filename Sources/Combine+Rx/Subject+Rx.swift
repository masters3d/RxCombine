//
//  Subject+Rx.swift
//  RxCombine
//
//  Created by Shai Mishali on 11/06/2019.
//  Copyright © 2019 Shai Mishali. All rights reserved.
//

import Combine
import RxSwift
import RxRelay

/// Represents a Combine Subject that can be converted
/// to a RxSwift AnyObserver of the underlying Output type.
///
/// - note: This only works when the underlying Failure is Swift.Error,
///         since RxSwift has no typed errors.
public protocol AnyObserverConvertible: Combine.Subject where Failure == Swift.Error {
    associatedtype Output

    /// Returns a RxSwift AnyObserver wrapping the Subject
    ///
    /// - returns: AnyObserver<Output>
    func asAnyObserver() -> AnyObserver<Output>
}

public extension AnyObserverConvertible {
    /// Returns a RxSwift AnyObserver wrapping the Subject
    ///
    /// - returns: AnyObserver<Output>
    func asAnyObserver() -> AnyObserver<Output> {
        return AnyObserver { [weak self] event in
            guard let self = self else { return }
            switch event {
            case .next(let value):
                self.send(value)
            case .error(let error):
                self.send(completion: .failure(error))
            case .completed:
                self.send(completion: .finished)
            }
        }
    }
}

extension PassthroughSubject: AnyObserverConvertible where Failure == Swift.Error {}
extension CurrentValueSubject: AnyObserverConvertible where Failure == Swift.Error {}

public extension ObservableType {
    /**
     Creates new subscription and sends elements to a Combine Subject.

     - parameter to: Combine subject to receives events.
     - returns: Disposable object that can be used to unsubscribe the observers.
     - seealso: `AnyOserverConvertible`
     */
    func bind<S: AnyObserverConvertible>(to subject: S) -> Disposable where S.Output == Element {
        return subscribe(subject.asAnyObserver())
    }
}
