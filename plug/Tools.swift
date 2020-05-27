
import UIKit
import Firebase

extension String  {
    var isNumber: Bool {
        return !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
    func capitalizingFirstLetter() -> String {
      return prefix(1).uppercased() + self.lowercased().dropFirst()
    }

    mutating func capitalizeFirstLetter() {
      self = self.capitalizingFirstLetter()
    }
    
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)

        return ceil(boundingBox.height)
    }

    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)

        return ceil(boundingBox.width)
    }
}

extension Float {
    var clean: String {
       return self.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
    }
}

struct Profile {
    let username:String
    
    init(_ uid: String, _ data: [String:Any]) {
        if let username = data["username"] as? String {
            self.username = username
        } else {
            self.username = "error"
        }
    }
}

func getProfileForUID(_ uid: String, complete: @escaping (Profile?) -> Void) {
    Firestore.firestore().collection("users").document(uid).getDocument { (snapshot, error) in
        if let error = error {
            print(error.localizedDescription)
            return
        }
        if let data = snapshot?.data() {
            complete(Profile.init(uid, data))
            return
        }
    }
}

extension UserDefaults {
    static func contains(_ key: String) -> Bool {
        return UserDefaults.standard.object(forKey: key) != nil
    }
}

let imageCache = NSCache<NSString, UIImage>()

func downloadImage(url: URL, completion: @escaping (_ image: UIImage?, _ error: String? ) -> Void) {
    if let cachedImage = imageCache.object(forKey: url.absoluteString as NSString) {
        completion(cachedImage, nil)
    } else {
        downloadData(url: url) { data, response, error in
            if let error = error {
                completion(nil, error.localizedDescription)
                
            } else if let data = data, let image = UIImage(data: data) {
                imageCache.setObject(image, forKey: url.absoluteString as NSString)
                completion(image, nil)
            } else {
                completion(nil, "unknown error")
            }
        }
    }
}

func downloadData(url: URL, completion: @escaping (_ data: Data?, _  response: URLResponse?, _ error: Error?) -> Void) {
    URLSession(configuration: .ephemeral).dataTask(with: URLRequest(url: url)) { data, response, error in
        completion(data, response, error)
        }.resume()
}

func justFetchItemName(_ itemID: String, _ completion: @escaping (String) -> Void) {
    if let name = UserDefaults.standard.string(forKey: "\(itemID)_name") {
        completion(name)
        return
    }
    Firestore.firestore().collection("items").document(itemID).getDocument { (snapshot, error) in
        if let error = error {
            print(error.localizedDescription)
            completion("Unknown Item")
            return
        }
        if let data = snapshot?.data() {
            if let name = data["name"] as? String {
                UserDefaults.standard.set(name, forKey: "\(itemID)_name")
                completion(name)
                return
            }
        }
        completion("Unkown Item")
        return
    }
}
