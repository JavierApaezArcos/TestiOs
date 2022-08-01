//
//  HomeViewController.swift
//  TestiOS
//
//  Created by javier apaez on 29/07/22.
//  Copyright (c) 2022 ___ORGANIZATIONNAME___. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit
import FirebaseDatabase
import FirebaseStorage
import FirebaseFirestore


protocol HomeDisplayLogic: AnyObject {
    func displaySomething(viewModel: Home.Charts.ViewModel)
    func displayNewBackgroundColor(viewModel: Home.BackgroundColor.ViewModel)
}

class HomeViewController: UIViewController, HomeDisplayLogic {
    var interactor: HomeBusinessLogic?
    var router: (NSObjectProtocol & HomeRoutingLogic & HomeDataPassing)?
    let homeView = HomeView()
    
    var selfieImage: UIImage? = nil
    
    // MARK: Object lifecycle
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    // MARK: - Setup Clean Code Design Pattern
    
    private func setup() {
        let viewController = self
        let interactor = HomeInteractor()
        let presenter = HomePresenter()
        let router = HomeRouter()
        viewController.interactor = interactor
        viewController.router = router
        interactor.presenter = presenter
        presenter.viewController = viewController
        router.viewController = viewController
        router.dataStore = interactor
    }
    
    // MARK: - Routing
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let scene = segue.identifier {
            let selector = NSSelectorFromString("routeTo\(scene)WithSegue:")
            if let router = router, router.responds(to: selector) {
                router.perform(selector, with: segue)
            }
        }
    }
    
    // MARK: - View lifecycle
    override func loadView() {
        view = homeView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Home"
        
        homeView.tableView.delegate = self
        homeView.tableView.dataSource = self
        homeView.delegate = self
        
        let request = Home.Charts.Request()
        interactor?.addDatabaseObserver(request: request)
       
    }
    
    // MARK: - request data from HomeInteractor
    func showCharts() {
        let request = Home.Charts.Request()
        interactor?.showCharts(request: request)
    }
    
    func showCamera() {
        
        
        let alertController = UIAlertController(title: nil, message: "Selfie.", preferredStyle: .alert)

        let showSelfie = UIAlertAction(title: "Ver selfie", style: .default, handler: { (alert: UIAlertAction!) in
            print("ver selfie")
            
            
            let cell = self.homeView.tableView.cellForRow(at: IndexPath(item: 0, section: 0)) as? TextFieldTableViewCell
            let name = cell?.textField.text!
            
            guard name! != "" else {
                return
            }
            
            self.retriveSelfie()
            
            

        })
        
        
        let retakePicture = UIAlertAction(title: "Tomar selfie", style: .default, handler: {  (alert: UIAlertAction!) in
            print("retomar foto")
            self.retakeSelfie()
        })

        alertController.addAction(retakePicture)
        alertController.addAction(showSelfie)
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    func retakeSelfie() {
        let picker =   UIImagePickerController()
        
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .photoLibrary
        } else {
            picker.sourceType = .camera
        }
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func uploadSelfie() {
        
        guard selfieImage != nil else {
            print("no selfieimage is set")
            return
        }
        let storageRef = Storage.storage().reference()
        let imageData = selfieImage?.jpegData(compressionQuality: 0.3)
        
        guard imageData != nil else {
            print("error imagedata")
            return
        }
        
        
        let cell = homeView.tableView.cellForRow(at: IndexPath(item: 0, section: 0)) as? TextFieldTableViewCell
        let name = cell?.textField.text!
        
        
        guard name != nil else {
            print("is no name")
            return
        }
        
        let path = "selfies/\(name!).jpg"
        let fileRef = storageRef.child(path)
        
        let uploadTask = fileRef.putData(imageData!) { metadata, error in
            if error == nil && metadata != nil {
                let db = Firestore.firestore()
                db.collection("selfies").document("\(name!)").setData(["url": path])
                
            }
        }
    }
    
    func retriveSelfie() {
        let db = Firestore.firestore()
        
        let cell = homeView.tableView.cellForRow(at: IndexPath(item: 0, section: 0)) as? TextFieldTableViewCell
        let name = cell?.textField.text!
        db.collection("selfies").document("\(name!)").getDocument { document, error in
            if let document = document, document.exists {
                    let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
                let url = document["url"] as? String
                
                    //retrive data image
                let storegeRef = Storage.storage().reference()
                let fileref = storegeRef.child(url!)
                // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
                fileref.getData(maxSize: 15 * 1024 * 1024) { data, error in
                    
                  if let error = error {
                    // Uh-oh, an error occurred!
                      print("\(error)")
                  } else {
                    // Data for "images/island.jpg" is returned
                    let image = UIImage(data: data!)
                          self.selfieImage = image
                          
                          let selfieViewController = SelfieViewController()
                          selfieViewController.selfieUIimage = self.selfieImage
                          self.present(selfieViewController, animated: true)
                      
                      
                  }
                }
                
                    print("Document data: \(url!)")
                } else {
                    print("Document does not exist")
                }
        }
    }
    
    
    
    // MARK: - display view model from HomePresenter
    
    func displaySomething(viewModel: Home.Charts.ViewModel) {
        router?.routeToCharts()
    }
    
    func displayNewBackgroundColor(viewModel: Home.BackgroundColor.ViewModel) {
        self.homeView.backgroundColor = UIColor(hexString: "#\(viewModel.hexColor)")
    }
}


