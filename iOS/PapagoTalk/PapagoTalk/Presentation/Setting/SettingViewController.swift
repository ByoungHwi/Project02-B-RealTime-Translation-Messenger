//
//  SettingViewController.swift
//  PapagoTalk
//
//  Created by 송민관 on 2020/12/12.
//

import UIKit
import ReactorKit
import RxCocoa

final class SettingViewController: UIViewController, StoryboardView {
    
    @IBOutlet private weak var sizeSettingSegmentedControl: UISegmentedControl!
    @IBOutlet private weak var micButtonDisplayView: UIView!
    @IBOutlet private weak var translationSettingSwitch: UISwitch!
    
    var buttonObserver: BehaviorRelay<MicButtonSize>?
    var microphoneButton = MicrophoneButton(mode: .none)
    var disposeBag = DisposeBag()
    
    init?(coder: NSCoder, reactor: SettingViewReactor, micButtonObserver: BehaviorRelay<MicButtonSize>?) {
        super.init(coder: coder)
        self.buttonObserver = micButtonObserver
        self.reactor = reactor
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initailizeSizeSettingSegmentedControl()
        initailizeMicButton(by: .none)
    }
        
    func bind(reactor: SettingViewReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }
    
    // MARK: - Input
    private func bindAction(reactor: SettingViewReactor) {
        sizeSettingSegmentedControl.rx.value
            .changed
            .map { Reactor.Action.sizeSegmentedControlChanged($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        translationSettingSwitch.rx.value
            .changed
            .map { Reactor.Action.translationSettingSwitchChanged($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
    
    // MARK: - Output
    private func bindState(reactor: SettingViewReactor) {
        reactor.state.map { $0.microphoneButtonState }
            .distinctUntilChanged()
            .do(onNext: { [weak self] in
                self?.applyMicrophoneButtonState(of: $0)
            })
            .map { $0.index }
            .filter { [weak self] in
                self?.sizeSettingSegmentedControl.selectedSegmentIndex != $0
            }
            .subscribe(onNext: { [weak self] in
                self?.sizeSettingSegmentedControl.selectedSegmentIndex = $0
            })
            .disposed(by: disposeBag)

        reactor.state.map { $0.translationSetting }
            .distinctUntilChanged()
            .filter { [weak self] in
                self?.translationSettingSwitch.isOn != $0
            }
            .subscribe(onNext: { [weak self] in
                self?.translationSettingSwitch.isOn = $0
            })
            .disposed(by: disposeBag)
    }
    
    private func initailizeMicButton(by size: MicButtonSize) {
        micButtonDisplayView.addSubview(microphoneButton)
        microphoneButton.isUserInteractionEnabled = false
        setMicButtonPosition()
    }
    
    private func setMicButtonPosition() {
        let xCenter = view.frame.width/2 - micButtonDisplayView.frame.origin.x
        microphoneButton.center = CGPoint(x: xCenter, y: micButtonDisplayView.frame.height/2)
    }
    
    private func initailizeSizeSettingSegmentedControl() {
        guard MicButtonSize.allCases.count <= sizeSettingSegmentedControl.numberOfSegments else {
            return
        }
        MicButtonSize.allCases.forEach {
            sizeSettingSegmentedControl.setTitle($0.description, forSegmentAt: $0.index)
        }
    }
    
    private func applyMicrophoneButtonState(of micButtonSize: MicButtonSize) {
        microphoneButton.mode = micButtonSize
        setMicButtonPosition()
        
        guard let buttonObserver = buttonObserver else {
            return
        }
        buttonObserver.accept(micButtonSize)
    }
}
