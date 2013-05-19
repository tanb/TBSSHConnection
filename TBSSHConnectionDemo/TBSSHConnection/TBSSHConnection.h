//
//  TBSSHConnection.h
//
//  Created by Tomonori Tanabe on 5/18/13.
//  Copyright (c) 2013 Tomonori Tanabe. All rights reserved.
//
//  https://github.com/tanB/TBSSHConnection

#import <Foundation/Foundation.h>

@interface TBSSHConnection : NSObject

- (id)initWithUser:(NSString *)user
          hostname:(NSString *)hostname
              port:(NSInteger)port;


- (void)addLocalForwardWithSourcePort:(NSInteger)source
                   destinationAddress:(NSString *)address
                      destinationPort:(NSInteger)destination;


- (void)execute;
- (void)terminate;

- (BOOL)isRunning;

@end


/* This notification is posted if the instance of TBSSHConnection got a situation that ssh exit with status code 255. According to `$ man ssh`, ssh exits with 255 if an error occurred.
 */
FOUNDATION_EXPORT NSString * const TBSSHExitWithErrorNotification;
/* This notification is posted when the instance of TBSSHConnection reads the data currently available at its ssh connection channel.
 */
FOUNDATION_EXPORT NSString * const TBSSHReadLineCompletionNotification;
