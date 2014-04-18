//
//  SymbolistBinaryLister.h
//  Symbolist
//
//  Created by Patrick Smith on 11/05/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <mach/machine.h>
#include <mach-o/fat.h>
#include <mach-o/loader.h>
#import <libkern/OSAtomic.h>

#import "SymbolistBinaryEntry.h"


typedef struct {
	cpu_type_t cpuType;
	cpu_subtype_t cpuSubtype;
	NSArray *symbols;
	NSArray *symbolsNames;
} SymbolistBinaryListerMachOInfo;

@interface SymbolistBinaryLister : NSObject
{
	NSString *_path;
	int _fd;
	
	struct {
		unsigned int executeFlag:1;
		unsigned int fatFlag:1;
	} _flags;
	
	uint32_t _archCount;
	SymbolistBinaryListerMachOInfo *_infos;
}

- (id)initWithPath:(NSString *)path error:(NSError **)outError;

- (BOOL)isValid;
- (BOOL)isFat;

- (void)execute;
- (void)clear;

- (uint32_t)numberOfArchitectures;

- (cpu_type_t)cpuTypeForArchAtIndex:(uint32_t)index;
- (cpu_subtype_t)cpuSubtypeForArchAtIndex:(uint32_t)index;

- (NSArray *)symbolsForArchAtIndex:(uint32_t)index;
- (NSArray *)symbolNamesForArchAtIndex:(uint32_t)index;

#pragma mark -

- (BOOL)checkIsFatHeader:(off_t)offset;
- (BOOL)checkIsMachOHeader:(off_t)offset;

- (BOOL)processFatHeader:(off_t)offset;
- (BOOL)processMachOHeader:(off_t)offset getInfo:(SymbolistBinaryListerMachOInfo *)outInfo;

- (ssize_t)readBytes:(void *)buffer length:(size_t)length offset:(off_t)offset;

@end
