//
//  IMPGivensProvider.m
//  ImproveUnitTests
//
//  Created by PanHongxi on 6/11/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

#if TARGET_OS_WATCH
#import <WatchKit/WatchKit.h>
#elif !TARGET_OS_OSX
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#import <net/if.h>
#import <net/if_dl.h>
#endif

#import "IMPAppGivensProvider.h"
#import "IMPUtils.h"
#import "IMPConstants.h"

@implementation IMPDeviceInfo

- (instancetype)initWithModel:(NSString *)model version:(int)version {
    if(self = [super init]) {
        _model = model;
        _version = version;
    }
    return self;
}

@end


/**
 * country - two letter code
 * language - two letter code
 * timezone - numeric GMT offset
 * carrier
 * os - lower case
 * os_version
 * device
 * device_version
 * app
 * app_version
 * build_version
 * improve_version == 6000
 * screen_width
 * screen_height
 * screen_pixels == screen_width x screen_height
 * weekday (ISO 8601, monday==1.0, sunday==7.0) plus fractional part of day
 * since_midnight
 * since_session_start
 * since_last_session_start
 * since_born
 * session_count
 * decision_count
 *
 * Versions are major x 1000 + minor + build / 1000
 * Times are fractional seconds
 * Persist necessary values in NSUserDefaults/Android Context with “ai.improve.” key prefixes
 */
static NSString * PersistPrefix = @"ai.improve";

static NSString * const kCountryKey = @"country";
static NSString * const kLanguageKey = @"language";
static NSString * const kTimezoneKey = @"timezone";
static NSString * const kCarrierKey = @"carrier";
static NSString * const kOSKey = @"os";
static NSString * const kOSVersionKey = @"os_version";
static NSString * const kDeviceKey = @"device";
static NSString * const kDeviceVersionKey = @"device_version";
static NSString * const kAppKey = @"app";
static NSString * const kAppVersionKey = @"app_version";
static NSString * const kBuildVersionKey = @"build_version";
static NSString * const kImproveVersionKey = @"improve_version";
static NSString * const kScreenWidthKey = @"screen_width";
static NSString * const kScreenHeightKey = @"screen_height";
static NSString * const kScreenPixelsKey = @"screen_pixels";
static NSString * const kWeekDayKey = @"weekday";
static NSString * const kSinceMidnightKey = @"since_midnight";
static NSString * const kSinceSessionStartKey = @"since_session_start";
static NSString * const kSinceLastSessionStartKey = @"since_last_session_start";
static NSString * const kSinceBornKey = @"since_born";
static NSString * const kSessionCountKey = @"session_count";
static NSString * const kDecisionCountKey = @"decision_count";

// persistent key

// The first time an AppGivensProvider is created on this device.
static NSString * const kBornTimeKey = @"ai.improve.born_time";

// When the AppGivensProvider instance is created.
// If there is some way to get the true app launch
// time in Android or iOS we could use that instead.
static NSString * const kSessionStartTimeKey = @"ai.improve.session_start_time";

static NSString * const kDefaultsSessionCountKey = @"ai.improve.session_count";

static NSString * const kDefaultsDecisionCountKey = @"ai.improve.decision_count";

@implementation IMPAppGivensProvider

static double sLastSessionStartTime;

- (instancetype)init {
    if(self = [super init]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            
            // cache last session start time before it is overwritten in NSUserDefaults
            // by current session start time
            sLastSessionStartTime = [defaults doubleForKey:kSessionStartTimeKey];
            
            // set born time
            if([defaults objectForKey:kBornTimeKey] == nil) {
                double bornTime = [[NSDate date] timeIntervalSince1970];
                [defaults setDouble:bornTime forKey:kBornTimeKey];
            }
            
            // set session start time
            double sessionStartTime = [[NSDate date] timeIntervalSince1970];
            [defaults setDouble:sessionStartTime forKey:kSessionStartTimeKey];
            
            // increment session count value by 1
            NSInteger curSessionCount = [defaults integerForKey:kDefaultsSessionCountKey];
            [defaults setInteger:curSessionCount+1 forKey:kDefaultsSessionCountKey];
        });
    }
    return self;
}

- (NSDictionary *)getGivens {
    NSMutableDictionary *givens = [[NSMutableDictionary alloc] init];
    [givens setObject:[self country] forKey:kCountryKey];
    [givens setObject:[self language] forKey:kLanguageKey];
    [givens setObject:@([self timezone]) forKey:kTimezoneKey];
    [givens setObject:[self carrier] forKey:kCarrierKey];
    [givens setObject:[self os] forKey:kOSKey];
    [givens setObject:@([self osVersion]) forKey:kOSVersionKey];
    [givens setObject:[self app] forKey:kAppKey];
    [givens setObject:@([self appVersion]) forKey:kAppVersionKey];
    [givens setObject:@([self buildVersion]) forKey:kBuildVersionKey];
    [givens setObject:@([self improveVersion:kIMPVersion]) forKey:kImproveVersionKey];
    [givens setObject:@([self screenWidth]) forKey:kScreenWidthKey];
    [givens setObject:@([self screenHeight]) forKey:kScreenHeightKey];
    [givens setObject:@([self screenPixels]) forKey:kScreenPixelsKey];
    [givens setObject:@([self weekDay]) forKey:kWeekDayKey];
    [givens setObject:@([self sinceMidnight]) forKey:kSinceMidnightKey];
    [givens setObject:@([self sinceSessionStart]) forKey:kSinceSessionStartKey];
    [givens setObject:@([self sinceLastSessionStart]) forKey:kSinceLastSessionStartKey];
    [givens setObject:@([self sinceBorn]) forKey:kSinceBornKey];
    [givens setObject:@([self sessionCount]) forKey:kSessionCountKey];
    [givens setObject:@([self decisionCount]) forKey:kDecisionCountKey];
    
    IMPDeviceInfo *deviceInfo = [self deviceInfo];
    [givens setObject:deviceInfo.model forKey:kDeviceKey];
    [givens setObject:@(deviceInfo.version) forKey:kDeviceVersionKey];
    
    // When getGivens is called, increment decision count value by 1
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger curDecisionCount = [defaults integerForKey:kDefaultsDecisionCountKey];
    [defaults setInteger:curDecisionCount+1 forKey:kDefaultsDecisionCountKey];
    
    return givens;
}

//  two letter code
- (NSString *)country {
    return [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
}

//  two letter code
- (NSString *)language {
    NSString *lang = [[NSLocale preferredLanguages] firstObject];
    NSDictionary *languageDic = [NSLocale componentsFromLocaleIdentifier:lang];
    
    for (NSString *key in languageDic) {
        NSLog(@"key=%@, value=%@", key, languageDic[key]);
    }
    return [languageDic objectForKey:NSLocaleLanguageCode];
}

// numeric GMT offset
- (NSInteger)timezone {
    return [[NSTimeZone localTimeZone] secondsFromGMT] / 3600;
}

// When there are multiple carriers, the first non-empty carrierName is used.
- (NSString *)carrier {
    CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
    NSDictionary<NSString *, CTCarrier *> *carriers = info.serviceSubscriberCellularProviders;
    for(NSString *key in carriers) {
        CTCarrier *carrier = carriers[key];
        if(carrier.carrierName.length > 0) {
            return carrier.carrierName;
        }
    }
    return @"unknown";
}

- (NSString *)os {
#if TARGET_OS_OSX
    return @"macos";
#elif TARGET_OS_TV
    return @"tvos";
#elif TARGET_OS_MACCATALYST
    return @"macos";
#elif TARGET_OS_WATCH
    return @"watchos";
#else
    return @"ios";
#endif
}

- (double)osVersion {
    NSOperatingSystemVersion systemVersion = [[NSProcessInfo processInfo] operatingSystemVersion];
    return systemVersion.majorVersion * 1000 + systemVersion.minorVersion + systemVersion.patchVersion/1000.0;
}

- (IMPDeviceInfo *)deviceInfo {
    NSString *platform = [IMPUtils getPlatformString];
    return [self parseDeviceInfo:platform];
}

- (NSString *)app {
    NSString *name = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if([name length] <= 0) {
        name = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    }
    return name == nil ? @"" : name;
}

// When running the unit test, appVersion is nil and can't be put in the dict.
// I'm making it empty string instead of nil to avoid the problem for now.
- (double)appVersion {
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
//    return appVersion == nil ? @"" : appVersion;
    return [self versionToNumber:appVersion];
}

- (double)buildVersion {
    NSString *buildVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    return [self versionToNumber:buildVersion];
}

- (double)improveVersion:(NSString *)version {
    return [self versionToNumber:version];
}

- (double)versionToNumber:(NSString *)version {
    NSArray<NSString *> *versionArray = [version componentsSeparatedByString:@"."];
    
    int major = 0;
    int minor = 0;
    int build = 0;
    
    if([versionArray count] == 1) {
        major = [versionArray[0] intValue];
    } else if([versionArray count] == 2) {
        major = [versionArray[0] intValue];
        minor = [versionArray[1] intValue];
    } else if([versionArray count] >= 3) {
        major = [versionArray[0] intValue];
        minor = [versionArray[1] intValue];
        build = [versionArray[2] intValue];
    }
    return major * 1000 + minor + build / 1000.0;
}

- (NSUInteger)screenWidth {
    CGFloat scale = [[UIScreen mainScreen] scale];
    CGRect rect = [[UIScreen mainScreen] bounds];
    return rect.size.width * scale;
}

- (NSUInteger)screenHeight {
    CGFloat scale = [[UIScreen mainScreen] scale];
    CGRect rect = [[UIScreen mainScreen] bounds];
    return rect.size.height * scale;
}

- (NSUInteger)screenPixels {
    CGFloat scale = [[UIScreen mainScreen] scale];
    CGRect rect = [[UIScreen mainScreen] bounds];
    return rect.size.width * scale * rect.size.height * scale;
}

- (double)weekDay {
    NSDate *now = [NSDate date];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    [gregorian setFirstWeekday:2];
    NSUInteger weekday = [gregorian ordinalityOfUnit:NSCalendarUnitWeekday inUnit:NSCalendarUnitWeekOfMonth forDate:now];
    double sinceMidnight = [now timeIntervalSinceDate:[gregorian startOfDayForDate:now]];
    return weekday + sinceMidnight / (24 * 3600);
}

- (double)sinceMidnight {
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDate *now = [NSDate date];
    NSDate *startOfDay = [gregorian startOfDayForDate:now];
    return [now timeIntervalSinceDate:startOfDay];
}

// When the AppGivensProvider instance is created.
// If there is some way to get the true app launch
// time in Android or iOS we could use that instead.
- (double)sinceSessionStart {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    double sessionStartTime = [defaults doubleForKey:kSessionStartTimeKey];
    return [[NSDate date] timeIntervalSince1970] - sessionStartTime;
}

// 0.0 is returned, if there is no last session
- (double)sinceLastSessionStart {
    if(sLastSessionStartTime <= 0) {
        return 0;
    }
    return [[NSDate date] timeIntervalSince1970] - sLastSessionStartTime;
}

// Born time is the first time an AppGivensProvider is created on this device.
- (double)sinceBorn {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    double bornTime = [defaults doubleForKey:kBornTimeKey];
    return [[NSDate date] timeIntervalSince1970] - bornTime;
}

// 0 is returned for the first session
- (NSUInteger)sessionCount {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger count = [defaults integerForKey:kDefaultsSessionCountKey];
    // We are counting previous session count here, so we need
    // to remove current session that is already counted in init.
    return count - 1 >= 0? count-1 : 0;
}

//  It’s the number of times a givens is provided
// 0 is returned for the first decision
- (NSUInteger)decisionCount {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults integerForKey:kDefaultsDecisionCountKey];
}

// https://www.theiphonewiki.com/wiki/Models#iPhone
// Check the link above to see what platform might look like.
// Pay attention to filed 'identifier'
- (IMPDeviceInfo *)parseDeviceInfo:(NSString *)platform {
    if(platform.length <= 0) {
        return [[IMPDeviceInfo alloc] initWithModel:@"unknown" version:0];
    }
    
    if([platform isEqualToString:@"i386"]) {
        return [[IMPDeviceInfo alloc] initWithModel:@"Simulator" version:0];
    } else if([platform isEqualToString:@"x86_64"]) {
        return [[IMPDeviceInfo alloc] initWithModel:@"Simulator" version:0];
    }

    NSUInteger lastLetterIndex = 0;
    for(NSUInteger i = 0; i < platform.length; ++i) {
        unichar c = [platform characterAtIndex:i];
        if(!((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z'))) {
            lastLetterIndex = i;
            break;
        }
    }
    if(lastLetterIndex == 0) {
        return [[IMPDeviceInfo alloc] initWithModel:platform version:0];
    }
    
    NSString *model = [platform substringToIndex:lastLetterIndex];
    
    NSString *versionString = [platform substringFromIndex:lastLetterIndex];
    NSArray<NSString *> *versionArray = [versionString componentsSeparatedByString:@","];
    if(versionArray.count != 2) {
        return [[IMPDeviceInfo alloc] initWithModel:model version:0];
    }
    
    int major = [versionArray[0] intValue];
    int minor = [versionArray[1] intValue];
    
    return [[IMPDeviceInfo alloc] initWithModel:model version:major*1000+minor];
}

@end
