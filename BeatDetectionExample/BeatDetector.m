//
//  BeatDetector.m
//  BeatDetectionExample
//
//  Created by Keijiro Takahashi on 2/14/16.
//  Copyright © 2016 Keijiro Takahashi. All rights reserved.
//

#import "BeatDetector.h"

@implementation BeatDetector
{
    float _level;
}

@synthesize level = _level;

- (void)processInputData:(float *)data frames:(UInt32)frames channels:(UInt32)channels
{
    _level = 0;
    
    for (UInt32 i = 0; i < frames; i++)
        _level = fmaxf(_level, data[i]);
}

@end
