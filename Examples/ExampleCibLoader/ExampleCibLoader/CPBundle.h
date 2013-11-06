//
//  AppDelegate.h
//  ExampleCibLoader
//
//  Created by Richard Sarkis on 9/27/13.
//  Copyright (c) 2013 Richard Sarkis. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSData+Base64.h"
#import "CPCibLoading.h"

/* 
 @import "CPDictionary.j"
 @import "CPNotification.j"
 @import "CPNotificationCenter.j"
 @import "CPObject.j"
*/

NSString *CPCibOwner              = @"CPCibOwner";
NSString *CPCibTopLevelObjects    = @"CPCibTopLevelObjects";
NSString *CPCibReplacementClasses = @"CPCibReplacementClasses";
NSString *CPCibExternalObjects    = @"CPCibExternalObjects";
NSString *CPCibObjectDataKey      = @"CPCibObjectDataKey";

@class CFBundle, CPBundle, CPCib, CPData, CPURL, CPURLConnection, CPURLRequest;

@interface CPBundle : NSObject


@end
