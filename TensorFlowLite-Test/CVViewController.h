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

- (UIImage *)clipImage:(UIImage *)oriImage;

+ (NSArray *)findBarCode:(UIImage *)originImage withData:(NSArray *)inputData;

@end
