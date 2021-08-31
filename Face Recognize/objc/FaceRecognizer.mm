//
//  FaceRecognizer.mm
//  Face Recognize
//
//  Created by John Smith on 2021/8/20.
//



#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#include <dlib/dnn.h>
#import <dlib/image_processing.h>
#import <dlib/image_processing/frontal_face_detector.h>
#import <dlib/image_processing/render_face_detections.h>
#import <dlib/opencv.h>
#import "FaceRecognizer.h"
#import <stdio.h>

#define MIN_IMG_SIZE 400.0
#define MIN_SOBEL_VALUE 2.0
#define MIN_BRIGHTNESS_VALUE 80
#define MAX_BRIGHTNESS_VALUE 200

using namespace dlib;
using namespace std;

template <template <int,template<typename>class,int,typename> class block, int N, template<typename>class BN, typename SUBNET>
using residual = add_prev1<block<N,BN,1,tag1<SUBNET>>>;

template <template <int,template<typename>class,int,typename> class block, int N, template<typename>class BN, typename SUBNET>
using residual_down = add_prev2<avg_pool<2,2,2,2,skip1<tag2<block<N,BN,2,tag1<SUBNET>>>>>>;

template <int N, template <typename> class BN, int stride, typename SUBNET>
using block  = BN<con<N,3,3,1,1,relu<BN<con<N,3,3,stride,stride,SUBNET>>>>>;

template <int N, typename SUBNET> using ares      = relu<residual<block,N,affine,SUBNET>>;
template <int N, typename SUBNET> using ares_down = relu<residual_down<block,N,affine,SUBNET>>;

template <typename SUBNET> using alevel0 = ares_down<256,SUBNET>;
template <typename SUBNET> using alevel1 = ares<256,ares<256,ares_down<256,SUBNET>>>;
template <typename SUBNET> using alevel2 = ares<128,ares<128,ares_down<128,SUBNET>>>;
template <typename SUBNET> using alevel3 = ares<64,ares<64,ares<64,ares_down<64,SUBNET>>>>;
template <typename SUBNET> using alevel4 = ares<32,ares<32,ares<32,SUBNET>>>;

using ResNet = loss_metric<fc_no_bias<128,avg_pool_everything<
                            alevel0<
                            alevel1<
                            alevel2<
                            alevel3<
                            alevel4<
                            max_pool<3,3,2,2,relu<affine<con<32,7,7,2,2,
                            input_rgb_image_sized<150>
                            >>>>>>>>>>>>;
@implementation FaceFeatures
@end

@implementation FaceRecognizer
FaceRecognizer *mFaceRecognizer;
dlib::shape_predictor sp;
ResNet net;
+ (FaceRecognizer *) shared {
    if(!mFaceRecognizer) {
        mFaceRecognizer = [FaceRecognizer new];
        NSString *landmarkPath = [[NSBundle mainBundle] pathForResource:@"shape_predictor_68_face_landmarks" ofType:@"dat"];
        std::string landmarkFileString = [landmarkPath UTF8String];
        NSString *resnetModelPath = [[NSBundle mainBundle] pathForResource:@"dlib_face_recognition_resnet_model_v1" ofType:@"dat"];
        std::string resnetFileString = [resnetModelPath UTF8String];
        deserialize(landmarkFileString) >> sp;
        deserialize(resnetFileString) >> net;
    }
    return mFaceRecognizer;
}

- (struct ImageQualityResult) checkImageQuality: (UIImage *) img {
    cv::Mat src;
    UIImageToMat(img, src);
    cv::cvtColor(src, src, cv::COLOR_RGB2BGR);
    struct ImageQualityResult result = {false, 0, 0, 0};
    result.minSize = MIN(src.cols, src.rows);
    if (result.minSize < MIN_IMG_SIZE) {
        result.passed = false;
        return result;
    }
    //若尺寸是符合规定的，再将图片根据长高的比例，保持原图比例缩小较短的一边的长度为 480 像素。
    resizeImg(src);
    cv::Mat gray;
    //转为灰度
    cv::cvtColor(src, gray, cv::COLOR_BGR2GRAY);
    //检测清晰度
    result.blur = checkImageQualityBlur(gray);
    //如果小于设定的平均值，则判定为不够清晰。经过实践，该分辨率下，取2.5是比较合理的值。
    if (result.blur < MIN_SOBEL_VALUE) {
        result.passed = false;
        return result;
    }
    result.brightness = checkImageBriteness(src);
    //如果平均亮度在规定范围以外，择判定为过暗或过量。经过实践，范围定在80-200是比较理想的亮度值。
    if (result.brightness < MIN_BRIGHTNESS_VALUE || result.brightness > MAX_BRIGHTNESS_VALUE) {
        result.passed = false;
        return result;
    }
    result.passed = true;
    return result;
}

void resizeImg(cv::Mat &img) {
    int newWidth, newHeight;
    double ratio = img.cols * 1.0 / img.rows * 1.0; //图片长高比
    if (ratio > 1) {
        newHeight = MIN_IMG_SIZE;
        newWidth = MIN_IMG_SIZE * ratio;
    } else {
        newWidth = MIN_IMG_SIZE;
        newHeight = MIN_IMG_SIZE / ratio;
    }
    cv::resize(img, img, cv::Size(newWidth, newHeight));
    cv::cvtColor(img, img, cv::COLOR_RGBA2BGR);
}


double checkImageQualityBlur(cv::Mat &img) {
    cv::Mat sobel;
    //Tenengrad梯度方法利用Sobel算子分别计算水平和垂直方向的梯度，梯度值越高，图像越清晰。
    cv::Sobel(img, sobel, CV_16U, 1, 1);
    //图像的平均梯度值
    double meanValue = cv::mean(sobel)[0];
    return meanValue;
}

double checkImageBriteness(cv::Mat &img) {
    cv::Mat hsvImg;
    //将图像转换为HSV色彩空间，提取亮度信息。
    cv::cvtColor(img, hsvImg, cv::COLOR_BGR2HSV);
    //计算hsv中的亮度平均值
    double meanValue = cv::mean(hsvImg)[2];
    return meanValue;
}

// 特征提取
- (FaceFeatures *) genFeatures: (UIImage *) img withFaceRect: (CGRect) rect {
    cv::Mat src;
    UIImageToMat(img, src);
    cv::cvtColor(src, src, cv::COLOR_RGBA2BGR);
    dlib::array2d<dlib::bgr_pixel> dlibImage;
    dlib::assign_image(dlibImage, dlib::cv_image<dlib::bgr_pixel>(src));
    long left = rect.origin.x;
    long top = rect.origin.y;
    long right = left + rect.size.width;
    long bottom = top + rect.size.height;
    dlib::rectangle det(left, top, right, bottom);
    dlib::full_object_detection shape = sp(dlibImage, det);
    NSMutableArray *landmarks = [NSMutableArray array];
    for (int i = 0; i < shape.num_parts(); i++) {
        dlib::point p = shape.part(i);
        CGPoint point = CGPointMake(p.x(), p.y());
        NSValue *pValue = [NSValue valueWithCGPoint:point];
        [landmarks addObject:pValue];
    }
    matrix<rgb_pixel> face_chip;
    extract_image_chip(dlibImage, get_face_chip_details(shape,150,0.25), face_chip);
    //图片和特征点坐标传入网络，获得 face_descriptor
    matrix<float,0,1> face_descriptor = net(move(face_chip));
    NSMutableArray *features = [NSMutableArray array];
    for (auto value : face_descriptor) {
        NSNumber *num = [NSNumber numberWithDouble:value];
        [features addObject:num];
    }
    FaceFeatures *faceFeatures = [FaceFeatures new];
    faceFeatures.features = features;
    faceFeatures.landmarks = landmarks;
    return faceFeatures;
}

- (double) calcDistance: (NSArray *) f1 with: (NSArray *) f2 {
    matrix<float,0,1> fd1, fd2;
    fd1.set_size(128);
    fd2.set_size(128);
    for (int i = 0; i < f1.count; i++) {
        fd1(i) = [f1[i] doubleValue];
        fd2(i) = [f2[i] doubleValue];
    }
    return length(fd1 - fd2);
}

- (UIImage *) enhanceImage: (UIImage *) img {
    cv::Mat src;
    UIImageToMat(img, src);
    resizeImg(src);
    cv::medianBlur(src, src, 3);
    cv::Mat sharpen_op = (cv::Mat_<char>(3, 3) <<
                          0, -1, 0,
                          -1, 5, -1,
                          0, -1, 0);
    filter2D(src, src, CV_32F, sharpen_op);
    convertScaleAbs(src, src);
    cv::cvtColor(src, src, cv::COLOR_BGR2RGB);
    return MatToUIImage(src);
}
@end
