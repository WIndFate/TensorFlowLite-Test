//
//  CVViewController.h
//  TensorFlowLite-Test
//
//  Created by 石嘉晨 on 2020/7/13.
//  Copyright © 2020 WIndFate. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CVViewController : UIViewController

@property(nonatomic, strong) UIImage *image;

@property(nonatomic, strong) UIImage *oriImage;

@property(nonatomic, strong) NSArray *array;

- (void)writeToCsv:(NSArray *)array;

- (void)saveImage:(UIImage *)image;

- (UIImage *)clipImage:(UIImage *)oriImage BgImageSize:(NSString *)sizeString withCurrentRects:(NSArray *)rects;

//+ (NSArray *)findBarCode:(UIImage *)originImage withData:(NSArray *)inputData;

+ (NSArray *)findRects:(UIImage *)originImage withData:(NSArray *)inputData;

+ (NSArray *)drawBox:(UIImage *)originImage withRects:(NSArray *)rects;

@end
