//
//  OpenCVManager.h
//  OpenCVDemo
//
//  Created by JWTHiOS02 on 2018/4/4.
//  Copyright © 2018年 JWTHiOS02. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <Foundation/Foundation.h>

@interface OpenCVManager : NSObject

+ (UIImage *)correctWithUIImage:(UIImage *)image; // 图像纠偏

@end
