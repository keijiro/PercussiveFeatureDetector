//
//  BeatDetector.m
//  BeatDetectionExample
//
//  Created by Keijiro Takahashi on 2/14/16.
//  Copyright © 2016 Keijiro Takahashi. All rights reserved.
//

#import "BeatDetector.h"
#import "RingBuffer.h"
#import "OnsetDetectionFunction.h"
#import "PeakProcessor.h"

static const int kFrameSize = 512;

@implementation BeatDetector
{
    float _level;
    RingBuffer *_ringBuffer;
    OnsetDetectionFunction *_onset;
    PeakProcessor *_peak;
}

@synthesize level = _level;

- (void)awakeFromNib
{
    _ringBuffer = new RingBuffer(kFrameSize * 4, 1);
    _onset = new OnsetDetectionFunction(kFrameSize, kFrameSize * 2, 6, 1);
    _peak = new PeakProcessor();
}

- (void)processInputData:(float *)data frames:(UInt32)frames channels:(UInt32)channels
{
    _ringBuffer->AddNewInterleavedFloatData(data, frames, channels);
    
    while (_ringBuffer->NumUnreadFrames() >= kFrameSize)
    {
        float temp[kFrameSize];
        float df_val;
        
        _ringBuffer->FetchData(temp, kFrameSize, 0, 1);
        
        df_val = _onset->getDFsample(temp) + 0.0001f;
        
        if (_peak->peakProcessing(df_val)) _level = 1;
    }
    
    _level *= 0.9f;
}

@end
