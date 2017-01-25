//
//  SettingsTableVC.swift
//  Music ++
//
//  Created by QUANG on 1/23/17.
//  Copyright © 2017 Q.U.A.N.G. All rights reserved.
//

import UIKit
import MessageUI
import SCLAlertView

class SettingsTableVC: UITableViewController, MFMailComposeViewControllerDelegate {
    
    //MARK: Properties
    let defaults = UserDefaults.standard
    var time: TimeInterval = 3600 //Default is 1 hour
    
    let datePickerView: UIDatePicker = UIDatePicker()
    let doneBtn: UIButton = UIButton()
    
    struct defaultsKeys {
        static let isReflectionOn = "isReflectionOn"
        static let isAutoStopOn = "isAutoStopOn"
        static let timeBeforeStop = "timeBeforeStop"
    }
    
    //MARK: Outlets
    @IBOutlet var lblVersion: UILabel!
    @IBOutlet var lblAutoStopTime: UILabel!
    
    @IBOutlet var swtReflection: UISwitch!
    @IBOutlet var swtAutoStop: UISwitch!
    
    //Actions
    @IBAction func navigationCancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func navigationSave(_ sender: UIBarButtonItem) {
        defaults.setValue(swtReflection.isOn, forKey: defaultsKeys.isReflectionOn)
        defaults.setValue(swtAutoStop.isOn, forKey: defaultsKeys.isAutoStopOn)
        defaults.setValue(time, forKey: defaultsKeys.timeBeforeStop)
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func albumReflectionChanged(_ sender: UISwitch) {
        print("albumReflectionChanged")
    }
    
    @IBAction func autoStopChanged(_ sender: UISwitch) {
        print("autoStopChanged")
    }
    
    @IBAction func changeTime(_ sender: UIButton) {
        
        /*
        let datePickerView: UIDatePicker = UIDatePicker()
        datePickerView.datePickerMode = UIDatePickerMode.countDownTimer
        datePickerView.minuteInterval = 5
        datePickerView.addTarget(self, action: #selector(updateTime), for: UIControlEvents.valueChanged)
        let datePickerViewSize: CGSize = datePickerView.sizeThatFits(CGSize.zero)
        datePickerView.frame = CGRect(x: 0, y: view.frame.height - 200, width: datePickerViewSize.width, height: 200)
        
        self.view.addSubview(datePickerView)*/
        
        if datePickerView.minuteInterval != 5 {
            datePickerView.datePickerMode = UIDatePickerMode.countDownTimer
            datePickerView.minuteInterval = 5
            datePickerView.addTarget(self, action: #selector(updateTime), for: UIControlEvents.valueChanged)
            let datePickerViewSize: CGSize = datePickerView.sizeThatFits(CGSize.zero)
            datePickerView.frame = CGRect(x: 0, y: view.frame.height - 200, width: datePickerViewSize.width, height: 200)
            datePickerView.backgroundColor = UIColor(red: 239, green: 239, blue: 244)
            
            doneBtn.frame = CGRect(x: view.frame.width - 55, y: view.frame.height - 200 + 5, width: 50, height: 30)
            doneBtn.setTitle("Done", for: UIControlState.normal)
            doneBtn.setTitleColor(.white, for: .normal)
            doneBtn.backgroundColor = UIColor(red: 3, green: 121, blue: 251)
            doneBtn.layer.cornerRadius = 5
            let press = UITapGestureRecognizer(target: self, action: #selector(dismissPicker))
            doneBtn.addGestureRecognizer(press)
            
            self.view.addSubview(datePickerView)
            self.view.addSubview(doneBtn)
        }
        
        datePickerView.isHidden = false
        doneBtn.isHidden = false
    }
    
    func dismissPicker() {
        datePickerView.isHidden = true
        doneBtn.isHidden = true
    }
    
    func updateTime(sender: UIDatePicker) { //Everytime value is changed
        let selectedTime = sender.countDownDuration
        
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.hour, .minute ]
        formatter.zeroFormattingBehavior = [.dropAll]
        
        lblAutoStopTime.text = "After: \(formatter.string(from: selectedTime)!)"
        time = selectedTime //Set to save
        print("Time: \(time)")
    }
    
    @IBAction func resetTap(_ sender: UIButton) {
        let appearance = SCLAlertView.SCLAppearance(
            showCloseButton: false
        )
        
        let alertView = SCLAlertView(appearance: appearance)
        alertView.addButton("I Understand") {
            self.clearALL()
        }
        alertView.addButton("Abort!!!") {
            print("Abort Clear Data.")
            SCLAlertView().showTitle(
                "👍", // Title of view
                subTitle: "Your ❤️❤️❤️ are safe now.", // String of view
                duration: 10.0, // Duration to show before closing automatically, default: 0.0
                completeText: "Thanks", // Optional button value, default: ""
                style: .notice, // Styles - see below.
                colorStyle: 0xA429FF,
                colorTextButton: 0xFFFFFF
            )
        }
        alertView.showNotice("WARNING!!!", subTitle: "All data will be lost.")
        

    }
    
    func clearALL() {
        var likes = [LikesArray]()
        likes.removeAll()
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(likes, toFile: LikesArray.ArchiveURL.path)
        if isSuccessfulSave {
            
            SCLAlertView().showTitle(
                "Done! 👍", // Title of view
                subTitle: "All your ❤️❤️❤️ are reseted now.", // String of view
                duration: 10.0, // Duration to show before closing automatically, default: 0.0
                completeText: "Thanks", // Optional button value, default: ""
                style: .success, // Styles - see below.
                colorStyle: 0xA429FF,
                colorTextButton: 0xFFFFFF
            )
            print("Data successfully cleared.")

        } else {
            SCLAlertView().showTitle(
                "Hmmm... 😱", // Title of view
                subTitle: "I somehow fail, plese try reopening the app. 😭", // String of view
                duration: 10.0, // Duration to show before closing automatically, default: 0.0
                completeText: "OK", // Optional button value, default: ""
                style: .error, // Styles - see below.
                colorStyle: 0xA429FF,
                colorTextButton: 0xFFFFFF
            )
            print("Failed to clear data...")
        }
    }
    
    @IBAction func reportBugTap(_ sender: UIButton) {
        let mailComposeViewController = configuredMailComposeViewController()
        if MFMailComposeViewController.canSendMail() {
            self.present(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    
    @IBAction func reviewTap(_ sender: UIButton) {
        if let url = URL(string: "https://www.facebook.com/crzQag") {
            UIApplication.shared.open(url, options: [:])
        }
    }
    
    //MARK: Private Methods
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    //MARK: Private Methods
    func showSendMailErrorAlert() {
        let sendMailErrorAlert = UIAlertController(title: "Mail couldn't be sent.", message: "Your device could not send e-mail. Please check e-mail configuration and try again.", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        sendMailErrorAlert.addAction(action)
        present(sendMailErrorAlert, animated: true, completion: nil)
    }
    
    func configuredMailComposeViewController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
        
        mailComposerVC.setToRecipients(["quangscorpio@gmail.com"])
        mailComposerVC.setSubject("MUSIC ++ BUG REPORT!!!")
        mailComposerVC.setMessageBody("Please type the bug down below, please be specific and clear...", isHTML: false)
        
        return mailComposerVC
    }

    
    //MARK: Defaults
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Update build version
        updateBuild()
        
        //Update save data switch
        loadSavedData()
    }
    
    func loadSavedData() {
        swtReflection.isOn = defaults.bool(forKey: defaultsKeys.isReflectionOn)
        swtAutoStop.isOn = defaults.bool(forKey: defaultsKeys.isAutoStopOn)
        
        time = defaults.object(forKey: defaultsKeys.timeBeforeStop) as! TimeInterval
        
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.hour, .minute ]
        formatter.zeroFormattingBehavior = [.dropAll]
        
        lblAutoStopTime.text = "After: \(formatter.string(from: time)!)"
    }
    
    func updateBuild() {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            self.lblVersion.text = "\(version) 👍."
        }
        else {
            self.lblVersion.text = "Unknown 😬."
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    // MARK: - Table view data source

    /*
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }*/

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
