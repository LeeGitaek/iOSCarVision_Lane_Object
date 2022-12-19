//
//  LaneDetector.hpp
//  BVision
//
//  Created by gitaeklee on 12/6/22.
//

#ifndef LaneDetector_hpp
#define LaneDetector_hpp

#ifdef __cplusplus
#undef NO
#undef YES
#import <opencv2/opencv.hpp>
#include <iostream>
#include <string>
#include <vector>
#include "regression.h"
#endif

using namespace cv;
using namespace std;

class LaneDetector {
public:
    
    /*
     Returns image with lane overlay
     */
    Mat detect_lane(Mat image);
    
private:

    Mat colorFilter(Mat src);
    /*
     Filters yellow and white colors on image
     */
    Mat filter_only_yellow_white(Mat image);
    
    /*
     Crops region where lane is most likely to be.
     Maintains image original size with the rest of the image blackened out.
     */
    Mat crop_region_of_interest(Mat image);
    
    /*
     Draws road lane on top image
     */
    Mat draw_lines(Mat image, vector<Vec4f> lines);
    Mat hough_lines(Mat img, double rho, double theta, int threshold, double min_line_len,double max_line_gap);
    Mat lineDetect(Mat img);
    Mat grayscale(Mat img);
    Mat canny(Mat img);
    
    /*
     Detects road lanes edges
     */
    Mat detect_edges(Mat image);

};

#endif /* LaneDetector_hpp */
