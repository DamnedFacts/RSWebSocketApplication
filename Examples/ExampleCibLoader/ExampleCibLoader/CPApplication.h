//
//  CPApplication.h
//  ExampleCibLoader
//
//  Created by Richard Sarkis on 9/29/13.
//  Copyright (c) 2013 Richard Sarkis. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CPCib.h"

static NSString *CPMainCibFile = @"CPMainCibFile";

@class CPBundle, CPCib;

@interface CPApplication : NSObject
{
}

+ (BOOL)loadMainCibFile;
@end
