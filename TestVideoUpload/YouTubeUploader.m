//
//  YouTubeUploader.m
//  YouTubeSample_iOS
//
//  Created by Manuel Carrasco Molina on 08.01.12.
//  Copyright (c) 2012 Pomcast. All rights reserved.
//

#import "YouTubeUploader.h"
#import "GDataEntryYouTubeUpload.h"
#import "GTMOAuth2ViewControllerTouch.h"

#define CLIENT_ID @"605593369496.apps.googleusercontent.com"
#define CLIENT_SECRET @"b61Z44oJcD47tbu7Nz8l-YpP"
#define DEV_KEY @"AI39si62TwTMFDeLKCJvEQydldPj30-mqMnzXN-Nx98BTu4XxOY3BgoEkSgtMxXPv1DFB62aF_xpI57cgwIvXqhzQ6sCAs9FTw"

@interface YouTubeUploader()

@property (nonatomic, strong) NSString *videoDescription;
@property (nonatomic, strong) NSString *videoLocalPath;

- (GDataServiceGoogleYouTube *)youTubeService;
- (BOOL)isSignedIn;
- (NSString *)signedInUsername;
- (void)runSignin:(NSString*)path;

@end
    
@implementation YouTubeUploader

@synthesize uploadProgressView = _uploadProgressView;
@synthesize delegate = _delegate;

static NSString *const kKeychainItemName = @"YouTubeSample_iOS: YouTube";

#pragma mark - Public Methods

- (id)init {
    if ((self = [super init])) {
        [self setupGOAuth];
    }
    return self;
}

- (void)setupGOAuth
{
    GTMOAuth2Authentication *auth;
    auth = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName
                                                                 clientID:CLIENT_ID
                                                             clientSecret:CLIENT_SECRET];
    [[self youTubeService] setAuthorizer:auth];
}

- (void)logout {
    GDataServiceGoogleYouTube *service = [self youTubeService];
    [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:kKeychainItemName];
    [service setAuthorizer:nil];
    NSLog(@"Logged Out");
}

- (void)uploadVideoFile:(NSString*)path description:(NSString *)des{
    NSLog(@"About to upload %@", path);
    self.videoDescription = des;
    self.videoLocalPath = path;
    if (![self isSignedIn]) {
        // Sign in
        [self runSignin:path];
    }
    [self uploadVideoFile];
}

- (void)uploadVideoFile
{
    GDataServiceGoogleYouTube *service = [self youTubeService];
    [service setYouTubeDeveloperKey:DEV_KEY];
    
    NSURL *url = [GDataServiceGoogleYouTube youTubeUploadURLForUserID:kGDataServiceDefaultUser];
    
    // load the file data
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:self.videoLocalPath];
    NSString *filename = [self.videoLocalPath lastPathComponent];
    
    // gather all the metadata needed for the mediaGroup
    GDataMediaTitle *title = [GDataMediaTitle textConstructWithString:[filename stringByDeletingPathExtension]];
    GDataMediaCategory *category = [GDataMediaCategory mediaCategoryWithString:@"Entertainment"];
    [category setScheme:kGDataSchemeYouTubeCategory];
    BOOL isPrivate = NO;
    
    GDataYouTubeMediaGroup *mediaGroup = [GDataYouTubeMediaGroup mediaGroup];
    GDataMediaDescription *description = [GDataMediaDescription textConstructWithString:self.videoDescription];
    [mediaGroup setMediaDescription:description];
    [mediaGroup setMediaTitle:title];
    [mediaGroup addMediaCategory:category];
    [mediaGroup setIsPrivate:isPrivate];
    
    NSString *mimeType = [GDataUtilities MIMETypeForFileAtPath:self.videoLocalPath
                                               defaultMIMEType:@"video/mp4"];
    
    // create the upload entry with the mediaGroup and the file
    GDataEntryYouTubeUpload *entry;
    entry = [GDataEntryYouTubeUpload uploadEntryWithMediaGroup:mediaGroup
                                                    fileHandle:fileHandle
                                                      MIMEType:mimeType
                                                          slug:filename];
    [service setServiceUploadProgressSelector:@selector(ticket:hasDeliveredByteCount:ofTotalByteCount:)];
    
    GDataServiceTicket *ticket;
    ticket = [service fetchEntryByInsertingEntry:entry
                                      forFeedURL:url
                                        delegate:self
                               didFinishSelector:@selector(uploadTicket:finishedWithEntry:error:)];
}

#pragma mark - Private Methods

- (BOOL)isSignedIn {
    NSString *name = [self signedInUsername];
    NSLog(@"name: %@", name);
    return (name != nil);
}

- (GDataServiceGoogleYouTube *)youTubeService {
    // A "service" object handles networking tasks.  Service objects
    // contain user authentication information as well as networking
    // state information (such as cookies and the "last modified" date for
    // fetched data.)
    
    static GDataServiceGoogleYouTube* service = nil;
    if (!service) {
        service = [[GDataServiceGoogleYouTube alloc] init];
        
        [service setShouldCacheResponseData:YES];
        [service setServiceShouldFollowNextLinks:YES];
        [service setIsServiceRetryEnabled:YES];
    }
    [service setYouTubeDeveloperKey:DEV_KEY];
    return service;
}

- (NSString *)signedInUsername {
    // Get the email address of the signed-in user
    GTMOAuth2Authentication *auth = [[self youTubeService] authorizer];
    BOOL isSignedIn = auth.canAuthorize;
    if (isSignedIn) {
        return auth.userEmail;
    } else {
        return nil;
    }
}

- (void)runSignin:(NSString*)path {
    // Show the OAuth 2 sign-in controller
    NSString *scope = [GDataServiceGoogleYouTube authorizationScope];
    
    id completionHandler = ^(GTMOAuth2ViewControllerTouch *viewController, GTMOAuth2Authentication *auth, NSError *error) {
        // TODO: Check the error and don't dismiss if an error has occured.
        NSLog(@"%@\n%@\n%@", viewController, auth, error);
        [self.parentViewController dismissViewControllerAnimated:YES completion:^{
            [self setupGOAuth];
            if ([[[self youTubeService] authorizer] canAuthorize]) {
                [self uploadVideoFile];
            }
        }];
    };
    
    GTMOAuth2ViewControllerTouch *viewController = [GTMOAuth2ViewControllerTouch controllerWithScope:scope
                                                                                            clientID:CLIENT_ID 
                                                                                        clientSecret:CLIENT_SECRET
                                                                                    keychainItemName:kKeychainItemName
                                                                                   completionHandler:completionHandler];

    [self.parentViewController presentViewController:viewController animated:YES completion:^{
        NSLog(@"Google Sign In presented");
    }];
}

// progress callback

- (void)ticket:(GDataServiceTicket *)ticket hasDeliveredByteCount:(unsigned long long)numberOfBytesRead ofTotalByteCount:(unsigned long long)dataLength 
{
    float progress = (float)numberOfBytesRead/dataLength;
    NSLog(@"numberOfBytesRead/dataLength => %llu/%llu = %f",numberOfBytesRead, dataLength, progress);
    [_uploadProgressView setProgress:progress animated:YES];
}


// upload callback
- (void)uploadTicket:(GDataServiceTicket *)ticket
   finishedWithEntry:(GDataEntryYouTubeVideo *)videoEntry
               error:(NSError *)error {
    NSLog(@"%@ %@", [videoEntry title], error);
    NSString *title, *message;
    if (error == nil) {
        // tell the user that the add worked
        title = NSLocalizedString(UPLOADED_VIDEO_TITLE, @"When the video upload succeeded ('title' in the UIAlertView).");
        message = [NSString stringWithFormat:NSLocalizedString(UPLOADED_VIDEO_MESSAGE, @"When the video upload succeeded ('message' in the UIAlertView)."), [[videoEntry title] stringValue]];
        NSString *videoID = [videoEntry mediaGroup].videoID;
        if ([self.delegate respondsToSelector:@selector(didFinishUploadVideo:)]) {
            [self.delegate didFinishUploadVideo:videoID];
        }
    } else {
        title = NSLocalizedString(ERROR_UPLOAD_VIDEO_TITLE, @"When the video upload FAILED ('title' in the UIAlertView).");
        message = [error localizedDescription];
        if ([self.delegate respondsToSelector:@selector(didFailUploadVideo:)]) {
            [self.delegate didFailUploadVideo:error];
        }
    }
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
    [_uploadProgressView setProgress:0 animated:YES];
}


- (void)dealloc {
}
@end
