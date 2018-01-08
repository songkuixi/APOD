//
//  APODInfoTableViewController.swift
//  APoD
//
//  Created by 宋 奎熹 on 2018/1/6.
//  Copyright © 2018年 宋 奎熹. All rights reserved.
//

import UIKit
import Kingfisher
import SVProgressHUD
import WebKit
import Alamofire

class APODInfoTableViewController: UITableViewController {
    
    private var animatedCellIndexs: [Int] = []
    
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var explanationLabel: UILabel!
    @IBOutlet weak var copyrightLabel: UILabel!
    lazy var webView: WKWebView = {
        let webViewConfig = WKWebViewConfiguration()
        webViewConfig.allowsInlineMediaPlayback = true
        webViewConfig.allowsPictureInPictureMediaPlayback = true
        let wkView = WKWebView(frame: mainImageView.frame, configuration: webViewConfig)
        wkView.isOpaque = false
        return wkView
    }()
    @IBOutlet weak var favoriteBarButtonItem: UIBarButtonItem!
    
    private var imageViewHeight: CGFloat = 100.0
    
    private var currentDate: Date = Date() {
        didSet {
            self.navigationItem.title = apodDateFormatter.string(from: currentDate)
        }
    }
    
    private var apodModel: APODModel? {
        didSet {
            if apodModel != nil {
                
                APODHelper.shared.cacheModel(model: apodModel!)
                
                DispatchQueue.main.async {
                    if let date = self.apodModel!.date {
                        if APODHelper.shared.isFavoriteModel(on: date) {
                            self.favoriteBarButtonItem.image = #imageLiteral(resourceName: "heart_full")
                        } else {
                            self.favoriteBarButtonItem.image = #imageLiteral(resourceName: "heart")
                        }
                    }
                    self.titleLabel.text = self.apodModel!.title
                    self.explanationLabel.text = self.apodModel!.explanation
                    self.copyrightLabel.text = self.apodModel!.copyright
                    
                    if self.apodModel!.media_type == APODMediaType.image {
                        
                        self.mainImageView.isHidden = false
                        
                        self.mainImageView.kf.setImage(with: (self.apodModel!.url)!, placeholder: nil, options: nil, progressBlock: { (current, total) in
                            SVProgressHUD.showProgress(Float(current) / Float(total))
                        }, completionHandler: { (image, error, cacheType, url) in
                            self.imageViewHeight = kScreenWidth / (image?.size.width ?? 1.0) * (image?.size.height ?? 1.0)
                            self.mainImageView.frame = CGRect(x: self.mainImageView.frame.origin.x,
                                                              y: self.mainImageView.frame.origin.y,
                                                              width: kScreenWidth,
                                                              height: self.imageViewHeight)
                            SVProgressHUD.dismiss()
                            self.tableView.reloadData()
                        })
                    } else if self.apodModel!.media_type == APODMediaType.video {
                        
                        self.mainImageView.isHidden = true
                        
                        self.imageViewHeight = kScreenWidth / 16.0 * 9.0
                        
                        self.webView.frame = CGRect(x: self.mainImageView.frame.origin.x,
                                                    y: self.mainImageView.frame.origin.y,
                                                    width: kScreenWidth,
                                                    height: self.imageViewHeight)
                        self.webView.load(URLRequest(url: self.apodModel!.url!))
                        self.tableView.addSubview(self.webView)
                        
                        SVProgressHUD.dismiss()
                        self.tableView.reloadData()
                    }
                }
            } else {
                self.animatedCellIndexs.removeAll()
                self.mainImageView.isHidden = true
                
                self.webView.removeFromSuperview()
                
                self.titleLabel.text = ""
                self.copyrightLabel.text = ""
                self.explanationLabel.text = ""
                self.favoriteBarButtonItem.image = #imageLiteral(resourceName: "heart")
                
                cancelNetworkRequests()
                
                self.tableView.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        
        let bgView = UIView(frame: tableView.bounds)
        bgView.backgroundColor = UIColor.apod
        tableView.backgroundView = bgView
        
        let swipeLeftGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipeAction(_:)))
        swipeLeftGesture.direction = .left
        tableView.addGestureRecognizer(swipeLeftGesture)
        
        let swipeRightGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipeAction(_:)))
        swipeRightGesture.direction = .right
        tableView.addGestureRecognizer(swipeRightGesture)
        
        loadModel(on: Date())
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.navigationController?.tabBarController?.tabBar.isHidden = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        cancelNetworkRequests()
    }
    
    func cancelNetworkRequests() {
        self.mainImageView.kf.cancelDownloadTask()
        
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDataTask, uploadData, downloadData) in
            sessionDataTask.forEach { $0.cancel() }
            uploadData.forEach { $0.cancel() }
            downloadData.forEach { $0.cancel() }
        }
        
        SVProgressHUD.dismiss()
    }
    
    @objc func swipeAction(_ sender: UISwipeGestureRecognizer) {
        switch sender.direction {
        case UISwipeGestureRecognizerDirection.left:
            let newDate = currentDate.addingTimeInterval(24 * 60 * 60)
            if newDate.timeIntervalSince1970 <= maximumDate.timeIntervalSince1970 {
                loadModel(on: newDate)
            }
        case UISwipeGestureRecognizerDirection.right:
            let newDate = currentDate.addingTimeInterval(-24 * 60 * 60)
            if newDate.timeIntervalSince1970 >= minimumDate.timeIntervalSince1970 {
                loadModel(on: newDate)
            }
        default:
            return
        }
    }
    
    func loadModel(on date: Date) {
        self.apodModel = nil
        self.currentDate = date
        
        if let model = APODHelper.shared.getCacheModel(on: date) {
            self.apodModel = model
        } else {
            SVProgressHUD.show(withStatus: "Loading")
            DispatchQueue.global().async {
                APODHelper.shared.getAPODInfo(on: date) { model in
                    if model != nil {
                        self.apodModel = model!
                    } else {
                        SVProgressHUD.showError(withStatus: "Something is wrong\non this day")
                        SVProgressHUD.dismiss(withDelay: 2.0)
                    }
                }
            }
        }
    }
    
    @IBAction func favoriteAction(_ sender: UIBarButtonItem) {
        if let model = self.apodModel {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
            
            if APODHelper.shared.isFavoriteModel(on: model.date!) {
                favoriteBarButtonItem.image = #imageLiteral(resourceName: "heart")
                
                APODHelper.shared.removeFavorite(model: model)
            } else {
                favoriteBarButtonItem.image = #imageLiteral(resourceName: "heart_full")
                
                APODHelper.shared.addFavorite(model: model)
            }
        }
    }

    @IBAction func calendarAction(_ sender: UIBarButtonItem) {
        let alertVC = UIAlertController(title: "Choose a Date", message: nil, preferredStyle: .actionSheet)
        alertVC.view.addSubview(apodDatePicker)
        apodDatePicker.date = currentDate
        alertVC.view.frame = CGRect(x: 0, y: 0, width: kScreenWidth, height: 10)
        
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            self.loadModel(on: apodDatePicker.date)
        }
        okAction.setValue(UIColor.apod, forKey: "titleTextColor")
        alertVC.addAction(okAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        cancelAction.setValue(UIColor.apod, forKey: "titleTextColor")
        alertVC.addAction(cancelAction)
        
        let height: NSLayoutConstraint = NSLayoutConstraint(item: alertVC.view,
                                                           attribute: .height,
                                                           relatedBy: .equal,
                                                           toItem: nil,
                                                           attribute: .notAnAttribute,
                                                           multiplier: 1,
                                                           constant: apodDatePicker.frame.height + 120)
        alertVC.view.addConstraint(height)
        
        present(alertVC, animated: true, completion: nil)
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0:
            return imageViewHeight
        default:
            return UITableViewAutomaticDimension
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if animatedCellIndexs.contains(indexPath.row) {
            return
        }
        cell.alpha = 0.0
        UIView.animate(withDuration: 0.3, delay: 0, options: UIViewAnimationOptions.curveEaseInOut, animations: {
            cell.alpha = 1.0
        }) { _ in
            self.animatedCellIndexs.append(indexPath.row)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let model = apodModel, indexPath.row == 0 {
            performSegue(withIdentifier: "detailSegue", sender: model)
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "detailSegue" {
            let detailVC = segue.destination as! APODDetailViewController
            detailVC.apodModel = (sender as! APODModel)
        }
    }
    
}