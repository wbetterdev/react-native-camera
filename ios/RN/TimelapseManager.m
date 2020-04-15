#import "TimelapseManager.h"
#import <React/RCTLog.h>


@interface TimelapseManager()

@property (strong, nonatomic) AVAssetWriter *assetWriter;
@property (strong, nonatomic) AVAssetWriterInput *assetWriterInput;

@property (nonatomic) int timeReductionFactor;
@property (nonatomic) int frameNumber;
@property (nonatomic) CMTime frameDuration;
@property (nonatomic) CMTime nextPTS;

@end


@implementation TimelapseManager

- (instancetype)init
{
  if (self = [super init]) {
      _isRecording = NO;
      [self reset];
  }
  return self;
}

- (void)reset
{
    if (_isRecording) {
        RCTLogWarn(@"TimelapseManager > Cannot reset while recording");
        return;
    }
    _outputURL = nil;
    _frameNumber = 0;
    _frameDuration = CMTimeMakeWithSeconds(1./30., 90000);
    _nextPTS = kCMTimeZero;
}

- (BOOL)prepareForRecordingAtURL:(NSURL *)fileURL withCaptureVideoDataOutput:(AVCaptureVideoDataOutput *)captureVideoDataOutput options:(NSDictionary *)options
{
    if (_outputURL) {
        RCTLogWarn(@"TimelapseManager > Recording already prepared");
        return NO;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:fileURL.path]) {
        NSError *removeError;
        [[NSFileManager defaultManager] removeItemAtURL:fileURL error:&removeError];
        if (removeError) {
            RCTLogWarn(@"TimelapseManager > Output file already exists and could not be removed");
            return NO;
        }
    }
    
    NSError *error = nil;
    _assetWriter = [[AVAssetWriter alloc] initWithURL:fileURL fileType:AVFileTypeQuickTimeMovie error:&error];
    if (error) {
        RCTLogWarn(@"TimelapseManager > Could not init asset writer");
        return NO;
    }
    
    NSMutableDictionary *videoSettings = [NSMutableDictionary dictionaryWithDictionary:[captureVideoDataOutput recommendedVideoSettingsForAssetWriterWithOutputFileType:AVFileTypeQuickTimeMovie]];
    NSMutableDictionary *compressionProperties = videoSettings[AVVideoCompressionPropertiesKey];
    if (!compressionProperties) {
        compressionProperties = [[NSMutableDictionary alloc] init];
    }
    if (options[@"videoBitrate"]) {
        compressionProperties[AVVideoAverageBitRateKey] = options[@"videoBitrate"];
    }
    compressionProperties[AVVideoExpectedSourceFrameRateKey] = @(30);
    videoSettings[AVVideoCompressionPropertiesKey] = compressionProperties;
    _assetWriterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    [_assetWriterInput setExpectsMediaDataInRealTime:YES];
    
    if ([_assetWriter canAddInput:_assetWriterInput]) {
      [_assetWriter addInput:_assetWriterInput];
    } else {
        RCTLogWarn(@"TimelapseManager > Could not add asset writer input");
        return NO;
    }
    
    if (options[@"timeReductionFactor"]) {
        _timeReductionFactor = [options[@"timeReductionFactor"] intValue];
    } else {
        _timeReductionFactor = 15;
    }
    if (_timeReductionFactor < 1) {
        _timeReductionFactor = 1;
    }
    
    _nextPTS = kCMTimeZero;
    [_assetWriter startWriting];
    [_assetWriter startSessionAtSourceTime:_nextPTS];
    
    _outputURL = fileURL;
    
    return YES;
}

- (void)startRecording
{
    if (_isRecording) {
        RCTLogWarn(@"TimelapseManager > Already recording");
    } else {
      _isRecording = YES;
    }
}

- (void)stopRecordingWithCompletionHandler:(void (^)(void))completion
{
    if (!_isRecording) {
        RCTLogWarn(@"TimelapseManager > Already stopped recording");
    } else {
        _isRecording = NO;
        [_assetWriterInput markAsFinished];
        [_assetWriter finishWritingWithCompletionHandler:completion];
    }
}

- (BOOL)processFrame:(CMSampleBufferRef)imageDataSampleBuffer
{
    if (!imageDataSampleBuffer) {
        RCTLogWarn(@"TimelapseManager > Could not process frame, it is null");
        return NO;
    }
    if (!_isRecording) {
        RCTLogWarn(@"TimelapseManager > Could not process frame, it is not recording");
        return NO;
    }
    if ([self shouldWriteFrame]) {
        [self writeFrame:imageDataSampleBuffer];
    }
    [self advanceToNextFrame];
    return YES;
}

- (BOOL)writeFrame:(CMSampleBufferRef)imageDataSampleBuffer
{
    CMSampleTimingInfo newTimingInfo = kCMTimingInfoInvalid;
    newTimingInfo.duration = _frameDuration;
    newTimingInfo.presentationTimeStamp = _nextPTS;

    CMSampleBufferRef sampleBufferWithNewTiming = NULL;
    OSStatus err = CMSampleBufferCreateCopyWithNewTiming(kCFAllocatorDefault, imageDataSampleBuffer, 1, &newTimingInfo, &sampleBufferWithNewTiming);

    if (err) {
        return NO;
    }

    if ([_assetWriterInput isReadyForMoreMediaData]) {
        if ([_assetWriterInput appendSampleBuffer:sampleBufferWithNewTiming]) {
            _nextPTS = CMTimeAdd(_frameDuration, _nextPTS);
        }
        else {
            RCTLogWarn(@"TimelapseManager > Could not write frame, error: %@", _assetWriter.error);
            return NO;
        }
    }
    else {
        RCTLogWarn(@"TimelapseManager > Could not write frame, asset writer input is not ready");
        return NO;
    }

    CFRelease(sampleBufferWithNewTiming);
    
    return YES;
}

- (BOOL)shouldWriteFrame
{
    return _frameNumber == 0;
}

- (void)advanceToNextFrame
{
    ++_frameNumber;
    if (_frameNumber >= _timeReductionFactor) {
        _frameNumber = 0;
    }
}

@end
