//
//  AACollageMaker.h
//  PhotoCollage
//
//  Created by Azat Almeev on 02.03.15.
//  Copyright (c) 2015 Azat Almeev. All rights reserved.
//

#import <Foundation/Foundation.h>
#define kMaxImagesInCollage 10 //5
#define kMinImagesInCollection 3

@interface AACollageMaker : NSObject

// returns @[ CGSize, NSInteger, CGFloat ]
+ (NSArray *)resultSizeForViewsWithSizes:(NSArray *)sizes
                         widthConstraint:(CGFloat)widthConstraint
                        heightConstraint:(CGFloat)heightConstraint
                            imagesMargin:(CGFloat)imagesMargin;

+ (NSArray *)rectsForViewsWithSizes:(NSArray *)sizes
                    widthConstraint:(CGFloat)widthConstraint
                   heightConstraint:(CGFloat)heightConstraint;

+ (NSArray *)rectsForViewsWithSizes:(NSArray *)sizes
                    widthConstraint:(CGFloat)widthConstraint
                   heightConstraint:(CGFloat)heightConstraint
                          totalSize:(NSValue **)totalSize;

@end
