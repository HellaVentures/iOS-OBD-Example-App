//
//  ViewController.swift
//  SwiftyOBD
//
//  Created by Daniel Montano on 06.10.16.
//  Copyright © 2016 Hella Ventures Berlin. All rights reserved.
//

import UIKit
import Eureka
import Alamofire
import CircleProgressView
import DZNEmptyDataSet
import SwiftyJSON

class ViewController: FormViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        form
            +++ LabelRow(){ row in
                row.title = "OBD Connection"
                row.value = "WiFI"
                isEditing = false
            }
            <<< LabelRow(){ row in
                row.title = "Translator"
                row.value = "Hella OBD API"
                isEditing = false
            }
            <<< AlertRow<String>("LanguageRow") {
                $0.title = "Translation Language"
                $0.selectorTitle = "Translation Language"
                $0.options = ["English", "German"]
                $0.value = "EN"
                }.onChange{ row in
                    if (row.value == "English"){
                        row.value = "EN"
                    }else if(row.value == "German"){
                        row.value = "DE"
                    }
                    apiManager.language = row.value!
                    row.updateCell()
            }
            <<< TextRow("VinRow"){ row in
                row.title = "Vin"
                row.value = "WBAES26C05D"
                }.onChange { textRow in
                    apiManager.vin = textRow.value!
            }
            +++ Section()
            
            <<< ButtonRow("ConnectButton"){ row in
                row.title = "Connect"
                row.presentationMode = .segueName(segueName: "SetupPushSegue", onDismiss:{  vc in vc.dismiss(animated: true, completion: nil) })
        }
        
        func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return 60.0
        }
        
        func didReceiveMemoryWarning() {
            super.didReceiveMemoryWarning()
        }
        
        func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
            return 0.1
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

class SetupViewController: UIViewController, OBDStreamManagerDelegate {
    
    @IBOutlet weak var progressLabel: UILabel!
    
    @IBOutlet weak var circleProgressView: CircleProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        circleProgressView.progress = 0.0
        obdStreamManager.delegate = self
        obdStreamManager.startStreaming()
        Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.timedTunc), userInfo: nil, repeats: false)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    func timedTunc(){
        obdStreamManager.setupAdapter()
    }
    
    func setupProgress(_ progress: Double) {
        circleProgressView.progress = progress/100.0
        progressLabel.text = "\(progress) %"
        
        if progress == 100 {
            let view = self.storyboard?.instantiateViewController(withIdentifier: "ResultsTableView")
            self.navigationController!.pushViewController( view!, animated: true)
        }
    }
}


class ResultsTableCell: UITableViewCell {
    
    @IBOutlet weak var bottomLabel: UILabel!
    
    @IBOutlet weak var leftLabel: UILabel!
    
    @IBOutlet weak var middleLabel: UILabel!
    
}


class ResultsTableViewController: UITableViewController, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, OBDStreamManagerDelegate{
    
    var dtcsArray: [String] = []
    var OBDDTCArray: [OBDDTC] = []
    var error = false
    var errorMsg = ""
    
    var currentResultData: String = ""
    
    let globalAttrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
    
    override func viewDidLoad() {
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.tableFooterView = UIView()
        
        obdStreamManager.delegate = self
        
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: "Disconnect", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.back))
        
        self.navigationItem.leftBarButtonItem = newBackButton;
        
        super.viewDidLoad()
    }
    
    func back(_ sender: UIBarButtonItem) {
        let _ = self.navigationController?.popToRootViewController(animated: true)
    }
    
    func makeAPIRequest(_ errorCodeNumber: Int){
        
        let parameters = [
            "code_id":dtcsArray[errorCodeNumber],
            "vin":apiManager.vin,
            "language":apiManager.language,
            "client_secret":apiManager.client_secret,
            "client_id": apiManager.client_id
        ]
        
        Alamofire.request(apiManager.api_address, parameters: parameters).responseJSON { response in
                
            if let responseJSON = response.result.value {
                let swiftyJSONObject = JSON(responseJSON)
                let dtcObject = OBDDTC.parseFronJSON(swiftyJSONObject, withDTC: self.dtcsArray[errorCodeNumber])
                
                if let uDTCObject = dtcObject {
                    self.OBDDTCArray.append(uDTCObject)
                    self.tableView.reloadData()
                }else {
                    if(!self.error){
                        self.errorMsg = response.result.value.debugDescription
                        self.error = true
                        self.tableView.reloadData()
                    }
                }
            }else{
                log.error("JSON is nil")
            }
        }
    }
    
    ////////////////////////////////////////////////////////
    // MARK: OBD STREAM MANAGER PROTOCOL IMPLEMENTATION
    ////////////////////////////////////////////////////////
    
    func DTCsUpdated(_ newDTCs: [String], dtcs: Int) {
        self.dtcsArray = newDTCs
        
        if(newDTCs.count == dtcs){
            Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.delayedFunc2), userInfo: nil, repeats: false)
        }
        tableView.reloadData()
    }
    
    func delayedFunc2(){
        self.error = false
        if dtcsArray.count > 0 {
            for i in 0...dtcsArray.count-1 {
                makeAPIRequest(i)
            }
        }
    }
    
    
    ////////////////////////////////////////////////////////
    // MARK: TABLE VIEW IMPLEMENTATION
    ////////////////////////////////////////////////////////
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: ResultsTableCell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! ResultsTableCell
        
        if(OBDDTCArray.count == dtcsArray.count){
            cell.leftLabel.text = OBDDTCArray[(indexPath as NSIndexPath).row].DTC
            
            cell.middleLabel.text = "Fault: \(OBDDTCArray[(indexPath as NSIndexPath).row].fault)"
            
            cell.bottomLabel.text = "System: \(OBDDTCArray[(indexPath as NSIndexPath).row].system)"
            
        }else{
            if(self.error){
                let alert = UIAlertController(title: "Error", message: self.errorMsg, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            cell.leftLabel.text = dtcsArray[(indexPath as NSIndexPath).row]
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dtcsArray.count
    }
    
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        cell.backgroundColor = UIColor.clear
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90.0
    }
    
    ////////////////////////////////////////////////////////
    // MARK: EMPTY DATA SET IMPLEMENTATION
    ////////////////////////////////////////////////////////
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "Connected"
        return NSAttributedString(string: str, attributes: self.globalAttrs)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "Tap the button below to load the Diagnostic Trouble Codes from the OBD2 Adapter."
        return NSAttributedString(string: str, attributes: self.globalAttrs)
    }
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString! {
        let str = "Get DTCs"
        return NSAttributedString(string: str, attributes: self.globalAttrs)
    }
    
    func emptyDataSetDidTapButton(_ scrollView: UIScrollView!) {
        obdStreamManager.requestDTCs()
    }
    
    
    // MARK: Stop edit mode when clicking outside of keyboard
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }
}

