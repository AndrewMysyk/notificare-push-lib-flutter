#import "NotificarePushLibPlugin.h"
#import "NotificarePushLib.h"
#import "NotificarePushLibUtils.h"

@interface NotificarePushLibPlugin () <FlutterStreamHandler,NotificarePushLibDelegate>
@end

@implementation NotificarePushLibPlugin {
    FlutterMethodChannel *_channel;
    FlutterEventSink _eventSink;
    NSDictionary *_launchOptions;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"notificare_push_lib"
                                     binaryMessenger:[registrar messenger]];

    NotificarePushLibPlugin* instance = [[NotificarePushLibPlugin alloc] initWithChannel:channel];
    [registrar addApplicationDelegate:instance];
    [registrar addMethodCallDelegate:instance channel:channel];
    
    FlutterEventChannel* eventsChannel = [FlutterEventChannel
                                          eventChannelWithName:@"notificare_push_lib/events"
                                          binaryMessenger:[registrar messenger]];
    [eventsChannel setStreamHandler:instance];
}

- (instancetype)initWithChannel:(FlutterMethodChannel *)channel {
    self = [super init];
    if (self) {
        _channel = channel;
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"initializeWithKeyAndSecret" isEqualToString:call.method]) {
      [[NotificarePushLib shared] initializeWithKey:nil andSecret:nil];
      [[NotificarePushLib shared] setDelegate:self];
      [[NotificarePushLib shared] didFinishLaunchingWithOptions:_launchOptions];
      result([NSNull null]);
  } else if ([@"launch" isEqualToString:call.method]) {
      [[NotificarePushLib shared] launch];
      result([NSNull null]);
  } else if ([@"registerForNotifications" isEqualToString:call.method]) {
      [[NotificarePushLib shared] registerForNotifications];
      result([NSNull null]);
  } else if ([@"unregisterForNotifications" isEqualToString:call.method]) {
      [[NotificarePushLib shared] unregisterForNotifications];
      result([NSNull null]);
  } else if ([@"isRemoteNotificationsEnabled" isEqualToString:call.method]) {
      result([NSNumber numberWithBool:[[NotificarePushLib shared] remoteNotificationsEnabled]]);
  } else if ([@"isAllowedUIEnabled" isEqualToString:call.method]) {
      result([NSNumber numberWithBool:[[NotificarePushLib shared] allowedUIEnabled]]);
  } else if ([@"isNotificationFromNotificare" isEqualToString:call.method]) {
      result([NSNumber numberWithBool:[[NotificarePushLib shared] isNotificationFromNotificare:call.arguments]]);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

-(void)notificarePushLib:(NotificarePushLib *)library onReady:(NotificareApplication *)application{
    _eventSink(@{@"event":@"ready", @"body": [[NotificarePushLibUtils shared] dictionaryFromApplication:application]});
}

-(void)sendEvent:(NSDictionary*)event{
    if (!_eventSink) {
        return;
    }
    _eventSink(event);
}

#pragma mark AppDelegate implementation
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    if (launchOptions != nil) {
        _launchOptions = launchOptions;
    }
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options{
    [[NotificarePushLib shared] handleOpenURL:url withOptions:options];
    NSMutableDictionary * payload = [NSMutableDictionary new];
    [payload setObject:[url absoluteString] forKey:@"url"];
    [payload setObject:options forKey:@"options"];
    _eventSink(@{@"event":@"urlOpened", @"body": payload});
    return YES;
}

-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(nonnull NSData *)deviceToken {
    [[NotificarePushLib shared] didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (BOOL)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
    [[NotificarePushLib shared] didReceiveRemoteNotification:userInfo completionHandler:^(id  _Nullable response, NSError * _Nullable error) {
        if (!error) {
            completionHandler(UIBackgroundFetchResultNewData);
        } else {
            completionHandler(UIBackgroundFetchResultNoData);
        }
    }];
    return YES;
}

-(void)application:(UIApplication *)application handleActionWithIdentifier:(nullable NSString *)identifier forRemoteNotification:(nonnull NSDictionary *)userInfo withResponseInfo:(nonnull NSDictionary *)responseInfo completionHandler:(nonnull void (^)())completionHandler{
    [[NotificarePushLib shared] handleActionWithIdentifier:identifier forRemoteNotification:userInfo withResponseInfo:responseInfo completionHandler:^(id  _Nullable response, NSError * _Nullable error) {
        completionHandler();
    }];
}

-(void)application:(UIApplication *)application handleActionWithIdentifier:(nullable NSString *)identifier forRemoteNotification:(nonnull NSDictionary *)userInfo completionHandler:(nonnull void (^)())completionHandler{
    [[NotificarePushLib shared] handleActionWithIdentifier:identifier forRemoteNotification:userInfo withResponseInfo:nil completionHandler:^(id  _Nullable response, NSError * _Nullable error) {
        completionHandler();
    }];
}


#pragma mark FlutterStreamHandler implementation
- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)eventSink {
    _eventSink = eventSink;
    return nil;
}

- (FlutterError*)onCancelWithArguments:(id)arguments {
    _eventSink = nil;
    return nil;
}

@end
