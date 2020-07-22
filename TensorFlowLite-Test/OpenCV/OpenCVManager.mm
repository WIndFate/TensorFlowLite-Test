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

@interface OpenCVManager ()

@end

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
//    cv::Canny(outputMat, tmp, 30, 220);
//    outputMat = tmp;

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
    CGRect cutRect;
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
    
    for (int i = 0; i < contours.size(); i++) {

        for (int i = 0; i < contours.size(); i++) {
            for (int j = 0; j < contours[i].size(); j++) {
                
                contours[i][j].x = contours[i][j].x * grid_size - 150;
                contours[i][j].y = contours[i][j].y * grid_size;
            }
        }
        
        cv::RotatedRect rect = cv::minAreaRect(contours[i]);
        
        cv::boxPoints(rect, box);
        
        float x = box.row(0).col(0).at<float>(0,0);
        float y = box.row(1).col(1).at<float>(0,0);
        float width = box.row(2).col(0).at<float>(0,0) - x;
        float height = box.row(0).col(1).at<float>(0,0) - y;
        cutRect = CGRectMake(x, y, width, height);
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setFloat:x forKey:@"cutRect_x"];
        [defaults setFloat:y forKey:@"cutRect_y"];
        [defaults setFloat:width forKey:@"cutRect_width"];
        [defaults setFloat:height forKey:@"cutRect_height"];
        
        std::cout << box.size() << std::endl;
        std::cout << "boxPts " << std::endl << " " << box << std::endl;
        
    }
    
    cv::Point2f src[4], dst[4];
    src[0].x = cutRect.origin.x;
    src[0].y = cutRect.origin.y;
    src[1].x = cutRect.origin.x + cutRect.size.width;
    src[1].y = cutRect.origin.y;
    src[2].x = cutRect.origin.x + cutRect.size.width;
    src[2].y = cutRect.origin.y + cutRect.size.height;
    src[3].x = cutRect.origin.x;
    src[3].y = cutRect.origin.y + cutRect.size.height;

    dst[0].x = 0;
    dst[0].y = 0;
    dst[1].x = 32;
    dst[1].y = 0;
    dst[2].x = 32;
    dst[2].y = 256;
    dst[3].x = 0;
    dst[3].y = 256;

//    cv::Mat transform = cv::getPerspectiveTransform(src, dst);
//    cv::warpPerspective(orig_img, outputMat, transform, cvSize(32, 256));
    
    cv::drawContours(orig_img, contours, 0, cv::Scalar(0,0,255), 2);
//
    return [UIImage imageWithCVMat:orig_img];
    
//    return [self imageRotatedByDegrees:90 withImage:[self tailoringImage:image Area:cutRect]];
}

+ (UIImage *)perspectiveWithUIImage:(UIImage *)image {
    
    cv::Mat inputMat;
    cv::Mat outputMat;
    cv::Mat tmp;
    
    inputMat = [image cvMatImage];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    float x = [[defaults objectForKey:@"cutRect_x"] floatValue];
    float y = [[defaults objectForKey:@"cutRect_y"] floatValue];
    float width = [[defaults objectForKey:@"cutRect_width"] floatValue];
    float height = [[defaults objectForKey:@"cutRect_height"] floatValue];
    CGRect cutRect = CGRectMake(x, y, width, height);
    
    cv::Point2f src[4], dst[4];
    src[0].x = cutRect.origin.x;
    src[0].y = cutRect.origin.y;
    src[1].x = cutRect.origin.x + cutRect.size.width;
    src[1].y = cutRect.origin.y;
    src[2].x = cutRect.origin.x + cutRect.size.width;
    src[2].y = cutRect.origin.y + cutRect.size.height;
    src[3].x = cutRect.origin.x;
    src[3].y = cutRect.origin.y + cutRect.size.height;

    dst[0].x = 0;
    dst[0].y = 0;
    dst[1].x = 32;
    dst[1].y = 0;
    dst[2].x = 32;
    dst[2].y = 256;
    dst[3].x = 0;
    dst[3].y = 256;

    cv::Mat transform = cv::getPerspectiveTransform(src, dst);
    cv::warpPerspective(inputMat, outputMat, transform, cvSize(32, 256));
    
    return [self imageRotatedByDegrees:90 withImage:[UIImage imageWithCVMat:outputMat]];
    
}

/**
 裁剪图片方法
 */
+ (UIImage* )tailoringImage:(UIImage*)img Area:(CGRect)area{
    CGImageRef sourceImageRef = [img CGImage];//将UIImage转换成CGImageRef
    CGRect rect = CGRectMake(area.origin.x, area.origin.y, area.size.width, area.size.height);
    CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, rect);//按照给定的矩形区域进行剪裁
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    return newImage;
}

/**
 旋转图片

 @param degrees 旋转角度
 */
+ (UIImage *)imageRotatedByDegrees:(CGFloat)degrees withImage:(UIImage *)aImage {
    
    // calculate the size of the rotated view's containing box for our drawing space
    UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0,aImage.size.width, aImage.size.height)];
    CGAffineTransform t = CGAffineTransformMakeRotation(degrees * M_PI/180);
    rotatedViewBox.transform = t;
    CGSize rotatedSize = rotatedViewBox.frame.size;
    rotatedViewBox = nil;
    
    // Create the bitmap context
    UIGraphicsBeginImageContextWithOptions(rotatedSize, NO, 0.0);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    
    // Move the origin to the middle of the image so we will rotate and scale around the center.
    CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
    
    //   // Rotate the image context
    CGContextRotateCTM(bitmap, (degrees * M_PI/180));
    
    // Now, draw the rotated/scaled image into the context
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-aImage.size.width / 2, -aImage.size.height / 2, aImage.size.width, aImage.size.height), aImage.CGImage);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
    
}

cv::Mat ProcessOutputWithFloatModel(NSArray* input) {
    int _outputWidth;
    int _outputHeight;
    int _outputChannels;
  if (BarCodeModel) {
      _outputWidth = 448;
      _outputHeight = 320;
      _outputChannels = 1;
  } else {
      
      _outputWidth = 320;
      _outputHeight = 448;
      _outputChannels = 1;
  }
  cv::Mat image = cv::Mat::zeros(_outputHeight, _outputWidth, CV_8UC3);
  for (int y = 0; y < _outputHeight; ++y) {
    for (int x = 0; x < _outputWidth; ++x) {
      float input_pixel = [input[(y * _outputWidth * _outputChannels) + (x * _outputChannels)] floatValue];
      cv::Vec3b & color = image.at<cv::Vec3b>(cv::Point(x, y));
      color[0] = (uchar) floor(input_pixel * 255.0f);
      color[1] = (uchar) floor(input_pixel * 255.0f);
      color[2] = (uchar) floor(input_pixel * 255.0f);
    }
  }
  return image;
}
@end
