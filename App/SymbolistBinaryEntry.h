//
//  SymbolistBinaryEntry.h
//  Symbolist
//
//  Created by Patrick Smith on 12/05/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <mach-o/nlist.h>



struct SymbolistBinaryEntry_Flags {
	//	unsigned int 
	unsigned int isObjCClass : 1;
	unsigned int isObjCCategory : 1;
	unsigned int isCPPSymbol : 1;
	unsigned int reserved : 29;
};


@interface SymbolistBinaryEntry : NSObject
{
	char *_name;
	NSString *_nameString;
	uint8_t _type;		/* type flag */
	uint8_t _sect;		/* section number or NO_SECT */
	int16_t _desc;		/* see <mach-o/stab.h> */
	
	struct SymbolistBinaryEntry_Flags _flags;
}

+ (BOOL)nlist32BitIsSymbolicDebuggingEntry:(struct nlist *)nlist;
+ (BOOL)nlist64BitIsSymbolicDebuggingEntry:(struct nlist_64 *)nlist;

+ (id)newWithNList32Bit:(struct nlist *)nlist string:(void *)string;
+ (id)newWithNList64Bit:(struct nlist_64 *)nlist string:(void *)string;

- (NSString *)name;
//- (NSString *)type;

- (NSString *)value;
- (BOOL)hasNonZeroValue;

- (BOOL)isDebug;
- (BOOL)isObjCClass;
//- (BOOL)isObjCCategory;
- (BOOL)isExternal;
- (BOOL)isPrivate;
- (BOOL)is64Bit;
- (NSString *)externalDescription;

@end

@interface SymbolistBinaryEntry (Demangle)

- (void)setName:(const char *)string;

+ (char *)demangledString:(const char *)string;

@end
