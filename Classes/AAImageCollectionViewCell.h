//
//  AAImageCollectionViewCell.h
//  AACollageView
//
//  Created by Azat Almeev on 02.04.15.
//  Copyright (c) 2015 Azat Almeev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AAImageCollectionViewCell : UICollectionViewCell
@property (nonatomic, readonly) UIImageView *imageView;
+ (NSString *)identifier;
@end
