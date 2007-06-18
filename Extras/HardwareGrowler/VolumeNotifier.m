//
//  VolumeNotifier.c
//  HardwareGrowler
//
//  Created by Diggory Laycock on 10/02/2005.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import "VolumeNotifier.h"
#import "AppController.h"
#import <Cocoa/Cocoa.h>

@interface VolumeNotifier : NSObject {
}

+ (void) volumeDidMount:(NSNotification *)aNotification;
+ (void) volumeDidUnmount:(NSNotification *)aNotification;

@end

@implementation VolumeNotifier

+ (void) volumeDidMount:(NSNotification *)aNotification {
	AppController_volumeDidMount([[aNotification userInfo] objectForKey:@"NSDevicePath"]);
}

+ (void) volumeDidUnmount:(NSNotification *)aNotification {
	AppController_volumeDidUnmount([[aNotification userInfo] objectForKey:@"NSDevicePath"]);
}

@end

void VolumeNotifier_init(void) {
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	NSNotificationCenter *center = [workspace notificationCenter];
	
	[center addObserver:[VolumeNotifier class] selector:@selector(volumeDidMount:) name:NSWorkspaceDidMountNotification object:nil];
	[center addObserver:[VolumeNotifier class] selector:@selector(volumeDidUnmount:) name:NSWorkspaceDidUnmountNotification object:nil];

	Boolean keyExistsAndHasValidFormat;
	if (CFPreferencesGetAppBooleanValue(CFSTR("ShowExisting"), CFSTR("com.growl.hardwaregrowler"), &keyExistsAndHasValidFormat)) {
		NSArray *paths = [workspace mountedLocalVolumePaths];
		unsigned int i;
		
		for (i = 0; i < [paths count]; ++i)
			AppController_volumeDidMount([paths objectAtIndex:i]);
	}
}

void VolumeNotifier_dealloc(void) {
	NSNotificationCenter *center = [[NSWorkspace sharedWorkspace] notificationCenter];
	
	[center removeObserver:[VolumeNotifier class] name:NSWorkspaceDidUnmountNotification object:nil];
	[center removeObserver:[VolumeNotifier class] name:NSWorkspaceDidMountNotification object:nil];
}
