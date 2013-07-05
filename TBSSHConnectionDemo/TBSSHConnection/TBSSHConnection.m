//
//  TBSSHConnection.m
//
//  Created by Tomonori Tanabe on 5/18/13.
//  Copyright (c) 2013 Tomonori Tanabe. All rights reserved.
//
//  https://github.com/tanB/TBSSHConnection

#import "TBSSHConnection.h"

NSString * const TBSSHTunnelConfigurationKeySourcePort = @"sourceport";
NSString * const TBSSHTunnelConfigurationKeyDestinationPort = @"destinationport";
NSString * const TBSSHTunnelConfigurationKeyDestinationAddress = @"destinationaddress";
NSString * const TBSSHTunnelConfigurationKeyHostName = @"hostname";

NSString * const TBSSHExitWithErrorNotification = @"TBSSHExitWithErrorNotification";
NSString * const TBSSHReadLineCompletionNotification = @"TBSSHReadLineCompletionNotification";

NSString * const TBSSHConfigurationKeyUsername = @"user";
NSString * const TBSSHConfigurationKeyPort = @"port";
NSString * const TBSSHConfigurationKeyHostname = @"hostname";
NSString * const TBSSHConfigurationKeyLocalForwards = @"localForwards";

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
    dict[TBSSHTunnelConfigurationKeySourcePort] = @(source);
    dict[TBSSHTunnelConfigurationKeyDestinationPort] = @(destination);
    dict[TBSSHTunnelConfigurationKeyDestinationAddress] = address;
    [self.localForwards addObject:dict];
}

- (void)removeLocalForwardWithSourcePort:(NSInteger)source
                      destinationAddress:(NSString *)address
                         destinationPort:(NSInteger)destination
{
    NSMutableDictionary *dict = @{}.mutableCopy;
    dict[TBSSHTunnelConfigurationKeySourcePort] = @(source);
    dict[TBSSHTunnelConfigurationKeyDestinationPort] = @(destination);
    dict[TBSSHTunnelConfigurationKeyDestinationAddress] = address;
    
    [self.localForwards removeObject:dict];
}

- (NSDictionary *)configuration
{
    NSMutableDictionary *dict = @{}.mutableCopy;
    dict[TBSSHConfigurationKeyUsername] = self.user;
    dict[TBSSHConfigurationKeyHostname] = self.hostname;
    dict[TBSSHConfigurationKeyPort] = @(self.port);
    dict[TBSSHConfigurationKeyLocalForwards] = [self.localForwards copy];
    
    return dict;
}

- (id)initWithConfiguration:(NSDictionary *)configuration
{
    self = [super init];
    if(!self) return nil;
    self.lock = [NSLock new];
    self.user = configuration[TBSSHConfigurationKeyUsername];
    self.port = [configuration[TBSSHConfigurationKeyPort] intValue];
    self.hostname = configuration[TBSSHConfigurationKeyHostname];
    self.localForwards = ((NSArray *)configuration[TBSSHConfigurationKeyLocalForwards]).mutableCopy;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(readData:)
                                                 name:NSFileHandleReadCompletionNotification
                                               object:nil];
    return self;    
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
                             [localForward[TBSSHTunnelConfigurationKeySourcePort] intValue],
                             localForward[TBSSHTunnelConfigurationKeyDestinationAddress],
                             [localForward[TBSSHTunnelConfigurationKeyDestinationPort] intValue]]];
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
