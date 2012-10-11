//
//  AppDelegate.h
//  WampRpcTest
//
//  Created by Richard Sarkis on 8/23/12.
//  Copyright (c) 2012 Richard Sarkis. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <RSWebSocketApplication/RSWebSocketApplication.h>

@interface AppDelegate : NSObject <NSApplicationDelegate,RSWebSocketApplication> {
    RSWebSocketApplication* wsa;
    NSString* response;
    NSPipe *pipe;
    NSFileHandle *pipeReadHandle;
    NSString *rpcUri;
    NSString *rpcCurie;
    NSString *op;
    NSString *val;
}

#pragma mark Interface Builder Outlets
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTextView *textViewResults;
@property (assign) IBOutlet NSScrollView *scrollViewResults;
@property (assign) IBOutlet NSTextField *calculatorResult;
@property (assign) IBOutlet NSWindow *calculatorWindow;

#pragma mark Internal variables
@property (nonatomic, readonly) RSWebSocketApplication* wsa;
@property (nonatomic, readonly) NSString* response;

@end
