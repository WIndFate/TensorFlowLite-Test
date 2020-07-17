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

+ (UIImage *)correctWithUIImage:(UIImage *)image withData:(NSArray *)inputData {
    cv::Mat inputMat;
    cv::Mat outputMat;
    cv::Mat tmp;
    cv::Mat orig_img;
    int min_grid_size = 3;

    double scaling = 0.7;
    double extend_multiplier = 1.1;
    double threshold = 0.8;
    double threshold_level = int(255*threshold);
    
    inputMat = ProcessOutputWithFloatModel(inputData);
    
    orig_img = [image cvMatImage];
    
    double grid_size = image.size.height / inputMat.rows;
//    cv::Mat grayMat;
//    if ( inputMat.channels() == 1 ) {
//        grayMat = inputMat;
//    }
//    else {
//        grayMat = cv :: Mat( inputMat.rows,inputMat.cols, CV_8UC1 );
//        cv::cvtColor(inputMat, grayMat, CV_BGR2GRAY);
//    }
    
    cv::threshold(inputMat, tmp, threshold_level, 255, CV_THRESH_BINARY);
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


+ (UIImage *)barCodeWithUIImage:(UIImage *)image withData:(NSArray *)inputData {
    cv::Mat inputMat;
    cv::Mat outputMat;
    cv::Mat tmp;
    cv::Mat orig_img;
    cv::Mat box;
    int min_grid_size = 3;

    double scaling = 0.7;
    double extend_multiplier = 1.1;
    double threshold = 0.8;
    double threshold_level = int(255*threshold);
    
    inputMat = ProcessOutputWithFloatModel(inputData);
    
    orig_img = [image cvMatImage];
    
    double grid_size = image.size.height / inputMat.rows;
    
    cv::threshold(inputMat, tmp, threshold_level, 255, CV_THRESH_BINARY);
    outputMat = tmp;
    
    // 边缘检测
    cv::Canny(outputMat, tmp, 30, 220);
    outputMat = tmp;

    // 边角检测  填充边界内空白色值
    std::vector<std::vector<cv::Point>> contours;
    cv::findContours(outputMat, contours, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_SIMPLE);

    int min_box_area = grid_size*grid_size*min_grid_size;

    for (int i = 0; i < contours.size(); i++) {

        cv::RotatedRect rect = cv::minAreaRect(contours[i]);

        cv::boxPoints(rect, box);
        rect.angle = rect.angle * grid_size;
        rect.size.width = rect.size.width * grid_size;
        rect.size.height = rect.size.height * grid_size;
    }
    
    return [UIImage imageWithCVMat:orig_img];
}

cv::Mat ProcessOutputWithFloatModel(NSArray* input) {
  cv::Mat image = cv::Mat::zeros(448, 320, CV_8UC3);
  for (int y = 0; y < 448; ++y) {
    for (int x = 0; x < 320; ++x) {
      float input_pixel = [input[(y * 320 * 1) + (x * 1)] floatValue];
      cv::Vec3b & color = image.at<cv::Vec3b>(cv::Point(x, y));
      color[0] = (uchar) floor(input_pixel * 255.0f);
      color[1] = (uchar) floor(input_pixel * 255.0f);
      color[2] = (uchar) floor(input_pixel * 255.0f);
    }
  }
  return image;
}
@end
