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
    
    var sections = SectionController()
    
    var items = [Item]()
    var itemSize:CGSize

    init(screenWidth: CGFloat, itemSize: CGSize) {
        let layout = UICollectionViewFlowLayout.init()
        layout.minimumLineSpacing = 0
//        layout.headerReferenceSize = CGSize(width: screenWidth, height: 35)
        layout.itemSize = itemSize
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 0
        
        layout.sectionInset = UIEdgeInsets.zero
        self.itemSize = itemSize
        
        super.init(collectionViewLayout: layout)
        self.view.backgroundColor = .systemGroupedBackground
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
    
    var checkBackView:UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "headerView")
        self.collectionView.backgroundColor = .clear
        self.collectionView.alwaysBounceVertical = true
        self.collectionView.keyboardDismissMode = .interactive
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "error")
        let searchParent = UIView.init(frame: CGRect.init(origin: CGPoint.init(x: -15, y: -80), size: CGSize.init(width: self.view.frame.size.width, height: 80)))
        searchParent.backgroundColor = .clear
        let searchBar = UISearchBar.init(frame: CGRect.init(origin: CGPoint.init(x: 10, y: 15), size: CGSize.init(width: self.view.frame.size.width-20, height: 50)))
        searchBar.placeholder = "Supreme, Yeezy, Jordan, Shirt..."
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self
        searchParent.addSubview(searchBar)
        self.collectionView.addSubview(searchParent)
        self.collectionView.contentInset = UIEdgeInsets.init(top: self.collectionView.contentInset.top+80, left: 15, bottom: self.collectionView.contentInset.bottom, right: 15)
        self.getLatest {
        }
    }
    
//    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
//        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "headerView", for: indexPath)
//        let title = UILabel.init(frame: CGRect.init(x: 15, y: 0, width: self.view.frame.size.width-30, height: 35))
//        title.text = self.sections.titleForSectionAtIndex(indexPath.section)?.uppercased()
//        title.font = subtitleFont
//        title.textAlignment = .center
//        headerView.addSubview(title)
//        headerView.frame.size.height = 35
//
//        return headerView
//    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return self.sections.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.sections.rowsInSectionAtIndex(section)
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let identifier = self.sections.identiferForSectionAtIndex(indexPath.section)
        var item:Item
        if identifier == .Browse {
            item = self.items[indexPath.item]
        } else {
            item = self.searchResults[indexPath.item]
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: item.id!, for: indexPath)
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
        var itemViewController:ItemViewController
        let identifier = self.sections.identiferForSectionAtIndex(indexPath.section)
        if identifier == .Browse {
            itemViewController = ItemViewController.init(item: &self.items[indexPath.item])
        } else {
            itemViewController = ItemViewController.init(item: &self.searchResults[indexPath.item])
        }
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
            for (_, change) in snapshot.documentChanges.enumerated() {
                if change.type == .added {
                    let item = Item.init(change.document.documentID)
                    item.attachData(change.document.data())
                    self.items.append(item)
                    self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: change.document.documentID)
                }
            }
            self.collectionView.performBatchUpdates({
                let (insert, index) = self.sections.updateSection(title: .Browse, rows: self.items.count)
                if insert {
                    self.collectionView.insertSections(IndexSet.init(integer: index))
                } else {
                    self.collectionView.reloadSections(IndexSet.init(integer: index))
                }
//                self.collectionView.insertItems(at: [IndexPath.init(item: self.items.count-2, section: index)])
            }) { (done) in
                complete()
            }
        }
    }

    var searchResults = [Item]()
    
    func searchFirestore(_ terms: [String]) {
        Firestore.firestore().collection("items").whereField("tags", arrayContainsAny: terms).getDocuments { (snapshot, error) in
            guard let results = snapshot?.documents else {
                return
            }
            if results.isEmpty {
                print("no no results")
                if let section = self.sections.removeSection(title: .ForYouResults) {
                    print("remove at section 0")
                    self.collectionView.performBatchUpdates({
                    self.collectionView.deleteSections(IndexSet.init(integer: section))
                }) { (done) in
                        
                    }
                }
                return
            }
            self.searchResults = results.map({ (qds) -> Item in
                self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: qds.documentID)
                return Item.init(fromQuery: qds.data(), qds.documentID)
            })
            let count = self.searchResults.count
            let (insert, _) = self.sections.updateSection(title: .ForYouResults, rows: count)
            self.sections.setHeaderTextForSection(.ForYouResults, "\(count == 0 ? "No" : "\(count)") item\(count == 1 ? "" : "s") found")
            self.sections.moveSectionToFirst(.ForYouResults)
            self.collectionView.performBatchUpdates({
                if insert {
                    self.collectionView.insertSections(IndexSet.init(integer: 0))
                } else {
                    self.collectionView.reloadSections(IndexSet.init(integer: 0))
                }
            }) { (done) in
            }
            
        }
    }
}

extension BrowseViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let text = searchBar.text?.lowercased() {
            let trimmed = text.trimmingCharacters(in: CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789").inverted)
            var filtered = trimmed.components(separatedBy: " ")
            if filtered.contains("shoe") {
                filtered.append("shoes")
            }
            searchFirestore(filtered)
        }
        searchBar.resignFirstResponder()
    }
    

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            if let section = self.sections.removeSection(title: .ForYouResults) {
                self.collectionView.performBatchUpdates({
                self.collectionView.deleteSections(IndexSet.init(integer: section))
            }) { (done) in
                    searchBar.resignFirstResponder()
                }
            }
        }
    }
}
