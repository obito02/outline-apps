// Copyright 2018 The Outline Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "AppDelegate.h"
#import "Outline-Swift.h"

@import ServiceManagement;
@import OutlineNotification;
@import OutlineTunnel;

@interface AppDelegate()
@property (strong, nonatomic) NSStatusItem *statusItem;
@property (strong, nonatomic) NSPopover *popover;
@property bool isSystemShuttingDown;
@end

@implementation AppDelegate

@synthesize window;

- (id)init {
  self = [super init];
  return self;
}

#pragma mark - Lifecycle

- (void)applicationDidStartLaunching:(NSNotification*)aNotification {
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
  [[NSAppleEventManager sharedAppleEventManager]
      setEventHandler:self
          andSelector:@selector(handleURLEvent:withReplyEvent:)
        forEventClass:kInternetEventClass
           andEventID:kAEGetURL];
  // Don't ever show the default Cordova window, as we will display its content view in a popover.
  [self.window close];

  [NSWorkspace.sharedWorkspace.notificationCenter
      addObserverForName:NSWorkspaceWillPowerOffNotification
                  object:nil
                   queue:nil
              usingBlock:^(NSNotification *_Nonnull n) {
                self.isSystemShuttingDown = YES;
              }];
  [NSNotificationCenter.defaultCenter addObserverForName:NSNotification.kVpnConnected
                                                  object:nil
                                                   queue:nil
                                              usingBlock:^(NSNotification * _Nonnull note) {
                                                [self setAppIcon:@"StatusBarButtonImageConnected"];
  }];
  [NSNotificationCenter.defaultCenter addObserverForName:NSNotification.kVpnDisconnected
                                                  object:nil
                                                   queue:nil
                                              usingBlock:^(NSNotification * _Nonnull note) {
                                                [self setAppIcon:@"StatusBarButtonImage"];
                                              }];
}

- (void)handleURLEvent:(NSAppleEventDescriptor*)event
        withReplyEvent:(NSAppleEventDescriptor*)replyEvent {
  NSString *url = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
  [[NSNotificationCenter defaultCenter]
      postNotificationName:NSNotification.kHandleUrl object:url];
  if (!self.popover.isShown) {
    [self showPopover];
  }
}

- (void)applicationDidFinishLaunching:(NSNotification*)aNotification {
  self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
  self.statusItem.button.action = @selector(togglePopover);
  [self setAppIcon:@"StatusBarButtonImage"];
  self.popover = [[NSPopover alloc] init];
  self.popover.behavior = NSPopoverBehaviorTransient;
  self.popover.contentViewController = [[NSViewController alloc] initWithNibName:@"MainViewController"
                                                                          bundle:[NSBundle mainBundle]];
  self.popover.contentViewController.view = self.window.contentView;

  if ([self wasStartedByLauncherApp]) {
    [OutlineVpn.shared startLastSuccessfulTunnel:^(NSString * _Nullable errMsg) {
      if (errMsg != nil && errMsg.length > 0) {
        NSLog(@"Failed to auto-connect the VPN on startup: %@", errMsg);
      }
    }];
  } else {
    // The rendering of the popover is relative to the app's status item in the status bar.
    // Even though we've already created the status bar above, the popover is being created
    // before the status item has been rendered in the UI. This causes the initial popover
    // load to be "floating" and ends up aligned at the bottom of the screen. For this initial
    // load we add a small artificial delay to prevent that from happening.
    double delayInSeconds = 0.5;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
      [self showPopover];
    });
  }
  [self setAppLauncherEnabled:true];  // Enable app launcher to start on boot.
}

- (void)applicationWillTerminate:(NSNotification *)notification {
  if (!self.isSystemShuttingDown) {
    // Don't post a quit notification if the system is shutting down so the VPN is not stopped
    // and it auto-connects on startup.
    [[NSNotificationCenter defaultCenter] postNotificationName:NSNotification.kAppQuit
                                                        object:nil];
  }
}

#pragma mark - Popover

- (void)togglePopover {
  if (self.popover.isShown) {
    [self closePopover];
  } else {
    [self showPopover];
  }
}

- (void)closePopover {
  [self.popover close];
}

- (void)showPopover {
  [self.popover showRelativeToRect:self.statusItem.button.bounds
                            ofView:self.statusItem.button
                     preferredEdge:NSRectEdgeMinY];
  // Activate the application in order to focus the popover.
  [[NSRunningApplication currentApplication]
      activateWithOptions:NSApplicationActivateIgnoringOtherApps];
}

- (void)setAppIcon:(NSString *)imageName {
  self.statusItem.button.image = [NSImage imageNamed:imageName];
  self.statusItem.button.image.template = YES;
}

#pragma mark - Launcher

// Enables or disables the embedded app launcher as a login item.
- (void)setAppLauncherEnabled:(bool)enabled {
  NSString *launcherBundleId = [self getLauncherBundleId];
  if (launcherBundleId == nil) {
    return;
  }
  if (!SMLoginItemSetEnabled((__bridge CFStringRef) launcherBundleId, enabled)) {
    return NSLog(@"Failed to %@ launcher %@", enabled ? @"enable" : @"disable", launcherBundleId);
  }
}

// Returns the embedded launcher application's bundle ID.
- (NSString *)getLauncherBundleId {
  static NSString *kAppLauncherName = @"launcher";
  NSString *bundleId = NSBundle.mainBundle.bundleIdentifier;
  if (bundleId == nil) {
    NSLog(@"Failed to retrieve the application's bundle ID");
    return nil;
  }
  return [[NSString alloc] initWithFormat:@"%@.%@", bundleId, kAppLauncherName];
}

// Returns whether the app was started by the embedded launcher app by inspecting the launch event.
- (bool)wasStartedByLauncherApp {
  NSAppleEventDescriptor *descriptor = [[NSAppleEventManager sharedAppleEventManager]
                                        currentAppleEvent];
  if (descriptor == nil) {
    return false;
  }
  NSAppleEventDescriptor *launcherDescriptor = [descriptor paramDescriptorForKeyword:keyAEPropData];
  if (launcherDescriptor == nil) {
    return false;
  }
  NSString *launcherBundleId = [self getLauncherBundleId];
  if (launcherBundleId == nil) {
    return false;
  }
  return [launcherBundleId isEqual:launcherDescriptor.stringValue];
}

@end
