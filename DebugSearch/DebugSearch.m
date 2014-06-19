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
            if (myFilter.length > 0 && [component rangeOfString:myFilter].location == NSNotFound && ![component hasPrefix:@"/"])
            {
                NSRange rangeToDelete = [[self string] rangeOfString:component options:0 range:aRange];
                if (rangeToDelete.location != NSNotFound) {
                    [self addAttributes:invisibleAttr range:rangeToDelete];
                }
            } else {
                if ([component hasPrefix:@"/set_filter=\""]) {
                    NSLog(@"Possible command!");
                    NSArray* cmdComponents = [component componentsSeparatedByString:@"\""];
                    if ([cmdComponents count] > 1 && ((NSString*)[cmdComponents objectAtIndex:1]).length > 0) {
                        // get the second to the last object
                        NSUInteger objIndex = cmdComponents.count - 2;
                        if (objIndex < cmdComponents.count) {
                            myFilter = [cmdComponents objectAtIndex:objIndex];
                        }
                    }
                }
            }
        }
    }
    [self dbgSearch_fixAttributesInRange:aRange];
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
    SEL origSel = @selector(fixAttributesInRange:);
    SEL overSel = @selector(dbgSearch_fixAttributesInRange:);
    
    Method orig = class_getInstanceMethod([NSTextStorage class], origSel);
    Method over = class_getInstanceMethod([NSTextStorage class], overSel);
    if (class_addMethod([NSTextStorage class], origSel, method_getImplementation(over), method_getTypeEncoding(over))) {
        class_replaceMethod([NSTextStorage class], overSel, method_getImplementation(orig), method_getTypeEncoding(orig));
    } else {
        method_exchangeImplementations(orig, over);
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
