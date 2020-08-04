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
    double threshold = 0.8;
    double threshold_level = int(255*threshold);
    
    float tl_x = 0.0;
    float tl_y = 0.0;
    float bl_x = 0.0;
    float bl_y = 0.0;
    float tr_x = 0.0;
    float tr_y = 0.0;
    float br_x = 0.0;
    float br_y = 0.0;
    
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
                
                contours[i][j].x = contours[i][j].x * grid_size;
                contours[i][j].y = contours[i][j].y * grid_size;
            }
        }
        
        cv::RotatedRect rect = cv::minAreaRect(contours[i]);
        
        cv::boxPoints(rect, box);
        
        tl_x = box.row(1).col(0).at<float>(0,0);
        tl_y = box.row(1).col(1).at<float>(0,0);
        bl_x = box.row(0).col(0).at<float>(0,0);
        bl_y = box.row(0).col(1).at<float>(0,0);
        tr_x = box.row(2).col(0).at<float>(0,0);
        tr_y = box.row(2).col(1).at<float>(0,0);
        br_x = box.row(3).col(0).at<float>(0,0);
        br_y = box.row(3).col(1).at<float>(0,0);
        
        NSValue *tl = [NSValue valueWithCGPoint:CGPointMake(tl_x, tl_y)];
        NSValue *bl = [NSValue valueWithCGPoint:CGPointMake(bl_x, bl_y)];
        NSValue *tr = [NSValue valueWithCGPoint:CGPointMake(tr_x, tr_y)];
        NSValue *br = [NSValue valueWithCGPoint:CGPointMake(br_x, br_y)];
        
        NSArray *arr = [NSArray arrayWithObjects:tl,bl,tr,br, nil];
        
        //排序四个顶点位置 左上-右上-右下-左下
        NSArray *sortArr = [arr sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            
            CGPoint value1 = [obj1 CGPointValue];
            CGPoint value2 = [obj2 CGPointValue];
            
            if (value1.x < value2.x) {
                return NSOrderedAscending;
            }else{
                return NSOrderedDescending;
            }
        }];
        
        CGPoint left1 = [sortArr[0] CGPointValue];
        CGPoint left2 = [sortArr[1] CGPointValue];
        if (left1.y < left2.y) {
            tl_x = left1.x;
            tl_y = left1.y;
            bl_x = left2.x;
            bl_y = left2.y;
        }else {
            
            tl_x = left2.x;
            tl_y = left2.y;
            bl_x = left1.x;
            bl_y = left1.y;
        }
        
        CGPoint right1 = [sortArr[2] CGPointValue];
        CGPoint right2 = [sortArr[3] CGPointValue];
        if (right1.y < right2.y) {
            tr_x = right1.x;
            tr_y = right1.y;
            br_x = right2.x;
            br_y = right2.y;
        }else {
            
            tr_x = right2.x;
            tr_y = right2.y;
            br_x = right1.x;
            br_y = right1.y;
        }
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setFloat:tl_x forKey:@"tl_x"];
        [defaults setFloat:tl_y forKey:@"tl_y"];
        [defaults setFloat:bl_x forKey:@"bl_x"];
        [defaults setFloat:bl_y forKey:@"bl_y"];
        [defaults setFloat:tr_x forKey:@"tr_x"];
        [defaults setFloat:tr_y forKey:@"tr_y"];
        [defaults setFloat:br_x forKey:@"br_x"];
        [defaults setFloat:br_y forKey:@"br_y"];
        
        std::cout << box.size() << std::endl;
        std::cout << "boxPts " << std::endl << " " << box << std::endl;
        
    }
    
//    cv::rectangle(orig_img,cvPoint(cutRect.origin.x,cutRect.origin.y),cvPoint(cutRect.origin.x + cutRect.size.width , cutRect.origin.y + cutRect.size.height),cv::Scalar(0,0,255), 2);
//    cv::drawContours(orig_img, contours, 0, cv::Scalar(0,0,255), 2);
    
    std::vector<cv::Point> vList;
    vList.push_back(cv::Point(tl_x, tl_y));// 点0
    vList.push_back(cv::Point(tr_x, tr_y));// 点1
    vList.push_back(cv::Point(br_x, br_y));// 点2
    vList.push_back(cv::Point(bl_x, bl_y));// 点3
    
    cv::polylines(orig_img, vList, true, cv::Scalar(0,0,255), 2);
    return [UIImage imageWithCVMat:orig_img];
    
//    return [self imageRotatedByDegrees:90 withImage:[self tailoringImage:image Area:cutRect]];
}

+ (UIImage *)perspectiveWithUIImage:(UIImage *)image {
    
    cv::Mat inputMat;
    cv::Mat outputMat;
    cv::Mat tmp;
    
    inputMat = [image cvMatImage];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    float tl_x = [[defaults objectForKey:@"tl_x"] floatValue];
    float tl_y = [[defaults objectForKey:@"tl_y"] floatValue];
    float bl_x = [[defaults objectForKey:@"bl_x"] floatValue];
    float bl_y = [[defaults objectForKey:@"bl_y"] floatValue];
    float tr_x = [[defaults objectForKey:@"tr_x"] floatValue];
    float tr_y = [[defaults objectForKey:@"tr_y"] floatValue];
    float br_x = [[defaults objectForKey:@"br_x"] floatValue];
    float br_y = [[defaults objectForKey:@"br_y"] floatValue];
    
    cv::Point2f src[4], dst[4];
    src[0].x = tl_x;
    src[0].y = tl_y;
    src[1].x = tr_x;
    src[1].y = tr_y;
    src[2].x = br_x;
    src[2].y = br_y;
    src[3].x = bl_x;
    src[3].y = bl_y;

    if ((tr_x - tl_x) > (bl_y - tl_y)) {
        
        dst[0].x = 0;
        dst[0].y = 0;
        dst[1].x = OCR_OUTPUT_LONG;
        dst[1].y = 0;
        dst[2].x = OCR_OUTPUT_LONG;
        dst[2].y = OCR_OUTPUT_SHORT;
        dst[3].x = 0;
        dst[3].y = OCR_OUTPUT_SHORT;

        cv::Mat transform = cv::getPerspectiveTransform(src, dst);
        cv::warpPerspective(inputMat, outputMat, transform, cvSize(OCR_OUTPUT_LONG, OCR_OUTPUT_SHORT));
        
//        float leftHeight = sqrtf((tl_x - bl_x) * (tl_x - bl_x) + (tl_y - bl_y) * (tl_y - bl_y));
//        float rightHeight = sqrtf((tr_x - br_x) * (tr_x - br_x) + (tr_y - br_y) * (tr_y - br_y));
//        float outputHeight = 0.0;
//        float outputWidth = 0.0;
//        float scale = 0.0;
//        if (leftHeight < rightHeight) {
//            scale = leftHeight / OCR_OUTPUT_SHORT;
//            outputHeight = leftHeight;
//        }else {
//            scale = rightHeight / OCR_OUTPUT_SHORT;
//            outputHeight = rightHeight;
//        }
//        outputWidth = scale * OCR_OUTPUT_LONG;
//
//        dst[0].x = 0;
//        dst[0].y = 0;
//        dst[1].x = outputWidth;
//        dst[1].y = 0;
//        dst[2].x = outputWidth;
//        dst[2].y = outputHeight;
//        dst[3].x = 0;
//        dst[3].y = outputHeight;
//
//        cv::Mat transform = cv::getPerspectiveTransform(src, dst);
//        cv::warpPerspective(inputMat, outputMat, transform, cvSize(outputWidth, outputHeight));
        
        cv::cvtColor(outputMat, tmp, CV_BGR2RGB);
        outputMat = tmp;
        
        return [UIImage imageWithCVMat:outputMat];
        
    } else {
        
        dst[0].x = 0;
        dst[0].y = 0;
        dst[1].x = OCR_OUTPUT_SHORT;
        dst[1].y = 0;
        dst[2].x = OCR_OUTPUT_SHORT;
        dst[2].y = OCR_OUTPUT_LONG;
        dst[3].x = 0;
        dst[3].y = OCR_OUTPUT_LONG;

        cv::Mat transform = cv::getPerspectiveTransform(src, dst);
        cv::warpPerspective(inputMat, outputMat, transform, cvSize(OCR_OUTPUT_SHORT, OCR_OUTPUT_LONG));
        
//        float topWidth = sqrtf((tl_x - tr_x) * (tl_x - tr_x) + (tl_y - tr_y) * (tl_y - tr_y));
//        float bottomWidth = sqrtf((bl_x - br_x) * (bl_x - br_x) + (bl_y - br_y) * (bl_y - br_y));
//        float outputHeight = 0.0;
//        float outputWidth = 0.0;
//        float scale = 0.0;
//        if (topWidth < bottomWidth) {
//            scale = topWidth / OCR_OUTPUT_SHORT;
//            outputWidth = topWidth;
//        }else {
//            scale = bottomWidth / OCR_OUTPUT_SHORT;
//            outputWidth = bottomWidth;
//        }
//        outputHeight = scale * OCR_OUTPUT_LONG;
//
//        dst[0].x = 0;
//        dst[0].y = 0;
//        dst[1].x = outputWidth;
//        dst[1].y = 0;
//        dst[2].x = outputWidth;
//        dst[2].y = outputHeight;
//        dst[3].x = 0;
//        dst[3].y = outputHeight;
//
//        cv::Mat transform = cv::getPerspectiveTransform(src, dst);
//        cv::warpPerspective(inputMat, outputMat, transform, cvSize(outputWidth, outputHeight));
        
        cv::cvtColor(outputMat, tmp, CV_BGR2RGB);
        outputMat = tmp;
        
        return [self imageRotatedByDegrees:90 withImage:[UIImage imageWithCVMat:outputMat]];
    }
    
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
