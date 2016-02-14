//
//  AppDelegate.m
//  BeatDetectionExample
//
//  Created by Keijiro Takahashi on 2/14/16.
//  Copyright © 2016 Keijiro Takahashi. All rights reserved.
//

#import "AppDelegate.h"
#import "Novocaine.h"
#import "BeatDetector.h"

@interface AppDelegate ()
@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet BeatDetector *beatDetector;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    Novocaine *novocaine = [Novocaine audioManager];
    
    novocaine.inputBlock = ^(float *data, UInt32 numFrames, UInt32 numChannels) {
        [self.beatDetector processInputData:data frames:numFrames channels:numChannels];
    };
    
    [novocaine play];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
}

@end
