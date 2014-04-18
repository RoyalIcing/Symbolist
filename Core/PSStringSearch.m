#import "PSStringSearch.h"

#pragma mark Private Structures

struct PSStringSearchOpaque {
	NSMutableData *data;
};

#pragma mark Private Functions

void SearchModuleFreeResources(SearchModule *module);

#pragma mark -

PSStringSearchRef PSStringSearchCreate(NSString *searchString)
{
	PSStringSearchRef stringSearch = malloc(sizeof(struct PSStringSearchOpaque));
	
	stringSearch->data = [NSMutableData new];
	NSMutableData *data = stringSearch->data;
	SearchModule *lastModule = NULL;
	SearchModule *newModule = NULL;
	size_t offset = 0;
	
	SearchModuleString stringModule;
	NSString *substring;
	
#if 1
	
	stringModule.base.type = SearchModuleTypeString;
	stringModule.base.next = NULL;
	stringModule.string = [searchString copy];
	[data appendBytes:&stringModule length:sizeof(stringModule)];
	
#else
	NSScanner *scanner = [NSScanner scannerWithString:searchString];
	[scanner setCharactersToBeSkipped:nil];
	
//	const unichar *characters = malloc([searchString length] * sizeof(unichar));
//	[searchString getCharacters:(unichar *)characters];
	
	for (;;) {
		SearchModule newModule;
		if ([scanner scanString:@"[" intoString:nil])
			newModule.base.type = SearchOptionImmediate;
		else if ([scanner scanString:@"," intoString:nil])
			newModule.base.type = SearchOptionContinueToNearest;
		else if ([scanner scanString:@"!" intoString:nil])
			newModule.base.type = SearchOptionNegate;
		else
			break;
		
		newModule.base.next = NULL;
		
		[data appendBytes:&stringModule length:sizeof(stringModule)];
		
		lastModule = [data mutableBytes] + offset;
		offset = [data length];
	}
	
	NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@"() ;"];
	size_t blockCount = 0;
	NSString *stringFound;
	uint32_t newType = SearchModuleTypeString;
	SearchModuleParent compoundModule;
	stringModule.base.next = NULL;
	
	unsigned long stringLength = [[scanner string] length];
	
	while ([scanner scanUpToCharactersFromSet:charSet intoString:&stringFound]) {
		if ([scanner scanLocation] == stringLength)
			break;
		
		BOOL addNewCompoundModule = NO;
		compoundModule.base.next = NULL;
		
		if ([scanner scanString:@"(" intoString:nil]) {
			blockCount++;
			addNewCompoundModule = YES;
		}
		else if ([scanner scanString:@")" intoString:nil]) {
			if (blockCount > 0)
				blockCount--;
			else
				return NO;
		}
		else if ([scanner scanString:@" " intoString:nil])
			compoundModule.base.type = SearchModuleTypeOr;
		else if ([scanner scanString:@";" intoString:nil])
			compoundModule.base.type = SearchModuleTypeAnd;
		
		if (newType != compoundModule.base.type)
			;
		
		[data appendBytes:&stringModule length:sizeof(stringModule)];
		
		newModule = [data mutableBytes] + offset;
		lastModule->base.next = newModule;
		lastModule = newModule;
		
		offset = [data length];
		
		if (addNewCompoundModule) {
			[data appendBytes:&compoundModule length:sizeof(compoundModule)];
			
			newModule = [data mutableBytes] + offset;
			lastModule->base.next = newModule;
			lastModule = newModule;
		}
	}
	
	
//	if ([searchString hasPrefix:@"["]) {
//		stringModule.base.type = SearchOptionImmediate;
//		substring = [[searchString substringFromIndex:1] copy];
//	}
//	else {
//		stringModule.base.type = SearchModuleTypeString;
//		substring = [searchString copy];
//	}
	
#endif
	
	return stringSearch;
}

void SearchModuleFreeResources(SearchModule *module)
{
	if (module->base.type == SearchModuleTypeString)
	{
		[((SearchModuleString *)module)->string release];
	}
	else if (module->base.type == SearchModuleTypeOr || module->base.type == SearchModuleTypeAnd)
	{
		SearchModule *child = SearchModuleParentGetFirstChild((SearchModuleParent *)module);
		
		do {
			SearchModuleFreeResources(child);
		} while (child = SearchModuleGetNextModule(child));
	}
}

void PSStringSearchFree(PSStringSearchRef stringSearch)
{
	SearchModule *module = (SearchModule *)[stringSearch->data bytes];
	
	do {
		SearchModuleFreeResources(module);
	} while (module = SearchModuleGetNextModule(module));
	
	[stringSearch->data release];
	free(stringSearch);
}

BOOL PSStringSearchMatchesString(PSStringSearchRef stringSearch, NSString *string)
{
	SearchModule *module = (SearchModule *)[stringSearch->data bytes];
	return SearchModuleMatchesString(module, string);
}

#pragma mark Modules

SearchModule *SearchModuleGetNextModule(SearchModule *module)
{
	return module->base.next;
}

SearchModule *SearchModuleParentGetFirstChild(SearchModuleParent *module)
{
	return module->firstChild;
}

BOOL SearchModuleMatchesString(SearchModule *module, NSString *string)
{
	unsigned long length = [string length];
	NSRange range;
	
	do {
		range = NSMakeRange(0, length);
		if (SearchMatchModuleWithString(module, string, &range) == NO)
			return NO;
	} while (module = SearchModuleGetNextModule(module));
	
	return YES;
}

#pragma mark Module Matching

BOOL SearchMatchModuleWithString(SearchModule *module, NSString *string, NSRange *range)
{
	BOOL flag = NO;
	
	do {
		if (module->base.type == SearchModuleTypeOr)
			flag = SearchMatchOrModule((SearchModuleParent *)module, string, range);
		else if (module->base.type == SearchModuleTypeAnd)
			flag = SearchMatchAndModule((SearchModuleParent *)module, string, range);
		else if (module->base.type == SearchModuleTypeString)
			flag = SearchMatchStringModule((SearchModuleString *)module, string, range);
		
		// Flip flag value if options include a negation.
		if (module->base.type & SearchOptionNegate)
			flag = !flag;
		
		if (!flag)
			return NO;
	} while (module = SearchModuleGetNextModule(module));
	
	return YES;
}

BOOL SearchMatchStringModule(SearchModuleString *module, NSString *string, NSRange *range)
{
	NSString *moduleString = module->string;
	unsigned int options = NSCaseInsensitiveSearch;
	if (module->base.type & SearchOptionImmediate)
		options |= NSAnchoredSearch;
	
	*range = [string rangeOfString:moduleString options:options range:*range];
	return (range->location != NSNotFound);
}

BOOL SearchMatchOrModule(SearchModuleParent *module, NSString *string, NSRange *range)
{
	SearchModule *child = SearchModuleParentGetFirstChild(module);
	// Save the initial range.
	NSRange oldRange = *range;
	
	// We need any match to be true.
	do {
		// Continue until a positive match is found.
		if (SearchMatchModuleWithString(child, string, range))
			return YES;
		// Reset to initial range.
		*range = oldRange;
	} while (child = SearchModuleGetNextModule(child));
	
	return NO;
}

BOOL SearchMatchAndModule(SearchModuleParent *module, NSString *string, NSRange *range)
{
	SearchModule *child = SearchModuleParentGetFirstChild(module);
	// Save the initial range.
	NSRange oldRange = *range;
	
	// We need all matches to be true.
	do {
		// Bail if any module returns false.
		if (!SearchMatchModuleWithString(child, string, range))
			return NO;
		// Revert to initial range.
		*range = oldRange;
	} while (child = SearchModuleGetNextModule(child));
	
	return YES;
}
