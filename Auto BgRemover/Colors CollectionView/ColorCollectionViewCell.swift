//
//  ColorCollectionViewCell.swift
//  PhotoEditorForPassport
//
//  Created by Pawan iOS on 11/10/2022.
//

import UIKit

class ColorCollectionViewCell: UICollectionViewCell {
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    
    class func registerColorsCollectionViewCell( collectionView: UICollectionView, indexpath: IndexPath) -> ColorCollectionViewCell {
        collectionView.register(UINib(nibName: "ColorCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "ColorCollectionViewCell")
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ColorCollectionViewCell", for: indexpath) as? ColorCollectionViewCell
        
        return cell!
    }
    
}
