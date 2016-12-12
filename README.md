# ColorScheme

A Cocoa app for converting Color Palettes (`.clr`) to UIColor Categories (`Objective-C`) to allow for smoother flow between IB and your code.

Simply launch ColorScheme, select your input file and be amazed as all your heart's desires are created for you.

## Expected format
UIColor categories should follow the following format:
```
@implementation UIColor (<CategoryName>)

+(UIColor *)colorName;
{
     return [UIColor colorWithRed:redValue green:greenValue blue:blueValue alpha:alphaValue];
}

@end
```

## Support
Supports Objective-C, Swift 2.x and Swift 3.x
