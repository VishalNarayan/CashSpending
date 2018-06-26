import GoogleAPIClientForREST
import GoogleSignIn
import UIKit
import Firebase
import FirebaseAuth

class ViewController: UIViewController, GIDSignInDelegate, GIDSignInUIDelegate {
    
    
    
    // If modifying these scopes, delete your previously saved credentials by
    // resetting the iOS simulator or uninstall the app.
    private let scopes = [kGTLRAuthScopeSheetsDrive, kGTLRAuthScopeSheetsSpreadsheets]
    
    private let service = GTLRSheetsService()
    
    private var ref: DatabaseReference!

    let signInButton = GIDSignInButton()
    //let output = UITextView()
    

    
    @IBOutlet weak var output: UITextView!
    @IBOutlet var firstView: UIView!
    
    
    @IBAction func google(_ sender: UIButton) {
        //GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().scopes = scopes
        GIDSignIn.sharedInstance().signIn()
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        //FirebaseApp.configure()
       // var ref: DatabaseReference! = Database.database().reference()
        output.isHidden = true
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        //var ref: DatabaseReference!
        
        ref = Database.database().reference()
        
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "LoggedIn") as! LoogedInViewController
        self.present(vc, animated: true, completion: nil)
//        // Configure Google Sign-in.
//        //GIDSignIn.sharedInstance().delegate = self
//        GIDSignIn.sharedInstance().uiDelegate = self
//        GIDSignIn.sharedInstance().scopes = scopes
//        GIDSignIn.sharedInstance().signIn()
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!,
              withError error: Error!) {
        if let error = error {
            //showAlert(title: "Authentication Error", message: error.localizedDescription)
            self.service.authorizer = nil
        } else {
            guard let authentication = user.authentication else { return }
            let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                           accessToken: authentication.accessToken)
            Auth.auth().signIn(with: credential) { (user, error) in
                if let error = error {
                    
                    return
                }
                // User is signed in
                print("user got signed in Firebase")
                
                print(signIn)
                print(user?.displayName)
                self.ref.child("users").child((user?.uid)!).setValue(["username": user?.displayName])
                
                print("Here is the code: ")
                //print(user.serverAuthCode)
                print("there was the code")
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "LoggedIn") as! LoogedInViewController
                self.present(vc, animated: true, completion: nil)
                self.signInButton.isHidden = true
                
                
            }
            self.service.authorizer = user.authentication.fetcherAuthorizer()
           // listMajors()
        }
    }
    
    // Helper for showing an alert
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
    
    
    /**
     So the below method was actually provided by QuickStart, but I chose not to use it because it's a read-only method. I'm leaving it here for future reference, in case I need to
     do some read calls. 
 **/
    // Display (in the UITextView) the names and majors of students in a sample
    // spreadsheet:
    // https://docs.google.com/spreadsheets/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms/edit
    func listMajors() {
        output.text = "Getting sheet data..."
        let spreadsheetId = "1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms"
        let range = "Class Data!A2:E"
        let query = GTLRSheetsQuery_SpreadsheetsValuesGet.query(withSpreadsheetId: spreadsheetId, range:range)
        service.executeQuery(query,
                             delegate: self,
                             didFinish: #selector(displayResultWithTicket(ticket:finishedWithObject:error:))
        )
    }
    // Process the response and display output
    @objc func displayResultWithTicket(ticket: GTLRServiceTicket,
                                 finishedWithObject result : GTLRSheets_ValueRange,
                                 error : NSError?) {
        if let error = error {
            showAlert(title: "Error", message: error.localizedDescription)
            return
        }
        var majorsString = ""
        let rows = result.values!
        if rows.isEmpty {
            output.text = "No data found."
            return
        }
        majorsString += "Name, Major:\n"
        for row in rows {
            let name = row[0]
            let major = row[4]
            
            majorsString += "\(name), \(major)\n"
        }
        output.text = majorsString
    }
}
