//
//  AppDelegate.h
//  ExampleCibLoader
//
//  Created by Richard Sarkis on 9/27/13.
//  Copyright (c) 2013 Richard Sarkis. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSData+Base64.h"

/*
@import <Foundation/CPObject.j>
@import <Foundation/CPURLConnection.j>
@import <Foundation/CPURLRequest.j>

@import "_CPCibClassSwapper.j"
@import "_CPCibCustomObject.j"
@import "_CPCibCustomResource.j"
@import "_CPCibCustomView.j"
@import "_CPCibKeyedUnarchiver.j"
@import "_CPCibObjectData.j"
@import "_CPCibProxyObject.j"
@import "_CPCibWindowTemplate.j"
*/

NSString *CPCibOwner              = @"CPCibOwner";
NSString *CPCibTopLevelObjects    = @"CPCibTopLevelObjects";
NSString *CPCibReplacementClasses = @"CPCibReplacementClasses";
NSString *CPCibExternalObjects    = @"CPCibExternalObjects";
NSString *CPCibObjectDataKey      = @"CPCibObjectDataKey";

@class CPBundle, CPCib, CPData, CPURL, CPURLConnection, CPURLRequest, CPCibLoading;

@interface CPCib : NSObject


@end
