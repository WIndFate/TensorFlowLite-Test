//
//  CVViewController.m
//  TensorFlowLite-Test
//
//  Created by 石嘉晨 on 2020/7/13.
//  Copyright © 2020 WIndFate. All rights reserved.
//

#import "OpenCVManager.h"
#import "CVViewController.h"
#import "TensorFlowLite_Test-Swift.h"

@interface CVViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation CVViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    if (BarCodeModel) {
        self.imageView.image = [OpenCVManager barCodeWithUIImage:self.image withData:self.array];
        
    } else {
        self.imageView.image = [OpenCVManager correctWithUIImage:self.image withData:self.array];
    }

//    [self writeToCsv];
}

- (IBAction)cutImageClick:(id)sender {
    
    UIImage *image = [OpenCVManager perspectiveWithUIImage:self.oriImage];
    
    UIImage *bgImg = [UIImage imageNamed:@"ocr_bgImg_256x32"];
    UIImage * finalImage = [self AddWaterImage:bgImg waterImage:image loactionRect:CGRectMake((bgImg.size.width - image.size.width) / 2, 0, image.size.width, image.size.height)];
    self.imageView.image = [UIImage imageWithCGImage:finalImage.CGImage scale:finalImage.scale orientation:UIImageOrientationLeftMirrored];
    
}

- (UIImage *)AddWaterImage:(UIImage *)originImage waterImage:(UIImage *)waterImage loactionRect:(CGRect)waterRect{
    //开启图形上下文
    UIGraphicsBeginImageContextWithOptions(originImage.size, NO, 0);
    //将原图加在画布上
    [originImage drawInRect:CGRectMake(0, 0, originImage.size.width, originImage.size.height)];
    //将水印图片加在画布上
    [waterImage drawInRect:waterRect];
    //合成图片
    UIImage * newImage = UIGraphicsGetImageFromCurrentImageContext();
    //关闭画布
    UIGraphicsEndImageContext();
    return newImage;
}


-(void)writeToCsv:(NSArray *)array {
    
    NSString *fileNameStr = @"iOS_99_accu.csv";
    NSString *DocPath = [NSString stringWithFormat:@"/Users/shijiachen/Desktop/%@",fileNameStr];

    NSMutableString *csvString = [NSMutableString string];
    for (int i = 0; i< array.count; i ++) {
        
        if ((i%37) == 0 && i != 0) {
            [csvString appendString:@"\n"];
        }
        [csvString appendFormat:@"%@,",array[i]];
    };
    
    NSData *data = [csvString dataUsingEncoding:NSUTF8StringEncoding];
    [data writeToFile:DocPath atomically:YES];
}

//-(void)stretchableImage:(UIImage *)image {
//
//    image = [image stretchableImageWithLeftCapWidth:1 topCapHeight:0];
//
//    CGFloat finalWidth = 1280;
//    CGFloat imageWidth = image.size.width;
//    CGFloat imageHeight = image.size.height;
//
//    CGFloat tempWidth = (finalWidth + imageWidth) / 2.0f;
//
//    UIGraphicsBeginImageContextWithOptions(CGSizeMake(tempWidth,imageHeight),NO, [UIScreen mainScreen].scale);
//
//    [image drawInRect:CGRectMake(0,0, tempWidth,imageHeight)];
//
//    UIImage * leftImage =UIGraphicsGetImageFromCurrentImageContext();
//
//    UIGraphicsEndImageContext();
//
//    UIImage *rightImage = [leftImage stretchableImageWithLeftCapWidth:(leftImage.size.width - 1) topCapHeight:0];
//
//    UIGraphicsBeginImageContextWithOptions(CGSizeMake(finalWidth,imageHeight),NO, [UIScreen mainScreen].scale);
//
//    [rightImage drawInRect:CGRectMake(0,0, finalWidth,imageHeight)];
//
//    UIImage * finalImage =UIGraphicsGetImageFromCurrentImageContext();
//
//    UIGraphicsEndImageContext();
//}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"OCRViewController"]) {
        
        OCRViewController *ocrVc = [segue destinationViewController];
        ocrVc.image = self.imageView.image;
    }
}

@end
