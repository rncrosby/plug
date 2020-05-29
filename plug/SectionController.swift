

class SectionController {
    
    var count: Int {
        return self.sections.count
    }
    
    var sections = [Section]()
    
    struct Section {
        let title: Identifier
        var rows: Int
        var showHeader:Bool = false
        var headerText:String = ""
        
        enum Identifier: String {
            case ItemMetrics = "metrics"
            case ItemDetails = "details"
            case ItemImages = "images"
            case ItemNaming = "naming"
            case ItemClassification = "classification"
            case ItemSizing = "sizing"
            case ItemPricing = "pricing"
            case Actions = "actions"
            case Authentication = "auth"
            case PublicProfile = "public profile"
            
            case OfferAmount = "offer amount"
            case OfferLocal = "offer local"
            case OfferCash = "offer cash"
            case OfferSubmit = "offer submit"
            
            case OfferNotSubmitted = "offer not submitted"
            case OfferMessages = "offer mesasages"
            case OfferComposer = "offer composer"
            case OfferPending = "offer pending"
            case OfferSellerAccept = "offer seller accept"
            case OfferCashCompletion = "offer cash pending complete"
            case OfferSellerMarkComplete = "offer seller mark complete"
            case OfferCardCompletion = "offer card completion"
            case OfferCustomerCardPayment = "offer card payment"
            case OfferPaid = "offer paid"
            case OfferShippingAddress = "shipping address"
            case OfferSellerMarkShipped = "mark shipped"
            case OfferShipped = "offer shipped"
            case OfferTrackShipped = "track"
            case OfferComplete = "offer complete"
            
            case MyStuffOffers = "my stuff offer"
            case MyStuffFavorites = "my stuff favorites"
        }
    }
    
    func orderSections(_ newOrder: [Section.Identifier]) {
        var temp = [Section]()
        for identifier in newOrder {
            if let index = self.sections.firstIndex(where: { (section) -> Bool in
                return section.title == identifier
            }) {
                temp.append(self.sections[index])
            }
        }
        self.sections = temp
    }
    
    func setHeaderTextForSection(_ title: Section.Identifier, _ text: String) {
        if let index = self.sections.firstIndex(where: { (section) -> Bool in
            return section.title == title
        }) {
            self.sections[index].headerText = text
            self.sections[index].showHeader = true
        }
    }
    
    func toggleShowHeaderForSection(_ title: Section.Identifier) {
        if let index = self.sections.firstIndex(where: { (section) -> Bool in
            return section.title == title
        }) {
            self.sections[index].showHeader.toggle()
        }
    }
    
    func moveSectionToFirst(_ title: Section.Identifier) {
        if let index = self.sections.firstIndex(where: { (section) -> Bool in
            return section.title == title
        }) {
            let t = self.sections[index]
            self.sections.remove(at: index)
            self.sections.insert(t, at: 0)
        }
    }
    
    func moveSectionBehindOther(_ title: Section.Identifier, _ target: Section.Identifier) {
        if let index = self.sections.firstIndex(where: { (section) -> Bool in
            return section.title == title
        }) {
            if let targetIndex = self.sections.firstIndex(where: { (section) -> Bool in
                return section.title == target
            }) {
                let t = self.sections[index]
                self.sections.remove(at: index)
                self.sections.insert(t, at: targetIndex + 1)
            }
        }
    }
    
    // TODO: Return specific changes made for cleaner animation
    func updateSection(title: Section.Identifier, rows: Int) {
        if let index = self.sections.firstIndex(where: { (section) -> Bool in
            return section.title == title
        }) {
            // already exists, update
            self.sections[index].rows = rows
        } else {
            self.sections.append(Section.init(title: title, rows: rows))
        }
    }
    
    func removeSection(title: Section.Identifier) {
        if let index = self.sections.firstIndex(where: { (section) -> Bool in
                   return section.title == title
            }) {
            self.sections.remove(at: index)
        }
    }
    
    func titleForSectionAtIndex(_ index: Int) -> String? {
        if self.sections[index].showHeader {
            if !(self.sections[index].headerText.isEmpty) {
                return self.sections[index].headerText
            }
            return nil
        }
        return nil
    }
    
    func identiferForSectionAtIndex(_ index: Int) -> SectionController.Section.Identifier {
        return self.sections[index].title
    }
    
    func indexForIdentifier(_ identifier: SectionController.Section.Identifier) -> Int? {
        return self.sections.firstIndex(where: { (section) -> Bool in
            return section.title == identifier
        })
    }
    
    func rowsInSectionAtIndex(_ index: Int) -> Int {
        if index < self.sections.count {
            return self.sections[index].rows
        }
        return 0
        
    }
    
    
    
}


