#import "SymbolistAppDelegate.h"
#import <dlfcn.h>

#import "SymbolistBinaryEntry.h"

NSString *SymbolistAppFindPboardDidChange = @"SymbolistAppFindPboardDidChange";

@implementation SymbolistAppDelegate

+ (void)initialize
{
//	uint32_t imageCount = _dyld_image_count();
//	uint32_t i;
//	for (i = 0; i < imageCount; i++)
//		NSLog(@"%s", _dyld_get_image_name(i));
	
	Dl_info dlInfo;
	if (dladdr(&NSZeroRect, &dlInfo)) {
		DebugLog(@"%s %s", dlInfo.dli_fname, dlInfo.dli_sname);
	}
	
	char *demangledSymbol;
	
	demangledSymbol = [SymbolistBinaryEntry demangledString:"_ZZ11getCentroidPfS_S_E4C.53"];
	DebugLog(@"%s", demangledSymbol);
	demangledSymbol = [SymbolistBinaryEntry demangledString:"_ZZ11getCentroidPfS_S_E4C.00"];
	DebugLog(@"%s", demangledSymbol);
	
//	demangledSymbol = [SymbolistBinaryEntry demangledString:"SPAAAAAA_"];
//	NSLog(@"%s", demangledSymbol);
//	demangledSymbol = [SymbolistBinaryEntry demangledString:"SPECHASH_"];
//	NSLog(@"%s", demangledSymbol);
//	demangledSymbol = [SymbolistBinaryEntry demangledString:"SPECHASH_LOCK"];
//	NSLog(@"%s", demangledSymbol);
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
	return YES;
}

- (void)performFindPanelActionOverride:(id)sender
{
	NSPasteboard *findPboard = [NSPasteboard pasteboardWithName:NSFindPboard];
	long changeCount = [findPboard changeCount];
	
	if ([sender respondsToSelector:@selector(tag)] && [sender tag] == NSFindPanelActionShowFindPanel)
		[NSApp sendAction:@selector(showFilterBar:) to:nil from:sender];
	else
		[NSApp sendAction:@selector(performFindPanelAction:) to:nil from:sender];
	
	if ([findPboard changeCount] != changeCount)
		[[NSNotificationCenter defaultCenter] postNotificationName:SymbolistAppFindPboardDidChange object:nil];
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
	SEL action = [anItem action];
	
	if (action == @selector(performFindPanelAction:)) {
		if ([anItem tag] == NSFindPanelActionShowFindPanel)
			return YES;
		else
			return [NSApp targetForAction:action] != nil;
	}
	
	return [self respondsToSelector:action];
}

#warning Crashes on *** -[NSCFString rangeOfString:options:range:locale:]: nil argument

@end
