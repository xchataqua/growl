//
//  GrowlPreferencesController.h
//  Growl
//
//  Created by Nelson Elhage on 8/24/04.
//  Renamed from GrowlPreferences.h by Mac-arena the Bored Zo on 2005-06-27.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#define HelperAppBundleIdentifier	@"com.Growl.GrowlHelperApp"
#define GrowlPreferencesChanged		@"GrowlPreferencesChanged"
#define GrowlPreview				@"GrowlPreview"
#define GrowlDisplayPluginKey		@"GrowlDisplayPluginName"
#define GrowlUserDefaultsKey		@"GrowlUserDefaults"
#define GrowlStartServerKey			@"GrowlStartServer"
#define GrowlRemoteRegistrationKey	@"GrowlRemoteRegistration"
#define GrowlEnableForwardKey		@"GrowlEnableForward"
#define GrowlForwardDestinationsKey	@"GrowlForwardDestinations"
#define GrowlUDPPortKey				@"GrowlUDPPort"
#define GrowlTCPPortKey				@"GrowlTCPPort"
#define GrowlUpdateCheckKey			@"GrowlUpdateCheck"
#define LastUpdateCheckKey			@"LastUpdateCheck"
#define	GrowlLoggingEnabledKey		@"GrowlLoggingEnabled"
#define	GrowlLogTypeKey				@"GrowlLogType"
#define	GrowlCustomHistKey1			@"Custom log history 1"
#define	GrowlCustomHistKey2			@"Custom log history 2"
#define	GrowlCustomHistKey3			@"Custom log history 3"
#define GrowlMenuExtraKey			@"GrowlMenuExtra"
#define GrowlSquelchModeKey			@"GrowlSquelchMode"
#define LastKnownVersionKey			@"LastKnownVersion"
#define GrowlStickyWhenAwayKey		@"StickyWhenAway"

@interface GrowlPreferencesController : NSObject {
	NSUserDefaults *helperAppDefaults;
}

+ (GrowlPreferencesController *) preferences;

- (void) registerDefaults:(NSDictionary *)inDefaults;
- (id) objectForKey:(NSString *)key;
- (void) setObject:(id)object forKey:(NSString *)key;
- (BOOL) boolForKey:(NSString*) key;
- (void) setBool:(BOOL)value forKey:(NSString *)key;
- (int) integerForKey:(NSString *)key;
- (void) setInteger:(int)value forKey:(NSString *)key;
- (void) synchronize;

- (BOOL) startGrowlAtLogin;
- (void) setStartGrowlAtLogin:(BOOL)flag;
- (void) setStartAtLogin:(NSString *)path enabled:(BOOL)flag;

- (BOOL) isRunning:(NSString *)theBundleIdentifier;
- (BOOL) isGrowlRunning;
- (void) setGrowlRunning:(BOOL)flag noMatterWhat:(BOOL)nmw;
- (void) launchGrowl:(BOOL)noMatterWhat;
- (void) terminateGrowl;

@end