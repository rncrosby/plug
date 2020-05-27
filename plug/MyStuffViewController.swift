//
//  MyStuffViewController.swift
//  plug
//
//  Created by Robert Crosby on 5/26/20.
//  Copyright © 2020 Robert Crosby. All rights reserved.
//

import UIKit

class MyStuffViewController: UITableViewController {
    
    var sections = SectionController()
    var favorites:[Item]?
    
    func favoritesChanged(_ favorites: inout [Item]) {
        self.favorites = favorites
        self.updateTabBarItem()
        self.sections.updateSection(title: .MyStuffFavorites, rows: self.favorites?.count ?? 0)
        self.sections.setHeaderTextForSection(.MyStuffFavorites, "Favorites")
    }
    
    var offers:[Offer]?
    
    func offersChanged(_ offers: inout [Offer]) {
        self.offers = offers
        self.updateTabBarItem()
        self.sections.updateSection(title: .MyStuffOffers, rows: self.offers?.count ?? 0)
        self.sections.setHeaderTextForSection(.MyStuffOffers, "Offers")
    }
    
    func updateTabBarItem() {
        let count = 0 + (self.favorites?.count ?? 0) + (self.offers?.count ?? 0)
        if count > 0 {
            self.tabBarItem = UITabBarItem.init(title: nil, image: UIImage.init(systemName: "\(count).square"), selectedImage: UIImage.init(systemName: "\(count).square.fill"))
        } else {
            self.tabBarItem = UITabBarItem.init(title: nil, image: UIImage.init(systemName: "square"), selectedImage: UIImage.init(systemName: "square.fill"))
        }
        self.sections.orderSections([.MyStuffOffers, .MyStuffFavorites])
        self.tableView.reloadData()
    }
    
    init() {
        super.init(style: .insetGrouped)
        self.updateTabBarItem()
        self.title = "For You"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        self.tableView.backgroundColor = .secondarySystemBackground
//        self.tableView.contentInset.top+=35
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 54
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView.init(frame: CGRect.init(origin: .zero, size: CGSize.init(width: self.view.frame.size.width, height: 54)))
        let label = UILabel.init(frame: CGRect.init(origin: CGPoint.init(x: 0, y: 0), size: CGSize.init(width: view.frame.size.width, height: view.frame.size.height)))
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
        let cell = UITableViewCell.init(style: .subtitle, reuseIdentifier: nil)
        cell.backgroundColor = .systemGroupedBackground
        let identifier = self.sections.identiferForSectionAtIndex(indexPath.section)
        switch identifier {
        case .MyStuffOffers:
            cell.textLabel?.font = buttonFont
            if let offer = self.offers?[indexPath.row] {
                justFetchItemName(offer.item!) { (name) in
                    cell.textLabel?.text = name
                }
            }
        case .MyStuffFavorites:
            if let favorite = self.favorites?[indexPath.row] {
                cell.textLabel?.text = favorite.name!
            }
        default:
            break
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let identifier = self.sections.identiferForSectionAtIndex(indexPath.section)
        switch identifier {
        case .MyStuffOffers:
            self.present(OfferViewController.init(offer: &self.offers![indexPath.row]), animated: true, completion: nil)
        case .MyStuffFavorites:
            self.present(ItemViewController.init(item: &self.favorites![indexPath.row]), animated: true, completion: nil)
        default:
            break
        }
    }

}
