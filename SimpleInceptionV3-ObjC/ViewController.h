//
//  ViewController.h
//  SimpleInceptionV3-ObjC
//
//  Created by Koan-Sin Tan on 6/11/17.
//  Copyright © 2017 Koan-Sin Tan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic) unsigned long numberOfResults;
@property (retain, nonatomic) NSArray *results;

- (IBAction)takePicture:(id)sender;
- (IBAction)chooseImage:(id)sender;

@end

