//
//  CVViewController.m
//  TensorFlowLite-Test
//
//  Created by 石嘉晨 on 2020/7/13.
//  Copyright © 2020 WIndFate. All rights reserved.
//

#import "OpenCVManager.h"
#import "CVViewController.h"

@interface CVViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation CVViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.imageView.image = [OpenCVManager correctWithUIImage:self.image];

//    [self writeToCsv];
}

-(void)writeToCsv {
    
    NSString *fileNameStr = @"iOS_test_5.csv";
    NSString *DocPath = [NSString stringWithFormat:@"/Users/windfate/Desktop/%@",fileNameStr];

    NSMutableString *csvString = [NSMutableString string];
    for (int i = 0; i< self.array.count; i ++) {
        
        if ((i%320) == 0 && i != 0) {
            [csvString appendString:@"\n"];
        }
        [csvString appendFormat:@"%@,",self.array[i]];
    };
    
    NSData *data = [csvString dataUsingEncoding:NSUTF8StringEncoding];
    [data writeToFile:DocPath atomically:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
