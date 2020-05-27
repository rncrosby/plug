import UIKit
import Firebase

@objc protocol ItemDelegate: class {
    @objc optional func openImagePicker()
    @objc optional func errorUploadingImage(index: Int, message: String)
    @objc optional func imageDoneUploading()
}
class Item: NSObject {
    
    static func == (lhs: Item, rhs: Item) -> Bool {
        return lhs.id == rhs.id
    }
    
    weak var delegate:ItemDelegate?
    
    public enum Kind:String, CaseIterable {
        case Shoes      = "shoes"
        case Shirt      = "shirt"
        case Outerwear  = "outerwear"
        case Pants      = "pants"
        case Accessory  = "accessory"
    }
    
    var imageURLS:[String:String]?
    var images:[UIImage]?
    
    var name:String?
    var size:String?
    var cost:Int?
    var kind:Kind = .Shoes
    var instant:Bool = false // instant sell option (first offer is accepted)
    
    
    // browse details
    var tags:[String]?
    var seller:String?
    var id:String?
    var views:Int?
    var showInFavorites:Bool?
    var offerReference:DocumentReference?
    
    override init() {
        
    }
    
    init(fromFavorites id: String, show: Bool?) {
        self.id = id
        self.showInFavorites = show
    }
    
    init(_ id: String) {
        self.id = id
    }
    
    init(fromQuery: [String:Any], _ id: String) {
        self.id = id
        if  let name = fromQuery["name"] as? String,
            let size = fromQuery["size"] as? String,
            let cost = fromQuery["cost"] as? Int,
            let kind = fromQuery["kind"] as? String,
            let instant = fromQuery["instant"] as? Bool,
            let tags = fromQuery["tags"] as? [String],
            let images = fromQuery["images"] as? [String],
            let seller = fromQuery["seller"] as? String {
            self.name = name
            self.size = size
            self.cost = cost
            self.kind = Kind.init(rawValue: kind) ?? Kind.Accessory
            self.instant = instant
            self.tags = tags
            self.imageURLS = [String:String]()
            for (index,url) in images.enumerated() {
                self.imageURLS!["\(index)"] = url
            }
            self.seller = seller
        }
        if let views = fromQuery["views"] as? Int {
            self.views = views
        }
    }
    
    func attachData(_ data: [String:Any]) {
        if  let name = data["name"] as? String,
            let size = data["size"] as? String,
            let cost = data["cost"] as? Int,
            let kind = data["kind"] as? String,
            let instant = data["instant"] as? Bool,
            let tags = data["tags"] as? [String],
            let images = data["images"] as? [String],
            let seller = data["seller"] as? String {
            print("attaching data!")
            self.name = name
            self.size = size
            self.cost = cost
            self.kind = Kind.init(rawValue: kind) ?? Kind.Accessory
            self.instant = instant
            self.tags = tags
            self.imageURLS = [String:String]()
            for (index,url) in images.enumerated() {
                self.imageURLS!["\(index)"] = url
            }
            self.seller = seller
        }
        if let views = data["views"] as? Int {
            self.views = views
        }
    }

    func readyToPost() -> String? {
        if name == nil {
            return "Name missing"
        }
        if size == nil {
            return "Size missing"
        }
        if cost == nil {
            return "Cost Missing"
        }
        if images == nil {
            return "Images missing"
        }
        if Auth.auth().currentUser == nil {
            return "Need to have an account"
        }
        return nil
    }

    func createFirestore(_ documentID: String) -> [String:Any]? {
        if  let name = self.name,
            let size = self.size,
            let cost = self.cost,
            let imageURLS = self.imageURLS,
            let uid = Auth.auth().currentUser?.uid
        {
            var tags = [String]()
            tags.append(documentID)
            tags.append(name)
            for word in name.components(separatedBy: " ") {
                tags.append(word)
            }
            tags.append(size)
            for word in size.components(separatedBy: " ") {
                tags.append(word)
            }
            tags.append(self.kind.rawValue)
            var imageUrlArray = [String]()
            for i in 0..<imageURLS.keys.count {
                if let url = imageURLS["\(i)"] {
                    imageUrlArray.append(url)
                }
            }
            return [
                "name"      : name,
                "size"      : size,
                "cost"      : cost,
                "kind"      : self.kind.rawValue,
                "instant"   : instant,
                "tags"      : tags,
                "images"    : imageUrlArray,
                "seller"    : uid,
                "posted"    : FieldValue.serverTimestamp()
            ]
        }
        return nil
    }
    
    func attachImage(_ image: UIImage) {
        if self.images == nil {
            self.images = [UIImage]()
        }
        self.images!.append(image)
    }
    
    func uploadImages() {
        if (self.images != nil) && (Auth.auth().currentUser != nil) {
            self.imageURLS = [String:String]()
            for (index,image) in self.images!.enumerated() {
                let data = image.jpegData(compressionQuality: 0.9)!
                let filePath = "\(Auth.auth().currentUser!.uid)/\(randomString(length: 16)).jpeg"
                let reference = Storage.storage().reference().child(filePath)
                let metadata = StorageMetadata()
                metadata.contentType = "image/jpeg"


                reference.putData(data, metadata: nil) { (metadata, error) in
                    if let error = error {
                        self.delegate?.errorUploadingImage?(index: index, message: error.localizedDescription)
                        return
                    }
                    reference.downloadURL { (url, error) in
                        if let error = error {
                            self.delegate?.errorUploadingImage?(index: index, message: error.localizedDescription)
                            return
                        }
                        if let url = url?.absoluteString {
                            self.imageURLS!["\(index)"] = url
                            self.delegate?.imageDoneUploading?()
                        }
                    }
                    
                    
                }
            }
        } else {
            self.delegate?.errorUploadingImage?(index: -1, message: "no images to upload")
        }
    }
    
    func makePost(_ complete: @escaping (Bool, String?) -> Void) {
        let reference = Firestore.firestore().collection("items").document()
        if let data = self.createFirestore(reference.documentID) {
            reference.setData(data) { (error) in
                if let error = error {
                    complete(false, error.localizedDescription)
                    return
                }
                complete(true, nil)
                return
            }
        }
    }
    
    func incrementMetric(_ metric: String) {
        if let id = self.id {
            Firestore.firestore().collection("items").document(id).updateData([
                metric : FieldValue.increment(Int64(1))
            ])
        }
        
    }
    
    // MARK: FAVORITES AND TAGS
    
    var favorite:Bool?
    
    func checkIfFavoritedItem(_ completion: @escaping (Bool) -> Void) {
        if let favorite = self.favorite {
            completion(favorite)
            return
        }
        if  let itemID = self.id,
            let itemName = self.name {
            if UserDefaults.contains(itemID) || UserDefaults.contains(itemName) {
                self.favorite = true
                completion(true)
                return
            } else {
                if let uid = Auth.auth().currentUser?.uid {
                    Firestore.firestore().collection("users").document(uid).collection("favorites").whereField("item", arrayContainsAny: [itemID,itemName]).getDocuments { (result, error) in
                        if let error = error {
                            completion(false)
                            print(error.localizedDescription)
                            return
                        }
                        if let _ = result?.documents.first {
                            UserDefaults.standard.set(true, forKey: itemID)
                            UserDefaults.standard.set(true, forKey: itemName)
                            self.favorite = true
                            completion(true)
                            return
                        }
                    }
                }
            }
        }
        completion(false)
    }
    
    func favoriteItem() {
        if  let itemID = self.id,
            let itemName = self.name {
            UserDefaults.standard.set(true, forKey: itemID)
            UserDefaults.standard.set(true, forKey: itemName)
            self.favorite = true
            if let uid = Auth.auth().currentUser?.uid {
                Firestore.firestore().collection("users").document(uid).collection("favorites").document().setData([
                    "item" : [itemID, itemName]
                ]) { (error) in
                    if let error = error {
                        print(error.localizedDescription)
                        return
                    }
                    return
                }
            }
        }
    }
    
    func unfavoriteItem() {
        if  let itemID = self.id,
            let itemName = self.name {
            UserDefaults.standard.removeObject(forKey: itemID)
            UserDefaults.standard.removeObject(forKey: itemName)
            self.favorite = false
            if let uid = Auth.auth().currentUser?.uid {
                Firestore.firestore().collection("users").document(uid).collection("favorites").whereField("item", arrayContainsAny: [itemID,itemName]).getDocuments { (result, error) in
                    if let error = error {
                        print(error.localizedDescription)
                        return
                    }
                    if let first = result?.documents.first {
                        first.reference.delete { (error) in
                            if let error = error {
                                print(error.localizedDescription)
                                return
                            }
                        }
                        return
                    }
                }
            }
        }
        
    }
    
    var tagReference:DocumentReference?
    var notification:Bool?
    
    func checkIfNotifications(_ completion: @escaping (Bool) -> Void) {
        if let notification = self.notification {
            completion(notification)
            return
        }
        if  let itemID = self.id,
            let itemName = self.name,
            let uid = Auth.auth().currentUser?.uid {
            if UserDefaults.contains("\(itemID)_notification") || UserDefaults.contains("\(itemName)_notification") {
                self.notification = true
                completion(true)
                return
            } else {
                getTagReference { (reference) in
                    reference.collection("users").document(uid).getDocument(completion: { (document, error) in
                        if let error = error {
                            print(error.localizedDescription)
                            completion(false)
                            return
                        }
                        if document?.exists ?? false {
                            self.notification = true
                            UserDefaults.standard.set(true, forKey: "\(itemID)_notification")
                            UserDefaults.standard.set(true, forKey: "\(itemName)_notification")
                            completion(true)
                            return
                        }
                    })
                }
            }
        }
        completion(false)
    }
    
    func enableNotifications() {
        if  let itemID = self.id,
            let itemName = self.name,
            let uid = Auth.auth().currentUser?.uid {
            UserDefaults.standard.set(true, forKey: "\(itemID)_notification")
            UserDefaults.standard.set(true, forKey: "\(itemName)_notification")
            self.notification = true
            getTagReference { (reference) in
                print(reference.path)
                reference.collection("users").document(uid).setData(["updated": FieldValue.serverTimestamp()], merge: true) { (error) in
                    if let error = error {
                        print(error)
                        return
                    }
                }
            }
        }
    }
    
    func disableNotifications() {
        if  let itemID = self.id,
            let itemName = self.name,
            let uid = Auth.auth().currentUser?.uid {
            UserDefaults.standard.removeObject(forKey: "\(itemID)_notification")
            UserDefaults.standard.removeObject(forKey: "\(itemName)_notification")
            self.notification = false
            getTagReference { (reference) in
                reference.collection("users").document(uid).delete()
            }
        }
    }
    
    func getTagReference(_ completion: @escaping (DocumentReference) -> Void) {
        if let reference = self.tagReference {
            completion(reference)
            return
        } else {
            if  let itemID = self.id,
                let itemName = self.name {
                Firestore.firestore().collection("tags").whereField("item", arrayContainsAny: [itemID,itemName]).getDocuments { (result, error) in
                    if let tag = result?.documents.first {
                        self.tagReference = tag.reference
                        completion(self.tagReference!)
                        return
                    }
                    let referenece = Firestore.firestore().collection("tags").document()
                    referenece.setData([
                    "item" : [itemID, itemName]
                    ]) { (error) in
                        if let error = error {
                            print(error.localizedDescription)
                            return
                        }
                        self.tagReference = referenece
                        completion(self.tagReference!)
                        return
                    }
                    
                }
            }
            
        }
    }
    
    // MARK: OFFER
    
    func checkForOffer(_ completion: @escaping (Bool) -> Void) {
        if  let uid = Auth.auth().currentUser?.uid,
            let itemID = self.id {
            Firestore.firestore().collection("offers").whereField("customer", isEqualTo: uid).whereField("item", isEqualTo: itemID).getDocuments { (snapshot, error) in
                if let error = error {
                    print(error.localizedDescription)
                    completion(false)
                    return
                }
                if let result = snapshot?.documents.first {
                    self.offerReference = result.reference
                    completion(true)
                    return
                }
            }
        }
        completion(false)
        return
    }
    
    var itemSize:CGSize?
    private var imageCollectionView:UICollectionView?
}

extension Item: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return self.itemSize!
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func getPostImageCollection(frame: CGRect) -> UICollectionView {
        if imageCollectionView == nil {
            let layout = UICollectionViewFlowLayout.init()
            let square = (frame.size.width-30)/3
            self.itemSize = CGSize.init(width: square, height: square)
            layout.itemSize = self.itemSize!
            layout.scrollDirection = .vertical
            layout.minimumLineSpacing = 15
            
//            layout.minimumInteritemSpacing = 5
            imageCollectionView = UICollectionView.init(frame: frame, collectionViewLayout: layout)
            imageCollectionView?.delegate = self
            imageCollectionView?.dataSource = self
            imageCollectionView?.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
            imageCollectionView?.backgroundColor = .clear
            imageCollectionView?.contentInset = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
            imageCollectionView?.dragDelegate = self
            imageCollectionView?.dropDelegate = self
            imageCollectionView?.dragInteractionEnabled = true
        }
        imageCollectionView?.reloadData()
        return imageCollectionView!
    }
    
    func getImageCollectionContentHeight() -> CGFloat {
        if let height = self.imageCollectionView?.collectionViewLayout.collectionViewContentSize.height {
            self.imageCollectionView?.frame.size.height = height
            return height + 30
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if collectionView.hasActiveDrag {
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }
        return UICollectionViewDropProposal(operation: .forbidden)
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        if  let sourceIndex = coordinator.items.first?.sourceIndexPath,
            let image = coordinator.items.first?.dragItem.localObject as? UIImage,
            let destinationIndex = coordinator.destinationIndexPath {
            
            collectionView.performBatchUpdates({
                self.images!.remove(at: sourceIndex.item)
                self.images?.insert(image, at: destinationIndex.item)
                collectionView.deleteItems(at: [sourceIndex])
                collectionView.insertItems(at: [destinationIndex])
            }, completion: nil)
        }
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let image = self.images![indexPath.item]
        let provider = NSItemProvider.init(object: image)
        let dragItem = UIDragItem.init(itemProvider: provider)
        dragItem.localObject = image
        return [dragItem]
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let count = self.images?.count {
            return count + 1
        }
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        let count = self.images?.count ?? 0
        if indexPath.item < count {
            let view = UIImageView.init(frame: CGRect.init(origin: .zero, size: self.itemSize!))
            if let image = self.images?[indexPath.item] {
                view.image = image
            }
            cell.addSubview(view)
        } else {
            cell.backgroundColor = .systemGray5
        }
        cell.layer.cornerRadius = 10
        cell.layer.masksToBounds = true
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let count = self.images?.count ?? 0
        if indexPath.item < count {
            
        } else {
            self.delegate?.openImagePicker?()
        }
            
    }
}

extension String {
    
    
}

func randomString(length: Int) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0..<length).map{ _ in letters.randomElement()! })
}

