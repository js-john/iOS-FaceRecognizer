//
//  FaceRecognizer.h
//  Face Recognize
//
//  Created by John Smith on 2021/8/20.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

struct ImageQualityResult {
    bool passed;
    double brightness;
    double blur;
    int minSize;
};


@interface FaceFeatures: NSObject
@property(strong, nonatomic) NSArray *landmarks;
@property(strong, nonatomic) NSArray *features;
@end


@interface FaceRecognizer : NSObject
+ (FaceRecognizer *) shared;
- (struct ImageQualityResult) checkImageQuality: (UIImage *) img;
- (UIImage *) enhanceImage: (UIImage *) img;
- (FaceFeatures *) genFeatures: (UIImage *) img withFaceRect: (CGRect) rect;
- (double) calcDistance: (NSArray *) f1 with: (NSArray *) f2;
@end

NS_ASSUME_NONNULL_END
