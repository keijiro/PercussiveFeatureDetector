//
//  BeatDetector.m
//  BeatDetectionExample
//
//  Created by Keijiro Takahashi on 2/14/16.
//  Copyright © 2016 Keijiro Takahashi. All rights reserved.
//

#import "BeatDetector.h"
#import "RingBuffer.h"

static const int kFrameSize = 2048;
static const int kHistory = 10;

static const float middleFreqs[] = {
    31.5f, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000
};

#define MIN_DB (-60.0f)

static float ConvertLogScale(float x)
{
    return -log10f(0.1f + x / (MIN_DB * 1.1f));
}

@implementation BeatDetector
{
    RingBuffer *_ringBuffer;
    
    float _bandHistory[kHistory][10];
    int _historyIndex;
    
    float _bangLevels[10];
    
    vDSP_DFT_Setup _dftSetup;
    DSPSplitComplex _dftBuffer;
    
    float *_inputBuffer;
    float *_window;
    
    int _counter;
}

- (float)getLevelOfBand:(int)band
{
    float sorted[kHistory];
    
    for (int i = 0; i < kHistory; i++)
        sorted[i] = _bandHistory[i][band];
    
    for (int i = 0; i < kHistory - 1; i++)
    {
        int min_i = i;
        float min = sorted[i];
        
        for (int i2 = i + 1; i2 < kHistory; i2++)
        {
            if (sorted[i2] < min)
            {
                min_i = i2;
                min = sorted[i2];
            }
        }
        if (min_i != i)
        {
            sorted[min_i] = sorted[i];
            sorted[i] = min;
        }
    }
    
    float current = _bandHistory[(_historyIndex + kHistory / 2) % kHistory][band];
    return current * 10;
    return fabsf(sorted[5] - current);
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
    
    _dftBuffer.realp = (float*)calloc(kFrameSize / 2, sizeof(float));
    _dftBuffer.imagp = (float*)calloc(kFrameSize / 2, sizeof(float));
    
    _window = (float*)calloc(kFrameSize, sizeof(float));
    vDSP_hann_window(_window, kFrameSize, 0);
    
    float normFactor = 2.0f / kFrameSize;
    vDSP_vsmul(_window, 1, &normFactor, _window, 1, kFrameSize);
}

- (void)processInputData:(float *)data frames:(UInt32)frames channels:(UInt32)channels
{
    _ringBuffer->AddNewInterleavedFloatData(data, frames, channels);
    _counter += frames;
    
    while (_counter >= kFrameSize)
    {
        float temp[kFrameSize];
        
        _ringBuffer->FetchData(temp, kFrameSize, 0, 1);
        _ringBuffer->SeekReadHeadPosition(-kFrameSize/2, 0);
        _counter -= kFrameSize / 2;
        
        [self processWave:temp];
    }
}

- (void)processWave:(float *)wave
{
    _historyIndex = (_historyIndex + 1) % kHistory;
    
    int length = kFrameSize / 2;
    
    // Split the waveform.
    DSPSplitComplex dest = { _dftBuffer.realp, _dftBuffer.imagp };
    vDSP_ctoz((const DSPComplex*)wave, 2, &dest, 1, length);
    
    // Apply the window function.
    vDSP_vmul(_dftBuffer.realp, 1, _window, 2, _dftBuffer.realp, 1, length);
    vDSP_vmul(_dftBuffer.imagp, 1, _window + 1, 2, _dftBuffer.imagp, 1, length);
    
    // DFT.
    vDSP_DFT_Execute(_dftSetup, _dftBuffer.realp, _dftBuffer.imagp, _dftBuffer.realp, _dftBuffer.imagp);
    
    // Zero out the nyquist value.
    _dftBuffer.imagp[0] = 0;
    
    // Calculate power spectrum.
    float rawSpectrum[length];
    vDSP_zvmags(&_dftBuffer, 1, rawSpectrum, 1, length);
    
    /*
    // Add -128db offset to avoid log(0).
    float kZeroOffset = 1.5849e-13;
    vDSP_vsadd(rawSpectrum, 1, &kZeroOffset, rawSpectrum, 1, length);
    
    // Convert power to decibel.
    float kZeroDB = 0.70710678118f; // 1/sqrt(2)
    vDSP_vdbcon(rawSpectrum, 1, &kZeroDB, rawSpectrum, 1, length, 0);
     */
    
    // Calculate the band levels.
    int bandCount = 10;
    float bandWidth = 1.41421356237f; // 2^(1/2)
    
    float freqToIndexCoeff = kFrameSize / 44100.0f;
    int maxIndex = length - 1;
    
    for (int band = 0; band < bandCount; band++)
    {
        int idxlo = MIN((int)floorf(middleFreqs[band] / bandWidth * freqToIndexCoeff), maxIndex);
        int idxhi = MIN((int)floorf(middleFreqs[band] * bandWidth * freqToIndexCoeff), maxIndex);
        vDSP_maxv(rawSpectrum + idxlo, 1, &_bandHistory[_historyIndex][band], idxhi - idxlo + 1);
//        _bandHistory[_historyIndex][band] = ConvertLogScale(_bandHistory[_historyIndex][band]);
    }
}

@end
