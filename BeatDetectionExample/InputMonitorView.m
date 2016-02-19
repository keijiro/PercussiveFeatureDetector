//
//  InputMonitorView.m
//  BeatDetectionExample
//
//  Created by Keijiro Takahashi on 2/14/16.
//  Copyright © 2016 Keijiro Takahashi. All rights reserved.
//

#import "InputMonitorView.h"
#import "BeatDetector.h"
#import <Accelerate/Accelerate.h>

static const int kHistory = 5;

@interface InputMonitorView ()
@property (weak, nonatomic) IBOutlet BeatDetector *beatDetector;
@end

@implementation InputMonitorView
{
    float _history[kHistory];
    int _historyIndex;
    float _level;
}

- (void)awakeFromNib
{
    // Refresh 60 times in a second.
    [NSTimer scheduledTimerWithTimeInterval:(1.0f / 60) target:self selector:@selector(refresh) userInfo:nil repeats:YES];
}

- (void)refresh
{
    self.needsDisplay = YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];

    float energy = 0;
    for (int i = 1; i < 1024; i++)
        energy += fmaxf([self.beatDetector getLevelOfBand:i], 0.0f);
    
    _historyIndex = (_historyIndex + 1) % kHistory;
    _history[_historyIndex] = energy / 1024;
    
    float temp[kHistory];
    for (int i = 0; i < kHistory; i++)
        temp[i] = _history[i];
    
    vDSP_vsort(temp, kHistory, 0);

    float avg = 0;
    for (int i = 0; i < kHistory; i++)
        avg += _history[i];
    avg /= kHistory;
    
    temp[kHistory / 2] = avg;
    
    float level = _history[_historyIndex] - temp[kHistory / 2];
    level = fmaxf(0.0f, level) / temp[kHistory / 2] / 2;
    
//    level = temp[kHistory / 2] * 20;
    
level = _history[_historyIndex] * 5;
    
    _level = fmaxf(0.8f * _level, level);
    _level = fminf(fmaxf(_level, 0.0f), 1.0f);
    
//    [[NSColor colorWithWhite:_level alpha:1] setFill];
    [[NSColor whiteColor] setFill];
    NSRectFill(dirtyRect);
    
    NSSize size = self.frame.size;
    float barInterval = size.width / 256;
    float barWidth = 0.5f * barInterval;

    [[NSColor colorWithWhite:0.1f alpha:1.0f] setFill];

    for (int i = 1; i < 256; i++) {
        float x = (0.5f + i)  * barInterval;
        float y = [self.beatDetector getLevelOfBand:i * 4] * size.height;
        NSRectFill(NSMakeRect(x - 0.5f * barWidth, 0, barWidth, y));
    }
}

@end
