//
//  DebugSearch.m
//  DebugSearch
//
//  Created by Moises Anthony Aranas on 6/19/14.
//    Copyright (c) 2014 moises. All rights reserved.
//

#import "DebugSearch.h"
#import <objc/objc-class.h>

static DebugSearch *sharedPlugin;
static NSString *myFilter;
static NSString *kFilterForDebugSearchChanged = @"kFilterForDebugSearchChanged";

static NSString *plistFilename = @"dbgHighlightConf.plist";
static NSString *plistConfigFolder = @".dbgSearch";

static NSDictionary *highlightsDictionary;

@interface NSTextStorage (DebugSearch)
- (void)dbgSearch_fixAttributesInRange:(NSRange)aRange;
@end

@implementation NSTextStorage (DebugSearch)
- (void)dbgSearch_fixAttributesInRange:(NSRange)aRange
{
    if ([[self string] rangeOfString:@"(lldb)"].location != NSNotFound) // currently debugging
    {
        [self dbgSearch_fixAttributesInRange:aRange];
        return;
    }
    BOOL found = NO;
    for (NSLayoutManager* item in [self layoutManagers]) {
        if ([[item firstTextView] isKindOfClass:NSClassFromString(@"IDEConsoleTextView")])
        {
            found = YES;
            break;
        }
    }
    if (found) {
        NSString *stringToModify = [[self string] substringWithRange:aRange];
        NSArray *components = [stringToModify componentsSeparatedByString:@"\n"];
        NSDictionary *invisibleAttr = @{
                                        NSFontAttributeName : [NSFont systemFontOfSize:0.001],
                                        NSForegroundColorAttributeName : [NSColor clearColor]
                                        };
        for (NSString* component in components) {
            if (myFilter.length > 0 && [component rangeOfString:myFilter].location == NSNotFound)
            {
                NSRange rangeToDelete = [[self string] rangeOfString:component options:0 range:aRange];
                if (rangeToDelete.location != NSNotFound) {
                    [self addAttributes:invisibleAttr range:rangeToDelete];
                }
            } else if (highlightsDictionary) {
                // highlighting
                NSString *wantedKey = nil;
                for (NSString* key in [highlightsDictionary allKeys]) {
                    if ([component rangeOfString:key].location != NSNotFound) {
                        wantedKey = key;
                        break;
                    }
                }
                if (wantedKey) {
                    NSArray *params = highlightsDictionary[wantedKey];
                    NSColor *textColor = [NSColor colorWithCalibratedRed:[params[0] floatValue] green:[params[1] floatValue] blue:[params[2] floatValue] alpha:[params[3] floatValue]];
                    NSRange rangeToColor = [[self string] rangeOfString:component options:0 range:aRange];
                    [self addAttribute:NSForegroundColorAttributeName value:textColor range:rangeToColor];
                }
            }
        }
    }
    [self dbgSearch_fixAttributesInRange:aRange];
}

@end

@interface NSViewController (DebugSearch)
- (void)dbgSearch_loadView;
// associated object
@property (nonatomic, weak) NSTextField *filterText;
// notification observer
- (void)filterChanged;
@end

@implementation NSViewController (DebugSearch)
- (void)setFilterText:(NSTextField *)filterText
{
    // doesn't need to be strong; we add it to a view anyway, which should retain it
    objc_setAssociatedObject(self, @selector(filterText), filterText, OBJC_ASSOCIATION_ASSIGN);
}

- (NSTextField*)filterText
{
    return objc_getAssociatedObject(self, @selector(filterText));
}

- (void)dbgSearch_loadView
{
    [self dbgSearch_loadView];
    if ([self isKindOfClass:NSClassFromString(@"IDEConsoleArea")]) {
        NSTextField *filterText;
        filterText = [[NSTextField alloc] initWithFrame:CGRectZero];
        filterText.font = [NSFont systemFontOfSize:10.0];
        filterText.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
        [filterText setStringValue:myFilter];
        filterText.delegate = sharedPlugin;
        if (self.view.subviews.count == 1) {
            // DVTViewControllers have only one subview in their main view, which is supposed to be the contentView.
            NSView *firstSubview = self.view.subviews[0];
            [firstSubview addSubview:filterText];
            filterText.frame = CGRectMake(0, firstSubview.frame.size.height - 20.0, firstSubview.frame.size.width, 20.0);
            for (NSView* sview in [firstSubview subviews]) {
                if ([sview isKindOfClass:NSClassFromString(@"DVTScrollView")]) {
                    // move this down!
                    sview.frame = CGRectMake(sview.frame.origin.x, sview.frame.origin.y - 20.0, sview.frame.size.width, sview.frame.size.height);
                }
            }
        }
        self.filterText = filterText;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(filterChanged) name:kFilterForDebugSearchChanged object:nil];
    }
}

- (void)filterChanged
{
    [self.filterText setStringValue:myFilter];
}
@end

@interface DebugSearch()

@property (nonatomic, strong) NSBundle *bundle;
@end

@implementation DebugSearch

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if ([currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[self alloc] initWithBundle:plugin];
            // load the plist for highlight definitions
            // path to plist
            NSString *configPath = [[NSHomeDirectory() stringByAppendingPathComponent:plistConfigFolder] stringByAppendingPathComponent:plistFilename];
            NSLog(@"Loading %@", configPath);
            if ([[NSFileManager defaultManager] fileExistsAtPath:configPath isDirectory:NO]) {
                highlightsDictionary = [NSDictionary dictionaryWithContentsOfFile:configPath];
                if (!highlightsDictionary) {
                    NSLog(@"There is something wrong with the config plist; skipping load");
                } else {
                    NSLog(@"Highlighting definitions loaded.");
                }
            } else {
                NSLog(@"No highlighting definitions.");
            }
        });
    }
}

- (id)initWithBundle:(NSBundle *)plugin
{
    if (self = [super init]) {
        // reference to plugin's bundle, for resource acccess
        self.bundle = plugin;
        myFilter = @""; // no filter initially
        [self replaceMethod];
    }
    return self;
}

- (void)replaceMethod
{
    [self swizzleMethod:@selector(fixAttributesInRange:) withMethod:@selector(dbgSearch_fixAttributesInRange:) inClass:[NSTextStorage class]];
    // try to replace the viewDidLoad method for the IDEConsoleArea
    [self swizzleMethod:@selector(loadView) withMethod:@selector(dbgSearch_loadView) inClass:NSClassFromString(@"IDEConsoleArea")];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// text field delegate
- (void)controlTextDidChange:(NSNotification *)obj
{
    NSLog(@"Filter changed!");
    myFilter = ((NSTextField*)[obj object]).stringValue;
    // post a notification
    [[NSNotificationCenter defaultCenter] postNotificationName:kFilterForDebugSearchChanged object:nil];
}

// swizzler
- (void)swizzleMethod:(SEL)origSel withMethod:(SEL)overSel inClass:(Class)theClass
{
    Method orig = class_getInstanceMethod(theClass, origSel);
    Method over = class_getInstanceMethod(theClass, overSel);
    if (class_addMethod(theClass, origSel, method_getImplementation(over), method_getTypeEncoding(over))) {
        class_replaceMethod(theClass, overSel, method_getImplementation(orig), method_getTypeEncoding(orig));
    } else {
        method_exchangeImplementations(orig, over);
    }
}

@end
