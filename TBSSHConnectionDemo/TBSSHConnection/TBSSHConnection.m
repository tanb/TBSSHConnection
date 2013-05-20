//
//  TBSSHConnection.m
//
//  Created by Tomonori Tanabe on 5/18/13.
//  Copyright (c) 2013 Tomonori Tanabe. All rights reserved.
//
//  https://github.com/tanB/TBSSHConnection

#import "TBSSHConnection.h"

static NSString * const TBSSHTunnelObjectKeySourcePort = @"sourceport";
static NSString * const TBSSHTunnelObjectKeyDestinationPort = @"destinationport";
static NSString * const TBSSHTunnelObjectKeyDestinationAddress = @"destinationaddress";
static NSString * const TBSSHTunnelObjectKeyHostName = @"hostname";

NSString * const TBSSHExitWithErrorNotification = @"TBSSHExitWithErrorNotification";
NSString * const TBSSHReadLineCompletionNotification = @"TBSSHReadLineCompletionNotification";

@interface TBSSHConnection ()
@property (nonatomic) NSString *user;
@property (nonatomic) NSInteger port;
@property (nonatomic) NSString *hostname;
@property (nonatomic) NSMutableArray *localForwards;
@property (atomic) NSLock *lock;
@property (nonatomic) NSTask *task;
@property (nonatomic) NSPipe *pipe;
@end

@implementation TBSSHConnection

- (void)addLocalForwardWithSourcePort:(NSInteger)source
                   destinationAddress:(NSString *)address
                      destinationPort:(NSInteger)destination
{
    NSMutableDictionary *dict = @{}.mutableCopy;
    dict[TBSSHTunnelObjectKeySourcePort] = @(source);
    dict[TBSSHTunnelObjectKeyDestinationPort] = @(destination);
    dict[TBSSHTunnelObjectKeyDestinationAddress] = address;
    [self.localForwards addObject:dict];
}

- (void)removeLocalForwardWithSourcePort:(NSInteger)source
                      destinationAddress:(NSString *)address
                         destinationPort:(NSInteger)destination
{
    NSMutableDictionary *dict = @{}.mutableCopy;
    dict[TBSSHTunnelObjectKeySourcePort] = @(source);
    dict[TBSSHTunnelObjectKeyDestinationPort] = @(destination);
    dict[TBSSHTunnelObjectKeyDestinationAddress] = address;
    
    [self.localForwards removeObject:dict];
}

- (id)initWithUser:(NSString *)user hostname:(NSString *)hostname port:(NSInteger)port
{
    self = [super init];
    if(!self) return nil;
    self.lock = [NSLock new];
    self.user = user;
    self.port = port;
    self.hostname = hostname;
    self.localForwards = @[].mutableCopy;
    self.lock = nil;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(readData:)
                                                 name:NSFileHandleReadCompletionNotification
                                               object:nil];
    return self;
}

- (void)readData:(NSNotification *)notification
{
    NSNotification *notice =
    [NSNotification notificationWithName:TBSSHReadLineCompletionNotification
                                  object:self
                                userInfo:notification.userInfo];
    [[NSNotificationCenter defaultCenter] postNotification:notice];
    
	if ([self.task isRunning]) {
		[[self.pipe fileHandleForReading] readInBackgroundAndNotify];
	}
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSArray *)arguments
{
    NSMutableArray *args = @[].mutableCopy;
    if(self.localForwards) {
        for (NSDictionary *localForward in self.localForwards) {
            [args addObject:@"-L"];
            [args addObject:[NSString stringWithFormat:@"%d:%@:%d",
                             [localForward[TBSSHTunnelObjectKeySourcePort] intValue],
                             localForward[TBSSHTunnelObjectKeyDestinationAddress],
                             [localForward[TBSSHTunnelObjectKeyDestinationPort] intValue]]];
        }
    }
    
    [args addObject:self.hostname];
    [args addObject:@"-t"];
    [args addObject:@"-t"];
    [args addObject:@"-p"];
    [args addObject:[NSString stringWithFormat:@"%ld", self.port]];
    [args addObject:@"-l"];
    [args addObject:self.user];
    
    return args;
}

- (void)execute
{
    if (!self.hostname || !self.user) {
#if DEBUG
        NSLog(@"Please set user and hostname");
        return;
#endif
    }
    
    if ([self isRunning]) [self terminate];
    
    self.pipe = [NSPipe new];
    [[self.pipe fileHandleForReading] readInBackgroundAndNotify];

    self.task = [NSTask new];
    [self.task setLaunchPath:@"/usr/bin/ssh"];
    [self.task setStandardOutput:self.pipe];
    [self.task setStandardError:self.pipe];
    [self.task setArguments:self.arguments];
    
    dispatch_queue_t queue =
    dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    dispatch_async(queue, ^{
        [self runCommand];
    });
}

- (void)terminate
{
    if(!self.task || ![self.task isRunning]) return;
    [self.task terminate];
    [self.lock lock];
    [self.lock unlock];
}

- (void)runCommand
{
    @autoreleasepool {
        [self.lock lock];
        [self.task launch];
        [self.task waitUntilExit];
        int status = [self.task terminationStatus];
        if (status == 255) {
            // ssh exits with the exit status of the remote command or with 255
            // if an error occurred. see $ man ssh
            NSNotification *notification =
            [NSNotification notificationWithName:TBSSHExitWithErrorNotification
                                          object:self];

            [[NSNotificationCenter defaultCenter] postNotification:notification];
        }
        [self.lock unlock];
    }
}

- (BOOL)isRunning
{
    if (!self.task) return NO;
    return [self.task isRunning];
}

@end
