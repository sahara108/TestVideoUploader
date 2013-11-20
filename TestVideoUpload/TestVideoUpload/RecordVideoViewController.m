//
//  RecordVideoViewController.m
//  TestVideoUpload
//
//  Created by Nguyen Tuan on 20/11/2013.
//  Copyright (c) Năm 2013 Nguyen Tuan. All rights reserved.
//

#import "RecordVideoViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "YouTubeUploader.h"
#import "ParseUtil.h"

@interface RecordVideoViewController ()<YouTubeUploaderDelegate>

@property (nonatomic, strong) NSString *moviePath;
@property (nonatomic, strong) YouTubeUploader *youTubeUploader;

@end

@implementation RecordVideoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    UIBarButtonItem *post = [[UIBarButtonItem alloc] initWithTitle:@"Post" style:UIBarButtonItemStyleBordered target:self action:@selector(postVideo:)];
    self.navigationItem.rightBarButtonItem = post;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapView:)];
    [self.view addGestureRecognizer:tap];
}

- (void)tapView:(id)sender
{
    [self.textView resignFirstResponder];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self startCameraControllerFromViewController:self usingDelegate:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Record Video

-(BOOL)startCameraControllerFromViewController:(UIViewController*)controller
                                 usingDelegate:(id )delegate {
    // 1 - Validattions
    if (([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == NO)
        || (delegate == nil)
        || (controller == nil)) {
        return NO;
    }
    // 2 - Get image picker
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;
    // Displays a control that allows the user to choose movie capture
    cameraUI.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeMovie, nil];
    // Hides the controls for moving & scaling pictures, or for
    // trimming movies. To instead show the controls, use YES.
    cameraUI.allowsEditing = NO;
    cameraUI.delegate = delegate;
    // 3 - Display image picker
    [controller presentViewController:cameraUI animated:YES completion:nil];
    return YES;
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
    [self dismissModalViewControllerAnimated:NO];
    // Handle a movie capture
    if (CFStringCompare ((__bridge_retained CFStringRef) mediaType, kUTTypeMovie, 0) == kCFCompareEqualTo) {
        NSString *moviePath = (NSString*)[[info objectForKey:UIImagePickerControllerMediaURL] path];
        self.moviePath = moviePath;
        [self generateImage];
//        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(moviePath)) {
//            UISaveVideoAtPathToSavedPhotosAlbum(moviePath, self,
//                                                @selector(video:didFinishSavingWithError:contextInfo:), nil);
//        }
    }
}

-(void)generateImage
{
    AVURLAsset *asset=[[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:self.moviePath] options:nil];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform=TRUE;
    CMTime thumbTime = CMTimeMakeWithSeconds(0,30);
    
    AVAssetImageGeneratorCompletionHandler handler = ^(CMTime requestedTime, CGImageRef im, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error){
        if (result != AVAssetImageGeneratorSucceeded) {
            NSLog(@"couldn't generate thumbnail, error:%@", error);
        }
        
//        dispatch_async(dispatch_get_main_queue(), ^(void){
            self.imageView.image = [UIImage imageWithCGImage:im];
//        });
    };
    
    CGSize maxSize = CGSizeMake(320, 180);
    generator.maximumSize = maxSize;
    [generator generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:[NSValue valueWithCMTime:thumbTime]] completionHandler:handler];
    
}

-(void)video:(NSString*)videoPath didFinishSavingWithError:(NSError*)error contextInfo:(void*)contextInfo {
    if (error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Video Saving Failed"
                                                       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    } else {
//        [self generateImage];
    }
}

#pragma mark YouTube

- (void)postVideo:(id)sender
{
    if (!self.youTubeUploader) {
        self.youTubeUploader = [[YouTubeUploader alloc] init];
        self.youTubeUploader.parentViewController = self;
        self.youTubeUploader.delegate = self;
    }
    [self.youTubeUploader uploadVideoFile:self.moviePath description:self.textView.text];
}

-(void)didFailUploadVideo:(NSError *)error
{
}

-(void)didFinishUploadVideo:(NSString *)videoId
{
    //upload to Parse.com
    ParseVideoRecord *videoRecord = [[ParseVideoRecord alloc] init];
    videoRecord.videoID = videoId;
    videoRecord.description = self.textView.text;
    [ParseUtil createVideoRecord:videoRecord];
}

@end
