//
//  RSWebSocketApplication.h
//  RSWebSocketApplication
//
//  Created by Richard Sarkis on 7/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RSWebSocket/RSWebSocket.h>

enum
{
    WebSocketApplictionVersion01 = 1
};
typedef NSUInteger WebSocketApplicationVersion;


#pragma mark WAMP Message Types
enum {
    // WAMP version this server speaks. Versions are numbered consecutively
    // (integers, no gaps).
    MESSAGE_TYPEID_WELCOME        = 0,
    // Server-to-client welcome message containing session ID.
    MESSAGE_TYPEID_PREFIX         = 1,
    // Client-to-server message establishing a URI prefix to be used in CURIEs.
    MESSAGE_TYPEID_CALL           = 2,
    // Client-to-server message initiating an RPC.
    MESSAGE_TYPEID_CALL_RESULT    = 3,
    // Server-to-client message returning the result of a successful RPC.
    MESSAGE_TYPEID_CALL_ERROR     = 4,
    // Server-to-client message returning the error of a failed RPC.
    MESSAGE_TYPEID_SUBSCRIBE      = 5,
    // Client-to-server message subscribing to a topic.
    MESSAGE_TYPEID_UNSUBSCRIBE    = 6,
    // Client-to-server message unsubscribing from a topic.
    MESSAGE_TYPEID_PUBLISH        = 7,
    // Client-to-server message publishing an event to a topic.
    MESSAGE_TYPEID_EVENT          = 8
    // Server-to-client message providing the event of a (subscribed) topic.
};
typedef NSUInteger RSWebSocketApplicationMessageType;

#pragma mark WAMP delegate class
@protocol RSWebSocketApplication <NSObject>

/**
   Called when the web socket application messaging protocol connects
   with a successful welcome message and is ready for reading and writing.
 **/
- (void) didWelcome;

@optional
/**
 Called when a subscriber receives an event
 **/
- (void) didEvent:(NSString*)topicUri event:(id)event;

@end


#pragma mark WAMP main class
@interface RSWebSocketApplication : NSObject <RSWebSocketDelegate> {
    id<RSWebSocketApplication> delegate;
    RSWebSocket* ws;
    NSString *sessionId;
    int protocol_version;
    NSString *serverIdent;
    NSMutableDictionary *callList;
    int Wamp_Protocol_Version;
    WebSocketApplicationVersion version;
}

// Callback delegate for websocket events.
@property(nonatomic,retain) id<RSWebSocketApplication> delegate;
@property (nonatomic, readonly) RSWebSocket* ws;
@property(nonatomic,assign) WebSocketVersion version;

+ (id) webSocketApplicationConnectWithUrl: (NSString *) aURLString delegate:(id<RSWebSocketApplication>) aDelegate;
- (id) initWebSocketApplicationConnectWithUrl: (NSString *) aURLString delegate:(id<RSWebSocketApplication>) aDelegate;
- (void) sendPrefixMessage:(NSString *)prefix uri:(NSString *)uri;
- (void) sendCallMessage:(NSString *) uri target:(id)target selector:(SEL)selector args:(id)args;
- (void) sendSubscribeMessage:(NSString*)topicUri;
- (void) sendUnsubscribeMessage:(NSString*)topicUri;
- (void) sendPublishMessage:(NSString*)topicUri event:(id)event;
- (void) sendPublishMessage:(NSString*)topicUri event:(id)event excludeMe:(BOOL)exclude;
- (void) sendPublishMessage:(NSString*)topicUri event:(id)event exclude:(NSArray *)exclude eligible:(NSArray *)eligible;
@end

@interface RSWebSocketApplication(Private)
- (void) dispatchFailure:(NSError*) aError;
- (void) dispatchClosed;
- (void) dispatchOpened;
@end