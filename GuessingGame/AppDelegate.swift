import UIKit
import Firebase
import FirebaseDatabase

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        testFirebaseConnection()
        return true
    }
    
    private func testFirebaseConnection() {
        let ref = Database.database().reference()
        let testData: [String: Any] = ["timestamp": ServerValue.timestamp(), "status": "connected"]
        
        // Write test data
        ref.child("testConnection").setValue(testData) { error, _ in
            if let error = error {
                print("❌ Firebase connection failed: \(error.localizedDescription)")
                return
            }
            
            // Read back the test data
            ref.child("testConnection").observeSingleEvent(of: .value) { snapshot in
                if snapshot.exists() {
                    print("✅ Firebase connection successful")
                } else {
                    print("❌ Firebase connection failed: Unable to read test data")
                }
            } withCancel: { error in
                print("❌ Firebase connection failed: \(error.localizedDescription)")
            }
        }
    }
}