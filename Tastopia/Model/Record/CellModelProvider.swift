//
//  CellModel.swift
//  Tastopia
//
//  Created by FISH on 2020/3/25.
//  Copyright © 2020 FISH. All rights reserved.
//

import Foundation
import UIKit

protocol TTCellModel {
    
    var identifier: String { get }
    
    func setCell(tableViewCell: UITableViewCell, writing: WritingData, agreeMethod: (() -> Void)?, disagreeMethod: (() -> Void)?)
}

extension TTCellModel {
    
    func countAgreeRatio(agree: Int, disagree: Int) -> Float {
    
        return Float(agree) / (Float(agree) + Float(disagree))
    }
}

struct TTRecordContentTopCellModel: TTCellModel {
        
    let identifier: String = TTConstant.CellIdentifier.recordContentTopTableViewCell
    
    func setCell(tableViewCell: UITableViewCell, writing: WritingData, agreeMethod: (() -> Void)?, disagreeMethod: (() -> Void)?) {
        
        guard let cell = tableViewCell as? RecordContentTopTableViewCell else { return }
        
        cell.authorImagePath = writing.userImagePath
        
        cell.nameLabel.text = writing.userName
                
        cell.dateLabel.text = DateFormatter.createTTDate(date: writing.date, format: "yyyy-MM-dd")
        
        let agreeRatio = countAgreeRatio(agree: writing.agree, disagree: writing.disagree)
        cell.agreeRatioLabel.text = "\(Int(agreeRatio * 100))%"
    }
            
}

struct TTRecordContentImageCellModel: TTCellModel {
    
    let identifier: String = TTConstant.CellIdentifier.recordContentImageTableViewCell
    
    func setCell(tableViewCell: UITableViewCell, writing: WritingData, agreeMethod: (() -> Void)?, disagreeMethod: (() -> Void)?) {
        
        guard let cell = tableViewCell as? RecordContentImageTableViewCell else { return }
        
        cell.writing = writing
        cell.imageCollectionView.reloadData()
    }
}

struct TTRecordContentCompositionCellModel: TTCellModel {
    
    let identifier: String = TTConstant.CellIdentifier.recordContentCompositionTableViewCell
    
    func setCell(tableViewCell: UITableViewCell, writing: WritingData, agreeMethod: (() -> Void)?, disagreeMethod: (() -> Void)?) {
        
        guard let cell = tableViewCell as? RecordContentCompositionTableViewCell else { return }
        
        let keyword = TastopiaTest.shared.keyword
        let composition = writing.composition.replacingOccurrences(of: keyword, with: "")
        cell.compositionLabel.text = composition
    }
}

struct TTRecordContentAgreeCellModel: TTCellModel {
    
    let identifier: String = TTConstant.CellIdentifier.recordContentAgreeTableViewCell
    
    func setCell(tableViewCell: UITableViewCell, writing: WritingData, agreeMethod: (() -> Void)?, disagreeMethod: (() -> Void)?) {
        
        // MARK: for edit composition
        if UserProvider.shared.userData?.uid == writing.uid {
            
        }
        
        guard let cell = tableViewCell as? RecordContentAgreeTableViewCell else { return }
        
        cell.documentID = writing.documentID
        cell.agree = agreeMethod
        cell.disagree = disagreeMethod
    }
}
