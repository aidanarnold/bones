#import "AppDelegate.h"

#import <React/RCTLinkingManager.h>

#import "mParticle.h"
#import <AppTrackingTransparency/AppTrackingTransparency.h>

#import "URLDelegate.h"

@import BrazeKit;

#import <React/RCTBundleURLProvider.h>

@implementation AppDelegate

URLDelegate *urlDelegate = [[URLDelegate alloc] init];

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  // Initialize mParticle
  NSString *mParticleEnv = @"MPARTICLE_ENV";
  NSString *mParticleApiKey = @"MPARTICLE_API_KEY";
  NSString *mParticleApiSecret = @"MPARTICLE_API_SECRET";

  MParticleOptions *mParticleOptions =
    [MParticleOptions optionsWithKey:mParticleApiKey secret:mParticleApiSecret];
  mParticleOptions.proxyAppDelegate = NO;
  mParticleOptions.logLevel = MPILogLevelVerbose;

  if (@available(iOS 14, *)) {
    mParticleOptions.attStatus = @([ATTrackingManager trackingAuthorizationStatus]);
  }

  if ([mParticleEnv isEqualToString:@"production"]) {
    mParticleOptions.environment = MPEnvironmentProduction;
  } else {
    mParticleOptions.environment = MPEnvironmentDevelopment;
  }

  [[MParticle sharedInstance] startWithOptions:mParticleOptions];
  
  NSMutableDictionary *newLaunchOptions = [NSMutableDictionary dictionaryWithDictionary:launchOptions];
  if (launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]) {
    NSDictionary *remoteNotif = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    // This will be present if a push notification with deeplink opened the app
    // We need to move this value to a different key so that it gets passed to `Linking.getInitialURL`
    if (remoteNotif[@"ab_uri"] && !launchOptions[UIApplicationLaunchOptionsURLKey]) {
      NSString *initialURL = remoteNotif[@"ab_uri"];
      newLaunchOptions[UIApplicationLaunchOptionsURLKey] = [NSURL URLWithString:remoteNotif[@"ab_uri"]];
    }
  }
  
  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
      [notificationCenter addObserver:self
                             selector:@selector(handleKitDidBecomeActive:)
                                 name:mParticleKitDidBecomeActiveNotification
                               object:nil];
  
  self.moduleName = @"bones";
  // You can add your custom initial props in the dictionary below.
  // They will be passed down to the ViewController used by React Native.
  self.initialProps = @{};

  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (void)handleKitDidBecomeActive:(NSNotification *)notification {
  NSDictionary *userInfo = [notification userInfo];
  NSNumber *kitNumber = userInfo[mParticleKitInstanceKey];
  MPKitInstance kitInstance = (MPKitInstance)[kitNumber integerValue];
  
  if (kitInstance == MPKitInstanceAppboy) {
    Braze *braze = [[MParticle sharedInstance] kitInstance:@28];
    if (braze) {
      braze.delegate = urlDelegate;
    }
  }
}

- (NSURL *)sourceURLForBridge:(RCTBridge *)bridge
{
  return [self getBundleURL];
}
 
- (NSURL *)getBundleURL
{
#if DEBUG
  return [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index"];
#else
  return [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"jsbundle"];
#endif
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(nonnull NSUserActivity *)userActivity
 restorationHandler:(nonnull void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler
{
 return [RCTLinkingManager application:application
                  continueUserActivity:userActivity
                    restorationHandler:restorationHandler];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
        return [RCTLinkingManager application:application openURL:url options:options];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  [[MParticle sharedInstance] didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)registerForPushNotifications {
  if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_9_x_Max) {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;
    UNAuthorizationOptions options = UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge;
    if (@available(iOS 12.0, *)) {
    options = options | UNAuthorizationOptionProvisional;
    }
    [center requestAuthorizationWithOptions:options
                          completionHandler:^(BOOL granted, NSError * _Nullable error) {
    }];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
  } else {
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeBadge | UIUserNotificationTypeAlert | UIUserNotificationTypeSound) categories:nil];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
  }
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
  [[MParticle sharedInstance] didFailToRegisterForRemoteNotificationsWithError:error];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
  [[MParticle sharedInstance] didReceiveRemoteNotification:userInfo];
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
  [[MParticle sharedInstance] userNotificationCenter:center didReceiveNotificationResponse:response];
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
  completionHandler(UNNotificationPresentationOptionAlert);
}

@end
