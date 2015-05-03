//
//  SymbolistBinaryEntry.m
//  Symbolist
//
//  Created by Patrick Smith on 12/05/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SymbolistBinaryEntry.h"

#define	N_TEXT	0x04		/* text segment */
#define	N_DATA	0x06		/* data segment */
#define	N_BSS	0x08		/* bss segment */
#define	N_COMM	0x12		/* common reference */
#define	N_FN	0x1e		/* file name */



@interface SymbolistBinaryEntry32Bit : SymbolistBinaryEntry
{
	uint32_t _value;	/* value of this symbol (or stab offset) */
}

- (id)initWithNList32Bit:(struct nlist *)nlist string:(void *)string;

@end

@interface SymbolistBinaryEntry64Bit : SymbolistBinaryEntry
{
	uint64_t _value;	/* value of this symbol (or stab offset) */
}

- (id)initWithNList64Bit:(struct nlist_64 *)nlist string:(void *)string;

@end


@implementation SymbolistBinaryEntry

+ (BOOL)nlist32BitIsSymbolicDebuggingEntry:(struct nlist *)nlist
{
	return (nlist->n_type & N_STAB) != 0;
}

+ (BOOL)nlist64BitIsSymbolicDebuggingEntry:(struct nlist_64 *)nlist
{
	return (nlist->n_type & N_STAB) != 0;
}

+ (id)newWithNList32Bit:(struct nlist *)nlist string:(void *)string
{
	return [[SymbolistBinaryEntry32Bit alloc] initWithNList32Bit:nlist string:string];
}

+ (id)newWithNList64Bit:(struct nlist_64 *)nlist string:(void *)string
{
	return [[SymbolistBinaryEntry64Bit alloc] initWithNList64Bit:nlist string:string];
}

- (void)dealloc
{
	free(_name);
}

- (NSString *)name
{
	if (_nameString)
		return _nameString;
	
	const char *string = _name;
	unsigned int length = strlen(_name);
	
//	if ([self isObjCClass]) {
//		string += 16;
//		length -= 16;
//	}
//	if (string[0] == '_') {
//		string += 1;
//		length -= 1;
//	}
//	unsigned int i;
//	for (i = 0; i < length; i++) {
//		if (string[i] == '$') {
//			length -= i;
//			break;
//		}
//	}
	
	// Not using 'free when done', as we can not rely on '_nameString' taking ownership, since this method may not be called.
	_nameString = [[NSString alloc] initWithBytesNoCopy:(void *)string length:length encoding:NSUTF8StringEncoding freeWhenDone:NO];
	
	return _nameString;
}

- (NSString *)typeShortDescription
{
	if ([self isDebug])
		return @"-";
	
	uint8_t nType = _type & N_TYPE;
	if (N_UNDF == nType)
		return @"Undefined";
	else if (N_ABS == nType)
		return @"Absolute";
	else if (N_SECT == nType)
		return [NSString stringWithFormat:@"Section %u", _sect];
	else if (N_PBUD == nType)
		return @"Prebound";
	else if (N_INDR == nType)
		return @"Indirect";
	else
		return @(nType).stringValue;
		//return @"?";
}

- (NSString *)typeDescription
{
	if ([self isDebug])
		return @"Debug";
	
	uint8_t nType = _type & N_TYPE;
	
	if (N_UNDF == nType) {
		if ([self isExternal] && [self hasNonZeroValue])
			return NSLocalizedStringFromTable(@"Common", @"SymbolistBinary", @"Common symbol type.");
		else
			return NSLocalizedStringFromTable(@"Undefined", @"SymbolistBinary", @"Undefined symbol type.");
	}
	else if (N_ABS == nType)
		return @"Absolute";
	else if (N_BSS == nType)
		return @"BSS";
	else if (N_SECT == nType)
		return [NSString stringWithFormat:@"Section %u", _sect];
	else if (N_PBUD == nType)
		return @"Prebound";
	else if (N_INDR == nType)
		return @"Indirect";
	else
		return @(nType).stringValue;
		//return @"?";
}

- (NSString *)value
{
	return nil;
}

- (BOOL)hasNonZeroValue
{
	return NO;
}

- (BOOL)isDebug
{
	return (_type & N_STAB) != 0;
}

- (BOOL)isObjCClass
{
	return _flags.isObjCClass;
}

- (BOOL)isExternal
{
	return (_type & N_EXT) != 0;
}

- (BOOL)isPrivate
{
	return (_type & N_PEXT) != 0;
}

- (BOOL)is64Bit
{
	return NO;
}

- (NSString *)externalDescription
{
	if ([self isPrivate])
		return NSLocalizedStringFromTable(@"Private", @"SymbolistBinary", @"Private symbol type.");
	else if ([self isExternal])
		return NSLocalizedStringFromTable(@"External", @"SymbolistBinary", @"External symbol type.");
	else
		return NSLocalizedStringFromTable(@"Local", @"SymbolistBinary", @"Local symbol type.");
}

@end

@implementation SymbolistBinaryEntry32Bit

- (id)initWithNList32Bit:(struct nlist *)nlist string:(void *)string
{
	self = [super init];
	if (self) {
		_type = nlist->n_type;
		_sect = nlist->n_sect;
		_desc = nlist->n_desc;
		_value = nlist->n_value;
		
		[self setName:string];
		
		_flags.isObjCClass = (strncmp(string, ".objc_class_name", 16) == 0);
	}
	return self;
}

- (BOOL)hasNonZeroValue
{
	return _value != 0;
}

- (NSString *)value
{
	if (_value != 0)
		return [NSString stringWithFormat:@"%08X", _value];
	else
		return nil;
}

- (BOOL)is64Bit
{
	return NO;
}

@end

@implementation SymbolistBinaryEntry64Bit

- (id)initWithNList64Bit:(struct nlist_64 *)nlist string:(void *)string
{
	self = [super init];
	if (self) {
		_type = nlist->n_type;
		_sect = nlist->n_sect;
		_desc = nlist->n_desc;
		_value = nlist->n_value;
		
		[self setName:string];
		
		_flags.isObjCClass = (strncmp(string, ".objc_class_name", 16) == 0);
	}
	return self;
}

- (BOOL)hasNonZeroValue
{
	return _value != 0;
}

- (NSString *)value
{
	if (_value != 0)
		return [NSString stringWithFormat:@"%016llX", _value];
	else
		return nil;
}

- (BOOL)is64Bit
{
	return YES;
}

@end
