//
//  ViewController.h
//  TestVideoUpload
//
//  Created by Nguyen Tuan on 20/11/2013.
//  Copyright (c) Năm 2013 Nguyen Tuan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (nonatomic, strong) IBOutlet UITextField *username;
@property (nonatomic, strong) IBOutlet UITextField *password;

-(IBAction)login:(id)sender;

@end
