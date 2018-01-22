//
//  ViewController.swift
//  rxplayground
//
//  Created by minoru_kojima on 2018/01/23.
//  Copyright © 2018年 minoru_kojima. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {
    private let disposeBag = DisposeBag()
    private let vm = ViewModel()

    @IBOutlet var input: UITextField!
    @IBOutlet var result: UILabel!
    @IBOutlet var buttonSync: UIButton!
    @IBOutlet var buttonAsync: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        // setup
        self.input.rx.text.orEmpty.bind(to: self.vm.inputString).disposed(by: disposeBag)
        self.vm.result.map({ value in String(value) }).bind(to: self.result.rx.text).disposed(by: disposeBag)

        self.buttonSync.rx.tap.bind(to: self.vm.doSomething).disposed(by: disposeBag)
        self.buttonAsync.rx.tap.bind(to: self.vm.doAsync).disposed(by: disposeBag)
    }
}

class ViewModel {
    private let disposeBag = DisposeBag()
    private let doSomethingSubject = PublishSubject<Void>()
    private let asyncingSubject = BehaviorSubject<Bool>(value: false)
    private let doAsyncSubject = PublishSubject<Void>()
    private let inputStringSubject = BehaviorSubject<String>(value: "")
    private let resultSubject = BehaviorSubject<Int>(value: 0)

    // input
    var doSomething: AnyObserver<Void>
    var doAsync: AnyObserver<Void>
    var inputString: AnyObserver<String>

    // output
    var result: Observable<Int>

    init() {
        self.doSomething = self.doSomethingSubject.asObserver()
        self.doAsync = self.doAsyncSubject.asObserver()
        self.inputString = self.inputStringSubject.asObserver()
        self.result = self.resultSubject.asObservable()

        self.doSomethingSubject.bind(onNext: self.something).disposed(by: disposeBag)
        self.doAsyncSubject
            .filter { !(try self.asyncingSubject.value()) }
            .bind(onNext: self.async)
            .disposed(by: disposeBag)

        self.asyncingSubject.subscribe(onNext: { (asyncing) in UIApplication.shared.isNetworkActivityIndicatorVisible = asyncing }).disposed(by: disposeBag)
    }

    private func method() {
        let text = try? self.inputStringSubject.value()
        let textCount = text?.count ?? 0
        self.resultSubject.onNext(textCount)
    }

    private func something() {
        method()
    }

    private func async() {
        print ("exec async()")
        self.asyncingSubject.onNext(true)

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(5)) {
            self.method()
            self.asyncingSubject.onNext(false)
        }
    }

}
