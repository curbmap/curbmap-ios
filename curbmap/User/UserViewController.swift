//
//  UserViewController.swift
//  curbmap
//
//  Created by Eli Selkin on 1/13/18.
//  Copyright © 2018 Eli Selkin. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

class UserViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var menu = false
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var menuButtonOutlet: UIButton!
    @IBAction func menuButtonAction(_ sender: Any) {
        menu = !menu
        if (menu) {
            self.menuView.isHidden = false
        } else {
            self.menuView.isHidden = true
        }
    }
    @IBOutlet weak var menuView: UIView!
    @IBAction func logoutAction(_ sender: Any) {
    }
    
    @IBAction func syncAction(_ sender: Any) {
    }
    var alertViewBG: UIView!
    var alertViewFG: UIView!
    var loading: NVActivityIndicatorView!
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "UserInfoCell")
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "UserInfoCell")
        }
        cell?.backgroundColor = UIColor.black
        cell?.textLabel?.textColor = UIColor.white
        cell?.detailTextLabel?.textColor = UIColor.white
        cell?.indentationWidth = 0.0
        cell?.selectionStyle = .blue
        if (indexPath.row == 0) {
            cell?.textLabel?.text = "My contributions"
            cell?.detailTextLabel?.text = "A list of all the photos and lines you've created"
        } else if (indexPath.row == 1) {
            cell?.textLabel?.text = "My photos queue"
            cell?.detailTextLabel?.text = "Photos not yet uploaded"
        } else if (indexPath.row == 2) {
            cell?.textLabel?.text = "My line queue"
            cell?.detailTextLabel?.text = "Lines not yet uploaded"
        }
        cell?.accessoryType = .none
//        cell?.imageView?.image = UIImage(named: "linemarker")
//        cell?.imageView?.frame.size = CGSize(width: 32, height: 32)
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if (indexPath.row == 0) {
            self.constructTableViewContributions()
        } else if (indexPath.row == 1) {
            self.constructTableViewPhotoQueue()
        } else if (indexPath.row == 2) {
            self.constructTableViewLineQueue()
        }
    }
    
    func constructTableViewContributions() {
        var frame = CGRect(x: self.view.center.x-50, y: self.view.center.y-50, width: 100, height: 100)
        self.loading = NVActivityIndicatorView(frame: self.view.frame, type: NVActivityIndicatorType.ballClipRotatePulse, color: .white, padding: 150.0)
        self.loading.startAnimating()
        self.view.addSubview(self.loading)
        self.alertViewBG = UIView()
        self.alertViewBG.isOpaque = false
        self.alertViewBG.alpha = 0.5
        self.alertViewBG.backgroundColor = UIColor.gray
        self.alertViewFG = UIView()
        self.alertViewFG.backgroundColor = UIColor.white
        let closeButton = UIButton()
        closeButton.titleLabel?.text = "Close"
        let tableView = UITableView()
        tableView.register(UINib(nibName: "ContributionCell", bundle: nil), forCellReuseIdentifier: "ContributionCell")
        let tableViewDD = ContributionsDD()
        //tableViewDD.contributionsPhotos = appDelegate.getPhotoContributions()!
        //tableViewDD.contributionsLines = appDelegate.getLineContributions()!
        Timer.scheduledTimer(timeInterval: 1.1, target: self, selector: #selector(removeLoading), userInfo: nil, repeats: false)
    }
    @objc func removeLoading() {
        self.loading.stopAnimating()
        self.loading.removeFromSuperview()
    }
    func constructTableViewPhotoQueue() {
        
    }
    func constructTableViewLineQueue() {
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.backgroundColor = UIColor.black
        self.menuView.backgroundColor = UIColor.clear
        let vc = MenuTableViewController(nibName: "MenuTableViewController", bundle: nil)
        vc.willMove(toParentViewController: self)
        self.menuView.addSubview(vc.tableView)
        vc.tableView.frame = self.menuView.frame
        vc.tableView.snp.remakeConstraints { (make) in
            make.width.equalTo(self.menuView.snp.width).priority(1000.0)
            make.height.equalTo(self.menuView.snp.height).priority(1000.0)
            make.leading.equalTo(self.menuView.snp.leading).priority(1000.0)
            make.trailing.equalTo(self.menuView.snp.trailing).priority(1000.0)
            make.top.equalTo(self.menuView.snp.top).priority(1000.0)
            make.bottom.equalTo(self.menuView.snp.bottom).priority(1000.0)
        }
        self.addChildViewController(vc)
        vc.didMove(toParentViewController: self)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
