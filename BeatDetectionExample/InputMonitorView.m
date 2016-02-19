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

static const int kHistory = 512;

@interface InputMonitorView ()
@property (weak, nonatomic) IBOutlet BeatDetector *beatDetector;
@end

@implementation InputMonitorView
{
    float _history[kHistory];
    int _historyIndex;
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
    
    {
        NSBezierPath *path = [NSBezierPath bezierPath];
        float xScale = size.width / kHistory;
        
        for (int i = 0; i < kHistory; i++) {
            float x = xScale * i;
            float y = _history[i] * size.height * 100;
            if (i == 0) {
                [path moveToPoint:NSMakePoint(x, y)];
            } else {
                [path lineToPoint:NSMakePoint(x, y)];
            }
        }
        
        [[NSColor colorWithWhite:0.5f alpha:1.0f] setStroke];
        path.lineWidth = 0.5f;
        [path stroke];
    }
}

@end
