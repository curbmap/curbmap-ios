//
//  UserViewController.swift
//  curbmap
//
//  Created by Eli Selkin on 1/13/18.
//  Copyright © 2018 Eli Selkin. All rights reserved.
//

import UIKit

class UserViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var menu = false
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
