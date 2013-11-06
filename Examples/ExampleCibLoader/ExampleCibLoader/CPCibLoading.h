//
//  AppDelegate.h
//  ExampleCibLoader
//
//  Created by Richard Sarkis on 9/27/13.
//  Copyright (c) 2013 Richard Sarkis. All rights reserved.
//

#import <Foundation/NSBundle.h>
#import <Cocoa/Cocoa.h>
#import "CPBundle.h"

@class NSString, NSDictionary, CPCib;

@interface NSBundle(CPCibLoading)
+ (CPCib *)loadCibFile:(NSString *)anAbsolutePath externalNameTable:(NSDictionary *)aNameTable;
+ (CPCib *)loadCibNamed:(NSString *)aName owner:(id)anOwner;
- (CPCib *)loadCibFile:(NSString *)aFileName externalNameTable:(NSDictionary *)aNameTable;
+ (CPCib *)loadCibFile:(NSString *)anAbsolutePath externalNameTable:(NSDictionary *)aNameTable loadDelegate:aDelegate;
+ (CPCib *)loadCibNamed:(NSString *)aName owner:(id)anOwner loadDelegate:(id)aDelegate;
- (CPCib *)loadCibFile:(NSString *)aFileName externalNameTable:(NSDictionary *)aNameTable loadDelegate:(id)aDelegate;
@end
