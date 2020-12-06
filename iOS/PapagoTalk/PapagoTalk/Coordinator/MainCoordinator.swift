//
//  MainCoordinator.swift
//  PapagoTalk
//
//  Created by Byoung-Hwi Yoon on 2020/12/01.
//

import UIKit

final class MainCoordinator: Coordinator {
    
    var navigationController: UINavigationController
    var networkService: NetworkServiceProviding
    var userData: UserDataProviding
    var alertFactory: AlertFactoryProviding
    var translationManager: PapagoAPIServiceProviding
    var speechManager: SpeechManager
    var childCoordinator: [Coordinator] = []
    
    private let storyboard = UIStoryboard(name: "Main", bundle: nil)
    
    init(navigationController: UINavigationController,
         networkService: NetworkServiceProviding,
         userData: UserDataProviding,
         alertFactory: AlertFactoryProviding,
         translationManager: PapagoAPIServiceProviding,
         speechManager: SpeechManager) {
        
        self.navigationController = navigationController
        self.networkService = networkService
        self.userData = userData
        self.alertFactory = alertFactory
        self.translationManager = translationManager
        self.speechManager = speechManager
    }
    
    func start() {
        let homeCoordinator = HomeCoordinator(networkService: networkService,
                                              userData: userData,
                                              alertFactory: alertFactory)
        
        let chatCoordinator = ChatCoordinator(networkService: networkService,
                                              userData: userData,
                                              translationManager: translationManager,
                                              speechManager: speechManager)
        
        homeCoordinator.parentCoordinator = self
        chatCoordinator.parentCoordinator = self
        childCoordinator.append(homeCoordinator)
        childCoordinator.append(chatCoordinator)
        
        homeCoordinator.start()
    }
}

extension MainCoordinator: MainCoordinating {
    
    func push(_ viewController: UIViewController) {
        navigationController.pushViewController(viewController, animated: true)
    }
    
    func present(_ viewController: UIViewController) {
        navigationController.viewControllers.last?.present(viewController, animated: true)
    }
   
    func codeInputToChat(roomID: Int, code: String) {
        navigationController.presentedViewController?.dismiss(animated: true, completion: { [weak self] in
            self?.pushChat(roomID: roomID, code: code)
        })
    }
    
    func pushChat(roomID: Int, code: String) {
        guard let chatCoordinator = childCoordinator[1] as? ChatCoordinator else {
            return
        }
        chatCoordinator.roomID = roomID
        chatCoordinator.code = code
        chatCoordinator.start()
    }
    
    func presentCodeInput() {
        let viewController = storyboard.instantiateViewController(
            identifier: ChatCodeInputViewController.identifier,
            creator: { [unowned self] coder -> ChatCodeInputViewController? in
                let reacter = ChatCodeInputReactor(networkService: networkService, userData: userData)
                return ChatCodeInputViewController(coder: coder,
                                                   reactor: reacter,
                                                   alertFactory: alertFactory)
            }
        )
        viewController.coordinator = self
        navigationController.present(viewController, animated: true)
    }
}
