//
//  ViewController.h
//  SimpleInceptionV3-ObjC
//
//  Created by Koan-Sin Tan on 6/11/17.
//  Copyright © 2017 Koan-Sin Tan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#import <CoreML/CoreML.h>
#import <Vision/Vision.h>

@interface ViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource, AVCaptureVideoDataOutputSampleBufferDelegate> {
    AVCaptureSession *session;
    AVCaptureDevice *inputDevice;
    AVCaptureDeviceInput *deviceInput;
    AVCaptureVideoPreviewLayer *previewLayer;

    MLModel *model;
    VNCoreMLModel *m;
    VNCoreMLRequest *rq;

    NSMutableArray *startTimes;
}

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UILabel *fpsLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic) unsigned long numberOfResults;
@property (retain, nonatomic) NSArray *results;

- (IBAction)takePicture:(id)sender;
- (IBAction)chooseImage:(id)sender;

@end

