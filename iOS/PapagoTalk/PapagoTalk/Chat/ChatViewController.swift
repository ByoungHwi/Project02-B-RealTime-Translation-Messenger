//
//  ChatViewController.swift
//  PapagoTalk
//
//  Created by 송민관 on 2020/11/25.
//

import UIKit
import ReactorKit
import RxCocoa
import RxGesture

final class ChatViewController: UIViewController, StoryboardView {
    
    @IBOutlet private weak var inputBarTextView: UITextView!
    @IBOutlet private weak var inputBarTextViewHeight: NSLayoutConstraint!
    @IBOutlet weak var chatCollectionView: UICollectionView!
    @IBOutlet private weak var sendButton: UIButton!
    @IBOutlet weak var chatDrawerButton: UIBarButtonItem!
    @IBOutlet private weak var bottomConstraint: NSLayoutConstraint!
    
    weak var coordinator: ChatCoordinating?
    var microphoneButton: MicrophoneButton!
    var disposeBag = DisposeBag()
    
    init?(coder: NSCoder, reactor: ChatViewReactor) {
        super.init(coder: coder)
        self.reactor = reactor
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        attachMicrophoneButton()
        bind()
        bindKeyboard()
    }
    
    func bind(reactor: ChatViewReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }
    
    // MARK: - Input
    private func bindAction(reactor: ChatViewReactor) {
        self.rx.viewWillAppear
            .map { _ in Reactor.Action.subscribeNewMessages }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        sendButton.rx.tap
            .withLatestFrom(inputBarTextView.rx.text)
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .map { Reactor.Action.sendMessage($0) }
            .do(afterNext: { [weak self] _ in
                self?.inputBarTextView.text = nil
            })
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        chatDrawerButton.rx.tap
            .map { Reactor.Action.chatDrawerButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
    
    // MARK: - Output
    private func bindState(reactor: ChatViewReactor) {
        reactor.state.map { $0.roomCode }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] in
                var code = $0
                code.insert("-", at: code.index(code.startIndex, offsetBy: 3))
                self?.navigationItem.title = code
            })
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.messageBox.messages }
            .do(afterNext: { [weak self] in
                guard let currentMessageType = $0.last?.type,
                      currentMessageType == .sent else {
                    return
                }
                self?.scrollToLastMessage()
            })
            .bind(to: chatCollectionView.rx.items) { [weak self] (_, row, element) in
                guard let cell = self?.configureChatMessageCell(at: row, with: element) else {
                    return UICollectionViewCell()
                }
                return cell
            }
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.sendResult }
            .asObservable()
            .subscribe()
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.presentDrawer }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] in
                self?.setDrawer(isPresent: $0)
            })
            .disposed(by: disposeBag)
    }
    
    private func bind() {
        chatCollectionView.rx.setDelegate(self)
            .disposed(by: disposeBag)
        
        inputBarTextView.rx.text
            .orEmpty
            .compactMap { [weak self] text in
                self?.calculateTextViewHeight(with: text)
            }
            .asObservable()
            .distinctUntilChanged()
            .bind(to: inputBarTextViewHeight.rx.constant)
            .disposed(by: disposeBag)
        
        microphoneButton?.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] in
                self?.microphoneButton?.moveForSpeech {
                    self?.presentSpeech()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func calculateTextViewHeight(with text: String) -> CGFloat {
        let size = inputBarTextView.sizeThatFits(CGSize(width: inputBarTextView.bounds.size.width,
                                                        height: CGFloat.greatestFiniteMagnitude))
        return min(Constant.inputBarTextViewMaxHeight, size.height)
    }
    
    private func configureChatMessageCell(at row: Int, with element: Message) -> UICollectionViewCell {
        guard let cell = chatCollectionView.dequeueReusableCell(withReuseIdentifier: element.type.identifier,
                                                                for: IndexPath(row: row, section: .zero)) as? MessageCell else {
            return UICollectionViewCell()
        }
        cell.configureMessageCell(message: element)
        return cell
    }
    
    private func scrollToLastMessage() {
        view.layoutIfNeeded()
        let newY = chatCollectionView.contentSize.height - chatCollectionView.bounds.height
        chatCollectionView.setContentOffset(CGPoint(x: 0, y: newY < 0 ? 0 : newY), animated: false)
    }
    
    private func presentSpeech() {
        hideKeyboard()
        coordinator?.presentSpeech(from: self)
    }
    
    private func setDrawer(isPresent: Bool) {
        if isPresent {
            hideKeyboard()
        }
        isPresent ? coordinator?.presentDrawer(from: self) : dismissDrawer()
    }
    
    private func dismissDrawer() {
        chatDrawerButton.isEnabled = false
        guard let drawer = children.first as? ChatDrawerViewController else {
            chatDrawerButton.isEnabled = true
            return
        }
        drawer.configureAnimation(state: .closed, duration: 0.5)
    }
    
    private func hideKeyboard() {
        UIView.performWithoutAnimation {
            inputBarTextView.resignFirstResponder()
        }
    }
}

extension ChatViewController: KeyboardProviding {
    private func bindKeyboard() {
        tapToDissmissKeyboard
            .drive()
            .disposed(by: disposeBag)
        
        keyboardWillShow
            .drive(onNext: { [weak self] keyboardFrame in
                guard let self = self else {
                    return
                }
                self.bottomConstraint.constant = keyboardFrame.height - self.view.safeAreaInsets.bottom
                UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseInOut) {
                    self.view.layoutIfNeeded()
                }
            })
            .disposed(by: disposeBag)
        
        keyboardWillHide
            .drive(onNext: { [weak self] _ in
                self?.bottomConstraint.constant = 0
                UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseInOut) {
                    self?.view.layoutIfNeeded()
                }
            })
            .disposed(by: disposeBag)
    }
}

// TODO: Rx로 수정
extension ChatViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: collectionView.frame.width, height: 40)
    }
}
