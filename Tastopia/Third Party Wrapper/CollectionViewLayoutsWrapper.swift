//
//  CollectionViewLayoutsWrapper.swift
//  Tastopia
//
//  Created by FISH on 2020/3/17.
//  Copyright © 2020 FISH. All rights reserved.
//

import collection_view_layouts

class CollectionViewLayoutsWrapper {
    
    func createLayout(delegate: LayoutDelegate) -> InstagramLayout {
        
        let layout = InstagramLayout()
        layout.delegate = delegate
        layout.cellsPadding = ItemsPadding(horizontal: 1, vertical: 1)
        return layout
    }
    
}
