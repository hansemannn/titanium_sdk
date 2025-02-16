//
//  TiAdjustModule.m
//  Adjust SDK
//
//  Created by Uglješa Erceg (@uerceg) on 18th May 2017.
//  Copyright © 2017-2019 Adjust GmbH. All rights reserved.
//

#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"
#import "TiAdjustModule.h"
#import "TiAdjustModuleDelegate.h"

static NSString * const kSdkPrefix = @"titanium4.28.0";

@implementation TiAdjustModule

#pragma mark - Internal

- (id)moduleGUID {
    return @"4cf76f14-c96e-49e7-91c2-5136c790c39e";
}

- (NSString *)moduleId {
    return @"ti.adjust";
}

#pragma - Public APIs

- (void)start:(id)args {
    NSArray *configArray = (NSArray *)args;
    NSDictionary *params = (NSDictionary *)[configArray objectAtIndex:0];

    NSString *appToken = [params objectForKey:@"appToken"];
    NSString *environment = [params objectForKey:@"environment"];
    NSString *logLevel = [params objectForKey:@"logLevel"];
    NSString *userAgent = [params objectForKey:@"userAgent"];
    NSString *defaultTracker = [params objectForKey:@"defaultTracker"];
    NSString *externalDeviceId = [params objectForKey:@"externalDeviceId"];
    NSString *urlStrategy = [params objectForKey:@"urlStrategy"];
    NSString *secretId = [params objectForKey:@"secretId"];
    NSString *info1 = [params objectForKey:@"info1"];
    NSString *info2 = [params objectForKey:@"info2"];
    NSString *info3 = [params objectForKey:@"info3"];
    NSString *info4 = [params objectForKey:@"info4"];
    NSNumber *delayStart = [params objectForKey:@"delayStart"];
    NSNumber *sendInBackground = [params objectForKey:@"sendInBackground"];
    NSNumber *shouldLaunchDeeplink = [params objectForKey:@"shouldLaunchDeeplink"];
    NSNumber *eventBufferingEnabled = [params objectForKey:@"eventBufferingEnabled"];
    NSNumber *isDeviceKnown = [params objectForKey:@"isDeviceKnown"];
    NSNumber *allowiAdInfoReading = [params objectForKey:@"allowiAdInfoReading"];
    NSNumber *allowIdfaReading = [params objectForKey:@"allowIdfaReading"];
    NSNumber *handleSkAdNetwork = [params objectForKey:@"handleSkAdNetwork"];

    self.jsAttributionCallback = [[params objectForKey:@"attributionCallback"] retain];
    self.jsSessionSuccessCallback = [[params objectForKey:@"sessionSuccessCallback"] retain];
    self.jsSessionFailureCallback = [[params objectForKey:@"sessionFailureCallback"] retain];
    self.jsEventSuccessCallback = [[params objectForKey:@"eventSuccessCallback"] retain];
    self.jsEventFailureCallback = [[params objectForKey:@"eventFailureCallback"] retain];
    self.jsDeferredDeeplinkCallback = [[params objectForKey:@"deferredDeeplinkCallback"] retain];

    BOOL allowSuppressLogLevel = NO;

    if ([self isFieldValid:logLevel]) {
        if ([logLevel isEqualToString:@"SUPPRESS"]) {
            allowSuppressLogLevel = YES;
        }
    }

    ADJConfig *adjustConfig = [ADJConfig configWithAppToken:appToken environment:environment allowSuppressLogLevel:allowSuppressLogLevel];
    if (![adjustConfig isValid]) {
        return;
    }

    // SDK prefix.
    if ([self isFieldValid:kSdkPrefix]) {
        [adjustConfig setSdkPrefix:kSdkPrefix];
    }

    // Log level.
    if ([self isFieldValid:logLevel]) {
        [adjustConfig setLogLevel:[ADJLogger logLevelFromString:[logLevel lowercaseString]]];
    }

    // Event buffering.
    if ([self isFieldValid:eventBufferingEnabled]) {
        [adjustConfig setEventBufferingEnabled:[eventBufferingEnabled boolValue]];
    }

    // Default tracker.
    if ([self isFieldValid:defaultTracker]) {
        [adjustConfig setDefaultTracker:defaultTracker];
    }

    // External device ID.
    if ([self isFieldValid:externalDeviceId]) {
        [adjustConfig setExternalDeviceId:externalDeviceId];
    }

    // URL strategy.
    if ([self isFieldValid:urlStrategy]) {
        if ([urlStrategy isEqualToString:@"china"]) {
            [adjustConfig setUrlStrategy:ADJUrlStrategyChina];
        } else if ([urlStrategy isEqualToString:@"india"]) {
            [adjustConfig setUrlStrategy:ADJUrlStrategyIndia];
        }
    }

    // Send in background.
    if ([self isFieldValid:sendInBackground]) {
        [adjustConfig setSendInBackground:[sendInBackground boolValue]];
    }

    // User agent.
    if ([self isFieldValid:userAgent]) {
        [adjustConfig setUserAgent:userAgent];
    }

    // Delay start.
    if ([self isFieldValid:delayStart]) {
        [adjustConfig setDelayStart:[delayStart doubleValue]];
    }

    // App secret.
    if ([self isFieldValid:secretId]
        && [self isFieldValid:info1]
        && [self isFieldValid:info2]
        && [self isFieldValid:info3]
        && [self isFieldValid:info4]) {
        [adjustConfig setAppSecret:[[NSNumber numberWithLongLong:[secretId longLongValue]] unsignedIntegerValue]
                             info1:[[NSNumber numberWithLongLong:[info1 longLongValue]] unsignedIntegerValue]
                             info2:[[NSNumber numberWithLongLong:[info2 longLongValue]] unsignedIntegerValue]
                             info3:[[NSNumber numberWithLongLong:[info3 longLongValue]] unsignedIntegerValue]
                             info4:[[NSNumber numberWithLongLong:[info4 longLongValue]] unsignedIntegerValue]];
    }

    // Is device known.
    if ([self isFieldValid:isDeviceKnown]) {
        [adjustConfig setIsDeviceKnown:[isDeviceKnown boolValue]];
    }

    // iAd info reading.
    if ([self isFieldValid:allowiAdInfoReading]) {
        [adjustConfig setAllowiAdInfoReading:[allowiAdInfoReading boolValue]];
    }

    // IDFA reading.
    if ([self isFieldValid:allowIdfaReading]) {
        [adjustConfig setAllowIdfaReading:[allowIdfaReading boolValue]];
    }

    // SKAdNetwork handling.
    if ([self isFieldValid:handleSkAdNetwork]) {
        if ([handleSkAdNetwork boolValue] == false) {
            [adjustConfig deactivateSKAdNetworkHandling];
        }
    }

    // User defined callbacks.
    BOOL isAttributionCallbackImplemented = self.jsAttributionCallback != nil ? YES : NO;
    BOOL isEventSuccessCallbackImplemented = self.jsEventSuccessCallback != nil ? YES : NO;
    BOOL isEventFailureCallbackImplemented = self.jsEventFailureCallback != nil ? YES : NO;
    BOOL isSessionSuccessCallbackImplemented = self.jsSessionSuccessCallback != nil ? YES : NO;
    BOOL isSessionFailureCallbackImplemented = self.jsSessionFailureCallback != nil ? YES : NO;
    BOOL isDeferredDeeplinkCallbackImplemented = self.jsDeferredDeeplinkCallback != nil ? YES : NO;
    BOOL shouldLaunchDeferredDeeplink = [self isFieldValid:shouldLaunchDeeplink] ? [shouldLaunchDeeplink boolValue] : YES;

    // Callbacks.
    if (isAttributionCallbackImplemented
        || isEventSuccessCallbackImplemented
        || isEventFailureCallbackImplemented
        || isSessionSuccessCallbackImplemented
        || isSessionFailureCallbackImplemented
        || isDeferredDeeplinkCallbackImplemented) {
        [adjustConfig setDelegate:
         [TiAdjustModuleDelegate getInstanceWithSwizzleOfAttributionCallback:isAttributionCallbackImplemented
                                                        eventSuccessCallback:isEventSuccessCallbackImplemented
                                                        eventFailureCallback:isEventFailureCallbackImplemented
                                                      sessionSuccessCallback:isSessionSuccessCallbackImplemented
                                                      sessionFailureCallback:isSessionFailureCallbackImplemented
                                                    deferredDeeplinkCallback:isDeferredDeeplinkCallbackImplemented
                                                shouldLaunchDeferredDeeplink:shouldLaunchDeferredDeeplink
                                                                  withModule:self]];
    }

    // Start SDK.
    [Adjust appDidLaunch:adjustConfig];
    [Adjust trackSubsessionStart];
}

- (void)trackEvent:(id)args {
    NSArray *configArray = (NSArray *)args;
    NSDictionary *params = (NSDictionary *)[configArray objectAtIndex:0];

    NSString *eventToken = [params objectForKey:@"eventToken"];
    NSString *revenue = [params objectForKey:@"revenue"];
    NSString *currency = [params objectForKey:@"currency"];
    NSString *transactionId = [params objectForKey:@"transactionId"];
    NSString *callbackId = [params objectForKey:@"callbackId"];
    NSDictionary *callbackParameters = [params objectForKey:@"callbackParameters"];
    NSDictionary *partnerParameters = [params objectForKey:@"partnerParameters"];

    ADJEvent *adjustEvent = [ADJEvent eventWithEventToken:eventToken];
    if (![adjustEvent isValid]) {
        return;
    }

    // Revenue and currency.
    if ([self isFieldValid:revenue]) {
        double revenueValue = [revenue doubleValue];
        [adjustEvent setRevenue:revenueValue currency:currency];
    }

    // Callback parameters.
    if ([self isFieldValid:callbackParameters]) {
        for (NSString *key in callbackParameters) {
            NSString *value = [callbackParameters objectForKey:key];
            [adjustEvent addCallbackParameter:key value:value];
        }
    }

    // Partner parameters.
    if ([self isFieldValid:partnerParameters]) {
        for (NSString *key in partnerParameters) {
            NSString *value = [partnerParameters objectForKey:key];
            [adjustEvent addPartnerParameter:key value:value];
        }
    }

    // Transaction ID.
    if ([self isFieldValid:transactionId]) {
        [adjustEvent setTransactionId:transactionId];
    }

    // Callback ID.
    if ([self isFieldValid:callbackId]) {
        [adjustEvent setCallbackId:callbackId];    
    }

    // Track event.
    [Adjust trackEvent:adjustEvent];
}

- (void)trackAppStoreSubscription:(id)args {
    NSArray *configArray = (NSArray *)args;
    NSDictionary *params = (NSDictionary *)[configArray objectAtIndex:0];

    NSString *price = [params objectForKey:@"price"];
    NSString *currency = [params objectForKey:@"currency"];
    NSString *transactionId = [params objectForKey:@"transactionId"];
    NSString *receipt = [params objectForKey:@"receipt"];
    NSString *transactionDate = [params objectForKey:@"transactionDate"];
    NSString *salesRegion = [params objectForKey:@"salesRegion"];
    NSMutableArray *callbackParameters = [[NSMutableArray alloc] init];
    NSMutableArray *partnerParameters = [[NSMutableArray alloc] init];

    for (id item in [params objectForKey:@"callbackParameters"]) {
        [callbackParameters addObject:item];
    }
    for (id item in [params objectForKey:@"partnerParameters"]) {
        [partnerParameters addObject:item];
    }

    // Price.
    NSDecimalNumber *priceValue = nil;
    if ([self isFieldValid:price]) {
        priceValue = [NSDecimalNumber decimalNumberWithString:price];
    }

    // Receipt.
    NSData *receiptValue = nil;
    if ([self isFieldValid:receipt]) {
        receiptValue = [receipt dataUsingEncoding:NSUTF8StringEncoding];
    }

    ADJSubscription *subscription = [[ADJSubscription alloc] initWithPrice:priceValue
                                                                  currency:currency
                                                             transactionId:transactionId
                                                                andReceipt:receiptValue];

    // Transaction date.
    if ([self isFieldValid:transactionDate]) {
        NSTimeInterval transactionDateInterval = [transactionDate doubleValue];
        NSDate *oTransactionDate = [NSDate dateWithTimeIntervalSince1970:transactionDateInterval];
        [subscription setTransactionDate:oTransactionDate];
    }

    // Sales region.
    if ([self isFieldValid:salesRegion]) {
        [subscription setSalesRegion:salesRegion];
    }

    // Callback parameters.
    for (int i = 0; i < [callbackParameters count]; i += 2) {
        NSString *key = [callbackParameters objectAtIndex:i];
        NSObject *value = [callbackParameters objectAtIndex:(i+1)];
        [subscription addCallbackParameter:key value:[NSString stringWithFormat:@"%@", value]];
    }

    // Partner parameters.
    for (int i = 0; i < [partnerParameters count]; i += 2) {
        NSString *key = [partnerParameters objectAtIndex:i];
        NSObject *value = [partnerParameters objectAtIndex:(i+1)];
        [subscription addPartnerParameter:key value:[NSString stringWithFormat:@"%@", value]];
    }

    // Track subscription.
    [Adjust trackSubscription:subscription];
}

- (void)trackAdRevenue:(id)args {
    NSArray *arrayArgs = (NSArray *)args;
    NSString *source = [args objectAtIndex:0];
    NSString *payload = [args objectAtIndex:1];

    NSData *dataPayload = [payload dataUsingEncoding:NSUTF8StringEncoding];
    [Adjust trackAdRevenue:source payload:dataPayload];
}

- (void)setOfflineMode:(id)args {
    NSNumber *isOffline = args;
    if (![self isFieldValid:isOffline]) {
        return;
    }
    [Adjust setOfflineMode:[isOffline boolValue]];
}

- (void)setEnabled:(id)args {
    NSNumber *isEnabled = args;
    if (![self isFieldValid:isEnabled]) {
        return;
    }
    [Adjust setEnabled:[isEnabled boolValue]];
}

- (void)setPushToken:(id)args {
    NSString *pushToken = args;
    if (![self isFieldValid:pushToken]) {
        return;
    }
    [Adjust setPushToken:pushToken];
}

- (void)sendFirstPackages:(id)args {
    [Adjust sendFirstPackages];
}

- (void)gdprForgetMe:(id)args {
    [Adjust gdprForgetMe];
}

- (void)disableThirdPartySharing:(id)args {
    [Adjust disableThirdPartySharing];
}

- (void)addSessionCallbackParameter:(id)args {
    NSArray *arrayArgs = (NSArray *)args;
    NSString *key = [args objectAtIndex:0];
    NSString *value = [args objectAtIndex:1];
    [Adjust addSessionCallbackParameter:key value:value];
}

- (void)removeSessionCallbackParameter:(id)args {
    NSArray *arrayArgs = (NSArray *)args;
    NSString *key = [args objectAtIndex:0];
    [Adjust removeSessionCallbackParameter:key];
}

- (void)resetSessionCallbackParameters:(id)args {
    [Adjust resetSessionCallbackParameters];
}

- (void)addSessionPartnerParameter:(id)args {
    NSArray *arrayArgs = (NSArray *)args;
    NSString *key = [args objectAtIndex:0];
    NSString *value = [args objectAtIndex:1];
    [Adjust addSessionPartnerParameter:key value:value];
}

- (void)removeSessionPartnerParameter:(id)args {
    NSArray *arrayArgs = (NSArray *)args;
    NSString *key = [args objectAtIndex:0];
    [Adjust removeSessionPartnerParameter:key];
}

- (void)resetSessionPartnerParameters:(id)args {
    [Adjust resetSessionPartnerParameters];
}

- (void)appWillOpenUrl:(id)args {
    NSArray *arrayArgs = (NSArray *)args;
    NSString *urlString = [args objectAtIndex:0];

    if (urlString == nil) {
        return;
    }

    NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [Adjust appWillOpenUrl:url];
}

- (void)isEnabled:(id)args {
    BOOL isEnabled = [Adjust isEnabled];
    KrollCallback *callback = [args objectAtIndex:0];
    NSArray *array = [NSArray arrayWithObjects:[NSNumber numberWithBool:isEnabled], nil];
    [callback call:array thisObject:nil];
}

- (void)getIdfa:(id)args {
    NSString *idfa = [Adjust idfa];
    KrollCallback *callback = [args objectAtIndex:0];
    NSArray *array = [NSArray arrayWithObjects:(nil != idfa ? idfa : @""), nil];
    [callback call:array thisObject:nil];
}

- (void)getAdid:(id)args {
    NSString *adid = [Adjust adid];
    KrollCallback *callback = [args objectAtIndex:0];
    NSArray *array = [NSArray arrayWithObjects:(nil != adid ? adid : @""), nil];
    [callback call:array thisObject:nil];
}

- (void)getAttribution:(id)args {
    ADJAttribution *attribution = [Adjust attribution];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [self addValueOrEmpty:dictionary key:@"trackerToken" value:attribution.trackerToken];
    [self addValueOrEmpty:dictionary key:@"trackerName" value:attribution.trackerName];
    [self addValueOrEmpty:dictionary key:@"network" value:attribution.network];
    [self addValueOrEmpty:dictionary key:@"campaign" value:attribution.campaign];
    [self addValueOrEmpty:dictionary key:@"creative" value:attribution.creative];
    [self addValueOrEmpty:dictionary key:@"adgroup" value:attribution.adgroup];
    [self addValueOrEmpty:dictionary key:@"clickLabel" value:attribution.clickLabel];
    [self addValueOrEmpty:dictionary key:@"adid" value:attribution.adid];

    KrollCallback *callback = [args objectAtIndex:0];
    NSArray *array = [NSArray arrayWithObjects:dictionary, nil];
    [callback call:array thisObject:nil];
}

- (void)getSdkVersion:(id)args {
    NSString *sdkVersion = [NSString stringWithFormat:@"%@@%@", kSdkPrefix, [Adjust sdkVersion]];
    KrollCallback *callback = [args objectAtIndex:0];
    NSArray *array = [NSArray arrayWithObjects:(nil != sdkVersion ? sdkVersion : @""), nil];
    [callback call:array thisObject:nil];
}

- (void)getGoogleAdId:(id)args {
    KrollCallback *callback = [args objectAtIndex:0];
    NSArray *array = [NSArray arrayWithObjects:@"", nil];
    [callback call:array thisObject:nil];
}

- (void)getAmazonAdId:(id)args {
    KrollCallback *callback = [args objectAtIndex:0];
    NSArray *array = [NSArray arrayWithObjects:@"", nil];
    [callback call:array thisObject:nil];
}

- (void)requestTrackingAuthorizationWithCompletionHandler:(id)args {
    [Adjust requestTrackingAuthorizationWithCompletionHandler:^(NSUInteger status) {
        KrollCallback *callback = [args objectAtIndex:0];
        NSArray *array = [NSArray arrayWithObjects:[NSNumber numberWithUnsignedLong:status], nil];
        [callback call:array thisObject:nil];
    }];
}

- (void)onResume:(id)args {
    NSArray *arrayArgs = (NSArray *)args;
    NSString *parameter = [args objectAtIndex:0];
    if (parameter == nil) {
        return;
    }

    // For test purposes only.
    [Adjust trackSubsessionStart];
}

- (void)onPause:(id)args {
    NSArray *arrayArgs = (NSArray *)args;
    NSString *parameter = [args objectAtIndex:0];
    if (parameter == nil) {
        return;
    }

    // For test purposes only.
    [Adjust trackSubsessionEnd];
}

- (void)setReferrer:(id)args {}

- (void)trackPlayStoreSubscription:(id)args {}

- (void)setTestOptions:(id)args {
    NSDictionary *params = (NSDictionary *)args;
    AdjustTestOptions *testOptions = [[AdjustTestOptions alloc] init];

    if ([params objectForKey:@"hasContext"]) {
        NSString *value = params[@"hasContext"];
        if ([self isFieldValid:value]) {
            testOptions.deleteState = [value boolValue];
        }
    }
    if ([params objectForKey:@"baseUrl"]) {
        NSString *value = params[@"baseUrl"];
        if ([self isFieldValid:value]) {
            testOptions.baseUrl = value;
        }
    }
    if ([params objectForKey:@"gdprUrl"]) {
        NSString *value = params[@"gdprUrl"];
        if ([self isFieldValid:value]) {
            testOptions.gdprUrl = value;
        }
    }
    /*
    if ([params objectForKey:@"basePath"]) {
        NSString *value = params[@"basePath"];
        if ([self isFieldValid:value]) {
            testOptions.basePath = value;
        }
    }
    if ([params objectForKey:@"gdprPath"]) {
        NSString *value = params[@"gdprPath"];
        if ([self isFieldValid:value]) {
            testOptions.gdprPath = value;
        }
    }
    */
    if ([params objectForKey:@"extraPath"]) {
        NSString *value = params[@"extraPath"];
        if ([self isFieldValid:value]) {
            testOptions.extraPath = value;
        }
    }
    if ([params objectForKey:@"timerIntervalInMilliseconds"]) {
        NSString *value = params[@"timerIntervalInMilliseconds"];
        if ([self isFieldValid:value]) {
            testOptions.timerIntervalInMilliseconds = [self convertMilliStringToNumber:value];
        }
    }
    if ([params objectForKey:@"timerStartInMilliseconds"]) {
        NSString *value = params[@"timerStartInMilliseconds"];
        if ([self isFieldValid:value]) {
            testOptions.timerStartInMilliseconds = [self convertMilliStringToNumber:value];
        }
    }
    if ([params objectForKey:@"sessionIntervalInMilliseconds"]) {
        NSString *value = params[@"sessionIntervalInMilliseconds"];
        if ([self isFieldValid:value]) {
            testOptions.sessionIntervalInMilliseconds = [self convertMilliStringToNumber:value];
        }
    }
    if ([params objectForKey:@"subsessionIntervalInMilliseconds"]) {
        NSString *value = params[@"subsessionIntervalInMilliseconds"];
        if ([self isFieldValid:value]) {
            testOptions.subsessionIntervalInMilliseconds = [self convertMilliStringToNumber:value];
        }
    }
    if ([params objectForKey:@"teardown"]) {
        NSString *value = params[@"teardown"];
        if ([self isFieldValid:value]) {
            testOptions.teardown = [value boolValue];
        }
    }
    if ([params objectForKey:@"noBackoffWait"]) {
        NSString *value = params[@"noBackoffWait"];
        if ([self isFieldValid:value]) {
            testOptions.noBackoffWait = [value boolValue];
        }
    }
    testOptions.iAdFrameworkEnabled = NO;
    if ([params objectForKey:@"iAdFrameworkEnabled"]) {
        NSString *value = params[@"iAdFrameworkEnabled"];
        if ([self isFieldValid:value]) {
            testOptions.iAdFrameworkEnabled = [value boolValue];
        }
    }

    [Adjust setTestOptions:testOptions];
}

- (void)teardown:(id)args {
    self.jsAttributionCallback = nil;
    self.jsSessionSuccessCallback = nil;
    self.jsSessionFailureCallback = nil;
    self.jsEventSuccessCallback = nil;
    self.jsEventFailureCallback = nil;
    self.jsDeferredDeeplinkCallback = nil;
    [TiAdjustModuleDelegate teardown];
}

- (BOOL)isFieldValid:(NSObject *)field {
    if (field == nil) {
        return NO;
    }

    // Check if its an instance of the singleton NSNull
    if ([field isKindOfClass:[NSNull class]]) {
        return NO;
    }

    // If field can be converted to a string, check if it has any content.
    NSString *str = [NSString stringWithFormat:@"%@", field];
    if (str != nil) {
        if ([str length] == 0) {
            return NO;
        }
    }

    return YES;
}

- (void)addValueOrEmpty:(NSMutableDictionary *)dictionary
                    key:(NSString *)key
                  value:(NSObject *)value {
    if (nil != value) {
        [dictionary setObject:[NSString stringWithFormat:@"%@", value] forKey:key];
    } else {
        [dictionary setObject:@"" forKey:key];
    }
}

- (NSNumber *)convertMilliStringToNumber:(NSString *)value {
    NSNumber *number = [NSNumber numberWithInt:[value intValue]];
    return number;
}

@end
