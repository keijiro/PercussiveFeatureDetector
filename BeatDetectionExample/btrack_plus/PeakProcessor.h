/*
 *  PeakProcessor.h
 *  peakOnsetDetector
 *
 *  Created by Andrew on 07/09/2012.
 *  Copyright 2012 QMUL. All rights reserved.
 *
 */

#ifndef PEAK_PROCESSOR
#define PEAK_PROCESSOR

#include <vector>

class PeakProcessor
{
public:
    
	PeakProcessor();
	~PeakProcessor();
    bool peakProcessing(const double& newDFval);
    
private:
    
    static const int vectorSize = 512/6;
	std::vector<double> recentDFsamples;
	std::vector<bool> recentDFonsetFound;
	std::vector<double> recentDFslopeValues;
    
	int numberOfDetectionValuesToTest;
    int currentFrame, lastSlopeOnsetFrame, cutoffForRepeatOnsetsFrames;
    float detectionTriggerThreshold, detectionTriggerRatio;
    float bestSlopeMedian, thresholdRelativeToMedian;
    bool newOnsetFound, slopeFallenBelowMedian;
    
    double getBestSlopeValue(const float& dfvalue);
	bool checkForSlopeOnset(const float& bestValue);
    void updateDetectionTriggerThreshold(const float& val);
};

#endif