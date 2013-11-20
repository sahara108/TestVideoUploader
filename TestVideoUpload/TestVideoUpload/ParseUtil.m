//
//  ParseUtil.m
//  TestVideoUpload
//
//  Created by Nguyen Tuan on 20/11/2013.
//  Copyright (c) Năm 2013 Nguyen Tuan. All rights reserved.
//

#import "ParseUtil.h"

@implementation ParseUtil

+(void)createVideoRecord:(ParseVideoRecord *)videoRecord
{
    PFObject *videoScore = [PFObject objectWithClassName:@"VideoScore"];
    videoScore[@"VideoID"] = videoRecord.videoID;
    videoScore[@"Description"] = videoRecord.description;
    [videoScore saveInBackground];
}


@end
