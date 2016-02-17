//
//  BeatDetector.h
//  BeatDetectionExample
//
//  Created by Keijiro Takahashi on 2/14/16.
//  Copyright © 2016 Keijiro Takahashi. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BeatDetector : NSObject

- (void)processInputData:(float *)data frames:(UInt32)frames channels:(UInt32)channels;
- (float)getLevelOfBand:(int)band;

@end
