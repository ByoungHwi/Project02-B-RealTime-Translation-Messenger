//
//  ChatViewController.swift
//  PapagoTalk
//
//  Created by 송민관 on 2020/11/25.
//

import UIKit
import ReactorKit
import RxCocoa

final class ChatViewController: UIViewController, StoryboardView {

    @IBOutlet private weak var inputBarTextView: UITextView!
    @IBOutlet private weak var inputBarTextViewHeight: NSLayoutConstraint!
    @IBOutlet private weak var chatCollectionView: UICollectionView!
    @IBOutlet private weak var sendButton: UIButton!
    
    var disposeBag = DisposeBag()
    
    // TODO: User정보 관리 객체 분리
    let userId = 7
    let roomID = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reactor = ChatViewReactor()
        bind()
    }
    
    func bind(reactor: ChatViewReactor) {
        self.rx.viewWillAppear
            .map { _ in
                Reactor.Action.subscribeNewMessages(1)
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        sendButton.rx.tap
            .withLatestFrom(inputBarTextView.rx.text)
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .map { Reactor.Action.sendMessage($0) }
            .do(afterNext: { [weak self] _ in
                self?.inputBarTextView.text = nil
                self?.scrollToLastMessage()
            })
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.messageBox.messages }
            .bind(to: chatCollectionView.rx.items) { [weak self] (_, row, element) in
                guard let cell = self?.configureMessageCell(at: row, with: element) else {
                    return UICollectionViewCell()
                }
                return cell
            }
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.sendResult }
            .asObservable()
            .do(afterNext: { [weak self] isSuccess in
                guard isSuccess else {
                    return
                }
                self?.scrollToLastMessage()
            })
            .subscribe()
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
    }
    
    private func calculateTextViewHeight(with text: String) -> CGFloat {
        let size = inputBarTextView.sizeThatFits(CGSize(width: inputBarTextView.bounds.size.width,
                                                        height: CGFloat.greatestFiniteMagnitude))
        return min(Constant.inputBarTextViewMaxHeight, size.height)
    }
    
    private func configureMessageCell(at row: Int, with element: Message) -> UICollectionViewCell {
        let indexPath = IndexPath(row: row, section: 0)
        let identifier: String
        
        switch element.sender.id {
        case userId:
            identifier = SentMessageCell.identifier
        default:
            identifier = ReceivedMessageCell.identifier
        }
        let cell = chatCollectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
        
        guard let messageCell = cell as? MessageCell else {
            return UICollectionViewCell()
        }
        messageCell.configureMessageCell(message: element)
        return cell
    }
    
    private func scrollToLastMessage() {
        let newY = chatCollectionView.contentSize.height - chatCollectionView.bounds.height
        chatCollectionView.setContentOffset(CGPoint(x: 0, y: newY < 0 ? 0 : newY), animated: true)
    }
}

// TODO: Rx로 수정
extension ChatViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: collectionView.frame.width, height: 40)
    }
}
