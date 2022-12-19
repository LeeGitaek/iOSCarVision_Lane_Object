//
//  LaneDetector.cpp
//  BVision
//
//  Created by gitaeklee on 12/6/22.
//

#ifdef __cplusplus
#undef NO
#undef YES
#import <opencv2/opencv.hpp>
#include <numeric>
#include <opencv2/core.hpp>
#include <opencv2/imgcodecs.hpp>
#include <opencv2/imgproc.hpp>
#include <opencv2/highgui.hpp>
#include <iostream>
#include <string>
#include <vector>
#include "LaneDetector.hpp"
#endif

float vectorAverage(vector<float> input_vec){
    float average = accumulate(input_vec.begin(), input_vec.end(), 0.0)/input_vec.size();
    return average;
}

double getAverage(vector<double> vector, int nElements) {
    
    double sum = 0;
    int initialIndex = 0;
    int last30Lines = int(vector.size()) - nElements;
    if (last30Lines > 0) {
        initialIndex = last30Lines;
    }
    
    for (int i=(int)initialIndex; i<vector.size(); i++) {
        sum += vector[i];
    }
    
    int size;
    if (vector.size() < nElements) {
        size = (int)vector.size();
    } else {
        size = nElements;
    }
    return (double)sum/size;
}

Mat LaneDetector::hough_lines(Mat img, double rho, double theta, int threshold, double min_line_len,double max_line_gap){
    vector<Vec4f> lines;
    Mat line_img(img.rows, img.cols, CV_8UC3, Scalar(0,0,0));
    HoughLinesP(img, lines, rho, theta, threshold, min_line_len, max_line_gap);
    draw_lines(line_img, lines);
    return line_img;
}

Mat LaneDetector::lineDetect(Mat img){
    return hough_lines(img, 1, CV_PI/180, 15, 10, 20);
}

Mat LaneDetector::grayscale(Mat img) {
    Mat gray_img;
    cvtColor(img, gray_img, COLOR_BGR2GRAY);
    return gray_img;
}

Mat LaneDetector::canny(Mat img){
    Mat edges;
    Canny(grayscale(img), edges, 50, 150);
    return edges;
}

Mat LaneDetector::detect_edges(Mat image) {
    
    Mat greyScaledImage;
    cvtColor(image, greyScaledImage, COLOR_RGB2GRAY);
    
    Mat edgedOnlyImage;
    Canny(greyScaledImage, edgedOnlyImage, 50, 120);
    
    return edgedOnlyImage;
}

bool isDayTime(Mat image)
{
    Scalar s = mean(image); // Mean pixel values
    if (s[0] < 30 || (s[1] < 33 && s[2] < 30))
    {
        return false;
    }
    return true;
}

Mat LaneDetector::colorFilter(Mat src){
    Mat hsv, whiteMask, whiteImage, yellowMask, yellowImage, whiteYellow;
    
    vector< int > lowerWhite = {130, 130, 130};
    vector< int > upperWhite = {255, 255, 255};
    inRange(src, lowerWhite, upperWhite, whiteMask);
    bitwise_and(src, src, whiteImage, whiteMask);

    cvtColor(src, hsv, COLOR_BGR2HSV);
    vector< int > lowerYellow = {20, 100, 110};
    vector< int > upperYellow = {30, 180, 240};
    inRange(hsv, lowerYellow, upperYellow, yellowMask);
    bitwise_and(src, src, yellowImage, yellowMask);
    
    addWeighted(whiteImage, 1., yellowImage, 1., 0., whiteYellow);
    
    if (!isDayTime)
    {
        Mat grayMask, grayImage, grayAndWhite, dst;
        vector< int > lowerGray = {80, 80, 80};
        vector< int > upperGray = {130, 130, 130};
        inRange(src, lowerGray, upperGray, grayMask);
        bitwise_and(src, src, grayImage, grayMask);
        addWeighted(grayImage, 1., whiteYellow, 1., 0., dst);
        return dst;
    }
    return whiteYellow;
}

Mat LaneDetector::draw_lines(Mat image, vector<Vec4f> lines) {
   
    Scalar right_color = Scalar(255, 255, 255);
    Scalar left_color = Scalar(255, 255, 255);
    
    vector<float> rightSlope, leftSlope, rightIntercept, leftIntercept;
    vector<float> slopes;
    vector<Vec4i> goodLines;
    
    float slopeThreshold = 0.5;
    
    for (Vec4f line : lines) {
        float x1 = line[0];
        float y1 = line[1];
        float x2 = line[2];
        float y2 = line[3];
        float slope = (y2-y1) / (x2/x1);
        
        if (abs(slope) > 0.5){
            slopes.push_back(slope);
            goodLines.push_back(line);
        }
    };
    
    vector<Vec4i> rightLines;
    vector<Vec4i> leftLines;
    
    int imgCenter = image.cols / 2;
    
    for (int i = 0; i < slopes.size(); i++) {
        if (slopes[i] > 0 && goodLines[i][0] > imgCenter && goodLines[i][2] > imgCenter)
        {
            rightLines.push_back(goodLines[i]);
        }
        if (slopes[i] < 0 && goodLines[i][0] < imgCenter && goodLines[i][2] < imgCenter)
        {
            leftLines.push_back(goodLines[i]);
        }
    }
    
    vector<int> rightLinesX;
    vector<int> rightLinesY;
    
    double rightB1, rightB0;
    // Slope and intercept
    
    for (int i = 0; i < rightLines.size(); i++) {
        rightLinesX.push_back(rightLines[i][0]); // X of starting point of line
        rightLinesX.push_back(rightLines[i][2]); // X of ending point of line
        rightLinesY.push_back(rightLines[i][1]); // Y of starting point of line
        rightLinesY.push_back(rightLines[i][3]); // Y of ending point of line
    }
    
    if (rightLinesX.size() > 0) {
        vector< double > coefRight = estimateCoefficients<int, double>(rightLinesX, rightLinesY); // y = b1x + b0
        rightB1 = coefRight[0];
        rightB0 = coefRight[1];
    } else {
        rightB1 = 1;
        rightB0 = 1;
    }
    
    // Now the points at the left side
    vector< int > leftLinesX;
    vector< int > leftLinesY;
    double leftB1, leftB0;
    // Slope and intercept
    
    for (int i = 0; i < leftLines.size(); i++) {
        leftLinesX.push_back(leftLines[i][0]); // X of starting point of line
        leftLinesX.push_back(leftLines[i][2]); // X of ending point of line
        leftLinesY.push_back(leftLines[i][1]); // Y of starting point of line
        leftLinesY.push_back(leftLines[i][3]); // Y of ending point of line
    }
    
    if (leftLinesX.size() > 0) {
        vector< double > coefLeft = estimateCoefficients<int, double>(leftLinesX, leftLinesY); // y = b1x + b0
        leftB1 = coefLeft[0];
        leftB0 = coefLeft[1];
    } else {
        leftB1 = 1;
        leftB0 = 1;
    }
    
    float left_intercept_avg = leftB0;
    float right_intercept_avg = rightB0;
    float left_slope_avg = leftB1;
    float right_slope_avg = rightB1;
    
    // cout << "slope and intercept:" << leftB0 << "," << rightB0 << "," << leftB1 << "," << rightB1 << endl;
    // 1084.37, 323.696, -0.455908, 0.751375
    // slope and intercept: 1116.48,149.921,-0.59924,0.972521

    int left_line_x1 = (int)round((0.5*image.rows - left_intercept_avg)/left_slope_avg);
    int left_line_x2 = (int)round((0.4*image.rows - left_intercept_avg)/left_slope_avg);
    int right_line_x1 = (int)round((0.5*image.rows - right_intercept_avg)/right_slope_avg);
    int right_line_x2 = (int)round((0.4*image.rows - right_intercept_avg)/right_slope_avg);
    
    // cout << "line: " << left_line_x1 << "," << left_line_x2 << "," << right_line_x1 << "," << right_line_x2 << endl;
    // line: 261,742,833,537
    Point line_vertices[1][4];
    line_vertices[0][0] = Point(left_line_x1, int(0.5*image.rows));
    line_vertices[0][1] = Point(left_line_x2, int(0.4*image.rows));
    line_vertices[0][2] = Point(right_line_x2, int(0.4*image.rows));
    line_vertices[0][3] = Point(right_line_x1, int(0.5*image.rows));

    // cout << "point: " << line_vertices[0][0] << "," << line_vertices[0][1]  << "," << line_vertices[0][2] << "," << line_vertices[0][3] << endl;
    
    const Point* inner_shape[1] = { line_vertices[0] };
    int n_vertices[] = { 4 };
    int lineType = LINE_8;

    Scalar fillColor(0, 255, 0);
    fillPoly(image, inner_shape, n_vertices, 1, fillColor, lineType);

    return image;

}

Mat LaneDetector::crop_region_of_interest(Mat image) {
    int x = image.cols;
    int y = image.rows;
    
    Point polygon_vertices[1][4];
    polygon_vertices[0][0] = Point(0, 0.6*y);
    polygon_vertices[0][1] = Point(x, 0.6*y);
    polygon_vertices[0][2] = Point((int)(0.55 * x), (int)(0.3 * y));
    polygon_vertices[0][3] = Point((int)(0.45 * x), (int)(0.3 * y));

    const Point* polygons[1] = { polygon_vertices[0] };
    int n_vertices[] = { 4 };
    int numberOfPolygons = 1;
    Mat mask(y, x, CV_8UC1, Scalar(0));
    int lineType = LINE_8;
    fillPoly(mask,polygons,n_vertices,1, Scalar(255,255,255),lineType);
    Mat masked_image;
    bitwise_and(image, image, masked_image, mask=mask);
    return masked_image;
}

cv::Mat weightedImage(Mat img, Mat initial_img, double alpha = 0.8, double beta=1.0, double gamma = 0.0){
    Mat weighted_img;
    addWeighted(img, alpha, initial_img, beta, gamma, weighted_img);
    return weighted_img;
}

Mat LaneDetector::detect_lane(Mat image) {
    
    Mat colorFilteredImage = colorFilter(image);
    Mat regionOfInterest = crop_region_of_interest(colorFilteredImage);
    Mat cannyImage = canny(regionOfInterest);
    Mat houghImage = lineDetect(cannyImage);
    Mat finalImage = weightedImage(houghImage, image);
    
    vector<Vec4f> lines;
    return draw_lines(finalImage, lines);
}
