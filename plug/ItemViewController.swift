//
//  ItemViewController.swift
//  plug
//
//  Created by Robert Crosby on 5/25/20.
//  Copyright © 2020 Robert Crosby. All rights reserved.
//

import UIKit

class ItemViewController: UITableViewController {
    
    weak var browseDelegate:BrowseDelegate?
    var item:Item
    let sections = SectionController()
    var itemSize:CGSize?
    
    var favoriteButton:UIBarButtonItem?
    var notificationButton:UIBarButtonItem?
    
    var imageCollection:UICollectionView?

    init( item: inout Item) {
        self.item = item
        super.init(style: .grouped)
        self.favoriteButton = UIBarButtonItem.init(image: UIImage.init(systemName: "heart.fill"), style: .plain, target: self, action: #selector(toggleFavorite))
        self.favoriteButton?.tintColor = .systemGray3
        self.notificationButton = UIBarButtonItem.init(image: UIImage.init(systemName: "bell.fill"), style: .plain, target: self, action: #selector(toggleNotification))
        self.notificationButton?.tintColor = .systemGray3
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        let layout = UICollectionViewFlowLayout.init()
        layout.minimumLineSpacing = 0
        self.itemSize = CGSize.init(width: self.view.frame.size.width-30, height: self.view.frame.size.width-30)
        layout.itemSize = self.itemSize!
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 15
        layout.sectionInset = UIEdgeInsets.init(top: 0, left: 15, bottom: 0, right: 0)
        imageCollection = UICollectionView.init(frame: CGRect.init(origin: .zero, size: CGSize.init(width: self.view.frame.size.width, height: self.view.frame.size.width)), collectionViewLayout: layout)
        imageCollection?.contentInset = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 15)
        imageCollection?.delegate = self
        imageCollection?.dataSource = self
        imageCollection?.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        imageCollection?.backgroundColor = .clear
        imageCollection?.isUserInteractionEnabled = true
        imageCollection?.showsHorizontalScrollIndicator = false
        self.tableView.separatorStyle = .none
        self.tableView.backgroundColor = .secondarySystemGroupedBackground
        
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItems = [self.favoriteButton!,self.notificationButton!]
        self.sections.updateSection(title: .ItemDetails, rows: 2)
        self.sections.updateSection(title: .ItemPricing, rows: 1)
        self.item.checkIfFavoritedItem { (isLiked) in
            if isLiked {
                self.favoriteButton?.tintColor = .systemRed
            }
        }
        self.item.checkIfNotifications { (isOn) in
            if isOn {
                self.notificationButton?.tintColor = .systemRed
            }
        }
        self.item.incrementMetric("views")
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return self.sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.sections.rowsInSectionAtIndex(section)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let identifier = self.sections.identiferForSectionAtIndex(indexPath.section)
        if identifier == .ItemDetails && indexPath.row == 0 {
            return self.view.frame.size.width
        }
        if identifier == .ItemPricing {
            return 50
        }
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let identifier = self.sections.identiferForSectionAtIndex(section)
        switch identifier {
        case .Actions:
            return "Favorited items will be pinned to your feed. You will recieve notifications when this item sells or is trending, as well as when future sales of this item are posted."
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch self.sections.identiferForSectionAtIndex(indexPath.section) {
        case .ItemDetails:
            let cell = UITableViewCell.init(style: .subtitle, reuseIdentifier: nil)
            cell.backgroundColor = .clear
            if indexPath.row == 0 {
                self.imageCollection?.reloadData()
                cell.addSubview(self.imageCollection!)
                cell.selectionStyle = .none
            } else {
                cell.textLabel?.text = "$\(self.item.cost!)\n\(self.item.name!)"
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.font = titleFont
                cell.detailTextLabel?.text = self.item.size!
                cell.detailTextLabel?.font = buttonFont
                cell.selectionStyle = .none
            }
            return cell
        case .ItemPricing:
            let cell = UITableViewCell.init(style: .default, reuseIdentifier: nil)
            cell.backgroundColor = .clear
            let action = UIButton.init(frame: CGRect.init(origin: CGPoint.init(x: 15, y: 0), size: CGSize.init(width:self.view.frame.size.width-30, height: 50)))
            action.addTarget(self, action: #selector(beginMakeOffer(sender:)), for: .touchDown)
            action.addTarget(self, action: #selector(makeOffer(sender:)), for: .touchUpInside)
            action.titleLabel?.numberOfLines = 0
            action.setTitle("MAKE OFFER", for: .normal)
            action.titleLabel?.font = buttonFont
            action.setTitleColor(.systemRed, for: .normal)
            action.backgroundColor = .white
            action.layer.cornerRadius = 5
            action.layer.masksToBounds = true
//            let shadowLayer = CAShapeLayer()
//            shadowLayer.path = UIBezierPath(roundedRect: action.bounds, cornerRadius: 5).cgPath
//            shadowLayer.fillColor = UIColor.white.cgColor
//            shadowLayer.shadowColor = UIColor.black.cgColor
//            shadowLayer.shadowPath = shadowLayer.path
//            shadowLayer.shadowOffset = CGSize(width: 0.0, height: 1.0)
//            shadowLayer.shadowOpacity = 0.1
//            shadowLayer.shadowRadius = 3
//            action.layer.insertSublayer(shadowLayer, at: 0)
            cell.addSubview(action)
            self.item.checkForOffer { (offerFound) in
                if offerFound {
//                    if let sublayer = (action.layer.sublayers!.first as? CAShapeLayer) {
                    UIView.animate(withDuration: 0.15, animations: {
                        action.alpha = 0
                    }) { (complete) in
                        if complete {
                            action.backgroundColor = .systemRed
                            action.setTitle("VIEW OFFER", for: .normal)
                            action.setTitleColor(.white, for: .normal)
                            UIView.animate(withDuration: 0.15) {
                                action.alpha = 1
                            }
                        }
                    }
                }
            }
            cell.selectionStyle = .none
            return cell
        default:
            return UITableViewCell()
        }
        
    }
    
    @objc func beginMakeOffer(sender: UIButton) {
        UIView.animate(withDuration: 0.15) {
            sender.transform = CGAffineTransform.init(scaleX: 0.95, y: 0.95)
        }
    }
    
    @objc func makeOffer(sender: UIButton) {
        UIView.animate(withDuration: 0.15) {
            sender.transform = .identity
        }
        var offerViewController:OfferViewController
        if self.item.offerReference != nil {
            offerViewController = OfferViewController.init(presentOffer: &item)
        } else {
            offerViewController = OfferViewController.init(newOffer: &self.item)
        }
        self.present(offerViewController, animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch self.sections.identiferForSectionAtIndex(indexPath.section) {
        default:
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @objc func toggleFavorite() {
        if let current = self.item.favorite {
            if current {
                self.item.unfavoriteItem()
                self.favoriteButton?.tintColor = .systemGray3
                self.browseDelegate?.itemFavoriteToggled?(false)
            } else {
                self.item.favoriteItem()
                self.favoriteButton?.tintColor = .systemRed
                self.browseDelegate?.itemFavoriteToggled?(true)
            }
        } else {
            self.item.favoriteItem()
            self.favoriteButton?.tintColor = .systemRed
            self.browseDelegate?.itemFavoriteToggled?(true)
        }
    }
    
    @objc func toggleNotification() {
        if let current = self.item.notification {
            if current {
                self.item.disableNotifications()
                self.notificationButton?.tintColor = .systemGray3
            } else {
                self.item.enableNotifications()
                self.notificationButton?.tintColor = .systemRed
            }
        } else {
            self.item.enableNotifications()
            self.notificationButton?.tintColor = .systemRed
        }
    }
}

extension ItemViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.item.imageURLS?.keys.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        let view = UIImageView.init(frame: CGRect.init(origin: CGPoint.zero, size: self.itemSize!))
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        view.backgroundColor = UIColor.systemGroupedBackground
        cell.addSubview(view)
        if let url = item.imageURLS?["\(indexPath.section)"] {
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
        return cell
    }
}
