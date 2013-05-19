TBSSHConnection
===============

TBSSHConnection makes easy to establish an ssh connection in Objective-C

```objective-c
TBSSHConnection *sshConnection = 
    [[TBSSHConnection alloc] initWithUser:@"username" hostname:@"hostname" port:22];

[sshConnection execute];
```

## How To Get Started
- Drag the `TBSSHConnection/` folder to your project (make sure you copy all files/folders)
- `#import "TBSSHConnection.h"`

## SSH Tunneling
```objective-c
TBSSHConnection *sshConnection = 
    [[TBSSHConnection alloc] initWithUser:@"username" hostname:@"hostname" port:22];
[sshConnection addLocalForwardWithSourcePort:80 destinationAddress:@"localhost" destinationPort:80];
[sshConnection addLocalForwardWithSourcePort:8080 destinationAddress:@"localhost" destinationPort:8080];

[sshConnection execute];
```

## Notification
### TBSSHExitWithErrorNotification
This notification is posted if an instance of TBSSHConnection got a situation that ssh exit with status code 255.
```objective-c
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(handleExitWithErrorNotification:)
                               name:TBSSHExitWithErrorNotification
                             object:nil];   
}

- (void)handleExitWithErrorNotification:(NSNotification *)notification
{
    NSLog(@"TBSSHConnection Exit: %@", notification.object);
    // blah blah blah...
}
```
### TBSSHReadLineCompletionNotification
This notification is posted when an instance of TBSSHConnection reads the data currently available at its ssh connection channel.
```objective-c
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(handleReadLineCompletionNotification:)
                               name:TBSSHReadLineCompletionNotification
                             object:nil]; 
}

- (void)handleReadLineCompletionNotification:(NSNotification *)notification
{
    NSData *data = [notification.userInfo valueForKey:NSFileHandleNotificationDataItem];
	NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	NSLog(@"%@", notification.object);
    NSLog(@"%@", string);
    // blah blah blah...
}
```
## License
TBSSHConnection is available under the MIT license. See the LICENSE file for more info.
