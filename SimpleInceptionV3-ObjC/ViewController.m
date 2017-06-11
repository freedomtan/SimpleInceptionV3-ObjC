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
    return self.numberOfResults;
}

@end
