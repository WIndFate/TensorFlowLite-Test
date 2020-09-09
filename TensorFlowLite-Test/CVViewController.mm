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

@property(nonatomic, strong) NSMutableArray *allRects;

@end

@implementation CVViewController

-(NSMutableArray *)allRects{
    
    if (!_allRects) {
        
        _allRects = [NSMutableArray array];
    }
    return _allRects;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    if (BarCodeModel) {
        
        NSArray *rects = [OpenCVManager findBarCodeRectWithData:self.array withImageHeight:self.image.size.height];
        for (NSArray *rect in rects) {
            [self.allRects addObject:rect];
        }
        
        self.imageView.image = [OpenCVManager drawContours:self.image withRects:self.allRects];

    } else {
        self.imageView.image = [OpenCVManager correctWithUIImage:self.image withData:self.array];
    }

//    [self writeToCsv];
}

//+ (NSArray *)findBarCode:(UIImage *)originImage withData:(NSArray *)inputData {
//    
//    UIImage *newImage = [OpenCVManager barCodeWithUIImage:originImage withData:inputData];
//    
//    if (newImage != nil) {
//        NSArray *arr = [NSArray arrayWithObjects:newImage, originImage, nil];
//        return arr;
//    }
//    
//    return nil;
//}

+ (NSArray *)findRects:(UIImage *)originImage withData:(NSArray *)inputData {
    
    NSArray *rectArr = [OpenCVManager findBarCodeRectWithData:inputData withImageHeight:originImage.size.height];
    
    return rectArr;
}

+ (NSArray *)drawBox:(UIImage *)originImage withRects:(NSArray *)rects {
    
    UIImage *finalImage = [OpenCVManager drawContours:originImage withRects:rects];
    
    if (finalImage != nil) {
        NSArray *arr = [NSArray arrayWithObjects:finalImage, rects, originImage, nil];
        return arr;
    }
    
    return nil;
}

- (IBAction)cutImageClick:(id)sender {
    
    UIImage *image = [OpenCVManager perspectiveWithUIImage:self.oriImage withRects:[self.allRects firstObject]];
    
    UIImage *bgImg = [UIImage imageNamed:@"ocr_bgImg_256x32"];
    UIImage * finalImage = [self AddWaterImage:bgImg waterImage:image loactionRect:CGRectMake((bgImg.size.width - image.size.width) / 2, 0, image.size.width, image.size.height)];
    self.imageView.image = [UIImage imageWithCGImage:finalImage.CGImage scale:finalImage.scale orientation:UIImageOrientationLeftMirrored];
    
}

- (UIImage *)clipImage:(UIImage *)oriImage BgImageSize:(NSString *)sizeString withCurrentRects:(NSArray *)rects {
    
    UIImage *image = [OpenCVManager perspectiveWithUIImage:oriImage withRects:rects];
    
    UIImage *bgImg = [UIImage imageNamed:[NSString stringWithFormat:@"ocr_bgImg_%@",sizeString]];
    UIImage * finalImage = [self AddWaterImage:bgImg waterImage:image loactionRect:CGRectMake((bgImg.size.width - image.size.width) / 2, 0, image.size.width, image.size.height)];
    
    return [UIImage imageWithCGImage:finalImage.CGImage scale:finalImage.scale orientation:UIImageOrientationLeftMirrored];
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
    
    NSString *fileNameStr = @"iOS_56438.csv";
    NSString *DocPath = [NSString stringWithFormat:@"/Users/shijiachen/Desktop/%@",fileNameStr];

    NSMutableString *csvString = [NSMutableString string];
    for (int i = 0; i< array.count; i ++) {
        
        if ((i%15) == 0 && i != 0) {
            [csvString appendString:@"\n"];
        }
        [csvString appendFormat:@"%@,",array[i]];
    };
    
    NSData *data = [csvString dataUsingEncoding:NSUTF8StringEncoding];
    [data writeToFile:DocPath atomically:YES];
}

- (void)saveImage:(UIImage *)image {
    
    BOOL result =[UIImagePNGRepresentation(image)writeToFile:@"/Users/shijiachen/Desktop/ocr_oriImage.png"   atomically:YES]; // 保存成功会返回YES
    if (result == YES) {
        NSLog(@"保存成功");
    }
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

+ (unsigned char *)getBGRWithImage:(UIImage *)image
{
    int RGBA = 4;
    int RGB  = 3;
    
    CGImageRef imageRef = [image CGImage];
    
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = (unsigned char *) malloc(width * height * sizeof(unsigned char) * RGBA);
    NSUInteger bytesPerPixel = RGBA;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
    unsigned char * tempRawData = (unsigned char *)malloc(width * height * 3 * sizeof(unsigned char));
    
    for (int i = 0; i < width * height; i ++) {
        
        NSUInteger byteIndex = i * RGBA;
        NSUInteger newByteIndex = i * RGB;
        
        // Get RGB
        CGFloat red    = rawData[byteIndex + 0];
        CGFloat green  = rawData[byteIndex + 1];
        CGFloat blue   = rawData[byteIndex + 2];
        //CGFloat alpha  = rawData[byteIndex + 3];// 这里Alpha值是没有用的
        
        // Set RGB To New RawData
        tempRawData[newByteIndex + 0] = blue;   // B
        tempRawData[newByteIndex + 1] = green;  // G
        tempRawData[newByteIndex + 2] = red;    // R
    }
    
    return tempRawData;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"OCRViewController"]) {
        
        OCRViewController *ocrVc = [segue destinationViewController];
        ocrVc.image = self.imageView.image;
    }
}

@end
