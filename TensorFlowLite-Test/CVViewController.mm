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
    
    self.imageView.image = [OpenCVManager perspectiveWithUIImage:self.imageView.image];
}

-(void)writeToCsv:(NSArray *)array {
    
    NSString *fileNameStr = @"iOS_OCR.csv";
    NSString *DocPath = [NSString stringWithFormat:@"/Users/windfate/Desktop/%@",fileNameStr];

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

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"OCRViewController"]) {
        
        OCRViewController *ocrVc = [segue destinationViewController];
        ocrVc.image = self.imageView.image;
    }
}

@end
