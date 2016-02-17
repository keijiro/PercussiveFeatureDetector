//
//  InputMonitorView.m
//  BeatDetectionExample
//
//  Created by Keijiro Takahashi on 2/14/16.
//  Copyright © 2016 Keijiro Takahashi. All rights reserved.
//

#import "InputMonitorView.h"
#import "BeatDetector.h"

@interface InputMonitorView ()
@property (weak, nonatomic) IBOutlet BeatDetector *beatDetector;
@end

@implementation InputMonitorView

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
    
    [[NSColor whiteColor] setFill];
    NSRectFill(dirtyRect);
    
    NSSize size = self.frame.size;
    float barInterval = size.width / 10;
    float barWidth = 0.5f * barInterval;

    [[NSColor colorWithWhite:0.8f alpha:1.0f] setFill];
    
    for (int i = 0; i < 10; i++) {
        float x = (0.5f + i)  * barInterval;
        float y = [self.beatDetector getLevelOfBand:i] * size.height;
        NSRectFill(NSMakeRect(x - 0.5f * barWidth, 0, barWidth, y));
    }
}

@end
