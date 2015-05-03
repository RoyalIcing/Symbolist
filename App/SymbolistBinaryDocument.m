//
//  SymbolistBinaryDocument.m
//  Symbolist
//
//  Created by Patrick Smith on 7/05/07.
//  Copyright __MyCompanyName__ 2007 . All rights reserved.
//

#import "SymbolistBinaryDocument.h"

#include <sys/types.h>
#include <sys/time.h>
#include <sys/resource.h>
#include <unistd.h>
#include <pthread.h>
#include <mach-o/arch.h>

//#import "PSStringSearch.h"

typedef struct {
	CFAbsoluteTime executeTime;
	CFAbsoluteTime readTime;
	CFAbsoluteTime stringTime;
} MyTimings;


#define GetTimeDifferenceUpdating(a) \
do {\
tempTime = CFAbsoluteTimeGetCurrent(); \
a = tempTime - time; \
time = tempTime; \
} while (0);

@implementation SymbolistBinaryDocument

/*+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
	if ([key])
}*/

+ (NSSet *)keyPathsForValuesAffectingSymbols
{
	return [NSSet setWithObject:@"selectedArch"];
}

+ (void)initialize
{
	//[self setKeys:[NSArray arrayWithObject:@"selectedArch"] triggerChangeNotificationsForDependentKey:@"symbols"];
}

- (id)init
{
    self = [super init];
    if (self) {
//		CFAbsoluteTime time, tempTime;
//		unsigned int count = 100, i;
//		MyTimings timings[count], average;
//		
//		for (i = 0; i < count; i++) {
//			time = CFAbsoluteTimeGetCurrent();
//			
//			FILE *nmOutput = popen("/usr/bin/nm -P /Applications/Utilities/Terminal.app/Contents/MacOS/Terminal", "r");
//			
//			GetTimeDifferenceUpdating(timings[i].executeTime);
//			
//			NSFileHandle *fileHandle = [[NSFileHandle alloc] initWithFileDescriptor:fileno(nmOutput)];
//			if (fileHandle) {
//				NSData *data = [fileHandle readDataToEndOfFile];
//				if (data && ([data length] > 2)) {
//					GetTimeDifferenceUpdating(timings[i].readTime);
//					
//					[fileHandle release];
//					pclose(nmOutput);
//					NSString *string = [[NSString alloc] initWithUTF8String:[data bytes]];
//					
//					GetTimeDifferenceUpdating(timings[i].stringTime);
//					
//					[string release];
//				}
//			}
//		}
//		
//		bzero(&average, sizeof(MyTimings));
//		for (i = 0; i < count; i++) {
//			average.executeTime += timings[i].executeTime / (CFAbsoluteTime)count;
//			average.readTime += timings[i].readTime / (CFAbsoluteTime)count;
//			average.stringTime += timings[i].stringTime / (CFAbsoluteTime)count;
//		}
//		DebugLog(@"popen: %f; read: %f; string: %f", average.executeTime, average.readTime, average.stringTime);

//		struct rlimit procLimit;
//		getrlimit(RLIMIT_NPROC, &procLimit);
//		DebugLog(@"%d %d", procLimit.rlim_cur, procLimit.rlim_max);
//		
//		pid_t newPid = 0;
//		for (i = 0; i < count; i++) {
//			time = CFAbsoluteTimeGetCurrent();
//			
//			int taskPipes[2];
//			if (pipe(taskPipes) == -1) {
//				DebugLog(@"Couldn't create pipe.");
//				break;
//			}
//			
//			newPid = fork();
//			if (newPid == 0) {
//				// new process
//				// close read, duplicate write to stdout
//				close(taskPipes[0]);
//				dup2(taskPipes[1], STDOUT_FILENO);
//				//close(taskPipes[1]);
//				execl("/usr/bin/nm", "nm", "-P", "/Applications/Utilities/Terminal.app/Contents/MacOS/Terminal", NULL);
//				
//				_exit(EXIT_FAILURE);
//			}
//			else if (newPid == -1) {
//				DebugLog(@"fork() failed for %d. errno:%d", i, errno);
//				// EAGAIN
//				break;
//			}
//			
//			int taskOutput;
//			close(taskPipes[1]);
//			taskOutput = dup(taskPipes[0]);
//			//close(taskPipes[0]);
//			//DebugLog(@"%d pid:%d", taskPipes[0], newPid);
//			
//			int status;
//			if (waitpid(newPid, &status, WNOHANG) == -1) {
//				DebugLog(@"waitpid() failed");
//				break;
//			}
//			//kill(newPid, SIGKILL);
//			
//			GetTimeDifferenceUpdating(timings[i].executeTime);
//			
//			NSFileHandle *fileHandle = [[NSFileHandle alloc] initWithFileDescriptor:taskOutput];
//			if (fileHandle) {
//				NSData *data = [fileHandle readDataToEndOfFile];
//				if (data && ([data length] > 2)) {
//					GetTimeDifferenceUpdating(timings[i].readTime);
//					
//					[fileHandle release];
//					close(taskOutput);
//					NSString *string = [[NSString alloc] initWithUTF8String:[data bytes]];
//					
//					GetTimeDifferenceUpdating(timings[i].stringTime);
//					
//					[string release];
//				}
//			}
//		}
//		
//		bzero(&average, sizeof(MyTimings));
//		for (i = 0; i < count; i++) {
//			average.executeTime += timings[i].executeTime / (CFAbsoluteTime)count;
//			average.readTime += timings[i].readTime / (CFAbsoluteTime)count;
//			average.stringTime += timings[i].stringTime / (CFAbsoluteTime)count;
//		}
//		DebugLog(@"manual: %f; read: %f; string: %f", average.executeTime, average.readTime, average.stringTime);
//		
//		
//		for (i = 0; i < count; i++) {
//			time = CFAbsoluteTimeGetCurrent();
//			
//			NSTask *task = [[NSTask alloc] init];
//			[task setLaunchPath:@"/usr/bin/nm"];
//			[task setArguments:[NSArray arrayWithObjects:@"-P", @"/Applications/Utilities/Terminal.app/Contents/MacOS/Terminal", nil]];
//			[task setStandardOutput:[NSPipe pipe]];
//			[task launch];
//			[task terminate];
//			
//			GetTimeDifferenceUpdating(timings[i].executeTime);
//			
//			NSFileHandle *fileHandle = [[task standardOutput] fileHandleForReading];
//			if (fileHandle) {
//				NSData *data = [fileHandle readDataToEndOfFile];
//				if (data && ([data length] > 2)) {
//					GetTimeDifferenceUpdating(timings[i].readTime);
//					
//					[task release];
//					NSString *string = [[NSString alloc] initWithUTF8String:[data bytes]];
//					
//					GetTimeDifferenceUpdating(timings[i].stringTime);
//					
//					[string release];
//				}
//			}
//		}
//		
//		bzero(&average, sizeof(MyTimings));
//		for (i = 0; i < count; i++) {
//			average.executeTime += timings[i].executeTime / (CFAbsoluteTime)count;
//			average.readTime += timings[i].readTime / (CFAbsoluteTime)count;
//			average.stringTime += timings[i].stringTime / (CFAbsoluteTime)count;
//		}
//		DebugLog(@"NSTask: %f; read: %f; string: %f", average.executeTime, average.readTime, average.stringTime);
    }
    return self;
}

- (NSString *)windowNibName
{
    return @"SymbolistBinaryDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
	[self setupToolbar];
}

- (NSData *)dataRepresentationOfType:(NSString *)aType
{
    return nil;
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	DebugLog(@"%@", typeName);
    symbolLister = [[SymbolistBinaryLister alloc] initWithPath:[absoluteURL path] error:outError];
	if (!symbolLister)
		return NO;
	
	[symbolLister process];
	[self setSelectedArch:0];
    
    return YES;
}

- (NSArray *)symbols
{
	if (!_symbols)
		_symbols = [[symbolLister symbolsForArchAtIndex:selectedArch] mutableCopy];
	return _symbols;
}

- (unsigned long)symbolCount
{
	return [[self symbols] count];
}

- (NSArray *)architectures
{
	if (!_architectures) {
		unsigned long count = [symbolLister numberOfArchitectures];
		NSMutableArray *architectures = [[NSMutableArray alloc] initWithCapacity:count];
		unsigned long i;
		for (i = 0; i < count; i++) {
			cpu_type_t cpuType = [symbolLister cpuTypeForArchAtIndex:i];
			cpu_subtype_t cpuSubtype = [symbolLister cpuSubtypeForArchAtIndex:i];
			const NXArchInfo *archInfo = NXGetArchInfoFromCpuType(cpuType, cpuSubtype);
			
			NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
			
			NSString *name;
			
			if (cpuType == CPU_TYPE_POWERPC) {
				if (cpuSubtype == CPU_SUBTYPE_POWERPC_7400 || cpuSubtype == CPU_SUBTYPE_POWERPC_7450)
					name = NSLocalizedString(@"PowerPC G4 (32-bit)", @"PowerPC G4 32-bit CPU subtype.");
				else if (cpuSubtype == CPU_SUBTYPE_POWERPC_970)
					name = NSLocalizedString(@"PowerPC G5 (32-bit)", @"PowerPC G5 32-bit CPU subtype.");
				else
					name = NSLocalizedString(@"PowerPC (32-bit)", @"PowerPC 32-bit CPU type.");
			}
			else if (cpuType == CPU_TYPE_POWERPC64)
				name = NSLocalizedString(@"PowerPC (64-bit)", @"PowerPC 64-bit CPU type.");
			else if (cpuType == CPU_TYPE_X86)
				name = NSLocalizedString(@"Intel x86 (32-bit)", @"PowerPC 32-bit CPU type.");
			else if (cpuType == (CPU_TYPE_X86 | CPU_ARCH_ABI64))
				name = NSLocalizedString(@"Intel x86 (64-bit)", @"PowerPC 64-bit CPU type.");
			else if (archInfo->description != NULL)
				name = [NSString stringWithFormat:@"%s", archInfo->description];
			else
				name = [NSString stringWithFormat:@"CPU type:%u subtype:%u", cpuType, cpuSubtype];
			
			dictionary[@"name"] = name;
			
			dictionary[@"description"] = [NSString stringWithFormat:@"%s - %s", archInfo->name, archInfo->description];
			
			[architectures addObject:[dictionary copy]];
		}
		
		_architectures = [architectures copy];
	}
	
	return _architectures;
}

- (void)setSelectedArch:(unsigned long)arch
{
	[self willChangeValueForKey:@"selectedArch"];
	
	selectedArch = arch;
	
	if (_symbols) {
		_symbols = nil;
		[self symbols];
		[self filterSearchResults];
	}
	
	[self didChangeValueForKey:@"selectedArch"];
	
	NSTableColumn *column = [_table tableColumnWithIdentifier:@"value"];
	cpu_type_t cpuType = [symbolLister cpuTypeForArchAtIndex:selectedArch];
	NSDictionary *attributes = [[[column dataCell] attributedStringValue] attributesAtIndex:0 effectiveRange:NULL];
	float width;
	if (cpuType & CPU_ARCH_ABI64)
		width = [@"0000000000000000" sizeWithAttributes:attributes].width;
	else
		width = [@"00000000" sizeWithAttributes:attributes].width;
	DebugLog(@"%f", width);
	[column setWidth:width + 4.0];
	[[[_table enclosingScrollView] contentView] setFrameSize:NSZeroSize];
	[[_table enclosingScrollView] tile];
}

- (unsigned long)selectedArch
{
	return selectedArch;
}

- (IBAction)focusSearch:(id)sender
{
	[[searchField window] makeFirstResponder:searchField];
}

- (void)copy:(id)sender
{
	SymbolistBinaryEntry *entry = [symbolsController selectedObjects][0];
	if (entry == nil)
		return;
	
	NSPasteboard *pboard = [NSPasteboard generalPasteboard];
	NSArray *types = @[NSStringPboardType];
	[pboard declareTypes:types owner:nil];
	[pboard setString:[entry name] forType:NSStringPboardType];
}

- (void)performFindPanelAction:(id)sender
{
	if ([sender respondsToSelector:@selector(tag)] && [sender tag] == NSFindPanelActionSetFindString) {
		SymbolistBinaryEntry *entry = [symbolsController selectedObjects][0];
		if (entry == nil)
			return;
		
		NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSFindPboard];
		NSArray *types = @[NSStringPboardType];
		[pboard declareTypes:types owner:nil];
		[pboard setString:[entry name] forType:NSStringPboardType];
	}
}

- (void)filterSearchResults
{
	[self willChangeValueForKey:@"symbols"];
	_symbols = nil;
	
	if (_searchString && ![_searchString isEqualToString:@""]) {
		// [(NS CG)(Rect Point Size),Transform gl CGL
		// [(NS,CG)(Rect,Point,Size);Transform,gl,CGL
		// [NS,CG/Rect,Point,Size+Transform gl CGL
		// [NS/CG,Rect/Point/Size;Transform gl CGL
		// [NS/CG[Rect/Point/Size;Transform gl CGL
		// The above searches for [NS|CG][Rect|Point]* && *Transform* || *gl* || *CGL*
		
		// [NS CG:[Rect Point Size: & Transform; gl; CGL
		// [(NS CG)(Rect Point;Size),Transform gl CGL
		
		// a/((b.c.d)/e).f
		
		//		BOOL negate;
		//		if ((negate = ([string characterAtIndex:0] == '!')))
		//			[string deleteCharactersInRange:NSMakeRange(0, 1)];
		
#if 1
		
		CFAbsoluteTime t = CFAbsoluteTimeGetCurrent();
	
		NSArray *symbols = [symbolLister symbolsForArchAtIndex:selectedArch];
		NSIndexSet *indexes = [symbols indexesOfObjectsWithOptions:NSEnumerationConcurrent passingTest: ^BOOL (id obj, NSUInteger idx, BOOL *stop) {
			SymbolistBinaryEntry *entry = obj;
			NSString *stringToSearch = (entry.name);
			NSRange foundRange = [stringToSearch rangeOfString:_searchString options:NSCaseInsensitiveSearch];
			
			return foundRange.location != NSNotFound;
		}];
		
		t = CFAbsoluteTimeGetCurrent() - t;
		DebugLog(@"took %fs to filter", t);
		
		_symbols = [[symbols objectsAtIndexes:indexes] mutableCopy];
		
#else
		PSStringSearchRef stringSearch = PSStringSearchCreate(_searchString);
		
		_symbols = [[NSMutableArray alloc] init];
		NSArray *symbols = [symbolLister symbolsForArchAtIndex:selectedArch];
		NSEnumerator *symEnum = [symbols objectEnumerator];
		SymbolistBinaryEntry *symbol;
		while ((symbol = [symEnum nextObject])) {
			if (PSStringSearchMatchesString(stringSearch, [symbol name]))
				[_symbols addObject:symbol];
		}
		
		PSStringSearchFree(stringSearch);
#endif
		
		/*
		 unsigned long match = 0;
		 if (!emptyString) {
		 if ([string characterAtIndex:0] == '#') {
		 match = MatchFunctionNames;
		 [string deleteCharactersInRange:NSMakeRange(0, 1)];
		 }
		 else if ([string characterAtIndex:0] == '@') {
		 match = MatchObjcClasses;
		 [string deleteCharactersInRange:NSMakeRange(0, 1)];
		 }
		 else if ([string characterAtIndex:0] == '[') {
		 match = MatchStart;
		 [string deleteCharactersInRange:NSMakeRange(0, 1)];
		 }
		 else if ([string characterAtIndex:0] == ']') {
		 match = MatchEnd;
		 [string deleteCharactersInRange:NSMakeRange(0, 1)];
		 }
		 //		else if ([string characterAtIndex:0] == '+') {
		 //			match = MATCH_OBJC_CLASS_METHODS;
		 //			[string deleteCharactersInRange:NSMakeRange(0, 1)];
		 //		}
		 //		else if ([string characterAtIndex:0] == '-') {
		 //			match = MATCH_OBJC_INSTANCE_METHODS;
		 //			[string deleteCharactersInRange:NSMakeRange(0, 1)];
		 //		}
		 
		 emptyString = [string isEqualToString:@""];
		 }
		 
		 _symbols = [[NSMutableArray alloc] init];
		 NSArray *symbols = [symbolLister symbolsForArchAtIndex:selectedArch];
		 NSEnumerator *symEnum = [symbols objectEnumerator];
		 SymbolistBinaryEntry *symbol;
		 while ((symbol = [symEnum nextObject])) {
		 if (match == MatchFunctionNames) {
		 if ((negate + [symbol isObjCClass]) == 1)
		 continue;
		 }
		 else if (match == MatchObjcClasses) {
		 if ((negate + ![symbol isObjCClass]) == 1)
		 continue;
		 }
		 else if (match == MatchStart) {
		 if ((negate + ([[symbol name] rangeOfString:string options:NSCaseInsensitiveSearch | NSAnchoredSearch].location == NSNotFound)) == 1)
		 continue;
		 }
		 else if (match == MatchEnd) {
		 if ((negate + ([[symbol name] rangeOfString:string options:NSCaseInsensitiveSearch | NSAnchoredSearch | NSBackwardsSearch].location == NSNotFound)) == 1)
		 continue;
		 }
		 else {
		 if ((negate + ([[symbol name] rangeOfString:string options:NSCaseInsensitiveSearch].location == NSNotFound)) == 1)
		 continue;
		 }
		 
		 [_symbols addObject:symbol];
		 }*/
	}
	[self didChangeValueForKey:@"symbols"];
}

- (IBAction)changeSearchString:(id)sender
{
	_searchString = [[sender stringValue] copy];
	[self filterSearchResults];
}

@end

@implementation SymbolistBinaryDocument (NSToolbarDelegate)

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
	return @[NSToolbarSeparatorItemIdentifier, NSToolbarSpaceItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, NSToolbarCustomizeToolbarItemIdentifier, @"ArchPopup", @"SearchField", @"ItemCount"];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
	return @[@"ArchPopup", NSToolbarFlexibleSpaceItemIdentifier, @"ItemCount", @"SearchField"];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag;
{
	NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
	
	NSSize size;
	if ([itemIdentifier isEqualToString:@"ArchPopup"]) {
		[item setLabel:@"Architecture"];
		[item setPaletteLabel:[item label]];
		[item setView:archPopup];
		size = [archPopup frame].size;
		size.width = 150;
		[item setMinSize:size];
		size.width = 60;
		[item setMaxSize:size];
		[item setVisibilityPriority:NSToolbarItemVisibilityPriorityStandard];
	} else if ([itemIdentifier isEqualToString:@"SearchField"]) {
		[item setLabel:@"Search"];
		[item setPaletteLabel:[item label]];
		[item setView:searchField];
		[item setVisibilityPriority:NSToolbarItemVisibilityPriorityHigh];
		size = [searchField frame].size;
		size.width = 100;
		[item setMinSize:size];
		size.width = 300;
		[item setMaxSize:size];
	} else if ([itemIdentifier isEqualToString:@"ItemCount"]) {
		[item setLabel:@"Search"];
		[item setPaletteLabel:[item label]];
		[item setView:itemCountField];
		[item setVisibilityPriority:NSToolbarItemVisibilityPriorityHigh];
		size = [itemCountField frame].size;
		[item setMaxSize:size];
		size.width = 40;
		[item setMinSize:size];
	} else if ([itemIdentifier isEqualToString:NSToolbarSpaceItemIdentifier]) {
		[item setMinSize:NSZeroSize];
		[item setVisibilityPriority:NSToolbarItemVisibilityPriorityLow];
	} else if ([itemIdentifier isEqualToString:NSToolbarFlexibleSpaceItemIdentifier]) {
		[item setMinSize:NSZeroSize];
		[item setVisibilityPriority:NSToolbarItemVisibilityPriorityLow];
	}
	
	return item;
}

- (void)setupToolbar
{
	NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"mainToolbar"];
	[toolbar setDelegate:self];
	[toolbar setDisplayMode:NSToolbarDisplayModeIconOnly];
	[toolbar setSizeMode:NSToolbarSizeModeRegular];
	[toolbar setAllowsUserCustomization:NO];
	[toolbar setAutosavesConfiguration:NO];
	[toolbar setShowsBaselineSeparator:NO];
	NSWindow *window = [self windowForSheet];
	[window setShowsToolbarButton:NO];
	[window setToolbar:toolbar];
}

@end

@implementation SymbolistBinaryDocument (NSTableDataSource)

- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
	[self symbols];
	[self filterSearchResults];
	[_symbols sortUsingDescriptors:[tableView sortDescriptors]];
}

@end
