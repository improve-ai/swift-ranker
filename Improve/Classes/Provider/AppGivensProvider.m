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

@implementation IMPDeviceInfo

- (instancetype)initWithModel:(NSString *)model version:(double)version {
    if(self = [super init]) {
        _model = model;
        _version = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.3lf", version]];
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

static NSString * const kCountryKey = @"$country";
NSString * const kLanguageKey = @"$lang";
static NSString * const kTimezoneKey = @"$tz";
static NSString * const kCarrierKey = @"$carrier";
static NSString * const kDeviceKey = @"$device";
static NSString * const kDeviceVersionKey = @"$devicev";
static NSString * const kOSKey = @"$os";
static NSString * const kOSVersionKey = @"$osv";
static NSString * const kScreenPixelsKey = @"$pixels";
static NSString * const kAppKey = @"$app";
static NSString * const kAppVersionKey = @"$appv";
static NSString * const kImproveVersionKey = @"$sdkv";
static NSString * const kWeekDayKey = @"$weekday";
static NSString * const kSinceMidnightKey = @"$time";
static NSString * const kSinceSessionStartKey = @"$runtime";
static NSString * const kSinceBornKey = @"$day";
static NSString * const kDecisionCountKey = @"$d"; // number of decisions for this model
static NSString * const kRewardsKey = @"$r";  // total rewards for this model
static NSString * const kRewardsPerDecision = @"$r/d";
static NSString * const kDecisionsPerDay = @"$d/day";

// persistent key

// The first time an AppGivensProvider is created on this device.
static NSString * const kBornTimeKey = @"ai.improve.born_time";

// When the AppGivensProvider instance is created.
// If there is some way to get the true app launch
// time in Android or iOS we could use that instead.
NSString * const kSessionStartTimeKey = @"ai.improve.session_start_time";

static NSString * const kDefaultsDecisionCountKey = @"ai.improve.decision_count-%@";

static NSString * const kDefaultsModelRewardsKey = @"ai.improve.rewards-%@";

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
        });
    }
    return self;
}

- (NSDictionary<NSString *, id> *)givensForModel:(IMPDecisionModel *)decisionModel givens:(NSDictionary *)givens_ {
    NSMutableDictionary *givens = [[NSMutableDictionary alloc] init];
    givens[kCountryKey] = [self country];
    givens[kLanguageKey] = [self language];
    givens[kTimezoneKey] = @([self timezone]);
    givens[kCarrierKey] = [self carrier];
    givens[kOSKey] = [self os];
    givens[kOSVersionKey] = [self osVersion];
    givens[kAppKey] = [self app];
    givens[kAppVersionKey] = [self appVersion];
    givens[kImproveVersionKey] = [self improveVersion:kIMPVersion];
    givens[kScreenPixelsKey] = @([self screenPixels]);
    givens[kWeekDayKey] = [self weekDay];
    givens[kSinceMidnightKey] = [self sinceMidnight];
    givens[kSinceBornKey] = [self sinceBornDecimalNumber];
    givens[kSinceSessionStartKey] = [self sinceSessionStart];
    givens[kDecisionCountKey] = @([self decisionCount:decisionModel.modelName]);
    givens[kRewardsKey] = [self rewardOfModelDecimalNumber:decisionModel.modelName];
    givens[kRewardsPerDecision] = [self rewardsPerDecision:decisionModel.modelName];
    givens[kDecisionsPerDay] = [self decisionsPerDay:decisionModel.modelName];
    
    IMPDeviceInfo *deviceInfo = [self deviceInfo];
    givens[kDeviceKey] = deviceInfo.model;
    givens[kDeviceVersionKey] = deviceInfo.version;
    
    // When getGivens is called, increment decision count value by 1
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *decisionCountKey = [NSString stringWithFormat:kDefaultsDecisionCountKey, decisionModel.modelName];
    NSInteger curDecisionCount = [defaults integerForKey:decisionCountKey];
    [defaults setInteger:curDecisionCount+1 forKey:decisionCountKey];

    // If keys in givens_ overlap with keys in AppGivensProvider, keys in givens_ win
    [givens addEntriesFromDictionary:givens_];
    
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
    return @"macOS";
#elif TARGET_OS_TV
    return @"tvOS";
#elif TARGET_OS_MACCATALYST
    return @"macOS";
#elif TARGET_OS_WATCH
    return @"watchOS";
#else
    return @"iOS";
#endif
}

- (NSDecimalNumber *)osVersion {
    NSOperatingSystemVersion systemVersion = [[NSProcessInfo processInfo] operatingSystemVersion];
    double t = systemVersion.majorVersion + systemVersion.minorVersion/1000.0 + systemVersion.patchVersion/1000000.0;
    return [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.6lf", t]];
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
    return [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.6lf", t]];
}

- (NSDecimalNumber *)improveVersion:(NSString *)version {
    double t = [self versionToNumber:version];
    return [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.6lf", t]];
    
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
    return major + minor / 1000.0 + build / 1000000.0;
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
    double t = ([now timeIntervalSinceDate:startOfDay]) / 86400.0;
    return [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.6lf", t]];
}

// When the AppGivensProvider instance is created.
// If there is some way to get the true app launch
// time in Android or iOS we could use that instead.
- (NSDecimalNumber *)sinceSessionStart {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    double sessionStartTime = [defaults doubleForKey:kSessionStartTimeKey];
    double t = ([[NSDate date] timeIntervalSince1970] - sessionStartTime) / 86400.0;
    return [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.6lf", t]];
}

// Born time is the first time an AppGivensProvider is created on this device.
- (NSDecimalNumber *)sinceBornDecimalNumber {
    double t = [self sinceBorn];
    return [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.6lf", t]];
}

- (double)sinceBorn {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    double bornTime = [defaults doubleForKey:kBornTimeKey];
    return ([[NSDate date] timeIntervalSince1970] - bornTime) / 86400.0;
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
    
    return [[IMPDeviceInfo alloc] initWithModel:model version:major+minor/1000.0];
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

+ (void)addReward:(double)reward forModel:(NSString *)modelName {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *key = [NSString stringWithFormat:kDefaultsModelRewardsKey, modelName];
    double curValue = [defaults doubleForKey:key];
    [defaults setDouble:(curValue+reward) forKey:key];
}

// Total rewards for this model
- (NSDecimalNumber *)rewardOfModelDecimalNumber:(NSString *)modelName {
    double reward = [self rewardOfModel:modelName];
    return [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.6lf", reward]];
}

- (double)rewardOfModel:(NSString *)modelName {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *key = [NSString stringWithFormat:kDefaultsModelRewardsKey, modelName];
    return [defaults doubleForKey:key];
}

- (NSDecimalNumber *)rewardsPerDecision:(NSString *)modelName {
    double rewards = [self rewardOfModel:modelName];
    NSUInteger decisions = [self decisionCount:modelName];
    if(decisions == 0) {
        return [NSDecimalNumber decimalNumberWithString:@"0"];
    } else {
        return [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.6lf", rewards / decisions]];
    }
}

- (NSDecimalNumber *)decisionsPerDay:(NSString *)modelName {
    NSUInteger decisions = [self decisionCount:modelName];
    double days = [self sinceBorn];
    return [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.6lf", decisions / days]];
}

@end
