/*
 *  OnsetDetectionFunction.cpp
 *  
 *
 *  Created by Adam Stark on 22/03/2011.
 *  Copyright 2011 Queen Mary University of London. All rights reserved.
 *
 */

#include <cmath>
#include <iostream>
#include "OnsetDetectionFunction.h"
#include "accFFT.h"

using namespace std;

//-------------------------------------------------------------------------------
// Constructor (with arguments)
OnsetDetectionFunction :: OnsetDetectionFunction(int arg_hsize,int arg_fsize)
{
	// indicate that we have not initialised yet
	initialised = 0;		
	
	// set pi
	pi = 3.14159265358979;	
	
	// initialise with arguments to constructor
    initialise(arg_hsize,arg_fsize);
}


//--------------------------------------------------------------------------------------
// Destructor
OnsetDetectionFunction :: ~OnsetDetectionFunction()
{
    fft->~accFFT();
    delete [] in;
    in = NULL;
    delete [] out;
    out = NULL;
    
	// deallocate memory
	delete [] frame;
	frame = NULL;	
	delete [] window;
	window = NULL;									
	delete [] wframe;
	wframe = NULL;											
	delete [] mag;
	mag = NULL;
	delete [] mag_old;
	mag_old = NULL;
	delete [] phase;
	phase = NULL;
	delete [] phase_old;
	phase_old = NULL;	
	delete [] phase_old_2;
	phase_old_2 = NULL;
}

//-------------------------------------------------------------------------------
// Initialisation
void OnsetDetectionFunction :: initialise(int arg_hsize,int arg_fsize)
{
	if (initialised == 1) // if we have already initialised some buffers and an FFT plan
	{
		//////////////////////////////////
		// TIDY UP FIRST - If initialise is called after the class has been initialised
		// then we want to free up memory and cancel existing FFT plans
        
        fft->~accFFT();
        delete [] in;
        in = NULL;
        delete [] out;
        out = NULL;
	
	
		// deallocate memory
		delete [] frame;
		frame = NULL;	
		delete [] window;
		window = NULL;									
		delete [] wframe;
		wframe = NULL;											
		delete [] mag;
		mag = NULL;
		delete [] mag_old;
		mag_old = NULL;
		delete [] phase;
		phase = NULL;
		delete [] phase_old;
		phase_old = NULL;	
		delete [] phase_old_2;
		phase_old_2 = NULL;
	
		////// END TIDY UP ///////////////
		//////////////////////////////////
	}
	
	hopsize = arg_hsize; // set hopsize
	framesize = arg_fsize; // set framesize
	
	// initialise buffers
	frame = new double[framesize];											
	window = new double[framesize];	
	wframe = new double[framesize];		
	
	mag = new double[framesize];											
	mag_old = new double[framesize];
	
	phase = new double[framesize];
	phase_old = new double[framesize];
	phase_old_2 = new double[framesize];
	
    set_win_hanning();
	
	// initialise previous magnitude spectrum to zero
	for (int i = 0;i < framesize;i++)
	{
		mag_old[i] = 0.0;
		phase_old[i] = 0.0;
		phase_old_2[i] = 0.0;
		frame[i] = 0.0;
	}
	
	energy_sum_old = 0.0;	// initialise previous energy sum value to zero
	
    in = new double[framesize];
    out = new fft_complex[framesize];
    fft = new accFFT(framesize,1);
	
	initialised = 1;
}

//--------------------------------------------------------------------------------------
// calculates a single detection function sample from a single audio frame.
float OnsetDetectionFunction :: getDFsample(float inputbuffer[])
{	
	double df_sample;
		
	// shift audio samples back in frame by hop size
	for (int i = 0; i < (framesize-hopsize);i++)
	{
		frame[i] = frame[i+hopsize];
	}
	
	// add new samples to frame from input buffer
	int j = 0;
	for (int i = (framesize-hopsize);i < framesize;i++)
	{
		frame[i] = inputbuffer[j];
		j++;
	}
    
    // calcualte complex spectral difference detection function sample (half-wave rectified)
    df_sample = complex_spectral_difference_hwr();
		
	return static_cast<float>(df_sample);
}


//--------------------------------------------------------------------------------------
// performs the fft, storing the complex result in 'out'
void OnsetDetectionFunction :: perform_FFT()
{
    for (int i = 0;i < framesize;i++)
	{
        in[i] = frame[i]*window[i];
	}
    fft->forward_FFT_d(in,out);
}

//--------------------------------------------------------------------------------------
// calculates a complex spectral difference detection function sample (half-wave rectified)
double OnsetDetectionFunction :: complex_spectral_difference_hwr()
{
	double dev,pdev;
	double sum;
	double mag_diff,phase_diff;
	double value;
	
	// perform the FFT
	perform_FFT();
	
	sum = 0; // initialise sum to zero
	
	// compute phase values from fft output and sum deviations
	for (int i = 0;i < framesize;i++)
	{
		// calculate phase value
		phase[i] = atan2(out[i][1],out[i][0]);
		
		// calculate magnitude value
		mag[i] = sqrt(pow(out[i][0],2) + pow(out[i][1],2));
		
		
		// phase deviation
		dev = phase[i] - (2*phase_old[i]) + phase_old_2[i];	
		
		// wrap into [-pi,pi] range
		pdev = princarg(dev);	
		
		
		// calculate magnitude difference (real part of Euclidean distance between complex frames)
		mag_diff = mag[i] - mag_old[i];
		
		// if we have a positive change in magnitude, then include in sum, otherwise ignore (half-wave rectification)
		if (mag_diff > 0)
		{
			// calculate phase difference (imaginary part of Euclidean distance between complex frames)
			phase_diff = -mag[i]*sin(pdev);

			// square real and imaginary parts, sum and take square root
			value = sqrt(pow(mag_diff,2) + pow(phase_diff,2));
		
			// add to sum
			sum = sum + value;
		}
		
		// store values for next calculation
		phase_old_2[i] = phase_old[i];
		phase_old[i] = phase[i];
		mag_old[i] = mag[i];
	}
	
	return sum;		
}

//--------------------------------------------------------------------------------------
// HANNING: set the window in the buffer 'window' to a Hanning window
void OnsetDetectionFunction :: set_win_hanning()
{
	double N;		// variable to store framesize minus 1
	
	N = (double) (framesize-1);	// framesize minus 1
	
	// Hanning window calculation
	for (int n = 0;n < framesize;n++)
	{
		window[n] = 0.5*(1-cos(2*pi*(n/N)));
	}
}

//--------------------------------------------------------------------------------------
// set phase values to the range [-pi,pi]
double OnsetDetectionFunction :: princarg(double phaseval)
{	
	// if phase value is less than or equal to -pi then add 2*pi
	while (phaseval <= (-pi)) 
	{
		phaseval = phaseval + (2*pi);
	}
	
	// if phase value is larger than pi, then subtract 2*pi
	while (phaseval > pi)
	{
		phaseval = phaseval - (2*pi);
	}
			
	return phaseval;
}
