//
//  AppDelegate.m
//  ColorScheme
//
//  Created by chris nielubowicz on 3/10/15.
//  Copyright (c) 2015 Assorted Intelligence. All rights reserved.
//

#import "AppDelegate.h"
#import <objc/message.h>

@interface AppDelegate ()

@property (strong, nonatomic) NSOpenPanel *openPanel;
@property (strong, nonatomic) NSColorList *colorList;

@end

@implementation AppDelegate

static NSString *const headerString = @"+(UIColor *)%@;\n";
static NSString *const rawMethodString = @"{\n\treturn [UIColor colorWithRed:%@ blue:%@ green:%@ alpha:%@];\n}\n";
static NSString *const methodString = @"[UIColor colorWithRed:%@ blue:%@ green:%@ alpha:%@];";

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    self.openPanel = [NSOpenPanel openPanel];
    [self.openPanel setCanChooseFiles:YES];

}

- (IBAction)loadColorList:(id)sender
{
    [self.openPanel setAllowedFileTypes:@[@"clr"]];
    
    if ( [self.openPanel runModal] == NSOKButton ) {
        [self readColorListFromFile:[self.openPanel URL]];
        [[NSApplication sharedApplication] terminate:nil];
    }
}

- (IBAction)loadColorCategory:(id)sender
{
    [self.openPanel setAllowedFileTypes:@[@"m"]];
    
    if ( [self.openPanel runModal] == NSOKButton ) {
        [self readColorCategoryFromFile:[self.openPanel URL]];
        [[NSApplication sharedApplication] terminate:nil];
    }
}

- (void)readColorListFromFile:(NSURL *)filePath
{
    NSMutableString *headerFile = [NSMutableString new];
    NSMutableString *implementationFile = [NSMutableString new];

    NSString *fileName = [[filePath lastPathComponent] stringByDeletingPathExtension];
    _colorList = [[NSColorList alloc] initWithName:fileName fromFile:filePath.path];

    NSString *docDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString *categoryName = [@"UIColor+" stringByAppendingString:_colorList.name];
    NSString *headerFilename = [[docDir stringByAppendingPathComponent:categoryName ] stringByAppendingString:@".h"];
    NSString *implementationFilename = [[docDir stringByAppendingPathComponent:categoryName ] stringByAppendingString:@".m"];
    
    NSString *categoryInterface = [NSString stringWithFormat:@"#import <UIKit/UIKit.h>\n\n@interface UIColor (%@)\n\n", _colorList.name];
    [headerFile appendString:categoryInterface];
    
    NSString *categoryImplementation = [NSString stringWithFormat:@"#import \"%@\"\n\n@implementation UIColor(%@)\n\n", [headerFilename lastPathComponent], _colorList.name];
    [implementationFile appendString:categoryImplementation];
    
    for (NSString *key in _colorList.allKeys)
    {
        NSColor *color = [_colorList colorWithKey:key];
        
        NSNumber *red = @([color redComponent]);
        NSNumber *blue = @([color blueComponent]);
        NSNumber *green = @([color greenComponent]);
        NSNumber *alpha = @([color alphaComponent]);
        
        NSString *header = [NSString stringWithFormat:headerString, key];
        [headerFile appendString:header];
        
        NSString *method = [NSString stringWithFormat:methodString, red, blue, green, alpha];
        [implementationFile appendString:header];
        [implementationFile appendString:method];
        [implementationFile appendString:@"\n\n"];
    }
    
    [headerFile appendString:@"\n@end"];
    [implementationFile appendString:@"\n@end"];
    
    NSError *err = nil;
    [headerFile writeToFile:headerFilename
                atomically:YES
                   encoding:NSUTF8StringEncoding
                      error:&err];
    
    [implementationFile writeToFile:implementationFilename
                         atomically:YES
                           encoding:NSUTF8StringEncoding
                              error:&err];
}

- (void)readColorCategoryFromFile:(NSURL *)filePath
{
    _colorList = [[NSColorList alloc] initWithName:[filePath lastPathComponent]];
    
    NSString *colorImplementation = [NSString stringWithContentsOfURL:filePath encoding:NSUTF8StringEncoding error:NULL];
    
    NSScanner *scanner = [NSScanner scannerWithString:colorImplementation];
    NSScanner *resultScanner = nil;
    NSString *resultString;
    NSString *subResultString;
    
    NSString *colorName;
    
    // scan to first method implementation
    [scanner scanUpToString:@"+(" intoString:&resultString];

    while (true) {
        // scan to end of first method implementation, get method name
        NSString *lastResult = resultString;
        [scanner scanUpToString:@"\n" intoString:&resultString];
        if ([lastResult isEqualToString:resultString]) {
            break;
        }
        
        resultScanner = [NSScanner scannerWithString:resultString];
        [resultScanner scanUpToString:@")" intoString:&subResultString];
        [resultScanner scanString:@")" intoString:NULL];
        [resultScanner scanUpToString:@"\n" intoString:&subResultString];
        colorName = [subResultString copy];
        
        [scanner scanUpToString:@"[UIColor colorWithRed" intoString:&resultString];
        
        // get method signature -- red, blue, green and alpha values
        [scanner scanUpToString:@";" intoString:&resultString];

        float red;
        float green;
        float blue;
        float alpha;
        
        float denominator;
        [scanner scanUpToString:@":" intoString:&subResultString];
        [scanner scanString:@":" intoString:&subResultString];
        [scanner scanFloat:&red];
        [scanner scanString:@"/" intoString:&subResultString];
        [scanner scanFloat:&denominator];
        red = red / denominator;

        [scanner scanUpToString:@":" intoString:&subResultString];
        [scanner scanString:@":" intoString:&subResultString];
        [scanner scanFloat:&green];
        [scanner scanString:@"/" intoString:&subResultString];
        [scanner scanFloat:&denominator];
        green = green / denominator;

        [scanner scanUpToString:@":" intoString:&subResultString];
        [scanner scanString:@":" intoString:&subResultString];
        [scanner scanFloat:&blue];
        [scanner scanString:@"/" intoString:&subResultString];
        [scanner scanFloat:&denominator];
        blue = blue / denominator;
        
        [scanner scanUpToString:@":" intoString:&subResultString];
        [scanner scanString:@":" intoString:&subResultString];
        [scanner scanFloat:&alpha];
        
        NSColor *color = (NSColor *)objc_msgSend([NSColor class], sel_getUid("colorWithRed:green:blue:alpha:"), *(float *)&red, *(float *)&blue, *(float *)&green, *(float *)&alpha);
        [_colorList setColor:color forKey:colorName];
    }

    NSString *docDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString *colorListName = [_colorList.name stringByAppendingPathExtension:@"clr"];
    [_colorList writeToFile:[docDir stringByAppendingPathComponent:colorListName]];
}

@end
