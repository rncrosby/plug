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
        
        enum Identifier:String {
            case ItemImages = "item images"
            case ItemNaming = "item naming"
            case ItemClassification = "item classification"
            case ItemSizing = "item sizing"
            case ItemPricing = "item pricing"
            case Actions = "actions"
        }
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
            return self.sections[index].title.rawValue
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
        return self.sections[index].rows
    }
    
    
    
}


