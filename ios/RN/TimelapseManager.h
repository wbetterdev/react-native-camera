#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


@interface TimelapseManager : NSObject

@property (nonatomic, readonly) BOOL isRecording;
@property (strong, nonatomic, readonly) NSURL *outputURL;

- (instancetype)init;
- (void)reset;
- (BOOL)prepareForRecordingAtURL:(NSURL *)fileURL withCaptureVideoDataOutput:(AVCaptureVideoDataOutput *)captureVideoDataOutput options:(NSDictionary *)options;
- (BOOL)processFrame:(CMSampleBufferRef)imageDataSampleBuffer;
- (void)startRecording;
- (void)stopRecordingWithCompletionHandler:(void (^)(void))completion;

@end
