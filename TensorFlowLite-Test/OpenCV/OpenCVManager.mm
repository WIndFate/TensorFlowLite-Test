//
//  OpenCVManager.m
//  OpenCVDemo
//
//  Created by JWTHiOS02 on 2018/4/4.
//  Copyright © 2018年 JWTHiOS02. All rights reserved.
//

#import "OpenCVManager.h"
#import "opencv2/opencv.hpp"
#import "UIImage+OpenCV.h"

@implementation OpenCVManager

+ (UIImage *)correctWithUIImage:(UIImage *)image {
    cv::Mat inputMat;
    cv::Mat outputMat;
    cv::Mat tmp;
    cv::Mat orig_img;
    int min_grid_size = 3;

    double scaling = 0.7;
    double extend_multiplier = 1.1;
    double threshold = 0.8;
    double threshold_level = int(255*threshold);
    
    inputMat = [image cvMatImage];
    
//    UIImage *blackImage = [UIImage imageNamed:@"test_5_bit_img"];
//    inputMat = [blackImage cvMatImage];
    
    UIImage *origImage = [UIImage imageNamed:@"test_5"];
    orig_img = [origImage cvMatImage];
    
    double grid_size = origImage.size.height / inputMat.rows;
    
//    for (auto it = inputMat.begin<cv::Vec3b>(); it != inputMat.end<cv::Vec3b>(); ++it)
//    {
////        std::cout << int((*it)[0]) << " " << int((*it)[1]) << " " << int((*it)[2]) << std::endl;
//        (*it)[0] = (*it)[0] * 255;
//        (*it)[1] = (*it)[1] * 255;
//        (*it)[2] = (*it)[2] * 255;
//    }
    
//    uchar * pxvec = inputMat.ptr<uchar>(0);
//
//
//     for(int i = 0 ;i < inputMat.rows ; i++) {
//         pxvec = inputMat.ptr<uchar>(i);
//        // const int * Mnewi = newSourceMatImage.ptr<int>(i);
//         for(int j = 0; j< inputMat.cols; j ++) {
//             //const int  Mnewj =  Mi[j] * 255;
//             pxvec[j] = pxvec[j] * 255;
//         }
//     }
    cv::Mat grayMat;
    if ( inputMat.channels() == 1 ) {
        grayMat = inputMat;
    }
    else {
        grayMat = cv :: Mat( inputMat.rows,inputMat.cols, CV_8UC1 );
        cv::cvtColor(inputMat, grayMat, CV_BGR2GRAY);
    }
    
    cv::threshold(grayMat, tmp, threshold_level, 255, CV_THRESH_BINARY);
    outputMat = tmp;
    
    // 边缘检测
    cv::Canny(outputMat, tmp, 30, 220);
    outputMat = tmp;

    // 边角检测  填充边界内空白色值
    std::vector<std::vector<cv::Point>> contours;
    cv::findContours(outputMat, contours, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_SIMPLE);

    int min_box_area = grid_size*grid_size*min_grid_size;

    for (int i = 0; i < contours.size(); i++) {

        cv::Rect rect = cv::boundingRect(contours[i]);
        
        rect.x = rect.x * grid_size;
        rect.width = rect.width * grid_size;
        rect.y = rect.y * grid_size;
        rect.height = rect.height * grid_size;
        
        int min_wh;
        if (rect.width <= rect.height) {
            min_wh = rect.width;
        }else {
            min_wh = rect.height;
        }

        if ((rect.width * rect.height) < min_box_area) {
            continue;
        } else {

            rect.x = rect.x - int(min_wh*scaling/2);
            rect.width = rect.width + int(min_wh*scaling*extend_multiplier);
            rect.y = rect.y - int((min_wh*scaling/2));
            rect.height = rect.height + int((min_wh*scaling)*extend_multiplier);

            cv::rectangle(orig_img, rect, cv::Scalar(0,0,255), 2);
        }
    }
    
    return [UIImage imageWithCVMat:orig_img];
}


@end
