#import "InputMonitorView.h"
#import "FeatureDetector.h"
#import <Accelerate/Accelerate.h>

static const int kHistory = 512;
static const float kAmplitude = 200;

@interface InputMonitorView ()
@property (weak, nonatomic) IBOutlet FeatureDetector *featureDetector;
@end

@implementation InputMonitorView
{
    float _history[kHistory];
    float _intensity;
}

- (void)awakeFromNib
{
    // Refresh 60 times in a second.
    [NSTimer scheduledTimerWithTimeInterval:(1.0f / 60) target:self selector:@selector(refresh) userInfo:nil repeats:YES];
}

- (void)refresh
{
    if (self.featureDetector.isFrameUpdated)
    {
        const float zero = 0;
        
        // shift history data
        vDSP_vsadd(&_history[1], 1, &zero, &_history[0], 1, kHistory - 1);
        
        // retrieve the latest data
        _history[kHistory - 1] = self.featureDetector.energy * kAmplitude;
        _intensity = fmaxf(_intensity * 0.8f, self.featureDetector.transient * kAmplitude);
        
        [self.featureDetector clearFrame];
    }
    
    self.needsDisplay = YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSSize size = self.frame.size;
    
    int binCount = self.featureDetector.spectrumSize;
    
    float bins[binCount];
    [self.featureDetector retrieveSpectrum:bins];
    
    [super drawRect:dirtyRect];
    
    [[NSColor colorWithWhite:_intensity alpha:1] setFill];
    NSRectFill(dirtyRect);
    
    {
        NSBezierPath *path = [NSBezierPath bezierPath];
        float xScale = size.width / binCount;
        
        for (int i = 0; i < binCount; i++)
        {
            float x = xScale * i;
            float y = bins[i] * kAmplitude * binCount * size.height;
            
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
            float y = (_history[i] / 2 + 0.5f) * size.height;
            
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
