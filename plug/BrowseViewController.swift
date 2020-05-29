//
//  BrowseViewController.swift
//  plug
//
//  Created by Robert Crosby on 5/25/20.
//  Copyright © 2020 Robert Crosby. All rights reserved.
//

import UIKit
import Firebase

private let reuseIdentifier = "Cell"

@objc protocol BrowseDelegate: class {
    @objc optional func itemFavoriteToggled(_ status: Bool)
}

extension BrowseViewController: BrowseDelegate {
    @objc func itemFavoriteToggled(_ status: Bool) {
        self.selectedItemHeart?.image = status ? UIImage.init(systemName: "heart.fill")?.withRenderingMode(.alwaysTemplate) : nil
    }
}

class BrowseViewController: UICollectionViewController {
    
    var items = [Item]()
    var itemSize:CGSize

    init(itemSize: CGSize) {
        let layout = UICollectionViewFlowLayout.init()
        layout.minimumLineSpacing = 0
        layout.itemSize = itemSize
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets.zero
        self.itemSize = itemSize
        
        super.init(collectionViewLayout: layout)
        self.view.backgroundColor = .secondarySystemGroupedBackground
        self.title = "Latest"
        self.tabBarItem = UITabBarItem.init(title: nil, image: UIImage.init(systemName: "square.grid.2x2"), selectedImage: UIImage.init(systemName: "square.grid.2x2.fill"))
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        if self.selectedItemIndex != nil {
//            self.collectionView.reloadItems(at: [self.selectedItemIndex!])
//            self.selectedItemIndex = nil
//        }
//    }
//
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView.backgroundColor = .clear
        self.collectionView.alwaysBounceVertical = true

        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        self.collectionView.contentInset = UIEdgeInsets.init(top: self.collectionView.contentInset.top+15, left: 15, bottom: self.collectionView.contentInset.bottom, right: 15)
        self.getLatest {
        }
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.items.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell:UICollectionViewCell
        
        cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        let item = self.items[indexPath.item]
        if cell.tag == 0 {
            cell.tag = 1
            let view = UIImageView.init(frame: CGRect.init(origin: CGPoint.zero, size: CGSize.init(width: self.itemSize.width, height: self.itemSize.height-60)))
            view.layer.cornerRadius = 5
            view.layer.masksToBounds = true
            view.backgroundColor = UIColor.systemGroupedBackground
            cell.addSubview(view)
            let label = UILabel.init(frame: CGRect.init(origin: CGPoint.init(x: 0, y: view.frame.maxY+10), size: CGSize.init(width: self.itemSize.width-25, height: 40)))
            label.font = buttonFont.withSize(14)
            label.numberOfLines = 2
            cell.addSubview(label)
            if let url = item.imageURLS?["0"] {
                downloadImage(url: URL.init(string: url)!) { (image, error) in
                    if let error = error {
                        print(error)
                    }
                    if let image = image {
                        DispatchQueue.main.async {
                        view.image = image
                        }
                    }
                }
            }
            if  let title = item.name {
                label.text = "\(title.uppercased())"
                label.sizeToFit()
            }
            let heart = UIImageView.init(frame: CGRect.init(x: self.itemSize.width-20, y: view.frame.maxY+10, width: 20, height: 15))
            heart.tag = -5
            heart.tintColor = .systemRed
            cell.addSubview(heart)
            item.checkIfFavoritedItem { (isFavorite) in
                if isFavorite {
                    heart.image = UIImage.init(systemName: "heart.fill")?.withRenderingMode(.alwaysTemplate)
                }
            }
        }
        
        return cell
    }

    var selectedItemHeart:UIImageView?
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        self.selectedItemHeart = cell?.subviews.first(where: { (v) -> Bool in
            return v.tag == -5
        }) as? UIImageView
        let itemViewController = ItemViewController.init(item: &self.items[indexPath.item])
        itemViewController.browseDelegate = self
        itemViewController.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(itemViewController, animated: true)
        
    }

    func getLatest(_ complete: @escaping () -> Void) {
        Firestore.firestore().collection("items").whereField("sold", isEqualTo: false).addSnapshotListener { (snapshot, error) in
            guard let snapshot = snapshot else {
                print("\(error!.localizedDescription)")
                complete()
                return
            }
            self.collectionView.performBatchUpdates({
                for (_, change) in snapshot.documentChanges.enumerated() {
                    if change.type == .added {
                        let item = Item.init(change.document.documentID)
                        item.attachData(change.document.data())
                        self.items.append(item)
                        self.collectionView.insertItems(at: [IndexPath.init(item: self.items.count-1, section: 0)])
                    }
//                    else if change.type == .removed {
//                        if let index =
//                        self.items.remove(at: index)
//                        self.collectionView.insertItems(at: [IndexPath.init(item: self.items.count, section: 0)])
//                    }
                }
            }) { (done) in
                complete()
            }
        }
    }

}
