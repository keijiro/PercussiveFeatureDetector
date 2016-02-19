//
//  BeatDetector.m
//  BeatDetectionExample
//
//  Created by Keijiro Takahashi on 2/14/16.
//  Copyright © 2016 Keijiro Takahashi. All rights reserved.
//

#import "BeatDetector.h"
#import "RingBuffer.h"

static const int kMedian1 = 25;
static const int kMedian2 = 15;
static const int kHopSize = 512;
static const int kFFTSize = 1024;
static const int kFrameSize = kFFTSize * 2;

@implementation BeatDetector
{
    RingBuffer *_ringBuffer;
    
    float _waveBuffer[kFrameSize];
    
    float _history[kMedian2][kFFTSize];
    int _historyIndex;
    
    float _freqMedian[kFFTSize];
    
    vDSP_DFT_Setup _dftSetup;
    DSPSplitComplex _dftBuffer;
    
    float *_inputBuffer;
    float *_window;
}

- (int)bandCount
{
    return kFFTSize;
}

- (float)getLevelOfBand:(int)band
{
//    return _history[_historyIndex][band] * kFFTSize;
//    return _freqMedian[band] * kFFTSize;
    
    float temp[kMedian2];
    
    for (int i = 0; i < kMedian2; i++)
        temp[i] = _history[i][band];
    
    vDSP_vsort(temp, kMedian2, 0);
    
    float pp = _freqMedian[band];
    float hp = temp[kMedian2 / 2];
    
//    return hp * kFFTSize;
    
    float mask = pp * pp / (pp * pp + hp * hp + 1e-10f);
    
    return fmaxf(0.0f, _history[_historyIndex][band] * mask * kFFTSize);
}

- (void)dealloc
{
    vDSP_DFT_DestroySetup(_dftSetup);
    
    free(_dftBuffer.realp);
    free(_dftBuffer.imagp);
    free(_inputBuffer);
    free(_window);
}

- (void)awakeFromNib
{
    _ringBuffer = new RingBuffer(kFrameSize * 4, 1);
    
    _dftSetup = vDSP_DFT_zrop_CreateSetup(_dftSetup, kFrameSize, vDSP_DFT_FORWARD);
    
    _dftBuffer.realp = (float*)calloc(kFFTSize, sizeof(float));
    _dftBuffer.imagp = (float*)calloc(kFFTSize, sizeof(float));
    
    _window = (float*)calloc(kFrameSize, sizeof(float));
    vDSP_blkman_window(_window, kFrameSize, 0);
    
    float normFactor = 1.0f / kFFTSize;
    vDSP_vsmul(_window, 1, &normFactor, _window, 1, kFrameSize);
}

- (void)processInputData:(float *)data frames:(UInt32)frames channels:(UInt32)channels
{
    _ringBuffer->AddNewInterleavedFloatData(data, frames, channels);
    
    while (_ringBuffer->NumUnreadFrames() >= kHopSize)
    {
        for (int i = kFrameSize - 1; i >= kHopSize; i--)
            _waveBuffer[i] = _waveBuffer[i - kHopSize];
        
        _ringBuffer->FetchData(_waveBuffer, kHopSize, 0, 1);
        
        [self processWave:_waveBuffer];
    }
}

- (void)processWave:(float *)wave
{
    _historyIndex = (_historyIndex + 1) % kMedian2;
    
    // Split the waveform.
    DSPSplitComplex dest = { _dftBuffer.realp, _dftBuffer.imagp };
    vDSP_ctoz((const DSPComplex*)wave, 2, &dest, 1, kFFTSize);
    
    // Apply the window function.
    vDSP_vmul(_dftBuffer.realp, 1, _window, 2, _dftBuffer.realp, 1, kFFTSize);
    vDSP_vmul(_dftBuffer.imagp, 1, _window + 1, 2, _dftBuffer.imagp, 1, kFFTSize);
    
    // DFT.
    vDSP_DFT_Execute(_dftSetup, _dftBuffer.realp, _dftBuffer.imagp, _dftBuffer.realp, _dftBuffer.imagp);
    
    // Zero out the nyquist value.
    _dftBuffer.imagp[0] = 0;
    
    // Calculate power spectrum.
    float* spectrum = _history[_historyIndex];
    vDSP_zvmags(&_dftBuffer, 1, spectrum, 1, kFFTSize);
    
    spectrum = _history[_historyIndex];
    
    for (int i = 0; i < kFFTSize; i++)
    {
        float temp[kMedian1];
        for (int i2 = 0; i2 < kMedian1; i2++)
            temp[i2] = i + i2 < kFFTSize ? spectrum[i + i2] : 0;
        vDSP_vsort(temp, kMedian1, 0);
        _freqMedian[i] = temp[kMedian1 / 2];
    }
}

@end
