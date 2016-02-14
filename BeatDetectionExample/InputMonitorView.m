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
    
    float whiteLevel = self.beatDetector.level;
    NSColor *fill = [NSColor colorWithWhite:whiteLevel alpha:1];

    [fill setFill];
    NSRectFill(dirtyRect);
}

@end
