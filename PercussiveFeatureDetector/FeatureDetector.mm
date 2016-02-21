//
// Percussive feature detector based on FitzGerald 2010
//
// http://dafx10.iem.at/papers/DerryFitzGerald_DAFx10_P15.pdf
//
// Objective-C implementation by Keijiro Takahashi
//

#import "FeatureDetector.h"
#import "RingBuffer.h"

// Filter parameters
static const int kFreqMedianSize = 17;
static const int kTimeMedianSize = 17;
static const int kFFTSize = 1024;
static const int kFFTBins = kFFTSize / 2;
static const int kHopSize = kFFTSize / 4;
static const int kTransientWidth = 5;

@implementation FeatureDetector
{
    RingBuffer *_ringBuffer;
    
    vDSP_DFT_Setup _dftSetup;
    DSPSplitComplex _dftBuffer;
    
    float _buffer[kFFTSize]; // input buffer
    float _window[kFFTSize]; // FFT window
    
    // linearized 2D array of spectrum data
    // [spectrum (FFT bins) + margin for freq-median] x [time-median]
    float _spectra[(kFFTBins + kFreqMedianSize - 1) * kTimeMedianSize];
    
    // percussive feature spectrum
    float _filteredSpectrum[kFFTBins];
    
    // history of energy value
    float _energyHistory[kTransientWidth];
    
    // maximum energy value of frame
    float _maxEnergy;
    
    // maximum transient value of frame
    float _maxTransient;
    
    int _frameCount;
}

#pragma mark Public properties

- (int)spectrumSize
{
    return kFFTBins;
}

- (BOOL)isFrameUpdated
{
    @synchronized(self) {
        return _maxEnergy >= 0;
    }
}

- (float)energy
{
    @synchronized(self) {
        return _maxEnergy;
    }
}

- (float)transient
{
    @synchronized(self) {
        return _maxTransient;
    }
}

#pragma mark Public methods

- (void)clearFrame
{
    @synchronized(self) {
        _maxEnergy = -1;
        _maxTransient = -1;
    }
}

- (void)retrieveSpectrum:(float *)destination
{
    @synchronized(self) {
        const float zero = 0;
        vDSP_vsadd(_filteredSpectrum, 1, &zero, destination, 1, kFFTBins);
    }
}

#pragma mark Initialization/finalization

- (void)awakeFromNib
{
    _ringBuffer = new RingBuffer(kFFTSize * 2, 1);
    
    _dftSetup = vDSP_DFT_zrop_CreateSetup(NULL, kFFTSize, vDSP_DFT_FORWARD);
    _dftBuffer.realp = (float*)calloc(kFFTBins, sizeof(float));
    _dftBuffer.imagp = (float*)calloc(kFFTBins, sizeof(float));
    
    float normFactor = 1.0f / kFFTBins;
    vDSP_blkman_window(_window, kFFTSize, 0);
    vDSP_vsmul(_window, 1, &normFactor, _window, 1, kFFTSize);
    
    vDSP_vclr(_spectra, 1, (kFFTBins + kFreqMedianSize - 1) * kTimeMedianSize);
    
    _maxEnergy = _maxTransient = -1;
}

- (void)dealloc
{
    delete _ringBuffer;
    vDSP_DFT_DestroySetup(_dftSetup);
    free(_dftBuffer.realp);
    free(_dftBuffer.imagp);
}

#pragma mark Input data processing

- (void)processInputData:(float *)data frames:(UInt32)frames channels:(UInt32)channels
{
    _ringBuffer->AddNewInterleavedFloatData(data, frames, channels);

    while (_ringBuffer->NumUnreadFrames() >= kHopSize)
    {
        // slide the content of the buffer by the hop size
        const float zero = 0;
        vDSP_vsadd(&_buffer[kFFTSize - 1], -1, &zero, &_buffer[kFFTSize - kHopSize - 1], -1, kFFTSize - kHopSize);
        
        // fetch new data
        _ringBuffer->FetchData(_buffer, kHopSize, 0, 1);
        
        [self processBuffer];
    }
}

- (void)processBuffer
{
    const float zero = 0;
    
    _frameCount++;
    
    // split input data
    DSPSplitComplex dest = { _dftBuffer.realp, _dftBuffer.imagp };
    vDSP_ctoz((const DSPComplex*)_buffer, 2, &dest, 1, kFFTBins);
    
    // windowing
    vDSP_vmul(_dftBuffer.realp, 1, _window, 2, _dftBuffer.realp, 1, kFFTBins);
    vDSP_vmul(_dftBuffer.imagp, 1, _window + 1, 2, _dftBuffer.imagp, 1, kFFTBins);
    
    // DFT
    vDSP_DFT_Execute(_dftSetup, _dftBuffer.realp, _dftBuffer.imagp, _dftBuffer.realp, _dftBuffer.imagp);
    
    // nyquist value cancellation
    _dftBuffer.imagp[0] = 0;
    
    // power spectra
    float* bins = &_spectra[(_frameCount % kTimeMedianSize) * (kFFTBins + kFreqMedianSize - 1)];
    vDSP_zvmags(&_dftBuffer, 1, bins, 1, kFFTBins);
    
    // time domain median filter
    float softenBins[kFFTBins];
    for (int i_bin = 0; i_bin < kFFTBins; i_bin++)
    {
        float temp[kFreqMedianSize];
        vDSP_vsadd(&bins[i_bin], 1, &zero, temp, 1, kFreqMedianSize);
        vDSP_vsort(temp, kFreqMedianSize, 0);
        softenBins[i_bin] = temp[kFreqMedianSize / 2];
    }
    
    // harmonic/percussive separation
    float filteredBins[kFFTBins];
    for (int i_bin = 0; i_bin < kFFTBins; i_bin++)
    {
        float timeDomain[kTimeMedianSize];
        vDSP_vsadd(&_spectra[i_bin], kFFTBins + kFreqMedianSize - 1, &zero, timeDomain, 1, kTimeMedianSize);
        vDSP_vsort(timeDomain, kTimeMedianSize, 0);
        
        float pp = softenBins[i_bin];
        float hp = timeDomain[kTimeMedianSize / 2];
        float mask = pp * pp / (pp * pp + hp * hp + 1e-10f);
        
        filteredBins[i_bin] = bins[i_bin] * mask;
    }
    
    @synchronized(self)
    {
        // copy filter result
        vDSP_vsadd(filteredBins, 1, &zero, _filteredSpectrum, 1, kFFTBins);
        
        // energy integration
        float energy;
        vDSP_sve(filteredBins, 1, &energy, kFFTBins);
        _energyHistory[_frameCount % kTransientWidth] = energy;
        
        // maximum transient
        float minEnergy;
        vDSP_minv(_energyHistory, 1, &minEnergy, kTransientWidth);
        float transient = energy - minEnergy;
        
        // record update
        _maxEnergy = fmaxf(_maxEnergy, energy);
        _maxTransient = fmaxf(_maxTransient, transient);
    }
}

@end
