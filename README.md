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
