//
//  SymbolistRuntimeDocument.m
//  Symbolist
//
//  Created by Patrick Smith on 19/11/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SymbolistRuntimeDocument.h"

#import "SymbolistAppDelegate.h"
#import "PSStringSearch.h"


@implementation SymbolistRuntimeDocument

- (id)init
{
	self = [super init];
	if (self) {
		_lister = [[SymbolistRuntimeLister alloc] init];
		[_lister setDelegate:self];
		
		_historyBack = [[NSMutableArray alloc] init];
		_historyForward = [[NSMutableArray alloc] init];
		
		_userPrefs = [[NSMutableDictionary alloc] init];
		[_userPrefs setObject:[NSColor textColor] forKey:@"mainColor"];
		[_userPrefs setObject:[NSColor purpleColor] forKey:@"keywordsColor"];
		[_userPrefs setObject:[NSColor purpleColor] forKey:@"directiveColor"];
		[_userPrefs setObject:[NSColor colorWithCalibratedRed:0.0 green:0.25 blue:0.75 alpha:1.0] forKey:@"typeColor"];
		[_userPrefs setObject:[NSColor colorWithCalibratedRed:0.675 green:0.0 blue:0.0 alpha:1.0] forKey:@"operatorColor"];
		[_userPrefs setObject:[NSColor textColor] forKey:@"variableColor"];
		[_userPrefs setObject:[NSColor colorWithCalibratedRed:0.75 green:0.25 blue:0.0 alpha:1.0] forKey:@"argumentColor"];
		[_userPrefs setObject:[NSFont fontWithName:@"Monaco" size:10.0] forKey:@"font"];
		
		[self setSearchMode:SymbolistRuntimeModeClass];
		
		_advancedSearchFlag = YES;
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(findPboardDidChange:) name:SymbolistAppFindPboardDidChange object:nil];
	}
	return self;
}

- (void)dealloc
{
	[_lister release];
	[_historyBack release];
	[_historyForward release];
	[_userPrefs release];
	[_filterString release];
	[_filteredClassNames release];
	[_filteredProtocolNames release];
	if (_structPointerCount) CFRelease(_structPointerCount);
	
	[super dealloc];
}

- (NSString *)windowNibName
{
    return @"SymbolistRuntimeDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)windowController
{
	[[_filterField cell] setPlaceholderString:NSLocalizedString(@"Filter", @"Placeholder string for filter field.")];
	[[_searchField cell] setPlaceholderString:NSLocalizedString(@"Symbol", @"Placeholder string for filter field.")];
	//[_searchField setCompletes:YES];
		
	[self setupToolbar];
	[self validateToolbarItems];
	
	NSMenu *menu = [_typePopup menu];
	while ([menu numberOfItems] > 0)
		[menu removeItemAtIndex:0];
	
	NSMenuItem *menuItem;
	menuItem = [menu addItemWithTitle:NSLocalizedString(@"Class", @"Title for Objective-C Class type") action:@selector(changeMode:) keyEquivalent:@"1"];
	[menuItem setTag:SymbolistRuntimeModeClass];
	
	menuItem = [menu addItemWithTitle:NSLocalizedString(@"Protocol", @"Title for Objective-C Protocol type") action:@selector(changeMode:) keyEquivalent:@"2"];
	[menuItem setTag:SymbolistRuntimeModeProtocol];
	
	[self focusSearch:nil];
	
	[_textView setDelegate:self];
	[_textView setLinkTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithInt:NSUnderlineStyleSingle], NSUnderlineStyleAttributeName,
									  [NSCursor pointingHandCursor], NSCursorAttributeName, nil]];
	//[_textView setFont:[_userPrefs objectForKey:@"font"]];
	
//	NSBundle *osaBundle = [NSBundle bundleWithPath:@"/System/Library/Frameworks/OSAKit.framework/"];
//	NSLog (@"%@", [osaBundle principalClass]);
	
//	NSLog(@"%@", [NSBundle allFrameworks]);
	NSLog(@"%@", [NSBundle allBundles]);
//	CFAbsoluteTime t = CFAbsoluteTimeGetCurrent();
//	NSArray *libraryPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask | NSLocalDomainMask | NSSystemDomainMask, YES);
//	NSFileManager *fileManager = [NSFileManager defaultManager];
//	NSString *path;
//	NSEnumerator *enumerator = [libraryPaths objectEnumerator];
//	while ((path = [enumerator nextObject])) {
//		NSString *subpath;
//		
//		subpath = [path stringByAppendingPathComponent:@"Frameworks"];
//		subpath = [subpath stringByResolvingSymlinksInPath];
//		if ([fileManager fileExistsAtPath:subpath])
//			[self frameworkBundlesInPath:subpath];
//		
//		subpath = [path stringByAppendingPathComponent:@"PrivateFrameworks"];
//		subpath = [subpath stringByResolvingSymlinksInPath];
//		if ([fileManager fileExistsAtPath:subpath])
//			[self frameworkBundlesInPath:subpath];
//	}
//	t = CFAbsoluteTimeGetCurrent() - t;
//	NSLog(@"frameworks %fs", t);
}

- (void)frameworkBundlesInPath:(NSString *)directory
{
//	NSFileManager *fileManager = [NSFileManager defaultManager];
//	NSArray *frameworks = [fileManager directoryContentsAtPath:directory];
//	
//	NSEnumerator *enumerator = [frameworks objectEnumerator];
//	NSString *path;
//	while ((path = [enumerator nextObject])) {
//		path = [directory stringByAppendingPathComponent:path];
//		CFURLRef url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)path, kCFURLPOSIXPathStyle, YES);
//		UInt32 type;
//		CFBundleGetPackageInfoInDirectory(url, &type, NULL);
//		if (type == 'FMWK') {
//			//url = CFBundleCopyBundleURL(bundle);
//			NSLog(@"%@", url);
//			//CFRelease(url);
//		}
//	}
	
	CFURLRef url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)directory, kCFURLPOSIXPathStyle, YES);
	CFArrayRef bundles = CFBundleCreateBundlesFromDirectory(kCFAllocatorDefault, url, CFSTR("framework"));
	CFRelease(url);
	
	if (bundles) {
		CFIndex i, count;
		count = CFArrayGetCount(bundles);
		for (i = 0 ; i < count; i++) {
			CFBundleRef bundle = (CFBundleRef)CFArrayGetValueAtIndex(bundles, i);
			UInt32 type;
			CFBundleGetPackageInfo(bundle, &type, NULL);
//			if (type == 'FMWK') {
				url = CFBundleCopyBundleURL(bundle);
				NSLog(@"%@", url);
				CFRelease(url);
//			}
		}
		
		CFRelease(bundles);
	}
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
	return [NSArray arrayWithObjects:NSToolbarSeparatorItemIdentifier, NSToolbarSpaceItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, NSToolbarCustomizeToolbarItemIdentifier, @"TypeControl", @"SearchField", @"NavigationButtons", nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
	return [NSArray arrayWithObjects:@"NavigationButtons", @"TypeControl", @"SearchField", nil];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag;
{
	NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
	
	NSSize size;
	if ([itemIdentifier isEqualToString:@"TypeControl"]) {
		[item setLabel:@"Type"];
		[item setPaletteLabel:[item label]];
		[item setView:_typePopup];
		[item setVisibilityPriority:NSToolbarItemVisibilityPriorityHigh];
		size = [_typePopup frame].size;
		size.width = 100;
		[item setMinSize:size];
		[item setMaxSize:size];
	}
	else if ([itemIdentifier isEqualToString:@"SearchField"]) {
		[item setLabel:@"Search"];
		[item setPaletteLabel:[item label]];
		[item setView:_searchField];
		[item setVisibilityPriority:NSToolbarItemVisibilityPriorityHigh + 1];
		size = [_searchField frame].size;
		size.width = 100;
		[item setMinSize:size];
		size.width = 1000;
		[item setMaxSize:size];
	}
	else if ([itemIdentifier isEqualToString:@"NavigationButtons"]) {
		[item setLabel:@"Navigate"];
		[item setPaletteLabel:[item label]];
		[item setView:_navigationControl];
		[item setVisibilityPriority:NSToolbarItemVisibilityPriorityHigh - 1];
		size = [_navigationControl frame].size;
		size.height++;
		[item setMinSize:size];
		[item setMaxSize:size];
		
		NSBezierPath *path;
		NSColor *fill = [NSColor colorWithCalibratedWhite:0.0 alpha:0.875];
		
		NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(9.0, 9.0)];
		[image lockFocus];
		path = [[NSBezierPath alloc] init];
		[path moveToPoint:NSMakePoint(8.0, 0.0)];
		[path lineToPoint:NSMakePoint(8.0, 9.0)];
		[path lineToPoint:NSMakePoint(0.0, 4.5)];
		[path closePath];
		[fill setFill];
		[path fill];
		[path release];
		[image unlockFocus];
		
		[_navigationControl setImage:image forSegment:0];
		[_navigationControl setLabel:nil forSegment:0];
		[image release];
		
		image = [[NSImage alloc] initWithSize:NSMakeSize(9.0, 9.0)];
		[image lockFocus];
		path = [[NSBezierPath alloc] init];
		[path moveToPoint:NSMakePoint(1.0, 0.0)];
		[path lineToPoint:NSMakePoint(1.0, 9.0)];
		[path lineToPoint:NSMakePoint(9.0, 4.5)];
		[path closePath];
		[fill setFill];
		[path fill];
		[path release];
		[image unlockFocus];
		
		[_navigationControl setImage:image forSegment:1];
		[_navigationControl setLabel:nil forSegment:1];
		[image release];
	}
	else if ([itemIdentifier isEqualToString:NSToolbarSpaceItemIdentifier]) {
		[item setMinSize:NSZeroSize];
		[item setVisibilityPriority:NSToolbarItemVisibilityPriorityLow];
	}
	else if ([itemIdentifier isEqualToString:NSToolbarFlexibleSpaceItemIdentifier]) {
		[item setMinSize:NSZeroSize];
		[item setVisibilityPriority:NSToolbarItemVisibilityPriorityLow];
	}
	
	return [item autorelease];
}

- (void)setupToolbar
{
	_toolbar = [[[NSToolbar alloc] initWithIdentifier:@"mainToolbar"] autorelease];
	[_toolbar setDelegate:self];
	[_toolbar setDisplayMode:NSToolbarDisplayModeIconOnly];
	[_toolbar setSizeMode:NSToolbarSizeModeRegular];
	[_toolbar setAllowsUserCustomization:NO];
	[_toolbar setAutosavesConfiguration:NO];
	[_toolbar setShowsBaselineSeparator:NO];
	NSWindow *window = [self windowForSheet];
	[window setShowsToolbarButton:NO];
	[window setToolbar:_toolbar];
}

- (BOOL)setSearchStringWithoutRecordingHistory:(NSString *)searchString
{
	if (!searchString)
		[self clear];
	else if ([_searchString isEqualToString:searchString]) 
		return NO;
	else {
		[_searchString release];
		_searchString = [searchString copy];
	}
	return YES;
}

- (void)setSearchString:(NSString *)string
{
	[self setSearchStringWithoutRecordingHistory:string];
}

- (NSString *)searchString
{
	return _searchString;
}

- (void)setSearchMode:(unsigned int)mode;
{
	if (mode != _searchMode) {
		_searchMode = mode;
		
		if (_searchMode != [_typePopup selectedTag])
			[_typePopup selectItemWithTag:_searchMode];
		//[self loadSearchResults];
		
		[self filterSearchCompletes:[_filterField stringValue]];
	}
}

- (unsigned int)searchMode
{
	return _searchMode;
}

- (BOOL)updateSearch:(BOOL)addOldToHistory
{
	SymbolistRuntimeEntry *oldEntry = [_lister searchEntry];
	
	SymbolistRuntimeEntry *entry = [[SymbolistRuntimeEntry alloc] initWithName:[self searchString] mode:[self searchMode]];
	[_lister setSearchEntry:entry];
	[entry release];
	
	if ([self loadSearchResults]) {
		if (addOldToHistory && oldEntry) {
			NSLog(@"ADD");
			[_historyBack addObject:oldEntry];
			[_historyForward removeAllObjects];
		}
		
		[self validateToolbarItems];
		
		[[_textView window] makeFirstResponder:_textView];
		
		unsigned int searchMode = [self searchMode];
		id searchObject = [_lister searchObject];
		NSString *objectString;
		NSString *typeString;
		if (searchMode == SymbolistRuntimeModeClass) {
			typeString = NSLocalizedString(@"Class", @"Title for Objective-C Class type");
			objectString = NSStringFromClass(searchObject);
		}
		else if (searchMode == SymbolistRuntimeModeProtocol) {
			typeString = NSLocalizedString(@"Protocol", @"Title for Objective-C Protocol type");
			objectString = NSStringFromProtocol((Protocol *)searchObject);
		}
		
		[self setSearchStringWithoutRecordingHistory:objectString];
		[_searchField setStringValue:objectString];
		
		[[self windowForSheet] setTitle:[NSString stringWithFormat:@"%@ %@", objectString, typeString]];
		
		return YES;
	}
	else {
		[_lister setSearchEntry:oldEntry];
		if (oldEntry) {
			[self setSearchStringWithoutRecordingHistory:[oldEntry name]];
//			[self setSearchMode:[oldEntry mode]];
		}
		
		return NO;
	}
}

- (void)validateToolbarItems
{
	NSToolbarItem *toolbarItem;
	NSEnumerator *enumerator = [[_toolbar visibleItems] objectEnumerator];
	while ((toolbarItem = [enumerator nextObject])) {
		if ([toolbarItem action] == @selector(navigate:))
			;
		else
			continue;
		
		[NSApp sendAction:@selector(validateToolbarItem:) to:[toolbarItem target] from:toolbarItem];
	}
}

- (BOOL)loadSearchResults
{
	BOOL flag = [_lister loadSearchResults];
	if (!flag) {
		NSLog(@"Couldn't load results.");
		return NO;
	}
	
	NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:[_userPrefs objectForKey:@"font"], NSFontAttributeName, nil];
	NSTextStorage *textStorage = [_textView textStorage];
	[[textStorage mutableString] setString:@""];
	[_lister appendInterfaceToAttributedString:textStorage attributes:attributes];
	NSLog(@"Did load text view.");
		
	return YES;
}

- (void)showInfoView:sender
{
	NSWindow *window = [_structInfoView window];
	if (!window) {
//		[_structTextView setBackgroundColor:[NSColor blackColor]];
//		[_structTextView setTextColor:[NSColor whiteColor]];
		
		NSRect frame = [self adjustedInfoWindowFrame];
		window = [[NSWindow alloc] initWithContentRect:frame styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
		[window setContentView:_structInfoView];
		[window setOpaque:NO];
		[window setBackgroundColor:[NSColor clearColor]];
		[window setHasShadow:YES];
		//[window invalidateShadow];
		[window setAlphaValue:0.9];
	}
	else {
		NSRect contentFrame = [window frameRectForContentRect:[self adjustedInfoWindowFrame]];
		[window setFrameOrigin:contentFrame.origin];
	}
	
	[[self windowForSheet] addChildWindow:window ordered:NSWindowAbove];
	[window makeKeyAndOrderFront:sender];
	
	if (_structType) {
		NSString *string = [NSString stringWithFormat:@"%s", _structType];
		[_structTextView setString:string];
	}
	else
		[_structTextView setString:@""];
}

- (void)hideInfoView:sender
{
	NSWindow *window = [_structInfoView window];
	[[window parentWindow] removeChildWindow:window];
	[window orderOut:nil];
}

- (void)showFilterBar:sender
{
	if (!_isFilterBarVisible && !_filterBarAnimation) {
		NSView *contentView = [[self windowForSheet] contentView];
		
		NSRect contentViewFrame = [contentView frame];
		NSRect barViewOpenFrame = [_filterBarView frame];
		barViewOpenFrame.origin.x = 0.0;
		barViewOpenFrame.origin.y = NSMaxY(contentViewFrame) - NSHeight(barViewOpenFrame);
		barViewOpenFrame.size.width = NSWidth(contentViewFrame);
		
		NSRect barViewClosedFrame = barViewOpenFrame;
		barViewClosedFrame.origin.y += NSHeight(barViewClosedFrame);
		
		[contentView addSubview:_filterBarView];
		[_filterBarView setFrame:barViewClosedFrame];
//		[_filterBarView resizeSubviewsWithOldSize:barViewClosedFrame.size];
		
		NSDictionary *filterBarAnimation = [NSDictionary dictionaryWithObjectsAndKeys:
											_filterBarView, NSViewAnimationTargetKey,
											[NSValue valueWithRect:barViewClosedFrame], NSViewAnimationStartFrameKey,
											[NSValue valueWithRect:barViewOpenFrame], NSViewAnimationEndFrameKey,
											nil];
		
		NSView *textScrollView = [_textView enclosingScrollView];
		NSRect textViewClosedFrame = [textScrollView frame];
		NSRect textViewOpenFrame = textViewClosedFrame;
		textViewOpenFrame.size.height -= NSHeight(barViewOpenFrame);
		
		NSDictionary *textViewAnimation = [NSDictionary dictionaryWithObjectsAndKeys:
										   textScrollView, NSViewAnimationTargetKey,
										   [NSValue valueWithRect:textViewClosedFrame], NSViewAnimationStartFrameKey,
										   [NSValue valueWithRect:textViewOpenFrame], NSViewAnimationEndFrameKey,
										   nil];
		
		_filterBarAnimation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:filterBarAnimation, textViewAnimation, nil]];
		[_filterBarAnimation setDuration:0.25];
		[_filterBarAnimation setDelegate:self];
		[_filterBarAnimation startAnimation];
	}
	
	[[_filterBarView window] makeFirstResponder:_filterField];
	
//	NSPasteboard *findPboard = [NSPasteboard pasteboardWithName:NSFindPboard];
//	NSString *string = [findPboard stringForType:NSStringPboardType];
//	if (string)
//		[_filterField setStringValue:string];
//	[_filterField sendAction:[_filterField action] to:[_filterField target]];
}

- (void)hideFilterBar:sender
{
	if (_isFilterBarVisible && !_filterBarAnimation) {
		[_filterField setStringValue:@""];
		[_filterField sendAction:[_filterField action] to:[_filterField target]];
		
		NSView *contentView = [[self windowForSheet] contentView];
		
		NSRect contentViewFrame = [contentView frame];
		NSRect barViewOpenFrame = [_filterBarView frame];
		barViewOpenFrame.origin.x = 0.0;
		barViewOpenFrame.origin.y = NSMaxY(contentViewFrame) - NSHeight(barViewOpenFrame);
		
		NSRect barViewClosedFrame = barViewOpenFrame;
		barViewClosedFrame.origin.y += NSHeight(barViewClosedFrame);
		
		[contentView addSubview:_filterBarView];
		[[_filterBarView window] makeFirstResponder:_filterField];
		
		NSDictionary *filterBarAnimation = [NSDictionary dictionaryWithObjectsAndKeys:
											_filterBarView, NSViewAnimationTargetKey,
											[NSValue valueWithRect:barViewOpenFrame], NSViewAnimationStartFrameKey,
											[NSValue valueWithRect:barViewClosedFrame], NSViewAnimationEndFrameKey,
											nil];
		
		NSView *textScrollView = [_textView enclosingScrollView];
		NSRect textViewOpenFrame = [textScrollView frame];
		NSRect textViewClosedFrame = textViewOpenFrame;
		textViewClosedFrame.size.height += NSHeight(barViewOpenFrame);
		
		NSDictionary *textViewAnimation = [NSDictionary dictionaryWithObjectsAndKeys:
										   textScrollView, NSViewAnimationTargetKey,
										   [NSValue valueWithRect:textViewOpenFrame], NSViewAnimationStartFrameKey,
										   [NSValue valueWithRect:textViewClosedFrame], NSViewAnimationEndFrameKey,
										   nil];
		
		_filterBarAnimation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:filterBarAnimation, textViewAnimation, nil]];
		[_filterBarAnimation setDuration:0.25];
		[_filterBarAnimation setDelegate:self];
		[_filterBarAnimation startAnimation];
	}
}

- (void)animationDidEnd:(NSAnimation *)animation
{
	if (animation == _filterBarAnimation) {
		[_filterBarAnimation release];
		_filterBarAnimation = nil;
		
		_isFilterBarVisible = !_isFilterBarVisible;
		if (!_isFilterBarVisible)
			[_filterBarView removeFromSuperviewWithoutNeedingDisplay];
	}
}

- (IBAction)changeMode:(id)sender
{
	[self setSearchMode:[sender tag]];
}

- (void)clear
{
	[_textView setString:@""];
}

#warning Change from NSComboBox so the user doesn't have to keep entering their search string again.

- (IBAction)search:(id)sender
{
	if (sender == _searchField) {
		NSString *string = [_searchField stringValue];
		if (_oldSearchString)
			[_searchField setStringValue:_oldSearchString];
		
		[self setSearchString:string];
		[self updateSearch:YES];
	}
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command
{
	if (control == _filterField) {
		if (command == @selector(cancelOperation:)) {
			[self hideFilterBar:nil];
			// We still want the default behaviour, so return NO.
			return NO;
		}
	}
	
	return NO;
}

- (IBAction)filter:(id)sender
{
	NSString *string = [sender stringValue];
	if ([string isEqualToString:@""])
		string = nil;
	
	if (_filterString == string || [_filterString isEqualToString:string])
		return;
	
	[_filterString release];
	_filterString = [string copy];
	[_lister setFilterString:_filterString];
	[self loadSearchResults];
}

- (void)filterSearchCompletes:(NSString *)filterString
{NSLog(@"%@", NSStringFromSelector(_cmd));
	if (!_filteredClassNames)
		_filteredClassNames = [NSMutableArray new];
	else
		[_filteredClassNames removeAllObjects];
	
	unsigned int mode = [self searchMode];
	NSArray *names;
	if (mode == SymbolistRuntimeModeClass)
		names = [SymbolistRuntimeLister classNames];
	else if (mode == SymbolistRuntimeModeProtocol)
		names = [SymbolistRuntimeLister protocolNames];
	else
		return;
	
	if (filterString && ![filterString isEqualToString:@""]) {
		NSString *string;
		NSEnumerator *enumerator = [names objectEnumerator];
		
		if (_advancedSearchFlag) {
			NSLog(@"Will search.");
			PSStringSearchRef stringSearch = PSStringSearchCreate(filterString);
			while ((string = [enumerator nextObject])) {
				if (PSStringSearchMatchesString(stringSearch, string))
					[_filteredClassNames addObject:string];
			}
			PSStringSearchFree(stringSearch);
			NSLog(@"Did search.");
		}
		else {
			while ((string = [enumerator nextObject])) {
				NSRange range = [string rangeOfString:filterString options:NSCaseInsensitiveSearch /*| NSLiteralSearch*/ | NSAnchoredSearch];
				if (range.location == 0)
					[_filteredClassNames addObject:string];
			}
		}
	}
	else
		[_filteredClassNames addObjectsFromArray:names];
	
	[_filteredClassNames sortUsingSelector:@selector(compare:)];
	
	[_searchField reloadData];
}

- (int)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
	if (_filteredClassNames)
		return [_filteredClassNames count];
	
	/*unsigned int mode = [self searchMode];
	NSDictionary *names;
	if (mode == SymbolistRuntimeModeClass)
		names = [SymbolistRuntimeLister classNames];
	else if (mode == SymbolistRuntimeModeProtocol)
		names = [SymbolistRuntimeLister protocolNames];
	return [names count];*/
	return 0;
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(int)index
{
	if (_filteredClassNames)
		return [_filteredClassNames objectAtIndex:index];
	
	/*unsigned int mode = [self searchMode];
	NSArray *names;
	if (mode == SymbolistRuntimeModeClass)
		names = [SymbolistRuntimeLister classNames];
	else if (mode == SymbolistRuntimeModeProtocol)
		names = [SymbolistRuntimeLister protocolNames];
	
	return [names objectAtIndex:index];*/
	return 0;
}

- (NSString *)comboBox:(NSComboBox *)aComboBox completedString:(NSString *)uncompletedString
{
	[self filterSearchCompletes:uncompletedString];
	
	if (!_advancedSearchFlag) {
		if ([_filteredClassNames count] > 0)
			return [_filteredClassNames objectAtIndex:0];
	}
	return nil;
}

- (unsigned int)comboBox:(NSComboBox *)aComboBox indexOfItemWithStringValue:(NSString *)aString
{
	if (_filteredClassNames)
		return [_filteredClassNames indexOfObject:aString];
	
	/*unsigned int mode = [self searchMode];
	NSArray *names;
	if (mode == SymbolistRuntimeModeClass)
		names = [SymbolistRuntimeLister classNames];
	else if (mode == SymbolistRuntimeModeProtocol)
		names = [SymbolistRuntimeLister protocolNames];
	
	return [names indexOfObject:aString];*/
	return NSNotFound;
}

- (void)comboBoxSelectionDidChange:(NSNotification *)notification
{
	if (_oldSearchString)
		[_oldSearchString release];
	
	_oldSearchString = [[_searchField stringValue] retain];
}

- (void)controlTextDidBeginEditing:(NSNotification *)aNotification
{
	NSControl *object = [aNotification object];
	if (object == _searchField) {
		NSText *fieldEditor = [[aNotification userInfo] objectForKey:@"NSFieldEditor"];
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(textViewDidChangeSelection:) name:NSTextViewDidChangeSelectionNotification object:fieldEditor];
		//[[_searchField cell] moveDown:nil];
	}
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
	NSControl *object = [aNotification object];
	if (object == _searchField)
		[self filterSearchCompletes:[_searchField stringValue]];
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	id object = [aNotification object];
	NSLog(@"Did end %@", object);
	if (object == _filterField) {
		[self filterSearchCompletes:[_filterField stringValue]];
		
		NSText *fieldEditor = [[aNotification userInfo] objectForKey:@"NSFieldEditor"];
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc removeObserver:self name:NSTextViewDidChangeSelectionNotification object:fieldEditor];
		
//		[self hideFilterBar:nil];
	}
}

- (void)textViewDidChangeSelection:(NSNotification *)aNotification
{
//	NSTextView *fieldEditor = [aNotification object];
//	NSRange range = [fieldEditor selectedRange];
//	
//	if (range.length == 0) {
//		NSString *prefix = [[_searchField stringValue] substringToIndex:range.location];
//		[self filterSearchCompletes:prefix];
//	}
}

- (BOOL)textView:(NSTextView *)aTextView clickedOnLink:(id)link atIndex:(NSUInteger)charIndex
{
	if ([link isKindOfClass:[SymbolistRuntimeEntry class]]) {
		
		SymbolistRuntimeEntry *entry = link;
		
		[self setSearchString:[entry name]];
		[self setSearchMode:[entry mode]];
		[self updateSearch:YES];
		
		return YES;
	}
	else if ([link isKindOfClass:[NSValue class]]) {
		_structType = [(NSValue *)link pointerValue];
		[self showInfoView:nil];
		
		return YES;
	}
	
	return NO;
}

- (IBAction)focusSearch:(id)sender
{
	[[_searchField window] makeFirstResponder:_searchField];
}

- (void)gotoHistoryIndex:(unsigned long)index goBack:(BOOL)back
{
	SymbolistRuntimeEntry *currentEntry = [_lister searchEntry];
	SymbolistRuntimeEntry *newEntry;
	
	if (back) {
		unsigned int count = [_historyBack count];
		NSRange range = NSMakeRange(count - 1 - index, index);
		NSAssert1(range.location < count, @"-%@; Index passed is greater than back history length.", NSStringFromSelector(_cmd));
		
		[_historyForward insertObject:currentEntry atIndex:0];
		newEntry = [[_historyBack objectAtIndex:range.location] retain];
		
		if (range.length > 0) {
			NSArray *clipped = [_historyBack subarrayWithRange:range];
			[_historyForward replaceObjectsInRange:NSMakeRange(0, 0) withObjectsFromArray:clipped];
		}
		
		range.length++;
		[_historyBack removeObjectsInRange:range];
	}
	else {
		unsigned int count = [_historyForward count];
		NSAssert1(index < count, @"-%@; Index passed is greater than forward history length.", NSStringFromSelector(_cmd));
		NSRange range = NSMakeRange(0, index);
		
		[_historyBack addObject:currentEntry];
		newEntry = [[_historyForward objectAtIndex:range.length] retain];
		
		if (range.length > 0) {
			NSArray *clipped = [_historyForward subarrayWithRange:range];
			[_historyBack addObjectsFromArray:clipped];
		}
		
		range.length++;
		[_historyForward removeObjectsInRange:range];
	}
	
	[self setSearchStringWithoutRecordingHistory:[newEntry name]];
	[self setSearchMode:[newEntry mode]];
	[newEntry release];
	
	[self updateSearch:NO];
}

- (IBAction)goBack:(id)sender
{
	[self gotoHistoryIndex:0 goBack:YES];
}

- (IBAction)goForward:(id)sender
{
	[self gotoHistoryIndex:0 goBack:NO];
}

- (BOOL)canGoBack
{
	return [_historyBack count] > 0;
}

- (BOOL)canGoForward
{
	return [_historyForward count] > 0;
}

- (IBAction)navigate:(id)sender
{
	if (sender == _navigationControl) {
		if ([_navigationControl selectedSegment] == 0)
			[self goBack:sender];
		else
			[self goForward:sender];
	}
}

- (void)windowDidResize:(NSNotification *)notification
{
	NSWindow *window = [notification object];
	if (window == [self windowForSheet]) {
		window = [_structInfoView window];
		if ([window isVisible]) {
			NSRect contentFrame = [window frameRectForContentRect:[self adjustedInfoWindowFrame]];
			[window setFrameOrigin:contentFrame.origin];
		}
	}
}

- (NSRect)adjustedInfoWindowFrame
{
	NSRect mainWindowFrame = [[self windowForSheet] frame];
	NSRect frame = [_structInfoView frame];
	frame.origin.x = NSMinX(mainWindowFrame) + (NSWidth(mainWindowFrame) - NSWidth(frame)) / 2.0;
	frame.origin.y = NSMaxY(mainWindowFrame) - NSHeight(frame) - 60.0;
	return frame;
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
	SEL action = [anItem action];
	
	if (action == @selector(goBack:))
		return [self canGoBack];
	else if (action == @selector(goForward:))
		return [self canGoForward];
//	else if (action == @selector(performFindPanelAction:)) {
//		if ([anItem tag] == NSFindPanelActionShowFindPanel)
//			return YES;
//		else
//			return [NSApp targetForAction:action] != nil;
//	}
	
	return [self respondsToSelector:action];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
	SEL action = [theItem action];
	if (action == @selector(navigate:)) {
		if ([theItem view] == _navigationControl) {
			[_navigationControl setEnabled:[self canGoBack] forSegment:0];
			[_navigationControl setEnabled:[self canGoForward] forSegment:1];
		}
	}
	
	return [self respondsToSelector:action];
}

- (Class)classForLister:(SymbolistRuntimeLister *)lister
{
	return NULL;
}

- (Protocol *)protocolForLister:(SymbolistRuntimeLister *)lister
{
	return NULL;
}

- (const char *)objcTypeForLister:(SymbolistRuntimeLister *)lister
{
	return NULL;
}

- (NSDictionary *)userPrefsForLister:(SymbolistRuntimeLister *)lister
{
	return _userPrefs;
}

- (void)findPboardDidChange:(NSNotification *)note
{
	if (_isFilterBarVisible) {
		NSPasteboard *findPboard = [NSPasteboard pasteboardWithName:NSFindPboard];
		NSString *string = [findPboard stringForType:NSStringPboardType];
		if (string)
			[_filterField setStringValue:string];
		[_filterField sendAction:[_filterField action] to:[_filterField target]];
//		[self showFilterBar:nil];
	}
}

@end

/*
NSString *StringFromObjCTypeGetRange(const char *type, BOOL *outIsObject, BOOL *outIsStruct, BOOL *hasName, NSRange *outNameRange, BOOL *outIsPointer)
{
	NSMutableString *fullString = [NSMutableString string];
	NSString *argString = @"?";
	struct runtimeFlags {
		unsigned int constFlag:1;
		unsigned int arrayFlag:1;
		unsigned int objectFlag:1;
		unsigned int structFlag:1;
		unsigned int hasName:1;
	} flags;
	unsigned int pointerCount = 0;
	
	flags.objectFlag = 0;
	flags.structFlag = 0;
	flags.hasName = 0;
				
	if (type[0] == 'r') {
		flags.constFlag = 1;
		type++;
	}
	else
		flags.constFlag = 0;
	
	
	while (type[0] == '^') {
		pointerCount++;
		type++;
	}
	
	if (type[0] == 'c')
		argString = @"char";
	else if (type[0] == 'i')
		argString = @"int";
	else if (type[0] == 's')
		argString = @"short";
	else if (type[0] == 'l')
		argString = @"long";
	else if (type[0] == 'q')
		argString = @"long long";
	else if (type[0] == 'C')
		argString = @"unsigned char";
	else if (type[0] == 'I')
		argString = @"unsigned int";
	else if (type[0] == 'S')
		argString = @"unsigned short";
	else if (type[0] == 'L')
		argString = @"unsigned long";
	else if (type[0] == 'Q')
		argString = @"unsigned long long";
	else if (type[0] == 'f')
		argString = @"float";
	else if (type[0] == 'd')
		argString = @"double";
	else if (type[0] == 'B')
		argString = @"_Bool";
	else if (type[0] == 'v')
		argString = @"void";
	else if (type[0] == '*') {
		argString = @"char";
		pointerCount++;
	}
	else if (type[0] == '@') {
		type++;
		if (type[0] == '"') {
			type++;
			unsigned long nameLength = 0;
			
			for (; ; type++) {
				if (type[0] == '"')
						break;
				
				nameLength++;
			}
			
			argString = [[[NSString alloc] initWithBytes:type-nameLength length:nameLength encoding:[NSString defaultCStringEncoding]] autorelease];
			pointerCount++;
			
			flags.hasName = 1;
			flags.objectFlag = 1;
			if (outNameRange) {
				outNameRange->location = 0;
				outNameRange->length = nameLength;
			}
		}
		else
			argString = @"id";
	}
	else if (type[0] == '#')
		argString = @"Class";
	else if (type[0] == ':')
		argString = @"SEL";
	else if (type[0] == '[')
		argString = @"array";
	else if (type[0] == '(')
		argString = @"union";
	else if (type[0] == '{') { // Struct
		const char *typeStart = ++type;
		unsigned long nameLength = 0;
		
		for (; ; type++) {
			//NSLog(@"char:%c %u %d", type[0], endCount, (endCount == 1));
			if (type[0] == '}')
				break;
			else {
				if (type[0] == '=')
					break;
				
				nameLength++;
			}
		}
		
		NSString *structName;
		
		if (nameLength == 0) {
			structName = [[NSString alloc] initWithBytes:typeStart length:(type - typeStart) encoding:[NSString defaultCStringEncoding]];
			argString = [NSString stringWithFormat:@"{%@}", structName];
		}
		else {
			structName = [[NSString alloc] initWithBytes:typeStart length:nameLength encoding:[NSString defaultCStringEncoding]];
			
//			if ([structName isEqualToString:@"_NSPoint"])
//				argString = @"NSPoint";
//			else if ([structName isEqualToString:@"_NSSize"])
//				argString = @"NSSize";
//			else if ([structName isEqualToString:@"_NSRect"])
//				argString = @"NSRect";
//			else if ([structName isEqualToString:@"_NSZone"])
//				argString = @"NSZone";
//			else if ([structName isEqualToString:@"CGPoint"])
//				argString = @"CGPoint";
//			else if ([structName isEqualToString:@"CGSize"])
//				argString = @"CGSize";
//			else if ([structName isEqualToString:@"CGRect"])
//				argString = @"CGRect";
//			else if ([structName isEqualToString:@"CGContext"] && (pointerCount > 0)) {
//				argString = @"CGContextRef";
//				pointerCount--;
//			}
//			else
			
			argString = [[structName retain] autorelease];
		}
		
		flags.hasName = 1;
		flags.structFlag = 1;
		if (outNameRange) {
			outNameRange->location = 0;
			outNameRange->length = [argString length];
		}
		
		[structName release];
	}
	
	if (flags.constFlag == 1)
		[fullString setString:@"const "];
	else
		[fullString setString:@""];
	
	if (flags.structFlag)
		[fullString appendString:@"struct "];
	
	if (!flags.hasName && outNameRange) {
		flags.hasName = 1;
		outNameRange->location = 0;
		outNameRange->length = [argString length];
	}
	
	if (outNameRange) {
		outNameRange->location += [fullString length];
		if ([fullString length] > 0)
			NSLog(@"%u %u '%@'", outNameRange->location, [fullString length], fullString);
	}
	
	[fullString appendString:argString];
	
	if (outIsPointer)
		*outIsPointer = pointerCount > 0;
	
	if (pointerCount > 0)
		[fullString appendString:@" "];
	while (pointerCount > 0) {
		[fullString appendString:@"*"];
		pointerCount--;
	}
	
	if (hasName)
		*hasName = flags.hasName;
	
	if (outIsObject)
		*outIsObject = flags.objectFlag;
	
	if (outIsStruct)
		*outIsStruct = flags.structFlag;
	
	return fullString;
}
 */
