//
//  RSWebSocketApplication.m
//  RSWebSocketApplication
//
//  Created by Richard Sarkis on 7/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RSWebSocketApplication.h"

const char * get_message_type(int mtype) {
    switch (mtype) {
        case MESSAGE_TYPEID_WELCOME: return "Welcome";
        case MESSAGE_TYPEID_PREFIX: return "Prefix";
        case MESSAGE_TYPEID_CALL: return "Call";
        case MESSAGE_TYPEID_CALL_RESULT: return "Call Result";
        case MESSAGE_TYPEID_CALL_ERROR: return "Call Error";
        case MESSAGE_TYPEID_SUBSCRIBE: return "Subscribe";
        case MESSAGE_TYPEID_UNSUBSCRIBE: return "Unsubscribe";
        case MESSAGE_TYPEID_PUBLISH: return "Publish";
        case MESSAGE_TYPEID_EVENT: return "Event";
    }
    return "Unknown Event";
}


@implementation RSWebSocketApplication

@synthesize delegate;
@synthesize ws;
@synthesize version;

#pragma mark RSWebSocketApplication Class Lifecycle
+ (id) webSocketApplicationConnectWithUrl: (NSString *) aURLString delegate:(id<RSWebSocketApplicationDelegate>) aDelegate {
    return [[[self class] alloc] initWebSocketApplicationConnectWithUrl:aURLString delegate:aDelegate];
}

- (id) initWebSocketApplicationConnectWithUrl: (NSString *) aURLString delegate:(id<RSWebSocketApplicationDelegate>) aDelegate {
    self = [super init];
    if (self) {
        self.version = WebSocketApplictionVersion01;
        
        self.delegate = aDelegate;
        
        // Insert code here to initialize your WebSocket application connection.
        // TODO Make sure we handle the named parameters for WebSocket, if needed.
        RSWebSocketConnectConfig* config = [RSWebSocketConnectConfig configWithURLString:aURLString 
                                                                                  origin:@"ws://localhost" 
                                                                               protocols:[NSMutableArray arrayWithObjects:@"wamp", nil]
                                                                             tlsSettings:nil 
                                                                                 headers:nil 
                                                                       verifySecurityKey:YES 
                                                                              extensions:nil ];
        ws = [RSWebSocket webSocketWithConfig:config delegate:self];
        [self.ws open];  
    }
    
    callList = [[NSMutableDictionary alloc] init];
    registeredRpcList = [[NSMutableDictionary alloc] init];
    prefixes = [[NSMutableDictionary alloc] init];
    
    return self;
}

- (void) closeWebSocketApplicationConnection
{
    NSLog(@"Closing WebSocket connection");
    [ws close];
}

#pragma mark RSWebSocketApplication Registrations
//Register an service object for RPC. A service object has methods which are decorated using @exportRpc.
- (void) registerForRpc:(id)target baseUri:(NSString *)uri;
{
    NSString *key = uri;
    
    NSURL *url = [NSURL URLWithString:uri];
    if ([[url scheme] compare:@"http"] != NSOrderedSame) {
        // We have a curie, normalize to full standard URI
        NSString *curie = [[uri componentsSeparatedByString:@":"] objectAtIndex:0];
        NSString *rpcName = [[uri componentsSeparatedByString:@":"] objectAtIndex:1];
        key = [NSString stringWithFormat:@"%@%@", [prefixes objectForKey:curie], rpcName];
    }
    
    // We'll set the argument when we get a callresult or a callerror type, above.
    // For now, store it in our dictionary.
    [registeredRpcList setObject:@{@"target":target,@"selector":[NSNull null]} forKey:key];
}

//Register a method of an object for RPC.
- (void) registerMethodForRpc:(id)target selector:(NSString *)selector baseUri:(NSString *)uri
{
    NSString *key = uri;
    
    NSURL *url = [NSURL URLWithString:uri];
    if ([[url scheme] compare:@"http"] != NSOrderedSame) {
        // We have a curie, normalize to full standard URI
        NSString *curie = [[uri componentsSeparatedByString:@":"] objectAtIndex:0];
        NSString *rpcName = [[uri componentsSeparatedByString:@":"] objectAtIndex:1];
        key = [NSString stringWithFormat:@"%@%@", [prefixes objectForKey:curie], rpcName];
    }
    
    // We'll set the argument when we get a callresult or a callerror type, above.
    // For now, store it in our dictionary.
    [registeredRpcList setObject:@{@"target":target,@"selector":selector} forKey:key];
}



//Register a (free standing) function/procedure for RPC.
//- (void) registerProcedureForRpc(uri, proc);

//Register a handler on an object for RPC.
//- (void) registerHandlerMethodForRpc(uri, obj, handler, extra=None);

//Register a (free standing) handler for RPC.
//- (void) registerHandlerProcedureForRpc(uri, handler, extra=None);

// Register a topic URI as publish/subscribe channel in this session.
//- (void) registerForPubSub;

// Register a handler object for PubSub.
//- (void) registerHandlerForPubSub;

// Register a method of an object as subscription handler.
//- (void) registerHandlerForSub;

// Register a method of an object as publication handler.
//- (void) registerHandlerForPub;


#pragma mark WAMP Server Events
- (void) receivedWelcomeMessage: (NSArray *) message {
    // For MESSAGE_TYPEID_WELCOME    
    sessionId = [message objectAtIndex:1];
    protocol_version = [[message objectAtIndex:2] intValue];
    serverIdent = [message objectAtIndex:3];
    
    [self dispatchWelcomed];    
}

- (void) receivedCallMessage: (NSArray *) message
{
    // FIXME unused. SHould be used for deferred, asynchronous calling tracking
    //NSString *typeId      = [message objectAtIndex:0];
    NSString *callId      = [message objectAtIndex:1];
    NSString *callprocURI = [message objectAtIndex:2];
    id callArgs           = [message objectAtIndex:3];
        
    id parameters = [callArgs objectForKey:@"parameters"];
    NSString *sentSelector = [callArgs objectForKey:@"selector"];
    
    NSURL *url = [NSURL URLWithString:callprocURI];
    NSString *key = callprocURI;
    if ([[url scheme] compare:@"http"] != NSOrderedSame) {
        // We have a curie, normalize to full standard URI
        NSString *curie = [[callprocURI componentsSeparatedByString:@":"] objectAtIndex:0];
        NSString *rpcName = [[callprocURI componentsSeparatedByString:@":"] objectAtIndex:1];
        key = [NSString stringWithFormat:@"%@%@", [prefixes objectForKey:curie], rpcName];
    }
    id target = [[registeredRpcList objectForKey:callprocURI] objectForKey:@"target"];
    NSString *selector = [[registeredRpcList objectForKey:callprocURI] objectForKey:@"selector"];
    
    if (![selector isKindOfClass:[NSNull class]] && [selector compare:sentSelector] != NSOrderedSame) {
        NSLog(@"receivedCallMessage: unregistered selector sent to object");
        return;
    }
    NSInvocation *inv = [self makeInvocationWithTarget:target selector:sentSelector parameters:parameters];
    
    // Handy technique learned here: http://stackoverflow.com/a/7078442/1724341
    CFTypeRef result = nil;

    id returnObj;
    [inv invoke];
    if ([[inv methodSignature] methodReturnLength] > 0) {
        [inv getReturnValue:&result];
    }
    
    if (result) {
        CFRetain(result);
        returnObj = (__bridge_transfer id)result;
    } else {
        // invocation has no return value, and result is nil
        returnObj = @"null";
    }
    
    
    NSError *e = nil;
    NSData *jsonData;
    //build an message object and convert to json
    NSMutableArray *resultMessage = [NSMutableArray arrayWithObjects:
                                     [NSNumber numberWithInt:MESSAGE_TYPEID_CALL_RESULT],
                                     callId,
                                     returnObj,
                                     nil];
    
    jsonData = [NSJSONSerialization dataWithJSONObject:resultMessage options:kNilOptions error:&e];
    
    if (!jsonData)
        NSLog(@"Error parsing JSON string for message: %@", e);
    
    [ws sendText:[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
}

- (void) receivedCallResultMessage: (NSArray *) message {
    // For MESSAGE_TYPEID_CALL_RESULT
    NSString *callId;
    id callResult; // We may receive a converted JSON value that maps to a simple or complex data type
    
    callId = [message objectAtIndex:1];
    callResult = [message objectAtIndex:2];
    
    NSInvocation *callInv = [[callList objectForKey:callId] objectAtIndex:0];
    if (callInv) {
        // The parameter to this invocation
        // Note that we pass it at index 2 - indices 0 and 1
        // are taken by the hidden arguments self and _cmd, accessible through -setTarget:
        // and -setSelector:
        [callInv setArgument:&callResult atIndex:2];
        [callInv invoke]; // We don't care about the return value?
        
        // Call is done, remove from dictionary
        [callList removeObjectForKey:callId];
    } else {
        NSLog(@"Warning: Received unsolicited CALLRESULT: %@", callId);
    }
}

- (void) receivedCallErrorMessage: (NSArray *) message {
    // For MESSAGE_TYPEID_CALL_ERROR
    NSString *callId;
    NSString *errorURI;
    NSString *errorDesc;
    id errorDetails; // We may receive a converted JSON value that maps to a simple or complex data type
    callId = [message objectAtIndex:1];
    errorURI = [message objectAtIndex:2];
    errorDesc = [message objectAtIndex:3]; // Always present, may be empty.
    
    if ([message count] - 1 == 4) 
        errorDetails = [message objectAtIndex:4]; // Optional, but cannot be empty 
                                                  // and must be human-readable
    
    NSInvocation *callInv = [[callList objectForKey:callId] objectAtIndex:1];
    if (callInv) {
        // The parameter to this invocation
        // Note that we pass it at index 2 - indices 0 and 1
        // are taken by the hidden arguments self and _cmd, accessible through -setTarget:
        // and -setSelector:
        [callInv setArgument:&errorURI atIndex:2];
        [callInv setArgument:&errorDesc atIndex:3];
        if (errorDetails)
            [callInv setArgument:&errorDetails atIndex:4];

        [callInv invoke]; // We don't care about the return value?
        
        // Call is done, remove from dictionary
        [callList removeObjectForKey:callId];
    } else {
        NSLog(@"Warning: Received unsolicited CALLERROR: %@", callId);
    }

    NSLog(@"Error received: %@ %@ %@", callId, errorURI, errorDesc);
}

- (void) receivedEventMessage: (NSArray *) message {
    // For MESSAGE_TYPEID_EVENT
    NSString *topicUri;
    id event; // We may receive a converted JSON value that maps to a simple or complex data type
    
    topicUri = [message objectAtIndex:1];
    event = [message objectAtIndex:2];
    
    // Delegate notification
    [self dispatchEvent:topicUri event:event];
}


#pragma mark WAMP Client Events
- (void) sendPrefixMessage:(NSString *)prefix uri:(NSString *)uri {
    NSError *e = nil;
    NSData *jsonData;
    
    //build an message object and convert to json
    NSArray* message = [NSArray arrayWithObjects:
                        [NSNumber numberWithInt:MESSAGE_TYPEID_PREFIX],
                        prefix,
                        uri,
                        nil];
    
    jsonData = [NSJSONSerialization dataWithJSONObject:message options:kNilOptions error:&e];
    
    if (!jsonData)
        NSLog(@"Error parsing JSON string for message: %@", e);
    
    [prefixes setValue:uri forKey:prefix];
    [prefixes  setValue:prefix forKey:uri];


    [ws sendText:[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
}

- (void) sendCallMessage:(NSString *) uri target:(id)target resultSelector:(SEL)cSel errorSelector:(SEL)eSel args:(id)callArgs {

    NSError *e = nil;
    NSData *jsonData;
    
    NSString *callId = [self genRandStringLength:16];
    
    //build an message object and convert to json
    NSMutableArray* message = [NSMutableArray arrayWithObjects:
                        [NSNumber numberWithInt:MESSAGE_TYPEID_CALL],
                        callId,
                        uri,
                        nil];
    
    if ([callArgs isKindOfClass: [NSArray class]]){
        message = [NSMutableArray arrayWithArray:message];
        [message addObjectsFromArray:callArgs];
    } else {
        [message addObject:callArgs];
    }
    
    jsonData = [NSJSONSerialization dataWithJSONObject:message options:kNilOptions error:&e];
    
    if (!jsonData)
        NSLog(@"Error parsing JSON string for message: %@", e);
    
    [ws sendText:[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
    
    // Record our call's information for later, asynchronous return of data
    [self addCallToList:callId target:target resultSelector:cSel errorSelector:eSel];
}

- (void) sendSubscribeMessage:(NSString*)topicUri {
    // [ TYPE_ID_SUBSCRIBE , topicURI ]
    NSError *e = nil;
    NSData *jsonData;
    
    //build an message object and convert to json
    NSArray* message = [NSArray arrayWithObjects:
                        [NSNumber numberWithInt:MESSAGE_TYPEID_SUBSCRIBE],
                        topicUri,
                        nil];
        
    jsonData = [NSJSONSerialization dataWithJSONObject:message options:kNilOptions error:&e];

    if (!jsonData)
        NSLog(@"Error parsing JSON string for message: %@", e);
    
    [ws sendText:[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
}

- (void) sendUnsubscribeMessage:(NSString*)topicUri {
    // [ TYPE_ID_UNSUBSCRIBE , topicURI ]
    NSError *e = nil;
    NSData *jsonData;
    
    //build an message object and convert to json
    NSArray* message = [NSArray arrayWithObjects:
                        [NSNumber numberWithInt:MESSAGE_TYPEID_UNSUBSCRIBE],
                        topicUri,
                        nil];
    
    jsonData = [NSJSONSerialization dataWithJSONObject:message options:kNilOptions error:&e];
    
    if (!jsonData)
        NSLog(@"Error parsing JSON string for message: %@", e);
    
    [ws sendText:[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
}

- (void) sendPublishMessage:(NSString*)topicUri event:(id)event {
    // [ TYPE_ID_PUBLISH , topicURI, event ]
    // By default, this method will include ourselves as the recipient of our own PubSub message
    [self sendPublishMessage:topicUri event:event excludeMe:FALSE];
}

- (void) sendPublishMessage:(NSString*)topicUri event:(id)event excludeMe:(BOOL)exclude {
    // [ TYPE_ID_PUBLISH , topicURI, event, excludeMe ]
    NSError *e = nil;
    NSData *jsonData;
    
    //build an message object and convert to json
    NSArray *exclusionList;
    if (exclude) {
        exclusionList = [NSArray arrayWithObjects:sessionId, nil];
    } else {
        exclusionList = [NSArray arrayWithObjects: nil];
    }
    
    NSArray* message = [NSArray arrayWithObjects:
                        [NSNumber numberWithInt:MESSAGE_TYPEID_PUBLISH],
                        topicUri,
                        event,
                        exclusionList,
                        nil];
    
    jsonData = [NSJSONSerialization dataWithJSONObject:message options:kNilOptions error:&e];
    
    if (!jsonData)
        NSLog(@"Error parsing JSON string for message: %@", e);
    
    [ws sendText:[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
}

- (void) sendPublishMessage:(NSString*)topicUri event:(id)event exclude:(NSArray *)exclude eligible:(NSArray *)eligible
{
    // [ TYPE_ID_PUBLISH , topicURI, event, exclude, eligible ]
    NSError *e = nil;
    NSData *jsonData;
    
    //build an message object and convert to json
    NSArray* message = [NSArray arrayWithObjects:
                        [NSNumber numberWithInt:MESSAGE_TYPEID_PUBLISH],
                        topicUri,
                        event,
                        exclude,
                        eligible,
                        nil];
    
    jsonData = [NSJSONSerialization dataWithJSONObject:message options:kNilOptions error:&e];
    
    if (!jsonData)
        NSLog(@"Error parsing JSON string for message: %@", e);
    
    [ws sendText:[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
}

#pragma mark RSWebSocketApplication Delegate Dispatch
- (void) dispatchWelcomed {
    if (delegate) [delegate didWelcome];
}

- (void) dispatchEvent: (NSString*)topicUri event:(id)event {
    if (delegate) [delegate didEvent:(NSString*)topicUri event:(id)event];
}

#pragma mark RSWebSocket Delegates
- (void) didOpen {
    NSLog(@"Connection Open to WebSocket Server");
}

- (void) didClose:(NSError *) closingStatusError
        localCode:(NSUInteger) closingStatusLocalCode
     localMessage:(NSString *) closingStatusLocalMessage
       remoteCode:(NSUInteger) closingStatusRemoteCode
    remoteMessage:(NSString *) closingStatusRemoteMessage {
    NSLog(@"Connection Closed to WebSocket Server");
}

- (void) didReceiveTextMessage: (NSString*) aMessage {    
    NSError *e = nil;
    NSArray *message = [NSJSONSerialization 
                         JSONObjectWithData: [aMessage dataUsingEncoding:NSUTF8StringEncoding] 
                         options: NSJSONReadingMutableContainers 
                         error: &e];
    
    if (!message) {
        NSLog(@"Error parsing JSON string for message: %@", e);
        [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:0.0];
    }
    
        
    int message_type = [[message objectAtIndex:0] intValue];
    NSLog(@"Received message type %s (id %d)", get_message_type(message_type), message_type);
    
    // We should receive SERVER messages here.
    switch (message_type) {
        case MESSAGE_TYPEID_WELCOME:
            [self receivedWelcomeMessage:message];
            break;
        case MESSAGE_TYPEID_CALL_RESULT:
            [self receivedCallResultMessage:message];
            break;
        case MESSAGE_TYPEID_CALL_ERROR:
            [self receivedCallErrorMessage:message];
            break;
        case MESSAGE_TYPEID_EVENT:
            [self receivedEventMessage:message];
            break;
        case MESSAGE_TYPEID_CALL:
            // AS of AutobahnPython release 0.6.3, symmetric RPC is now supported
            // Allowing the server to call RPC endpoints on the client.
            [self receivedCallMessage:message];
            break;
        case MESSAGE_TYPEID_PREFIX:
            // Not supported
        case MESSAGE_TYPEID_SUBSCRIBE:
            // Not supported
        case MESSAGE_TYPEID_UNSUBSCRIBE:
            // Not supported
        case MESSAGE_TYPEID_PUBLISH:
            // Not supported
        default:
            // Will WAMP ever be a Peer-to-Peer protocol?
            NSLog(@"Received unexpected client message from server! Attempting to ignore.");
            NSLog(@"Unexpected message from server: %@", aMessage);
            break;
    }

}

- (void) didReceiveBinaryMessage: (NSData*) aMessage {
    NSLog(@"Received a binary message");
    // WAMP does not support binary messages yet, of any sort.
}

- (void) didReceiveError: (NSError*) aError {
    NSLog(@"Error: errorDesc=%@, failureReason=%@", [aError localizedDescription], [aError localizedFailureReason]);
}

#pragma mark Utility functions
-(NSInvocation *) makeInvocationWithTarget:(id)target selector:(NSString *)selectorString parameters:(NSArray *)parameters
{
    SEL selector = sel_registerName([selectorString cStringUsingEncoding:NSASCIIStringEncoding]);
    NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[target methodSignatureForSelector:selector]];
    
    [inv setSelector:selector];
    [inv setTarget:target];
    int index = 2; // indices 0,1 are for self and _cmd
    
    for (id param in parameters) {
        if ([param isKindOfClass:[NSNumber class]] && strcmp([param objCType], @encode(BOOL)) == 0) {
            // FIXME: Cocoa decodes boolean values in JSON into the NSNumber Foundation type.
            // Since NSNumber can wrap a variety of numerical types, this technique is used to determine
            // if the value is a boolean.
            // In the future, we'll process the JSON-converted data types according to the type encodings
            // of the method being called.
            NSLog(@"this is a bool");
            BOOL val = [param boolValue];
            [inv setArgument:(void *)&val atIndex:index];
        } else {
            [inv setArgument:(void *)&param atIndex:index];
        }
        index+=1;
    }
    
    return inv;
}

-(void) addCallToList:(NSString *) callId target:(id)callBackObj resultSelector:(SEL)rSel errorSelector:(SEL)eSel {
//    NSLog(@"%@ %@ %@ %@ %@ %@",callId, callBackObj, NSStringFromSelector(rSel), NSStringFromSelector(eSel), [callBackObj methodSignatureForSelector:rSel],[callBackObj methodSignatureForSelector:eSel]);
    
    //This invocation is going to be of the form aSelector
    NSInvocation *aRInv = [NSInvocation invocationWithMethodSignature:[callBackObj methodSignatureForSelector:rSel]];
    NSInvocation *aEInv = [NSInvocation invocationWithMethodSignature:[callBackObj methodSignatureForSelector:eSel]];

    //This invocation is going to be an invocation of aSelector
    [aRInv setSelector:rSel];
    [aEInv setSelector:eSel];

    //This invocation is going to send its message to self
    [aRInv setTarget:callBackObj];
    [aEInv setTarget:callBackObj];

    // We'll set the argument when we get a callresult or a callerror type, above.
    // For now, store it in our dictionary.
    NSArray *invArray = [NSArray arrayWithObjects: aRInv, aEInv, nil];
    [callList setObject:invArray forKey:callId];
}

NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
-(NSString *) genRandStringLength: (int) len {
    
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random() % [letters length]]];
    }
    
    return randomString;
}
@end
