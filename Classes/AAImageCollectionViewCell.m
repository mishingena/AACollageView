//
//  AAImageCollectionViewCell.m
//  AACollageView
//
//  Created by Azat Almeev on 02.04.15.
//  Copyright (c) 2015 Azat Almeev. All rights reserved.
//

#import "AAImageCollectionViewCell.h"

@implementation AAImageCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    UIImageView *imgView = [[UIImageView alloc] init];
    imgView.frame = self.bounds;
    imgView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    imgView.tag = 1;
    [self addSubview:imgView];
    return self;
}

- (UIImageView *)imageView {
    return (UIImageView *)[self viewWithTag:1];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
}

+ (NSString *)identifier {
    return @"AAImageCollectionViewCellReuseIdentifier";
}

@end
