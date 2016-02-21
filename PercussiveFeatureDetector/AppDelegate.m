#import "AppDelegate.h"
#import "Novocaine.h"
#import "FeatureDetector.h"

@interface AppDelegate ()
@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet FeatureDetector *featureDetector;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    Novocaine *novocaine = [Novocaine audioManager];
    
    novocaine.inputBlock = ^(float *data, UInt32 numFrames, UInt32 numChannels) {
        [self.featureDetector processInputData:data frames:numFrames channels:numChannels];
    };
    
    [novocaine play];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
}

@end
