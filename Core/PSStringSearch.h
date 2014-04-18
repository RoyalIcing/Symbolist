#import <Foundation/Foundation.h>

enum {
	SearchModuleTypeString = 1 << 0,
	SearchModuleTypeAnd = 1 << 1,  // AND, Conjunction
	SearchModuleTypeOr = 1 << 2, // OR, Disjunction
	
	SearchOptionImmediate = 1 << 3, // NEXT, Adjoin
	SearchOptionContinueToNearest = 1 << 4, // FOLLOW
	SearchOptionBackwards = 1 << 5, // REVERSE
	SearchOptionNegate = 1 << 6, // NOT
	SearchOptionsMask = SearchOptionImmediate | SearchOptionContinueToNearest | SearchOptionBackwards | SearchOptionNegate,
};

enum {
	MatchStart = 1 << 8,
	MatchEnd,
	MatchFunctionNames,
	MatchObjcClasses,
	MatchObjcClassMethods,
	MatchObjcInstanceMethods
};

typedef struct PSStringSearchOpaque *PSStringSearchRef;

PSStringSearchRef PSStringSearchCreate(NSString *searchString);
void PSStringSearchFree(PSStringSearchRef stringSearch);

#pragma mark Internals

typedef struct SearchModuleBase {
	uint32_t type;
	struct SearchModule *next;
} SearchModuleBase;

typedef struct SearchModule {
	SearchModuleBase base;
} SearchModule;

typedef struct SearchModuleString {
	SearchModuleBase base;
	NSString *string;
} SearchModuleString;

typedef struct SearchModuleParent {
	SearchModuleBase base;
	SearchModule *firstChild;
} SearchModuleParent;

//void SearchModuleFree(SearchModule *module);

BOOL PSStringSearchMatchesString(PSStringSearchRef stringSearch, NSString *string);

#pragma mark -

BOOL SearchModuleMatchesString(SearchModule *module, NSString *string);

SearchModule *SearchModuleGetNextModule(SearchModule *module);
SearchModule *SearchModuleParentGetFirstChild(SearchModuleParent *module);

BOOL SearchMatchModuleWithString(SearchModule *module, NSString *string, NSRange *range);

BOOL SearchMatchStringModule(SearchModuleString *module, NSString *string, NSRange *range);
BOOL SearchMatchOrModule(SearchModuleParent *module, NSString *string, NSRange *range);
BOOL SearchMatchAndModule(SearchModuleParent *module, NSString *string, NSRange *range);
