//
//  ViewController.m
//  SimpleInceptionV3-ObjC
//
//  Created by Koan-Sin Tan on 6/11/17.
//  Copyright © 2017 Koan-Sin Tan. All rights reserved.
//

#import "ViewController.h"

// #import "MobileNet_10_224.h"
#import "MobileNet_050_160.h"
// #import "Inceptionv3.h"

// Core ML MobileNet models could be converted from Keras models using script at https://github.com/freedomtan/coreml-mobilenet-models/.
// E.g., to get MobileNet 0.5/160,
//   > python mobilenets.py --alpha 0.50 --image_size 160

@interface ViewController ()
@end

@implementation ViewController 

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    // self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell");

    startTimes = [NSMutableArray array];
    // model = [[[Inceptionv3 alloc] init] model];
    // model = [[[MobileNet_10_224 alloc] init] model];
    model = [[[MobileNet_050_160 alloc] init] model];
    m = [VNCoreMLModel modelForMLModel: model error:nil];
    rq = [[VNCoreMLRequest alloc] initWithModel: m completionHandler: (VNRequestCompletionHandler) ^(VNRequest *request, NSError *error){
        dispatch_async(dispatch_get_main_queue(), ^{
            NSTimeInterval start, stop;
            stop = [[NSDate date] timeIntervalSince1970];
            start = [[startTimes objectAtIndex: 0] doubleValue];
            [startTimes removeObjectAtIndex: 0];
            // NSLog(@"diff: %ld, %f\n", [startTimes count], (stop - start) * 1000);
            self.messageLabel.text = @"done";
            self.numberOfResults = request.results.count;
            self.results = [request.results copy];
            VNClassificationObservation *topResult = ((VNClassificationObservation *)(self.results[0]));
            self.messageLabel.text = [NSString stringWithFormat: @"%f: %@", topResult.confidence, topResult.identifier];
            self.fpsLabel.text = [NSString stringWithFormat: @"%f fps", 1/((stop - start))];
            
            [self.tableView reloadData];
        });
    }];
    
    [self.tableView registerClass:UITableViewCell.self forCellReuseIdentifier: @"cell"];
    [self setupCamera];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) labelImage: (CIImage *)image {
    NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
    [startTimes addObject: [NSNumber numberWithDouble: start]];
    
    NSArray *a = @[rq];
    NSDictionary *d = [[NSDictionary alloc] init];
    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCIImage:image options:d];
    dispatch_sync(dispatch_get_main_queue(), ^{
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
    CVImageBufferRef cvImage = CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:cvImage];
    [self labelImage: ciImage];
}

@end
