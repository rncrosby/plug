//
//  MyStuffViewController.swift
//  plug
//
//  Created by Robert Crosby on 5/26/20.
//  Copyright © 2020 Robert Crosby. All rights reserved.
//

import UIKit

class MyStuffViewController: UITableViewController {
    
    weak var rootDelegate:RootDelegate?
    var sections = SectionController()
    var favorites:[Item]?
    
    func favoritesChanged(_ favorites: inout [Item]) {
        self.favorites = favorites
        
        self.sections.updateSection(title: .MyStuffFavorites, rows: self.favorites?.count ?? 0)
        self.sections.setHeaderTextForSection(.MyStuffFavorites, "Favorites")
        self.updateTable()
    }
    
    var offers:[Offer]?
    
    func offersChanged(_ offers: inout [Offer]) {
        self.offers = offers
        
        self.sections.updateSection(title: .MyStuffOffers, rows: self.offers?.count ?? 0)
        self.sections.setHeaderTextForSection(.MyStuffOffers, "Offers")
        self.updateTable()
    }
    
    func updateTable() {
        
        self.sections.orderSections([.MyStuffOffers, .MyStuffFavorites])
        self.tableView.reloadData()
    }
    
    init() {
        super.init(style: .grouped)
        self.title = "Your Bag"
        self.tabBarItem = UITabBarItem.init(title: nil, image: UIImage.init(systemName: "bag"), selectedImage: UIImage.init(systemName: "bag.fill"))
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        self.tableView.backgroundColor = .secondarySystemGroupedBackground
        self.tableView.separatorInset = UIEdgeInsets.init(top: 0, left: 15, bottom: 0, right: 15)
        self.tableView.register(UINib(nibName: "OfferCell", bundle: nil), forCellReuseIdentifier: "OfferCell")
//        self.tableView.contentInset.top+=35
        super.viewDidLoad()
        
        
        let refresh = UIRefreshControl.init()
        refresh.addTarget(self, action: #selector(refreshStuff(_:)), for: .valueChanged)
        self.tableView.refreshControl = refresh
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    @objc func refreshStuff(_ sender: UIRefreshControl) {
        self.rootDelegate?.refreshMyStuff()
        sender.endRefreshing()
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 54
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView.init(frame: CGRect.init(origin: .zero, size: CGSize.init(width: self.view.frame.size.width, height: 54)))
        let label = UILabel.init(frame: CGRect.init(origin: CGPoint.init(x: 15, y: 0), size: CGSize.init(width: view.frame.size.width-30, height: view.frame.size.height)))
        label.font = titleFont
        label.textColor = .label
        label.text = self.sections.titleForSectionAtIndex(section)
        view.addSubview(label)
        return view
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return self.sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.sections.rowsInSectionAtIndex(section)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let identifier = self.sections.identiferForSectionAtIndex(indexPath.section)
        switch identifier {
        case .MyStuffOffers:
            let cell = tableView.dequeueReusableCell(withIdentifier: "OfferCell") as! OfferCell
            cell.backgroundColor = .systemGroupedBackground
//            cell.itemName?.font = buttonFont
            if let offer = self.offers?[indexPath.row] {
                cell.itemImageView.backgroundColor = .systemGroupedBackground
                cell.itemImageView.layer.cornerRadius = 5
                cell.itemImageView.layer.masksToBounds = true
//                cell.offerStatus.text = offer.offerStatusString
                fetchItemDetail(offer.item!) { (name, imageUrl) in
                    if let name = name {
                        cell.itemName.text = name
                    }
                    if let imageUrl = imageUrl {
                        downloadImage(url: URL.init(string: imageUrl)!) { (image, error) in
                            if let error = error {
                                print(error)
                            }
                            print("image downloaded")
                            
                            if let image = image {
                                DispatchQueue.main.async {
                                    cell.itemImageView.image = image
                                }
                                
                            }
                        }
                    }
                }
            }
            return cell
        case .MyStuffFavorites:
            let cell = UITableViewCell.init(style: .subtitle, reuseIdentifier: nil)
            cell.backgroundColor = .systemGroupedBackground
            cell.imageView?.backgroundColor = .systemRed
            if let favorite = self.favorites?[indexPath.row] {
                cell.textLabel?.text = favorite.name!
            }
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let identifier = self.sections.identiferForSectionAtIndex(indexPath.section)
        switch identifier {
        case .MyStuffOffers:
            self.present(OfferViewController.init(offer: &self.offers![indexPath.row]), animated: true, completion: nil)
        case .MyStuffFavorites:
            self.navigationController?.pushViewController(ItemViewController.init(item: &self.favorites![indexPath.row]), animated: true)
        default:
            break
        }
        self.tableView.deselectRow(at: indexPath, animated: true)
    }

}
