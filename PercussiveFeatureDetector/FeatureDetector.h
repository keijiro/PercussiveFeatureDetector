//
// Percussive feature detector based on FitzGerald 2010
//
// http://dafx10.iem.at/papers/DerryFitzGerald_DAFx10_P15.pdf
//
// Objective-C implementation by Keijiro Takahashi
//

#import <Cocoa/Cocoa.h>

@interface FeatureDetector : NSObject

// Size of percussive feature spectrum
@property (readonly) int spectrumSize;

// Is the current frame updated?
@property (readonly) BOOL isFrameUpdated;

// Total energy of current spectrum
@property (readonly) float energy;

// Transient intensity of current frame
@property (readonly) float transient;

// Clears the frame data and start a new frame
- (void)clearFrame;

// Retrives spectrum of percussive feature
- (void)retrieveSpectrum:(float *)destination;

// Data input callback (invoked from the audio driver)
- (void)processInputData:(float *)data frames:(UInt32)frames channels:(UInt32)channels;

@end
