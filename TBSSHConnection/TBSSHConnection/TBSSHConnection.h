//
//  TBSSHConnection.h
//  tanB
//
//  Created by tanB on 5/18/13.
//  Copyright (c) 2013 tanB. All rights reserved.
//

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
