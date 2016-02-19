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
    int bandCount = self.beatDetector.bandCount;
    
    float totalEnergy = 0;
    float bandLevels[bandCount];

    for (int i = 0; i < bandCount; i++)
    {
        float lv = fmaxf([self.beatDetector getLevelOfBand:i], 0.0f);
        totalEnergy += lv;
        bandLevels[i] = lv;
    }
    
    _history[_historyIndex] = totalEnergy;
    
    _historyIndex = (_historyIndex + 1) % kHistory;

    NSSize size = self.frame.size;
    
    [super drawRect:dirtyRect];
    
    [[NSColor whiteColor] setFill];
    NSRectFill(dirtyRect);
    
    {
        NSBezierPath *path = [NSBezierPath bezierPath];
        float xScale = size.width / bandCount;
        
        for (int i = 0; i < bandCount; i++)
        {
            float x = xScale * i;
            float y = bandLevels[i] * size.height;
            
            if (i == 0)
                [path moveToPoint:NSMakePoint(x, y)];
            else
                [path lineToPoint:NSMakePoint(x, y)];
        }
        
        [[NSColor colorWithWhite:0.5f alpha:1.0f] setStroke];
        path.lineWidth = 0.5f;
        [path stroke];
    }
    
    {
        NSBezierPath *path = [NSBezierPath bezierPath];
        float xScale = size.width / kHistory;
        
        for (int i = 0; i < kHistory; i++)
        {
            float x = xScale * i;
            float y = (_history[i] + 0.5f) * size.height;
            
            if (i == 0)
                [path moveToPoint:NSMakePoint(x, y)];
            else
                [path lineToPoint:NSMakePoint(x, y)];
        }
        
        [[NSColor colorWithWhite:0.5f alpha:1.0f] setStroke];
        path.lineWidth = 0.5f;
        [path stroke];
    }
}

@end
