//
//  ViewController.m
//  SimpleInceptionV3-ObjC
//
//  Created by Koan-Sin Tan on 6/11/17.
//  Copyright © 2017 Koan-Sin Tan. All rights reserved.
//

#import "ViewController.h"

#import <CoreML/CoreML.h>
#import <Vision/Vision.h>

#import "Inceptionv3.h"

@interface ViewController () 
@end

@implementation ViewController 

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    // self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell");
    [self.tableView registerClass:UITableViewCell.self forCellReuseIdentifier: @"cell"];
    [self setupCamera];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) labelImage: (CIImage *)image {
    MLModel *model = [[[Inceptionv3 alloc] init] model];
    VNCoreMLModel *m = [VNCoreMLModel modelForMLModel: model error:nil];
    VNCoreMLRequest *rq = [[VNCoreMLRequest alloc] initWithModel: m completionHandler: (VNRequestCompletionHandler) ^(VNRequest *request, NSError *error){
        dispatch_async(dispatch_get_main_queue(), ^{
            self.messageLabel.text = @"done";
            self.numberOfResults = request.results.count;
            self.results = [request.results copy];
            VNClassificationObservation *topResult = ((VNClassificationObservation *)(self.results[0]));
            self.messageLabel.text = [NSString stringWithFormat: @"%f: %@", topResult.confidence, topResult.identifier];
            
            [self.tableView reloadData];
        });
    }];
    
    NSDictionary *d = [[NSDictionary alloc] init];
    NSArray *a = @[rq];
    
    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCIImage:image options:d];
    dispatch_async(dispatch_get_main_queue(), ^{
        [handler performRequests:a error:nil];
    });
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage *uiImage = info[UIImagePickerControllerOriginalImage];
    self.imageView.image = uiImage;
    self.messageLabel.text = @"Analyzing Image..";
    
    CIImage* ciImage = [[CIImage alloc] initWithCGImage:uiImage.CGImage];
    [self labelImage: ciImage];
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)takePicture:(id)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self presentViewController:picker animated:YES completion:NULL];
}

- (IBAction)chooseImage:(id)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:picker animated:YES completion:NULL];
}

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    VNClassificationObservation *observation = ((VNClassificationObservation *)(self.results[indexPath.row]));
    
    cell.textLabel.text = [NSString stringWithFormat: @"%f: %@", observation.confidence, observation.identifier];
    return cell;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // store only top 5 results
    return (self.numberOfResults > 5)? self.numberOfResults : 5 ;
}

- (void) setupCamera {
    session = [[AVCaptureSession alloc] init];
    [session setSessionPreset:AVCaptureSessionPresetPhoto];
    
    inputDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error;
    deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:&error];
    
    if ([session canAddInput:deviceInput]) {
        [session addInput:deviceInput];
    }
    
    previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    CALayer *rootLayer = [[self view] layer];
    [rootLayer setMasksToBounds:YES];
    CGRect frame = self.view.frame;
    [previewLayer setFrame:frame];
    [rootLayer insertSublayer:previewLayer atIndex:0];

    AVCaptureVideoDataOutput *videoDataOutput = [AVCaptureVideoDataOutput new];
    
    NSDictionary *rgbOutputSettings = [NSDictionary
                                       dictionaryWithObject:[NSNumber numberWithInt:kCMPixelFormat_32BGRA]
                                       forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    [videoDataOutput setVideoSettings:rgbOutputSettings];
    [videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
    dispatch_queue_t videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
    [videoDataOutput setSampleBufferDelegate:self queue:videoDataOutputQueue];
    
    if ([session canAddOutput:videoDataOutput])
        [session addOutput:videoDataOutput];
    [[videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:YES];
    
    [session startRunning];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    // NSLog(@"here");
    CVImageBufferRef cvImage = CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:cvImage];
    [self labelImage: ciImage];
}

@end
