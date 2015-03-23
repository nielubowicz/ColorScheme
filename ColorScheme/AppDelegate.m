//
//  AppDelegate.m
//  ColorScheme
//
//  Created by chris nielubowicz on 3/10/15.
//  Copyright (c) 2015 Assorted Intelligence. All rights reserved.
//

#import "AppDelegate.h"
#import "ColorWindowController.h"
#import <objc/message.h>

@interface AppDelegate ()

@property (strong, nonatomic) ColorWindowController *windowController;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    self.windowController = [[ColorWindowController alloc] init];
    [self.windowController showWindow:self];
}

@end
