//
//  TBAppDelegate.m
//  TBSSHConnectionDemo
//
//  Created by tanB on 5/18/13.
//  Copyright (c) 2013 tanB. All rights reserved.
//

#import "TBAppDelegate.h"
#import "TBSSHConnection.h"


@interface TBAppDelegate ()
@property (nonatomic) TBSSHConnection *sshConnection;

@end

@implementation TBAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // please set user and hostname, or couldn't execute ssh command.
    // e.g. [[TBSSHConnection alloc] initWithUser:@"username" hostname:@"example.com" port:10022];
    self.sshConnection = [[TBSSHConnection alloc] initWithUser:nil hostname:nil port:22];

    [self.sshConnection execute];
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(handleExitWithErrorNotification:)
                               name:TBSSHExitWithErrorNotification
                             object:nil];
    
}

- (void)handleExitWithErrorNotification:(NSNotification *)notification
{
    // This notification was sent if an instance of TBSSHConnection got a
    // situation that ssh exit with status code 255.
    NSLog(@"TBSSHConnection Exit: %@", notification.object);
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [self.sshConnection terminate];
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self];
}

@end
