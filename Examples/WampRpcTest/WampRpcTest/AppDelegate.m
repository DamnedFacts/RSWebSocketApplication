//
//  AppDelegate.m
//  WampRpcTest
//
//  Created by Richard Sarkis on 8/23/12.
//  Copyright (c) 2012 Richard Sarkis. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

BOOL flag = YES;

@synthesize wsa;
@synthesize response;
@synthesize window = _window;
@synthesize textViewResults;
@synthesize scrollViewResults;
@synthesize calculatorResult;
@synthesize calculatorWindow;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{    
    // Insert code here to initialize your application
    wsa = [RSWebSocketApplication webSocketApplicationConnectWithUrl: @"ws://localhost:9000/" delegate:self];
    
    pipe = [NSPipe pipe] ;
    pipeReadHandle = [pipe fileHandleForReading];
    dup2([[pipe fileHandleForWriting] fileDescriptor], STDERR_FILENO) ;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(getData:)
                                                 name:NSFileHandleReadCompletionNotification
                                               object:pipeReadHandle];
    
    [pipeReadHandle readInBackgroundAndNotify];
    
    [calculatorWindow setTitle:@"WAMP Calculator"];
    [calculatorResult setEditable:NO];
    
    // Initial value for calculator
    val = @"0";
    [calculatorResult setStringValue:@"0"];
}

- (void) getData: (NSNotification *) aNotification {
    [pipeReadHandle readInBackgroundAndNotify];
    
    NSString *str = [[NSString alloc] initWithData: [[aNotification userInfo] objectForKey: NSFileHandleNotificationDataItem]
                                          encoding: NSASCIIStringEncoding] ;
    
    // Get text storage of the NSTextView and append text to it.
	NSAttributedString *string = [[NSAttributedString alloc] initWithString:str];
	NSTextStorage *storage = [textViewResults textStorage];
    
	[storage beginEditing];
	[storage appendAttributedString:string];
	[storage endEditing];
    
    // Scroll to bottom after appending
    NSRange end_pos = NSMakeRange([storage length], 0);
    [textViewResults scrollRangeToVisible:end_pos];
}


#pragma mark RSWebSocketApplication Delege Methods
- (void) didWelcome
{
    rpcUri   = @"http://example.com/simple/calculator#";
    rpcCurie = @"calculator";

    [wsa sendPrefixMessage:rpcCurie uri:rpcUri];
}

- (IBAction)calculatorButtonPressed:(id)sender
{
    // Value literal paired with operator.
    //e.g.: {"op":"+","num":"1"}
    //      {"op":"=","num":"2"}
    //      (1 +) (2 =) 3
    NSString *call = [NSString stringWithFormat:@"%@:calc", rpcCurie];
    NSString *buttonValue = [sender title];
    NSArray  *callArgs;
    NSDictionary *opArgs;
        
    if ([buttonValue isEqualToString:@"C"]) {
        op = buttonValue;
        opArgs = [NSDictionary dictionaryWithObjectsAndKeys:op, @"op", nil];
        callArgs = [NSArray arrayWithObjects:opArgs, nil];
        op = val = [NSString new];
        [calculatorResult setStringValue:@"0"];
        [wsa sendCallMessage:call target:self selector:@selector(callBack:) args:callArgs];
    } else if ([val length]) {
        if ([buttonValue isEqualToString:@"+"] ||
            [buttonValue isEqualToString:@"-"] ||
            [buttonValue isEqualToString:@"*"] ||
            [buttonValue isEqualToString:@"/"] ||
            [buttonValue isEqualToString:@"="]) {
            op = buttonValue;
            
            opArgs = [NSDictionary dictionaryWithObjectsAndKeys:op, @"op", val, @"num", nil];
            callArgs = [NSArray arrayWithObjects:opArgs, nil];
            [wsa sendCallMessage:call target:self selector:@selector(callBack:) args:callArgs];
            op = val = [NSString new];
        }
    } else if (![val length] || [val isEqualToString:@"0"]) {
            val = buttonValue;
    }    
}

- (void) callBack:(id)value
{
    NSLog(@"Event received: %@", value);
    [calculatorResult setStringValue:value];
}

@end