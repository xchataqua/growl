//
//  GrowlSmokeWindowController.m
//  Display Plugins
//
//  Created by Matthew Walton on 11/09/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//
//  Most of this is lifted from KABubbleWindowController in the Growl source

#import "GrowlSmokeWindowController.h"
#import "GrowlSmokeWindowView.h"
#import "GrowlSmokeDefines.h"
#import "GrowlDefines.h"
#import "NSGrowlAdditions.h"

static unsigned int smokeWindowDepth = 0;
static unsigned int globalId = 0;

@implementation GrowlSmokeWindowController

static const double gTimerInterval = ( 1. / 30. );
static const double gFadeIncrement = 0.05;
static const double gMinDisplayTime = 4.;
static const double gAdditionalLinesDisplayTime = 0.5;
static const double gMaxDisplayTime = 10.;

#pragma mark -

+ (GrowlSmokeWindowController *) notify {
	return [[[self alloc] init] autorelease];
}

+ (GrowlSmokeWindowController *) notifyWithTitle:(NSString *) title text:(id) text icon:(NSImage *) icon sticky:(BOOL) sticky {
	return [[[self alloc] initWithTitle:title text:text icon:icon sticky:sticky] autorelease];
}

#pragma mark Delegate Methods
/*	
	These methods are the methods that this class calls on the delegate.  In this case
	this class is the delegate for the class
*/

- (void) notificationDidFadeOut:(id)sender {
	NSSize windowSize = [[self window] frame].size;
//	NSLog(@"self id: [%d]", self->_id);
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:_id], @"ID",
		[NSNumber numberWithFloat:windowSize.height], @"Depth",
		nil];
	// stop smokeWindowDepth wrapping around
	if(windowSize.height > smokeWindowDepth)
		smokeWindowDepth = 0;
	else
		smokeWindowDepth -= windowSize.height;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"Glide" object:nil userInfo:dict];
}

- (void) _glideUp:(NSNotification *)note {
	NSDictionary *userInfo = [note userInfo];
//	NSLog(@"id: %d depth: %f", [[userInfo objectForKey:@"ID"] intValue], [[userInfo objectForKey:@"Depth"] floatValue]);
//	NSLog(@"self id: %d smokeWindowDepth: %d", _id, smokeWindowDepth);
	if ([[userInfo objectForKey:@"ID"] intValue] < _id) {
		NSRect theFrame = [[self window] frame];
		theFrame.origin.y += [[[note userInfo] objectForKey:@"Depth"] floatValue];
		// don't allow notification to fly off the top of the screen
		if(theFrame.origin.y >= NSMaxY( [[NSScreen mainScreen] visibleFrame] ) - GrowlSmokePadding)
			return;
		[[self window] setFrame:theFrame display:NO animate:YES];
	}
}

#pragma mark Regularly Scheduled Coding

- (id) initWithTitle:(NSString *) title text:(id) text icon:(NSImage *) icon sticky:(BOOL) sticky {
	_id = globalId++;

	[[NSNotificationCenter defaultCenter] addObserver:self 
											selector:@selector( _glideUp: ) 
												name:@"Glide"
											  object:nil];
	
	NSPanel *panel = [[[NSPanel alloc] initWithContentRect:NSMakeRect( 0., 0., GrowlSmokeNotificationWidth, 65. ) 
												 styleMask:NSBorderlessWindowMask 
												   backing:NSBackingStoreBuffered defer:NO] autorelease];
	NSRect panelFrame = [panel frame];
	[panel setBecomesKeyOnlyIfNeeded:YES];
	[panel setHidesOnDeactivate:NO];
	[panel setBackgroundColor:[NSColor clearColor]];
	[panel setLevel:NSStatusWindowLevel];
	[panel setSticky:YES];
	[panel setAlphaValue:0.];
	[panel setOpaque:NO];
	[panel setHasShadow:YES];
	[panel setCanHide:NO];
	[panel setReleasedWhenClosed:YES];
	[panel setDelegate:self];
	[self setDelegate:self];

	GrowlSmokeWindowView *view = [[[GrowlSmokeWindowView alloc] initWithFrame:panelFrame] autorelease];
	[view setTarget:self];
	[view setAction:@selector( _bubbleClicked: )];
	[panel setContentView:view];
	
	[view setTitle:title];
	if( [text isKindOfClass:[NSString class]] ) [view setText:text];
	else if( [text isKindOfClass:[NSAttributedString class]] ) [view setText:[text string]]; // we'll have no attributes here
	
	[view setIcon:icon];
	panelFrame = [view frame];
	[panel setFrame:panelFrame display:NO];
	
	NSRect screen = [[NSScreen mainScreen] visibleFrame];
	[panel setFrameTopLeftPoint:NSMakePoint( NSWidth( screen ) - NSWidth( panelFrame ) - GrowlSmokePadding, 
											 NSMaxY( screen ) - GrowlSmokePadding - ( smokeWindowDepth ) )];

	_depth = smokeWindowDepth += NSHeight( panelFrame );
	_autoFadeOut = YES;
	_delegate = nil;
	_target = nil;
	_representedObject = nil;
	_action = NULL;
	_animationTimer = nil;
	
	// the visibility time for this notification should be the minimum display time plus
	// some multiple of gAdditionalLinesDisplayTime, not to exceed gMaxDisplayTime
	int rowCount = [view descriptionRowCount];
	if (rowCount <= 2)
		rowCount = 0;
	/*BOOL limitPref = YES;
	READ_GROWL_PREF_BOOL(GrowlSmokeLimitPref, GrowlSmokePrefDomain, &limitPref);
	if (!limitPref) {*/
		_displayTime = MIN (gMinDisplayTime + rowCount * gAdditionalLinesDisplayTime, 
							gMaxDisplayTime);
	/*} else {
		_displayTime = gMinDisplayTime;
	}*/

	[self setAutomaticallyFadesOut:!sticky];
	
	return ( self = [super initWithWindow:panel] );
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[_delegate release];
	[_target release];
	[_representedObject release];
	[_animationTimer invalidate];
	[_animationTimer release];

	_target = nil;
	_representedObject = nil;
	_delegate = nil;
	_animationTimer = nil;

	extern unsigned int smokeWindowDepth;
//	NSLog(@"smokeController deallocking");
	if( _depth == smokeWindowDepth ) 
		smokeWindowDepth = 0;

	[super dealloc];
}

#pragma mark -

- (void) _stopTimer {
	[_animationTimer invalidate];
	[_animationTimer release];
	_animationTimer = nil;
}

- (void) _waitBeforeFadeOut {
	[self _stopTimer];
	_animationTimer = [[NSTimer scheduledTimerWithTimeInterval:_displayTime 
														target:self 
													  selector:@selector( startFadeOut ) 
													  userInfo:nil 
													   repeats:NO] retain];
}

- (void) _fadeIn:(NSTimer *) inTimer {
	NSWindow *myWindow = [self window];
	float alpha = [myWindow alphaValue];
	if( alpha < 1. ) {
		[myWindow setAlphaValue:(alpha + gFadeIncrement)];
	} else if( _autoFadeOut ) {
		if( _delegate && [_delegate respondsToSelector:@selector( notificationDidFadeIn: )] )
			[_delegate notificationDidFadeIn:self];
		[self _waitBeforeFadeOut];
	}
}

- (void) _fadeOut:(NSTimer *) inTimer {
	NSWindow *myWindow = [self window];
	float alpha = [myWindow alphaValue];
	if( alpha > 0. ) {
		[myWindow setAlphaValue:(alpha - gFadeIncrement)];
	} else {
		[self _stopTimer];
//		NSLog(@"_delegate: %@", _delegate);
		[self notificationDidFadeOut:self];
		if( _delegate && [_delegate respondsToSelector:@selector( notificationDidFadeOut: )] ) {
			[_delegate notificationDidFadeOut:self];
		}
		[self close];
		[self autorelease]; // Release, we retained when we faded in.
	}
}

- (void) _notificationClicked:(id) sender {
	if( _target && _action && [_target respondsToSelector:_action] )
		[_target performSelector:_action withObject:self];
	[self startFadeOut];
}

#pragma mark -

- (void) startFadeIn {
	if( _delegate && [_delegate respondsToSelector:@selector( notificationWillFadeIn: )] )
		[_delegate notificationWillFadeIn:self];
	[self retain]; // Retain, after fade out we release.
	[self showWindow:nil];
	[self _stopTimer];
	_animationTimer = [[NSTimer scheduledTimerWithTimeInterval:gTimerInterval target:self selector:@selector( _fadeIn: ) userInfo:nil repeats:YES] retain];
}

- (void) startFadeOut {
	if( _delegate && [_delegate respondsToSelector:@selector( notificationWillFadeOut: )] )
		[_delegate notificationWillFadeOut:self];
	[self _stopTimer];
	_animationTimer = [[NSTimer scheduledTimerWithTimeInterval:gTimerInterval target:self selector:@selector( _fadeOut: ) userInfo:nil repeats:YES] retain];
}

#pragma mark -

- (BOOL) automaticallyFadesOut {
	return _autoFadeOut;
}

- (void) setAutomaticallyFadesOut:(BOOL) autoFade {
	_autoFadeOut = autoFade;
}

#pragma mark -

- (id) target {
	return _target;
}

- (void) setTarget:(id) object {
	[_target autorelease];
	_target = [object retain];
}

#pragma mark -

- (SEL) action {
	return _action;
}

- (void) setAction:(SEL) selector {
	_action = selector;
}

#pragma mark -

- (id) representedObject {
	return _representedObject;
}

- (void) setRepresentedObject:(id) object {
	[_representedObject autorelease];
	_representedObject = [object retain];
}

#pragma mark -

- (id) delegate {
	return _delegate;
}

- (void) setDelegate:(id) delegate {
	_delegate = delegate;
//	NSLog(@"setDelegate: %@", _delegate);
}

#pragma mark -

- (void)_bubbleClicked:(id)sender {
	[self _stopTimer];
	[self startFadeOut];
}
	
#pragma mark -

- (BOOL) respondsToSelector:(SEL) selector {
	BOOL contentViewRespondsToSelector = [[[self window] contentView] respondsToSelector:selector];
	return contentViewRespondsToSelector ? contentViewRespondsToSelector : [super respondsToSelector:selector];
}

- (void) forwardInvocation:(NSInvocation *) invocation {
	NSView *contentView = [[self window] contentView];
	if( [contentView respondsToSelector:[invocation selector]] )
		[invocation invokeWithTarget:contentView];
	else
		[super forwardInvocation:invocation];
}

- (NSMethodSignature *) methodSignatureForSelector:(SEL) selector {
	NSView *contentView = [[self window] contentView];
	if( [contentView respondsToSelector:selector] )
		return [contentView methodSignatureForSelector:selector];
	else
		return [super methodSignatureForSelector:selector];
}
@end
