//
//  LoogedInViewController.swift
//  GoogleAPIClientForREST
//
//  Created by Vishal Narayan on 4/11/18.
//

import GoogleAPIClientForREST
import GoogleSignIn
import UIKit
import Firebase

class LoogedInViewController: UIViewController, UITextFieldDelegate, GIDSignInDelegate, GIDSignInUIDelegate {
    
    private let scopes = [kGTLRAuthScopeSheetsSpreadsheets]
    private let service = GTLRSheetsService()
    
    private var ref: DatabaseReference!
    
    public var PAYORDEPOSIT = true
    
    private var sheetId: String = ""
    
    let user: GIDGoogleUser! = GIDGoogleUser.init()
    
    @IBOutlet weak var item: UITextField!
    @IBOutlet weak var amount: UITextField!
    @IBOutlet weak var transactionType: UISegmentedControl!


    override func viewDidLoad() {
        super.viewDidLoad()
//        let token = GIDSignIn.sharedInstance().currentUser?.authentication?.accessToken
//        print(token!)
        // Do any additional setup after loading the view.
        
        ref = Database.database().reference()
        
        item.delegate = self
        item.tag = 0
        amount.delegate = self
        amount.tag = 1
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        self.view.addGestureRecognizer(tapGesture)
    }

    //Function to hide keyboards
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        // Try to find next responder
        if let nextField = textField.superview?.viewWithTag(textField.tag + 1) as? UITextField {
            nextField.becomeFirstResponder()
        } else {
            // Not found, so remove keyboard.
            textField.resignFirstResponder()
        }
        // Do not add a line break
        return false
    }
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        item.resignFirstResponder()
        amount.resignFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Sign User in, if not already done. Just in case the user somehow gets here without having signed in. This is also needed because this class implements GIDSignInDelegate
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!,
              withError error: Error!) {
        if let error = error {
            showAlert(title: "Authentication Error", message: error.localizedDescription)
            self.service.authorizer = nil
        } else {
            //let vc = self.storyboard?.instantiateViewController(withIdentifier: "LoggedIn") as! LoogedInViewController
            //self.present(vc, animated: true, completion: nil)
            //self.signInButton.isHidden = true
            
            self.service.authorizer = user.authentication.fetcherAuthorizer()
            // listMajors()
            
        }
    }
    
    func showAlert(title : String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: UIAlertControllerStyle.alert
        )
        let ok = UIAlertAction(
            title: "OK",
            style: UIAlertActionStyle.default,
            handler: nil
        )
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }

    
    
    //Sign the user out.
    @IBAction func signOut(_ sender: UIButton) {
        GIDSignIn.sharedInstance().signOut()
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "ViewC") as! ViewController
        self.present(vc, animated: true, completion: nil)
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
        
    }


    //If user clicks on the "pay" or "deposit" toggle button, this method will change the placeholder text accordingly.
    @IBAction func changes(_ sender: UISegmentedControl) {
        if (transactionType.selectedSegmentIndex == 0){
            print("hello?")
            item.placeholder = "What did you buy?"
            PAYORDEPOSIT = true
        }else if (transactionType.selectedSegmentIndex == 1){
            print("wo")
            item.placeholder = "What are you depositing?"
            PAYORDEPOSIT = false
        }
    }

    //When the record button is pressed, this function adds whatever is in "item" and "amount" to the spreadsheet
    @IBAction func record(_ sender: UIButton) {
        
        //Makes sure that item field isn't empty. If empty, will send an alert.
        if (item.text?.elementsEqual(""))!{
            let alert = UIAlertController(title: "Oops!", message: "Please enter an item.", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "ok", style: .cancel, handler: nil))
            
            self.present(alert, animated: true)
            return
        }
        
        print(sheetId)

        let token = (GIDSignIn.sharedInstance().currentUser?.authentication?.accessToken)!
        print(token)
        let myUrl = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/1GGKLfSLQBtxVQ3yxTYLLmJm5N8HXWFDt0gDyFVP_S34/values/Sheet1!A1:B2:append?valueInputOption=RAW&insertDataOption=INSERT_ROWS");
        
        var request = URLRequest(url:myUrl!)
        
        request.httpMethod = "POST"// Compose a query string
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        
        //Sets amount text to be uploaded
        var amt: String = ""
        if transactionType.selectedSegmentIndex == 0{
            print(amount.text!)
            amt = "-\(String(describing: amount.text!))"
        }else{
            amt = amount.text!
        }
        print(amt)
        
        //Sets date to be uploaded
        let date = Date()
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        
        let dot = "\(month)-\(day)-\(year)"
        
        
        let json : [String:Any] = ["values": [[item.text, String?(amt), String?(dot)]]]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        //Runs the HTTP request
        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            
            //Let's convert response sent from a server side script to a NSDictionary object:
            do {
                let jayson = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                if let parseJSON = jayson {
                    print(jayson)
                }
            } catch {
                print(error)
            }
        }
        task.resume()
        
        //Reset "item" and "amount" fields
        item.text = ""
        amount.text = "$0.00"
    }
    

    //Creates a new spreadsheet using HTTP Request
    @IBAction func create(_ sender: UIButton) {
        
//        self.ref.child("users").child((user.userID)!).child("spreadsheetID").observe(.value, with: {snapshot in
//            if snapshot.exists() {
//                print("id exists")
//                return }
//
//        })
        
        
        let token = (GIDSignIn.sharedInstance().currentUser?.authentication?.accessToken)!
        print(token)
        let myUrl = URL(string: "https://sheets.googleapis.com/v4/spreadsheets");
        
        var request = URLRequest(url:myUrl!)
        
        request.httpMethod = "POST"// Compose a query string
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let json : [String:Any] = ["properties": ["title": "square"]]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)

        
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        //Runs the HTTP request
        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            
            //Let's convert response sent from a server side script to a NSDictionary object:
            do {
                let jayson = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                if let parseJSON = jayson {
                    print(jayson)
                    self.sheetId = jayson?.object(forKey: "spreadsheetId") as! String
                }
            } catch {
                print(error)
            }
        }
        task.resume()

    }

}

