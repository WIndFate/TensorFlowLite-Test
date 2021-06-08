//
//  ScanView.swift
//  WareHouse
//
//  Created by Shi Jiachen on 2020/09/02.
//  Copyright © 2020 Shi Jiachen. All rights reserved.
//

import UIKit

class AITeamScanView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        
        let topLetfImage = UIImage(named: "qr_top_left.png")!
        let imageW = topLetfImage.size.width;
        let imageH = topLetfImage.size.height;
        
        let topLeft = UIImageView(frame: CGRect(x: 0, y: 0, width: imageW, height: imageH))
        topLeft.image = topLetfImage
        self.addSubview(topLeft)
        
        let topRight = UIImageView(frame: CGRect(x: self.frame.size.width - imageW, y: 0, width: imageW, height: imageH))
        topRight.image = UIImage(named: "qr_top_right.png")!
        self.addSubview(topRight)
        
        let bottomLeft = UIImageView(frame: CGRect(x: 0, y: self.frame.size.height - imageH, width: imageW, height: imageH))
        bottomLeft.image = UIImage(named: "qr_bottom_left")!
        self.addSubview(bottomLeft)
        
        let bottomRight = UIImageView(frame: CGRect(x: self.frame.size.width - imageW, y: self.frame.size.height - imageH, width: imageW, height: imageH))
        bottomRight.image = UIImage(named: "qr_bottom_right")!
        self.addSubview(bottomRight)
        
        
        let lineCu:CGFloat = 1.0
        let topLineX = 0 - lineCu
        let topLineY = 0 - lineCu
        let topLineW = self.frame.size.width + lineCu * 2
        let topLineH = lineCu
        let topLine = UIView(frame: CGRect(x: topLineX, y: topLineY, width: topLineW, height: topLineH))
        topLine.backgroundColor = .gray
        self.addSubview(topLine)
        
        let bottomLineX = 0 - lineCu
        let bottomLineY = self.frame.size.height
        let bottomLineW = self.frame.size.width + lineCu * 2
        let bottomLineH = lineCu
        let bottomLine = UIView(frame: CGRect(x: bottomLineX, y: bottomLineY, width: bottomLineW, height: bottomLineH))
        bottomLine.backgroundColor = .gray
        self.addSubview(bottomLine)
        
        let leftLineX = 0 - lineCu
        let leftLineY = 0 - lineCu
        let leftLineW = lineCu
        let leftLineH = self.frame.size.height + lineCu * 2
        let leftLine = UIView(frame: CGRect(x: leftLineX, y: leftLineY, width: leftLineW, height: leftLineH))
        leftLine.backgroundColor = .gray
        self.addSubview(leftLine)
        
        let rightLineX = self.frame.size.width
        let rightLineY = 0 - lineCu
        let rightLineW = lineCu
        let rightLineH = self.frame.size.height + lineCu * 2
        let rightLine = UIView(frame: CGRect(x: rightLineX, y: rightLineY, width: rightLineW, height: rightLineH))
        rightLine.backgroundColor = .gray
        self.addSubview(rightLine)
    }

}
