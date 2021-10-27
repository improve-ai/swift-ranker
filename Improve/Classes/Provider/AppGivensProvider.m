//
//  AppGivensProvider.m
//  ImproveUnitTests
//
//  Created by PanHongxi on 10/27/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//
#import <UIKit/UIKit.h>

#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <sys/sysctl.h>
#import <sys/types.h>

#import "AppGivensProvider.h"
#import "IMPDecisionModel.h"
#import "IMPConstants.h"

@interface IMPDeviceInfo : NSObject

@property (nonatomic, strong) NSString *model;

@property (nonatomic) int version;

@end

@implementation IMPDeviceInfo

- (instancetype)initWithModel:(NSString *)model version:(int)version {
    if(self = [super init]) {
        _model = model;
        _version = version;
    }
    return self;
}

@end

@implementation AppGivensProvider

+ (instancetype)shared {
    static AppGivensProvider *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AppGivensProvider alloc] init];
    });
    return instance;
}

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
static NSString * const kScreenPixelsKey = @"pixels";
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

static NSString * const kDefaultsDecisionCountKey = @"ai.improve.decision_count-%@";

NSString * const kGivensModelNameMessages = @"messages";
NSString * const kGivensModelNameThemes = @"themes";
NSString * const kGivensModelNameStories = @"stories";
NSString * const kGivensModelNameSongs = @"songs";

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

- (NSDictionary<NSString *, id> *)givensForModel:(NSString *)modelName {
    NSMutableDictionary *givens = [[NSMutableDictionary alloc] init];
    givens[kCountryKey] = [self country];
    givens[kLanguageKey] = [self language];
    givens[kTimezoneKey] = @([self timezone]);
    givens[kCarrierKey] = [self carrier];
    givens[kOSKey] = [self os];
    givens[kOSVersionKey] = [self osVersion];
    givens[kAppKey] = [self app];
    givens[kAppVersionKey] = [self appVersion];
    givens[kBuildVersionKey] = @([self buildVersion]);
    givens[kImproveVersionKey] = [self improveVersion:kIMPVersion];
    givens[kScreenPixelsKey] = @([self screenPixels]);
    givens[kWeekDayKey] = [self weekDay];
    givens[kSinceMidnightKey] = [self sinceMidnight];
    givens[kSinceSessionStartKey] = [self sinceSessionStart];
    givens[kSinceLastSessionStartKey] = [self sinceLastSessionStart];
    givens[kSinceBornKey] = [self sinceBorn];
    givens[kSessionCountKey] = @([self sessionCount]);
    givens[kDecisionCountKey] = @([self decisionCount:modelName]);
    
    IMPDeviceInfo *deviceInfo = [self deviceInfo];
    givens[kDeviceKey] = deviceInfo.model;
    givens[kDeviceVersionKey] = @(deviceInfo.version);
    
    // When getGivens is called, increment decision count value by 1
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *decisionCountKey = [NSString stringWithFormat:kDefaultsDecisionCountKey, modelName];
    NSInteger curDecisionCount = [defaults integerForKey:decisionCountKey];
    [defaults setInteger:curDecisionCount+1 forKey:decisionCountKey];
    
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
    return nil;
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

- (NSDecimalNumber *)osVersion {
    NSOperatingSystemVersion systemVersion = [[NSProcessInfo processInfo] operatingSystemVersion];
    double t = systemVersion.majorVersion * 1000 + systemVersion.minorVersion + systemVersion.patchVersion/1000.0;
    return [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.3lf", t]];
}

- (IMPDeviceInfo *)deviceInfo {
    NSString *platform = [AppGivensProvider getPlatformString];
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
- (NSDecimalNumber *)appVersion {
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    double t = [self versionToNumber:appVersion];
    return [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.3lf", t]];
}

- (double)buildVersion {
    NSString *buildVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    return [self versionToNumber:buildVersion];
}

- (NSDecimalNumber *)improveVersion:(NSString *)version {
    double t = [self versionToNumber:version];
    return [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.3lf", t]];
    
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

- (NSUInteger)screenPixels {
    CGFloat scale = [[UIScreen mainScreen] scale];
    CGRect rect = [[UIScreen mainScreen] bounds];
    return rect.size.width * scale * rect.size.height * scale;
}

- (NSDecimalNumber *)weekDay {
    NSDate *now = [NSDate date];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    [gregorian setFirstWeekday:2];
    NSUInteger weekday = [gregorian ordinalityOfUnit:NSCalendarUnitWeekday inUnit:NSCalendarUnitWeekOfMonth forDate:now];
    double sinceMidnight = [now timeIntervalSinceDate:[gregorian startOfDayForDate:now]];
    double t = weekday + sinceMidnight / (24 * 3600);
    return [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.5lf", t]];
}

- (NSDecimalNumber *)sinceMidnight {
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDate *now = [NSDate date];
    NSDate *startOfDay = [gregorian startOfDayForDate:now];
    double t = [now timeIntervalSinceDate:startOfDay];
    return [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.3lf", t]];
}

// When the AppGivensProvider instance is created.
// If there is some way to get the true app launch
// time in Android or iOS we could use that instead.
- (NSDecimalNumber *)sinceSessionStart {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    double sessionStartTime = [defaults doubleForKey:kSessionStartTimeKey];
    double t = [[NSDate date] timeIntervalSince1970] - sessionStartTime;
    return [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.3lf", t]];
}

// 0.0 is returned, if there is no last session
- (NSDecimalNumber *)sinceLastSessionStart {
    if(sLastSessionStartTime <= 0) {
        return [NSDecimalNumber decimalNumberWithString:@"0"];
    }
    double t = [[NSDate date] timeIntervalSince1970] - sLastSessionStartTime;
    return [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.3lf", t]];
}

// Born time is the first time an AppGivensProvider is created on this device.
- (NSDecimalNumber *)sinceBorn {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    double bornTime = [defaults doubleForKey:kBornTimeKey];
    double t = [[NSDate date] timeIntervalSince1970] - bornTime;
    return [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.3lf", t]];
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
- (NSUInteger)decisionCount:(NSString *)modelName {
    NSString *decisionCountKey = [NSString stringWithFormat:kDefaultsDecisionCountKey, modelName];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults integerForKey:decisionCountKey];
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

+ (NSString *)getPlatformString {
#if !TARGET_OS_OSX
    const char *sysctl_name = "hw.machine";
#else
    const char *sysctl_name = "hw.model";
#endif
    size_t size;
    sysctlbyname(sysctl_name, NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname(sysctl_name, machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    return platform;
}

@end
