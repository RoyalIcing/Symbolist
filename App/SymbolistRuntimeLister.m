//
//  SymbolistRuntimeLister.m
//  Symbolist
//
//  Created by Patrick Smith on 3/01/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "SymbolistRuntimeLister.h"

#import <dlfcn.h>
#import <objc/Protocol.h>


@implementation SymbolistRuntimeLister
	
NSString *StringFromObjCTypeGetRange(const char *type, unsigned int *outType, BOOL *hasName, NSRange *outNameRange, BOOL *outIsPointer);

static NSMutableDictionary *_namesToClassesTable = nil;
static NSMutableArray *_classNames = nil;

+ (NSArray *)classNames
{
	if (!_namesToClassesTable) {
		//DebugLog(@"FRAMEWORKS %@", [NSBundle allFrameworks]);
		
		CFAbsoluteTime t = CFAbsoluteTimeGetCurrent();
		
		_namesToClassesTable = [NSMutableDictionary new];
		_classNames = [NSMutableArray new];
		
		unsigned int classCount = 0;
		Class *classBuffer = objc_copyClassList(&classCount);
		
		// Find our app's path.
		NSBundle *mainBundle = [NSBundle mainBundle];
		const char *appPath = [[mainBundle bundlePath] fileSystemRepresentation];
		size_t appPathLen = strlen(appPath);
		unsigned int i;
		for (i = 0; i < classCount; i++) {
#if 1
			// Use the dynamic linker to find the executable path for the class.
			Dl_info dlInfo;
			if (dladdr((__bridge const void *)(classBuffer[i]), &dlInfo)) {
				// If the class path matches (or is inside) our app path, then skip it.
				if (strncmp(appPath, dlInfo.dli_fname, appPathLen) == 0)
					continue;
			}
#endif
			
			Class class = classBuffer[i];
			NSString *className = NSStringFromClass(class);
			NSValue *classObject = [NSValue valueWithNonretainedObject:class];
			
			if (!_namesToClassesTable[className]) {
				// Add a strict case-sensitive entry.
				_namesToClassesTable[className] = classObject;
				
				NSString *lowercaseName = [className lowercaseString];
				if (![lowercaseName isEqualToString:className]) {
					// Add a user friendly case-insensitive entry.
					if (_namesToClassesTable[lowercaseName])
						// Don't allow multiple classes with the same case-insensitive name.
						[_namesToClassesTable removeObjectForKey:lowercaseName];
					else
						_namesToClassesTable[lowercaseName] = classObject;
				}
				
				[_classNames addObject:className];
			}
		}
		
		free(classBuffer);
				
		t = CFAbsoluteTimeGetCurrent() - t;
		
		DebugLog(@"Loading classes (%d) took %fs.", classCount, t);
	}
	
	return _classNames;
}

+ (Class)classForName:(NSString *)name
{
	Class class = NSClassFromString(name);
	if (class)
		return class;
	
	NSValue *classObject = _namesToClassesTable[name] ?: _namesToClassesTable[[name lowercaseString]];
	return [classObject nonretainedObjectValue];
}

CFComparisonResult SymbolistRuntimeDocument_CompareProtocol(Protocol *protocol1, Protocol *protocol2, void *context);

static NSMutableDictionary *_namesToProtocolTable = nil;
static NSMutableArray *_protocolNames = nil;

+ (NSArray *)protocolNames
{
	if (!_namesToProtocolTable) {
		_namesToProtocolTable = [NSMutableDictionary new];
		_protocolNames = [NSMutableArray new];
		
		unsigned int classCount = 0;
		Class *classBuffer = objc_copyClassList(&classCount);
		
		long i;
		for (i = 0; i < classCount; i++) {
			Class class = classBuffer[i];
			unsigned int protocolCount;
			Protocol * __unsafe_unretained *protocolArray = class_copyProtocolList(class, &protocolCount);
			
			for (unsigned int i = 0; i < protocolCount; i++) {
				Protocol *protocol = protocolArray[i];
				NSString *protocolName = @(protocol_getName(protocol));
				
				if (!_namesToProtocolTable[protocolName]) {
					// Add a strict case-sensitive entry.
					_namesToProtocolTable[protocolName] = protocol;
				}
				
				[_protocolNames addObject:protocolName];
			}
			
			free(protocolArray);
			
#if 0
			struct objc_protocol_list *protocolList = classBuffer[i]->protocols;
			while (protocolList) {
				long j;
				Protocol *protocol;
				NSString *protocolName;
				//CFRange range = CFRangeMake(0, 0);
				for (j = 0; j < protocolList->count; j++) {
					protocol = protocolList->list[j];
					protocolName = [NSString stringWithUTF8String:(const char *)[protocol name]];
					
					if (![_namesToProtocolTable objectForKey:protocolName]) {
						// Add a strict case-sensitive entry.
						[_namesToProtocolTable setObject:protocol forKey:protocolName];
						
						NSString *lowercaseName = [protocolName lowercaseString];
						if (![lowercaseName isEqualToString:protocolName]) {
							// Add a user friendly case-insensitive entry.
							if ([_namesToProtocolTable objectForKey:lowercaseName])
								// Don't allow multiple protocols with the same case-insensitive name.
								[_namesToProtocolTable removeObjectForKey:lowercaseName];
							else
								[_namesToProtocolTable setObject:protocol forKey:lowercaseName];
						}
						
						[_protocolNames addObject:protocolName];
					}
				}
				
				protocolList = protocolList->next;
			}
#endif
		}
		
		free(classBuffer);
	}
	
	return _protocolNames;
	//return _namesToProtocolTable;
}

CFComparisonResult SymbolistRuntimeDocument_CompareProtocol(Protocol *protocol1, Protocol *protocol2, void *context)
{
	NSString *protocol1Name = @(protocol_getName(protocol1));
	NSString *protocol2Name = @(protocol_getName(protocol2));
	
	return [protocol1Name compare:protocol2Name];
	
	/*
	int cmp = strcmp(protocol_getName(protocol1), protocol_getName(protocol2));
	if (cmp < 0)
		return kCFCompareLessThan;
	else if (cmp > 0)
		return kCFCompareGreaterThan;
	else
		return kCFCompareEqualTo;
	*/
}

+ (Protocol *)protocolForName:(NSString *)name
{
	[self protocolNames];
	
	return _namesToProtocolTable[name] ?: _namesToProtocolTable[[name lowercaseString]];
}

- (id)init
{
	self = [super init];
	if (self) {
		
	}
	return self;
}

//	DebugLog(@"%@", [NSBundle allFrameworks]);
//	DebugLog(@"%@", [NSBundle allBundles]);
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
//	DebugLog(@"frameworks %fs", t);

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
	//			DebugLog(@"%@", url);
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
			DebugLog(@"%@", url);
			CFRelease(url);
			//			}
		}
		
		CFRelease(bundles);
	}
}

- (void)setDelegate:(id<SymbolistRuntimeListerDelegate>)anObject;
{
	if (anObject != _delegate)
		_delegate = anObject;
}

- (id<SymbolistRuntimeListerDelegate>)delegate
{
	return _delegate;
}

- (void)setSearchEntry:(SymbolistRuntimeEntry *)entry
{
	if (_searchEntry != entry) {
		_searchEntry = entry;
	}
}

- (SymbolistRuntimeEntry *)searchEntry
{
	return _searchEntry;;
}

- (void)setFilterString:(NSString *)string
{
	if (_filterString != string) {
		_filterString = [string copy];
	}
}

- (NSString *)filterString
{
	return _filterString;
}

- (id)searchObject
{
	return _searchObject;
}

- (BOOL)loadSearchResults
{
	BOOL flag = NO;
	
	SymbolistRuntimeEntry *entry = [self searchEntry];
	if (!entry)
		return NO;
	
	unsigned int mode = [entry mode];
	
	if (mode == SymbolistRuntimeModeClass)
		flag = [self loadClassResults];
	else if (mode == SymbolistRuntimeModeProtocol)
		flag = [self loadProtocolResults];
	
	return flag;
}

- (BOOL)loadClassResults
{
	if (_classMethods)
		CFRelease(_classMethods);
	_classMethods = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
	
	if (_instanceMethods)
		CFRelease(_instanceMethods);
	_instanceMethods = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);

	if (_classProtocols) {
		CFRelease(_classProtocols);
		_classProtocols = NULL;
	}
	
	if (_instanceVariables) {
		CFRelease(_instanceVariables);
		_instanceVariables = NULL;
	}
	
	CFAbsoluteTime t = CFAbsoluteTimeGetCurrent();
	Class class = [[self class] classForName:[[self searchEntry] name]];
	_searchObject = class;
	if (!class)
		return NO;
	
	DebugLog(@"Class: %@; BUNDLE %@;", class, [NSBundle bundleForClass:class]);
	
	[self loadMethodsForClass:class intoArray:_instanceMethods];
	[self loadMethodsForClass:object_getClass(class) intoArray:_classMethods];
	t = CFAbsoluteTimeGetCurrent() -  t;
//	DebugLog(@"loading methods (%u %u) took %fs", CFArrayGetCount(_instanceMethods), CFArrayGetCount(_classMethods), t);
	
	unsigned int protocolCount = 0;
	Protocol * __unsafe_unretained *protocolList = class_copyProtocolList(class, &protocolCount);
	if (protocolList && protocolCount > 0) {
		_classProtocols = CFBridgingRetain([[NSArray alloc] initWithObjects:protocolList count:protocolCount]);
		//_classProtocols = CFArrayCreate(kCFAllocatorDefault, (const void **)protocolList, protocolCount, NULL);
		free((void *)protocolList);
		//[NSData dataWithBytesNoCopy:protocolList length:(sizeof(unsigned int) * protocolCount) freeWhenDone:YES];
		
		//long i;
		//for (i = 0; i < protocols->count; i++)
		//	[self loadMethodsForClass:(Class)protocols->list[i] intoArray:_classProtocols];
	}
	
	unsigned int instanceVariableCount = 0;
	const Ivar *instanceVariables = class_copyIvarList(class, &instanceVariableCount);
	if (instanceVariables) {
		_instanceVariables = CFArrayCreate(kCFAllocatorDefault, (const void **)instanceVariables, instanceVariableCount, NULL);
		free((void *)instanceVariables);
	}

	
	return YES;
}

- (BOOL)loadProtocolResults
{
	Protocol *protocol = [[self class] protocolForName:[[self searchEntry] name]];
	_searchObject = protocol;
	if (!protocol)
		return NO;
	
	if (_classMethods)
		CFRelease(_classMethods);
	_classMethods = CFArrayCreateMutable(kCFAllocatorDefault, 0, NULL);
	if (_instanceMethods)
		CFRelease(_instanceMethods);
	_instanceMethods = CFArrayCreateMutable(kCFAllocatorDefault, 0, NULL);
	
	
	struct objc_method_description *protocolMethods = NULL;
	unsigned int protocolMethodCount = 0;
	NSData *methodPointersData;
	
	// Required instance methods
	protocolMethods = protocol_copyMethodDescriptionList(protocol, true, true, &protocolMethodCount);
	if (protocolMethodCount > 0) {
		methodPointersData = [NSData dataWithBytesNoCopy:(void *)protocolMethods length:(protocolMethodCount * sizeof(struct objc_method_description *)) freeWhenDone:YES];
		[self loadMethodsForMethodDescriptions:methodPointersData intoArray:_instanceMethods];
		protocolMethods = NULL;
	}
	// Optional instance methods
	protocolMethods = protocol_copyMethodDescriptionList(protocol, false, true, &protocolMethodCount);
	if (protocolMethodCount > 0) {
		methodPointersData = [NSData dataWithBytesNoCopy:(void *)protocolMethods length:(protocolMethodCount * sizeof(struct objc_method_description *)) freeWhenDone:YES];
		[self loadMethodsForMethodDescriptions:methodPointersData intoArray:_instanceMethods];
		protocolMethods = NULL;
	}
	
	// Required class methods
	protocolMethods = protocol_copyMethodDescriptionList(protocol, true, false, &protocolMethodCount);
	if (protocolMethodCount > 0) {
		methodPointersData = [NSData dataWithBytesNoCopy:(void *)protocolMethods length:(protocolMethodCount * sizeof(struct objc_method_description *)) freeWhenDone:YES];
		[self loadMethodsForMethodDescriptions:methodPointersData intoArray:_classMethods];
		protocolMethods = NULL;
	}
	// Optional class methods
	protocolMethods = protocol_copyMethodDescriptionList(protocol, false, false, &protocolMethodCount);
	if (protocolMethodCount > 0) {
		methodPointersData = [NSData dataWithBytesNoCopy:(void *)protocolMethods length:(protocolMethodCount * sizeof(struct objc_method_description *)) freeWhenDone:YES];
		[self loadMethodsForMethodDescriptions:methodPointersData intoArray:_classMethods];
		protocolMethods = NULL;
	}
	
	return YES;
}

- (void)loadStructResults
{
	
}

#define ApplyAttributes(newRange) \
if (newRange.length != 0) {\
	[attrString addAttributes:_attributeBuffer range:newRange];\
	[_attributeBuffer removeAllObjects];\
}

#define UpdateAttributesRange(originInset, newLength) \
ApplyAttributes(_attributeRange);\
_attributeRange.length = newLength;\
_attributeRange.location = [string length] - [substring length] + originInset

#define AddAttributedString(newSubstring) do {\
	substring = (newSubstring);\
		[string appendString:substring];\
			UpdateAttributesRange(0, [substring length]);\
} while(0)

#define AddAttributedSubstringWithRange(newRange) do {\
	[string appendString:substring];\
		UpdateAttributesRange(newRange.location, newRange.length);\
} while(0)

#define AddAttributedSubrange(newRange) \
ApplyAttributes(newRange);

- (void)appendInterfaceToAttributedString:(NSMutableAttributedString *)attrString attributes:(NSDictionary *)attrs
{
	_attributeBuffer = [attrs mutableCopy];
	_attributeRange = NSMakeRange(0, 0);
	NSMutableString *string = [attrString mutableString];
	NSString *substring;
	NSDictionary *userPrefs = [[self delegate] userPrefsForLister:self];
	
	[attrString beginEditing];
	
	//[_textView setTypingAttributes:_attributeBuffer];
	//[attrString setAttributes:_attributeBuffer range:_attributeRange];
	
	if (_searchObject == nil) {
		;
	}
	else if ([[self searchEntry] mode] == SymbolistRuntimeModeClass) {
		AddAttributedString(@"@interface");
		ApplyAttributes(_attributeRange);
		_attributeBuffer[NSForegroundColorAttributeName] = userPrefs[@"directiveColor"];
		
		[string appendString:@" "];
		
		Class class = _searchObject;
		
		AddAttributedString(NSStringFromClass(class));
		_attributeBuffer[NSForegroundColorAttributeName] = userPrefs[@"typeColor"];
		
		// Add inherited superclass, if it exists.
		Class superclass = class_getSuperclass(class);
		if (superclass != NULL) {
			[string appendString:@" : "];
			AddAttributedString(NSStringFromClass(superclass));
			_attributeBuffer[NSForegroundColorAttributeName] = userPrefs[@"typeColor"];
			
			SymbolistRuntimeEntry *entry = [SymbolistRuntimeEntry entryWithName:substring mode:SymbolistRuntimeModeClass];
			_attributeBuffer[NSLinkAttributeName] = entry;
		}
		
		CFIndex count = _classProtocols ? CFArrayGetCount(_classProtocols) : 0;
		if (count > 0) {
			[string appendString:@" <"];
			
			CFIndex i;
			for (i = 0; i < count; i++) {
				Protocol *protocol = (Protocol *)CFArrayGetValueAtIndex(_classProtocols, i);
				AddAttributedString(@(protocol_getName(protocol)));
				_attributeBuffer[NSForegroundColorAttributeName] = userPrefs[@"typeColor"];
				
				SymbolistRuntimeEntry *entry = [SymbolistRuntimeEntry entryWithName:substring mode:SymbolistRuntimeModeProtocol];
				_attributeBuffer[NSLinkAttributeName] = entry;
				
				if (count > 1 && i != count - 1)
					[string appendString:@", "];
			}
			
			[string appendString:@">"];
		}
		
		if (_instanceVariables) {
			[string appendFormat:@"\n{\n"];
			
			Ivar ivar;
			long i;
			for (i = 0; i < CFArrayGetCount(_instanceVariables); i++) {
				ivar = (Ivar)CFArrayGetValueAtIndex(_instanceVariables, i);
				
				[string appendString:@"\t"];
				
				BOOL hasName;
				NSRange nameRange;
				BOOL noSpace;
				unsigned int type;
				substring = StringFromObjCTypeGetRange(ivar_getTypeEncoding(ivar), &type, &hasName, &nameRange, &noSpace);
				AddAttributedSubstringWithRange(nameRange);
				unsigned long nameRangeMax = NSMaxRange(nameRange);
				if (nameRange.location > 0) {
					NSRange range;
					range.length = nameRange.location;
					range.location = [string length] - [substring length];
					_attributeBuffer[NSForegroundColorAttributeName] = userPrefs[@"keywordsColor"];
					ApplyAttributes(range);
				}
				
				if (type == SymbolistTypeObject) {
					unsigned int mode;
					mode = SymbolistRuntimeModeClass;
					
					SymbolistRuntimeEntry *entry = [SymbolistRuntimeEntry entryWithName:[substring substringWithRange:nameRange] mode:mode];
					_attributeBuffer[NSLinkAttributeName] = entry;
				}
				else if (type == SymbolistTypeStruct) {
					NSValue *ivarValue = [NSValue valueWithPointer:ivar_getTypeEncoding(ivar)];
					_attributeBuffer[NSLinkAttributeName] = ivarValue;
				}
				
				_attributeBuffer[NSForegroundColorAttributeName] = userPrefs[@"typeColor"];
				if (nameRangeMax < [substring length]) {
					nameRange.location = nameRangeMax;
					nameRange.length = [substring length] - nameRangeMax;
					UpdateAttributesRange(nameRange.location, nameRange.length);
					_attributeBuffer[NSForegroundColorAttributeName] = userPrefs[@"operatorColor"];
				}
				if (!noSpace)
					[string appendString:@" "];
				
				AddAttributedString(([NSString stringWithFormat:@"%s", ivar_getName(ivar)]));
				_attributeBuffer[NSForegroundColorAttributeName] = userPrefs[@"variableColor"];
				
				AddAttributedString(@";");
				_attributeBuffer[NSForegroundColorAttributeName] = userPrefs[@"operatorColor"];
				
				[string appendString:@"\n"];
			}
			
			[string appendString:@"}"];
		}
		
		[string appendString:@"\n\n"];
		
		if (_attributeRange.length != 0)
			[attrString addAttributes:_attributeBuffer range:_attributeRange];
		
		CFAbsoluteTime t = CFAbsoluteTimeGetCurrent();
		if (_classMethods && CFArrayGetCount(_classMethods) > 0) {
			[self appendMethodsList:_classMethods toAttributedString:attrString isMetaclass:YES];
			[string appendString:@"\n"];
		}
		
		if (_instanceMethods && CFArrayGetCount(_instanceMethods) > 0) {
			[self appendMethodsList:_instanceMethods toAttributedString:attrString isMetaclass:NO];
			[string appendString:@"\n"];
		}
		t = CFAbsoluteTimeGetCurrent() -  t;
//		DebugLog(@"adding methods %fs", t);
		
		AddAttributedString(@"@end");
		_attributeBuffer[NSForegroundColorAttributeName] = userPrefs[@"directiveColor"];
	}
	else if ([[self searchEntry] mode] == SymbolistRuntimeModeProtocol) {
		Protocol *protocol = _searchObject;
		
		AddAttributedString(@"@protocol");
		ApplyAttributes(_attributeRange);
		_attributeBuffer[NSForegroundColorAttributeName] = userPrefs[@"directiveColor"];
		
		[string appendFormat:@" %s", protocol_getName(protocol)];
		
		[string appendString:@"\n\n"];
		
		//struct {@defs (Protocol)} *protocolInner = (void *)protocol;
		BOOL classFlag = YES;
		
		do {
//			struct objc_method_description_list *descList;
//			if (classFlag)
//				descList = protocolInner->class_methods;
//			else
//				descList = protocolInner->instance_methods;
			CFMutableArrayRef methodDescs;
			if (classFlag)
				methodDescs = _classMethods;
			else
				methodDescs = _instanceMethods;
			
			if (methodDescs && CFArrayGetCount(methodDescs) > 0) {
//				CFMutableArrayRef section = CFArrayCreateMutable(kCFAllocatorDefault, descList->count, NULL);
//				unsigned long i;
//				for (i = 0; i < descList->count; i++) {
//					CFArrayAppendValue(section, &descList->list[i]);
//				}
				
				CFArrayRef protocolDescs = CFArrayCreate(kCFAllocatorDefault, (const void **)&methodDescs, 1, &kCFTypeArrayCallBacks);
				[self appendMethodsList:protocolDescs toAttributedString:attrString isMetaclass:classFlag];
				CFRelease(protocolDescs);
				[string appendString:@"\n"];
			}
			
			classFlag = !classFlag;
		} while (!classFlag);
		
		AddAttributedString(@"@end");
		_attributeBuffer[NSForegroundColorAttributeName] = userPrefs[@"directiveColor"];
	}
end:
	// Apply the last attributes.
	ApplyAttributes(_attributeRange);
	
	[attrString endEditing];
}

- (void)loadMethodsForClass:(Class)class intoArray:(CFMutableArrayRef)array;
{
	unsigned int methodCount = 0;
	Method *methods = class_copyMethodList(class, &methodCount);
	
	CFMutableArrayRef section = CFArrayCreateMutable(kCFAllocatorDefault, methodCount, NULL);
	unsigned long i;
	for (i = 0; i < methodCount; i++) {
		Method theMethod = methods[i];
		
		if (_filterString) {
			NSString *selector = NSStringFromSelector(method_getName(theMethod));
			NSRange range = [selector rangeOfString:_filterString options:NSCaseInsensitiveSearch | NSLiteralSearch /*| NSAnchoredSearch*/];
			if (range.location == NSNotFound)
				continue;
		}
		
		CFArrayInsertValueAtIndex(section, 0, theMethod);
	}
	
	if (CFArrayGetCount(section) > 0)
		CFArrayInsertValueAtIndex(array, 0, section);
	CFRelease(section);

	
	/*
	void *methodIterator = NULL;
	struct objc_method_list *mlist = class_nextMethodList(class, &methodIterator);
	while (methodIterator != NULL) {
		CFMutableArrayRef section = CFArrayCreateMutable(kCFAllocatorDefault, mlist->method_count, NULL);
		unsigned long i;
		for (i = 0; i < mlist->method_count; i++) {
			Method theMethod = &mlist->method_list[i];
			
			if (_filterString) {
				NSString *selector = NSStringFromSelector(theMethod->method_name);
				NSRange range = [selector rangeOfString:_filterString options:NSCaseInsensitiveSearch | NSLiteralSearch];
				if (range.location == NSNotFound)
					continue;
			}
			
			CFArrayInsertValueAtIndex(section, 0, theMethod);
		}
		
		if (CFArrayGetCount(section) > 0)
			CFArrayInsertValueAtIndex(array, 0, section);
		CFRelease(section);
		
		mlist = class_nextMethodList(class, &methodIterator);
	}*/
}

- (void)loadMethodsForMethodDescriptions:(NSData *)methodDescriptionsPointerData intoArray:(CFMutableArrayRef)array
{
	unsigned int i;
	unsigned int count = [methodDescriptionsPointerData length] / sizeof(struct objc_method_description *);
	const struct objc_method_description *methodDescription = (const struct objc_method_description *)[methodDescriptionsPointerData bytes];
	
	for (i = 0; i < count; i++, methodDescription++) {
		if (_filterString) {
			NSString *selector = NSStringFromSelector(methodDescription->name);
			NSRange range = [selector rangeOfString:_filterString options:NSCaseInsensitiveSearch | NSLiteralSearch /*| NSAnchoredSearch*/];
			if (range.location == NSNotFound)
				continue;
		}
		
		CFArrayInsertValueAtIndex(array, 0, methodDescription);
	}
}

- (void)appendMethodsList:(CFArrayRef)methods toAttributedString:(NSMutableAttributedString *)attrString isMetaclass:(BOOL)meta;
{
	CFArrayRef section;
	CFIndex count = CFArrayGetCount(methods);
	CFIndex i;
	for (i = 0; i < count; i++) {
		section = CFArrayGetValueAtIndex(methods, i);
		
		Method method;
		CFIndex m;
		CFIndex methodCount = CFArrayGetCount(section);
		for (m = 0; m < methodCount; m++) {
			method = (Method)CFArrayGetValueAtIndex(section, m);
			[self appendMethod:method toAttributedString:attrString isMeta:meta];
		}
		
		if (i != count - 1)
			[[attrString mutableString] appendString:@"\n"];
	}
}

- (void)appendMethod:(Method)method toAttributedString:(NSMutableAttributedString *)attrString isMeta:(BOOL)meta
{
	NSMutableString *string = [attrString mutableString];
	NSString *substring;
	NSDictionary *userPrefs = [[self delegate] userPrefsForLister:self];
	
	NSString *prefix = meta ? @"+" : @"-";
	AddAttributedString(prefix);
	_attributeBuffer[NSForegroundColorAttributeName] = userPrefs[@"operatorColor"];
	
	[string appendString:@" ("];
	
	const char *argType = method_getTypeEncoding(method); //method->method_types;
	[self appendType:argType toAttributedString:attrString];
	
	[string appendString:@")"];
	
	[attrString addAttributes:_attributeBuffer range:_attributeRange];
	
	unsigned int count = method_getNumberOfArguments(method);
	const char *selector = sel_getName(method_getName(method));
	NSString *selectorPart;
	
	if (count > 2)
	{
		unsigned int index;
		const char *partEnd;
		
		for (index = 2; index < count; index++) {
			partEnd = strchr(selector, ':') + 1;
			selectorPart = [[NSString alloc] initWithBytes:selector length:(partEnd - selector) encoding:[NSString defaultCStringEncoding]];
			
			if (index > 2)
				[string appendString:@" "];
			
			AddAttributedString(selectorPart);
			_attributeBuffer[NSForegroundColorAttributeName] = userPrefs[@"mainColor"];
			
			
			[string appendString:@"("];
			
			argType = method_copyArgumentType(method, index);
			//method_getArgumentInfo(method, index, &argType, &offset);
			[self appendType:argType toAttributedString:attrString];
			free((void *)argType);
			
			[string appendString:@")"];
			
			if (count == 3)
				AddAttributedString(@"arg");
			else {
				AddAttributedString(([NSString stringWithFormat:@"arg%u", index - 1]));
				selector = partEnd;
			}
			_attributeBuffer[NSForegroundColorAttributeName] = userPrefs[@"argumentColor"];
		}
	}
	else
	{
		size_t length = strlen(selector);
		if (length != 0) {
			selectorPart = [[NSString alloc] initWithBytes:selector length:length encoding:[NSString defaultCStringEncoding]];
			AddAttributedString(selectorPart);
			_attributeBuffer[NSForegroundColorAttributeName] = userPrefs[@"mainColor"];
		}
	}
	
	AddAttributedString(@";");
	_attributeBuffer[NSForegroundColorAttributeName] = userPrefs[@"operatorColor"];
	[string appendString:@"\n"];
}

- (void)appendType:(const char *)objcType toAttributedString:(NSMutableAttributedString *)attrString
{
	NSMutableString *string = [attrString mutableString];
	NSString *substring;
	NSDictionary *userPrefs = [[self delegate] userPrefsForLister:self];
	NSRange nameRange;
	
	unsigned int type;
	BOOL hasName;
	substring = StringFromObjCTypeGetRange(objcType, &type, &hasName, &nameRange, NULL);
	AddAttributedSubstringWithRange(nameRange);
	unsigned long nameRangeMax = NSMaxRange(nameRange);
	if (nameRange.location > 0) {
		nameRange.length = nameRange.location;
		nameRange.location = [string length] - [substring length];
		_attributeBuffer[NSForegroundColorAttributeName] = userPrefs[@"keywordsColor"];
		ApplyAttributes(nameRange);
	}
	
	_attributeBuffer[NSForegroundColorAttributeName] = userPrefs[@"typeColor"];
	if (type == SymbolistTypeObject) {
		unsigned int mode;
		mode = SymbolistRuntimeModeClass;
		
		SymbolistRuntimeEntry *entry = [SymbolistRuntimeEntry entryWithName:[substring substringWithRange:nameRange] mode:mode];
		_attributeBuffer[NSLinkAttributeName] = entry;
	}
	else if (type == SymbolistTypeStruct) {
		NSValue *ivarValue = [NSValue valueWithPointer:objcType];
		_attributeBuffer[NSLinkAttributeName] = ivarValue;
	}
	
	if (nameRangeMax < [substring length]) {
		nameRange.location = nameRangeMax;
		nameRange.length = [substring length] - nameRangeMax;
		UpdateAttributesRange(nameRange.location, nameRange.length);
		_attributeBuffer[NSForegroundColorAttributeName] = userPrefs[@"operatorColor"];
	}
	//[_attributeBuffer setObject:typeValue forKey:NSLinkAttributeName];
}

@end

NSString *StringFromObjCTypeGetRange(const char *type, unsigned int *outType, BOOL *hasName, NSRange *outNameRange, BOOL *outIsPointer)
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
			
			argString = [[NSString alloc] initWithBytes:(type - nameLength) length:nameLength encoding:[NSString defaultCStringEncoding]];
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
#warning Unimplemented
		argString = @"(array)";
	else if (type[0] == '(')
#warning Unimplemented
		argString = @"(union)";
	else if (type[0] == '{') { // Struct
		const char *typeStart = ++type;
		unsigned long nameLength = 0;
		
		for (; ; type++) {
			//DebugLog(@"char:%c %u %d", type[0], endCount, (endCount == 1));
			if (type[0] == '}')
				break;
			else {
				if (type[0] == '=')
					break;
				
				nameLength++;
			}
		}
		
//		DebugLog(@"%s", type);
		
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
			
			argString = structName;
		}
		
		flags.hasName = 1;
		flags.structFlag = 1;
		if (outNameRange) {
			outNameRange->location = 0;
			outNameRange->length = [argString length];
		}
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
//		if ([fullString length] > 0)
//			DebugLog(@"%u %u '%@'", outNameRange->location, [fullString length], fullString);
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
	
	if (outType) {
		if (flags.objectFlag)
			*outType = SymbolistTypeObject;
		else if (flags.structFlag)
			*outType = SymbolistTypeStruct;
		else
			*outType = SymbolistTypeOther;
	}
	
	return fullString;
}
