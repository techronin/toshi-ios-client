// Copyright (c) 2017 Token Browser, Inc
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface StaticBackdropAreaData : NSObject

@property (nonatomic, strong) UIImage *background;
@property (nonatomic) CGRect mappedRect;
@property (nonatomic) CGFloat luminance;

- (instancetype)initWithBackground:(UIImage *)background;
- (instancetype)initWithBackground:(UIImage *)background mappedRect:(CGRect)mappedRect;

- (void)drawRelativeToImageRect:(CGRect)imageRect;

@end
