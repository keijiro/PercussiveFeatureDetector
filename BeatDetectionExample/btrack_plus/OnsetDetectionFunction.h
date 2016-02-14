/*
 *  OnsetDetectionFunction.h
 *  
 *
 *  Created by Adam Stark on 22/03/2011.
 *  Copyright 2011 Queen Mary University of London. All rights reserved.
 *
 */

#ifndef __RTONSETDF_H
#define __RTONSETDF_H

#include "accFFT.h"

typedef double fft_complex[2];

class OnsetDetectionFunction
{
public:
    
    // Constructor/destructor
	OnsetDetectionFunction(int arg_hsize,int arg_fsize);
	~OnsetDetectionFunction();
    
    // Initialisation Function
	void initialise(int arg_hsize,int arg_fsize);
	
    // process input buffer and calculate detection function sample
	float getDFsample(float inputbuffer[]);
	
private:
	
    // perform the FFT on the data in 'frame'
	void perform_FFT();

    // calculate complex spectral difference detection function sample (half-wave rectified)
	double complex_spectral_difference_hwr();

    // calculate a Hanning window
	void set_win_hanning();
	
    // set phase values between [-pi, pi]
	double princarg(double phaseval);
	
	
	double pi;																				// pi, the constant
	
	int framesize;																			// audio framesize
	int hopsize;																			// audio hopsize	
	
    accFFT *fft;
    fft_complex *out;
    double *in;
	
	int initialised;																		// flag indicating whether buffers and FFT plans have been initialised

	double *frame;																			// audio frame
	double *window;																			// window
	double *wframe;																			// windowed frame
	
	double energy_sum_old;																	// to hold the previous energy sum value
	
	double *mag;																			// magnitude spectrum
	double *mag_old;																		// previous magnitude spectrum
	
	double *phase;																			// FFT phase values
	double *phase_old;																		// previous phase values
	double *phase_old_2;																	// second order previous phase values
};

#endif
