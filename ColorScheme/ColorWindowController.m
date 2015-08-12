//
//  ColorWindowController.m
//  ColorScheme
//
//  Created by Chris Nielubowicz on 3/23/15.
//  Copyright (c) 2015 Assorted Intelligence. All rights reserved.
//

#import "ColorWindowController.h"

static NSString *const categoryHeader = @"#import <UIKit/UIKit.h>\n\n@interface UIColor (%@)\n\n";
static NSString *const categoryImplementationHeader = @"#import \"%@\"\n\n@implementation UIColor(%@)\n\n";
static NSString *const headerString = @"+(UIColor *)%@;\n";
static NSString *const rawMethodString = @"{\n\treturn [UIColor colorWithRed:%@ green:%@ blue:%@ alpha:%@];\n}\n";
static NSString *const methodString = @"[UIColor colorWithRed:%@ green:%@ blue:%@ alpha:%@];";

@interface ColorWindowController () <NSTableViewDataSource, NSTableViewDelegate>

@property (strong, nonatomic) NSOpenPanel *openPanel;
@property (strong, nonatomic) NSSavePanel *savePanel;
@property (strong, nonatomic) NSColorList *colorList;

@property (weak, nonatomic) IBOutlet NSTableView *tableView;

@end

@implementation ColorWindowController

- (id)init
{
    if (self = [super initWithWindowNibName:@"ColorWindow"]) {
        
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    self.openPanel = [NSOpenPanel openPanel];
    [self.openPanel setCanChooseFiles:YES];
    
    self.savePanel = [NSSavePanel savePanel];
    self.savePanel.showsTagField = NO;
}

- (IBAction)loadColorList:(id)sender
{
    [self.openPanel setAllowedFileTypes:@[@"clr"]];
    
    if ( [self.openPanel runModal] == NSOKButton ) {
        self.savePanel.allowedFileTypes = nil;
        self.savePanel.nameFieldStringValue = @"UIColor+";
        self.savePanel.title = @"Give your color category a name:";
        if ( [ self.savePanel runModal] == NSOKButton ) {
            [self readColorListFromFile:[self.openPanel URL] intoFile:[self.savePanel URL]];
        }
    }
}

- (IBAction)loadColorCategory:(id)sender
{
    [self.openPanel setAllowedFileTypes:@[@"m"]];
    
    if ( [self.openPanel runModal] == NSOKButton ) {
        self.savePanel.allowedFileTypes = @[ @"clr" ];
        self.savePanel.title = @"Give your color palette a name:";
        if ( [ self.savePanel runModal] == NSOKButton ) {
            [self readColorCategoryFromFile:[self.openPanel URL] intoFile:[self.savePanel URL]];
        }
    }
}

- (void)readColorListFromFile:(NSURL *)filePath intoFile:(NSURL *)saveFilePath
{
    NSMutableString *headerFile = [NSMutableString new];
    NSMutableString *implementationFile = [NSMutableString new];
    
    NSString *fileName = [[filePath lastPathComponent] stringByDeletingPathExtension];
    _colorList = [[NSColorList alloc] initWithName:fileName fromFile:filePath.path];
    
    [self.tableView reloadData];
    
    NSString *headerFilename = [saveFilePath.path stringByAppendingString:@".h"];
    NSString *implementationFilename = [saveFilePath.path stringByAppendingString:@".m"];
    
    NSString *categoryInterface = [NSString stringWithFormat:categoryHeader, _colorList.name];
    [headerFile appendString:categoryInterface];
    
    NSString *categoryImplementation = [NSString stringWithFormat:categoryImplementationHeader, [headerFilename lastPathComponent], _colorList.name];
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
        
        NSString *method = [NSString stringWithFormat:rawMethodString, red, green, blue, alpha];
        [implementationFile appendString:header];
        [implementationFile appendString:method];
        [implementationFile appendString:@"\n"];
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





- (void)readColorCategoryFromFile:(NSURL *)filePath intoFile:(NSURL *)saveFilePath{
    _colorList = [[NSColorList alloc] initWithName:[filePath lastPathComponent]];
    
    NSString *colorImplementation = [NSString stringWithContentsOfURL:filePath encoding:NSUTF8StringEncoding error:NULL];
    
    NSString *stripped = [colorImplementation stringByReplacingOccurrencesOfString : @" "
                                                                        withString : @""];
    
    
    NSScanner *scanner = [NSScanner scannerWithString:stripped];
    NSScanner *resultScanner = nil;
    NSString *resultString = @"\n";
    
    
    NSString *lastResult = nil;
    
    while (![scanner isAtEnd] && ![lastResult isEqualToString:resultString]) {
        NSColor *color;
        [scanner scanUpToString:@"+(" intoString:&resultString];
        // scan to end of first method implementation, get method name
        lastResult = resultString;
        [scanner scanUpToString:@"}" intoString:&resultString];
        
        
        resultScanner = [NSScanner scannerWithString:resultString];
        
        
        if (![resultScanner isAtEnd]) {
            [resultScanner setScanLocation:resultScanner.scanLocation + 1];
        }
        NSLog(@"RES = %@", resultString);;
        
        NSString*title = [self findPattern:@"\\+\\(UIColor\\*\\)(.*?)\\{" FromString:resultString];
        NSLog(@"TITLE = %@",title);
        
        if (title == nil){
            continue;
        }
        
        NSString *red = [self findPattern:@"colorWithRed:(.*?)green" FromString:resultString];
        NSLog(@"red = %@",red);
        NSString *green = [self findPattern:@"green:(.*?)blue" FromString:resultString];
        NSLog(@"green = %@",green);
        NSString *blue = [self findPattern:@"blue:(.*?)alpha:" FromString:resultString];
        NSLog(@"blue = %@",blue);
        NSString *alpha = [self findPattern:@"alpha:(.*?)\\]" FromString:resultString];
        NSLog(@"alpha = %@",alpha);
        
        if (red == nil){
            NSString *white = [self findPattern:@"UIColorcolorWithWhite:(.*?)alpha:" FromString:resultString];
            NSLog(@"white = %@",white);
            CGFloat w = [self floatMyString:white];
            CGFloat a = [self floatMyString:alpha];
            
            color = [NSColor colorWithDeviceWhite:w alpha:a];
            
        }else{
            CGFloat r = [self floatMyString:red];
            CGFloat g = [self floatMyString:green];
            CGFloat b = [self floatMyString:blue];
            CGFloat a = [self floatMyString:alpha];
            
            color = [NSColor colorWithDeviceRed:r green:g blue:b alpha:a];
            
        }
        
        [_colorList setColor:color forKey:title];
    }
    
    NSLog(@"_colorArray = %@",_colorList.allKeys);
    
    [_colorList writeToFile:saveFilePath.path];
    [self.tableView reloadData];
}


#pragma mark - RegEx Content -
-(NSString*)findPattern:(NSString*)pattern FromString:(NSString*)inputString{
    
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern : pattern
                                  options : NSRegularExpressionCaseInsensitive | NSRegularExpressionAnchorsMatchLines
                                  error : nil];
    
    NSTextCheckingResult *textCheckingResult = [regex firstMatchInString : inputString
                                                                 options : 0
                                                                   range : NSMakeRange(0, inputString.length)];
    
    NSRange matchRange = [textCheckingResult rangeAtIndex:1];
    NSString *match    = [inputString substringWithRange:matchRange];
    
    //NSLog(@"Found string '%@'", match);
    
    if (match.length<1) {
        return nil;
    }
    
    return match;
}



-(CGFloat)floatMyString:(NSString*)string{
    string = [string stringByReplacingOccurrencesOfString : @"f"
                                               withString : @""];
    NSLog(@"str = %@",string);
    NSString* left = [self findPattern:@"^(.*?)/[0-9]+" FromString:string];
    NSString* right = [self findPattern:@"[0-9]+/(.*?)$" FromString:string];
    
    NSLog(@"l = %@, r = %@", left, right);
    if (left == nil){
        return [string floatValue];
    }
    
    return [left floatValue] / [right floatValue];
}


#pragma mark - NSTableViewDataSource methods
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView;
{
    return [_colorList allKeys].count;
}

#pragma mark - NSTableViewDelegate methods
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    return NO;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSTableCellView *rowView = [tableView makeViewWithIdentifier:@"colorRow" owner:self];
    if (rowView == nil) {
        rowView = [[NSTableCellView alloc] init];
        rowView.identifier = @"colorRow";
    }
    
    NSColor *color = (NSColor *)[_colorList colorWithKey:[_colorList allKeys][row]];
    rowView.textField.stringValue = [_colorList allKeys][row];
    rowView.textField.backgroundColor = color;
    rowView.wantsLayer = YES;
    rowView.layer.backgroundColor = color.CGColor;
    return rowView;
}


@end
