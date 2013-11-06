//
//  CPApplication.m
//  ExampleCibLoader
//
//  Created by Richard Sarkis on 9/29/13.
//  Copyright (c) 2013 Richard Sarkis. All rights reserved.
//

#import "CPApplication.h"

@implementation CPApplication
+ (BOOL)loadMainCibFile
{
    CPBundle *mainBundle = [CPBundle mainBundle];
    CPCib *mainCibFile = [mainBundle objectForInfoDictionaryKey:CPMainCibFile];
    CPApplication *CPApp = [[self alloc] init];
    
    if (mainCibFile)
    {
        [mainBundle loadCibFile:mainCibFile
              externalNameTable:@{ CPCibOwner: CPApp }
                   loadDelegate:self];
        return YES;
    }
//    else
//        [self loadCiblessBrowserMainMenu];

    return NO;
}
@end
