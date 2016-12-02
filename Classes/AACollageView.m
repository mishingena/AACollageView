//
//  AACollageView.m
//  PhotoCollage
//
//  Created by Azat Almeev on 02.03.15.
//  Copyright (c) 2015 Azat Almeev. All rights reserved.
//

#import "AACollageView.h"
#import "AACollageMaker.h"
#import <BlocksKit/BlocksKit.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "AAImageCollectionViewCell.h"

@interface AACollageView () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout> {
    CGFloat _imagesMargin;
    CGFloat _heightConstraint;
    CGFloat _widthConstraint;
    NSInteger _collectionViewItemsCount;
    CGFloat _collectionViewHeight;
    NSArray *_preCalculatedFrames;
}
@property (readonly) BOOL assignedPropertiesAreCorrect;
@property (readonly) NSArray *imagesSizesArray;
@end

@implementation AACollageView
@synthesize imagesSizesArray = _imagesSizesArray;

#define kIncorrectSetup @"Incorrect setup parameters"

- (BOOL)assignedPropertiesAreCorrect {
    if (!_imagesArray && !_delegate)
        return NO;
    if ((_heightConstraint <= 0 && _widthConstraint <= 0) || _imagesMargin < 0)
        @throw [NSException exceptionWithName:kIncorrectSetup reason:@"Constraints setup is incorrect" userInfo:nil];
    if (_imagesArray)
        return YES;
    if (!_delegate)
        @throw [NSException exceptionWithName:kIncorrectSetup reason:@"Should pass either imagesArray or delegate" userInfo:nil];
    if (![_delegate respondsToSelector:@selector(imagesCountInCollageView:)])
        return NO;
    if ([_delegate respondsToSelector:@selector(collageView:imageForIndex:)])
        return YES;
    if (![_delegate respondsToSelector:@selector(collageView:URLForImageAtIndex:withSize:)] || ![_delegate respondsToSelector:@selector(collageView:sizeForImageAtIndex:)])
        @throw [NSException exceptionWithName:kIncorrectSetup reason:@"Delegate should implement either -collageView:imageForIndex: or both of -collageView:URLForImageAtIndex:withSize: and -collageView:sizeForImageAtIndex: methods" userInfo:nil];
    return YES;
}

- (CGSize)collageViewSize {
    if (!self.assignedPropertiesAreCorrect)
        return CGSizeMake(_widthConstraint, _heightConstraint);
    else {
        CGSize innerSize = self.collageViewInnerSize;
        return _collectionViewItemsCount > 0 ? CGSizeMake(innerSize.width, innerSize.height + _collectionViewHeight) : innerSize;
    }
}

- (CGSize)collageViewInnerSize {
    if (!self.assignedPropertiesAreCorrect)
        return CGSizeMake(_widthConstraint, _heightConstraint);
    else {
        NSArray *retVal = [AACollageMaker resultSizeForViewsWithSizes:self.imagesSizesArray widthConstraint:_widthConstraint heightConstraint:_heightConstraint imagesMargin:_imagesMargin];
        _collectionViewItemsCount = [retVal[1] integerValue];
        _collectionViewHeight = [retVal[2] floatValue];
        return [retVal[0] CGSizeValue];
    }
}

- (void)updateCollageVithFrame:(CGRect)frame {
    if (isnan(_heightConstraint))
        _widthConstraint = frame.size.width;
    else if (isnan(_widthConstraint))
        _heightConstraint = frame.size.height;
    [self refreshCollage];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateCollageVithFrame:self.frame];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self updateCollageVithFrame:frame];
}

- (void)setupCollageConstraintsWithMargin:(CGFloat)imagesMargin
                                   height:(CGFloat)heightConstraint
                                  orWidth:(CGFloat)widthConstraint
                           refreshCollage:(BOOL)needRefresh {
    NSAssert((isnan(heightConstraint) ^ isnan(widthConstraint)) == 1, @"Should pass constraint only by one dimension");
    NSAssert((heightConstraint > 0 || widthConstraint > 0) && imagesMargin >= 0, @"Should pass meaningful parameters");
    _imagesMargin = imagesMargin;
    _heightConstraint = heightConstraint;
    _widthConstraint = widthConstraint;
    _imagesSizesArray = nil;
    if (needRefresh)
        [self refreshCollage];
}

- (void)setupCollageWithFrames:(NSArray *)imageFrames
                        margin:(CGFloat)imagesMargin
                refreshCollage:(BOOL)needRefresh {
    _imagesMargin = imagesMargin;
    _heightConstraint = NAN;
    _widthConstraint = 1;
    _imagesSizesArray = nil;
    _preCalculatedFrames = imageFrames;
    if (needRefresh)
        [self refreshCollage];
}

+ (NSArray *)calculatedFramesForImageSizes:(NSArray *)sizes
                           widthConstraint:(CGFloat)widthConstraint
                          heightConstraint:(CGFloat)heightConstraint
                               totalHeight:(NSNumber **)height {
    return [AACollageMaker rectsForViewsWithSizes:sizes widthConstraint:widthConstraint heightConstraint:heightConstraint totalSize:height];
//    return [frames bk_map:^id(id obj) {
//        CGRect rect = [obj CGRectValue];
//        return [NSValue valueWithCGRect:CGRectInset(rect, imagesMargin / 2, imagesMargin / 2)];
//    }];
}

- (void)refreshCollage {
    if (!self.assignedPropertiesAreCorrect)
        return;
    
//    _imagesSizesArray = nil;
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    NSArray *sizesArray = self.imagesSizesArray;
    
    NSArray *frames = _preCalculatedFrames ?: [AACollageMaker rectsForViewsWithSizes:sizesArray widthConstraint:_widthConstraint heightConstraint:_heightConstraint];
    BOOL interactive = [_delegate respondsToSelector:@selector(collageView:didTapAtImageView:atIndex:)];
    [frames enumerateObjectsUsingBlock:^(NSValue *value, NSUInteger idx, BOOL *stop) {
        UIImageView *imgView = [[UIImageView alloc] init];
        if (self.imagesArray)
            imgView.image = self.imagesArray[idx];
        else if ([_delegate respondsToSelector:@selector(collageView:imageForIndex:)])
            imgView.image = [_delegate collageView:self imageForIndex:idx];
        else
            [imgView sd_setImageWithURL:[_delegate collageView:self URLForImageAtIndex:idx withSize:value.CGRectValue.size]];
        imgView.frame = CGRectInset(value.CGRectValue, _imagesMargin / 2, _imagesMargin / 2);
        imgView.tag = idx;
        if (interactive) {
            imgView.userInteractionEnabled = YES;
            UITapGestureRecognizer *rec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecogmiserDidFire:)];
            imgView.gestureRecognizers = @[ rec ];
        }
        [self addSubview:imgView];
    }];
    
    if (/* DISABLES CODE */ (NO) && _collectionViewItemsCount > 0) { //we need add collection view
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, self.collageViewInnerSize.height, _widthConstraint, _collectionViewHeight) collectionViewLayout:UICollectionViewFlowLayout.new];
        [(UICollectionViewFlowLayout *)(collectionView.collectionViewLayout) setScrollDirection:UICollectionViewScrollDirectionHorizontal];
        [collectionView registerClass:AAImageCollectionViewCell.class forCellWithReuseIdentifier:AAImageCollectionViewCell.identifier];
        collectionView.showsHorizontalScrollIndicator = NO;
        collectionView.showsVerticalScrollIndicator = NO;
        collectionView.contentInset = UIEdgeInsetsMake(0, _imagesMargin, 0, _imagesMargin);
        collectionView.dataSource = self;
        collectionView.delegate = self;
        collectionView.backgroundColor = [UIColor clearColor];
        [self addSubview:collectionView];
        [collectionView reloadData];
    }
}

- (NSArray *)imagesSizesArray {
    if (!_imagesSizesArray) {
        if (self.imagesArray)
            _imagesSizesArray = [self.imagesArray bk_map:^id(UIImage *img) {
                return [NSValue valueWithCGSize:img.size];
            }];
        else if ([_delegate respondsToSelector:@selector(imageSizesArrayForCollageview:)])
            _imagesSizesArray = [_delegate imageSizesArrayForCollageview:self];
        else {
            if ([_delegate respondsToSelector:@selector(collageView:imageForIndex:)]) {
                NSMutableArray *sizes = [NSMutableArray new];
                for (NSUInteger index = 0; index < [_delegate imagesCountInCollageView:self]; index++)
                    [sizes addObject:[NSValue valueWithCGSize:[_delegate collageView:self imageForIndex:index].size]];
                _imagesSizesArray = sizes;
            }
            else {
                NSMutableArray *sizes = [NSMutableArray new];
                for (NSUInteger index = 0; index < [_delegate imagesCountInCollageView:self]; index++)
                    [sizes addObject:[NSValue valueWithCGSize:[_delegate collageView:self sizeForImageAtIndex:index]]];
                _imagesSizesArray = sizes;
            }
        }
    }
    return _imagesSizesArray;
}

- (IBAction)tapGestureRecogmiserDidFire:(UITapGestureRecognizer *)sender {
    if ([_delegate respondsToSelector:@selector(collageView:didTapAtImageView:atIndex:)])
        [_delegate collageView:self didTapAtImageView:(UIImageView *)sender.view atIndex:sender.view.tag];
}

#pragma mark - Collection View Delegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _collectionViewItemsCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    AAImageCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:AAImageCollectionViewCell.identifier forIndexPath:indexPath];
    UIImageView *imgView = cell.imageView;
    NSUInteger idx = self.imagesSizesArray.count - _collectionViewItemsCount + indexPath.item;
    if (self.imagesArray)
        imgView.image = self.imagesArray[idx];
    else if ([_delegate respondsToSelector:@selector(collageView:imageForIndex:)])
        imgView.image = [_delegate collageView:self imageForIndex:idx];
    else {
        CGSize size = [self collectionView:collectionView layout:collectionView.collectionViewLayout sizeForItemAtIndexPath:indexPath];
        [imgView sd_setImageWithURL:[_delegate collageView:self URLForImageAtIndex:idx withSize:size]];
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([_delegate respondsToSelector:@selector(collageView:didTapAtImageView:atIndex:)]) {
        AAImageCollectionViewCell *cell = (AAImageCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
        [_delegate collageView:self didTapAtImageView:cell.imageView atIndex:_collectionViewItemsCount + indexPath.item];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *sizesArray = self.imagesSizesArray;
    CGSize imageSize = [sizesArray[sizesArray.count - _collectionViewItemsCount + indexPath.item] CGSizeValue];
    
    NSInteger iHeight = imageSize.height;
    NSInteger iWidth = imageSize.width;
    CGFloat scale = iHeight / collectionView.frame.size.height;
    return CGSizeMake(iWidth / scale, collectionView.frame.size.height);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return _imagesMargin;
}

@end
