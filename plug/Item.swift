import UIKit

class Item: NSObject {
    
    public enum Kind:String, CaseIterable {
        case Shoes       = "shoes"
        case Shirt      = "shirt"
        case Sweatshirt = "sweatshirt"
        case Jacket     = "jacket"
        case Accessory  = "accessory"
    }
    
    var images:[UIImage]?
    
    var brand:String?
    var name:String?
    var size:String?
    var cost:Int?
    var kind:Kind = .Shoes
    var instant:Bool = false // instant sell option (first offer is accepted)


    var firestore: [String:Any]? {
        if  let brand = self.brand,
            let name = self.name,
            let size = self.size,
            let cost = self.cost
        {
            var tags = [String]()
            tags.append(brand)
            for word in brand.components(separatedBy: " ") {
                tags.append(word)
            }
            tags.append(name)
            for word in name.components(separatedBy: " ") {
                tags.append(word)
            }
            tags.append(size)
            for word in size.components(separatedBy: " ") {
                tags.append(size)
            }
            tags.append(self.kind.rawValue)
            return [
                "brand"     : brand,
                "name"      : name,
                "size"      : size,
                "cost"      : cost,
                "kind"      : self.kind.rawValue,
                "instant"   : instant,
                "tags"      : tags
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
    
    private var imageCollectionView:UICollectionView?
    func getImageCollection(frame: CGRect) -> UICollectionView {
        if imageCollectionView == nil {
            let layout = UICollectionViewFlowLayout.init()
            layout.itemSize = CGSize.init(width: 100, height: 100)
            layout.scrollDirection = .horizontal
            layout.minimumLineSpacing = 15
            layout.minimumInteritemSpacing = 15
            imageCollectionView = UICollectionView.init(frame: frame, collectionViewLayout: layout)
            imageCollectionView?.delegate = self
            imageCollectionView?.dataSource = self
            imageCollectionView?.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
            imageCollectionView?.backgroundColor = .clear
            imageCollectionView?.contentInset = UIEdgeInsets.init(top: 0, left: 15, bottom: 0, right: 30)
            imageCollectionView?.dragDelegate = self
            imageCollectionView?.dropDelegate = self
            imageCollectionView?.dragInteractionEnabled = true
            
        }
        imageCollectionView?.reloadData()
        return imageCollectionView!
    }
    
}

extension Item: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    
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
        return self.images?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)

        let view = UIImageView.init(frame: CGRect.init(origin: .zero, size: CGSize.init(width: 100, height: 100)))
        if let image = self.images?[indexPath.item] {
            view.image = image
        }
        cell.addSubview(view)
        return cell
    }
    
}

extension String {
    func capitalizingFirstLetter() -> String {
      return prefix(1).uppercased() + self.lowercased().dropFirst()
    }

    mutating func capitalizeFirstLetter() {
      self = self.capitalizingFirstLetter()
    }
}

