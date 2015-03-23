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
static NSString *const rawMethodString = @"{\n\treturn [UIColor colorWithRed:%@ blue:%@ green:%@ alpha:%@];\n}\n";
static NSString *const methodString = @"[UIColor colorWithRed:%@ blue:%@ green:%@ alpha:%@];";

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
}

- (IBAction)loadColorList:(id)sender
{
    [self.openPanel setAllowedFileTypes:@[@"clr"]];
    
    if ( [self.openPanel runModal] == NSOKButton ) {
        self.savePanel.nameFieldStringValue = @"UIColor+";
        self.savePanel.title = @"Give your color category a name:";
        if ( [ self.savePanel runModal] == NSOKButton ) {
            [self readColorListFromFile:[self.openPanel URL] intoFile:[self.savePanel URL]];
            //            [[NSApplication sharedApplication] terminate:nil];
        }
    }
}

- (IBAction)loadColorCategory:(id)sender
{
    [self.openPanel setAllowedFileTypes:@[@"m"]];
    
    if ( [self.openPanel runModal] == NSOKButton ) {
        self.savePanel.title = @"Give your color palette a name:";
        if ( [ self.savePanel runModal] == NSOKButton ) {
            [self readColorCategoryFromFile:[self.openPanel URL] intoFile:[self.savePanel URL]];
            //            [[NSApplication sharedApplication] terminate:nil];
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
        
        NSString *method = [NSString stringWithFormat:rawMethodString, red, blue, green, alpha];
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

- (void)readColorCategoryFromFile:(NSURL *)filePath intoFile:(NSURL *)saveFilePath
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
        [resultScanner scanUpToString:@";\n" intoString:&subResultString];
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
    
    [_colorList writeToFile:saveFilePath.path];
    [self.tableView reloadData];
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
