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
This notification was sent if an instance of TBSSHConnection got a situation that ssh exit with status code 255.
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
    // blah blah blah...
}
```
## License
Copyright (c) 2013 Tomonori Tanabe

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
