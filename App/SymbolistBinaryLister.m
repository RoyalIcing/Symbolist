//
//  SymbolistBinaryLister.m
//  Symbolist
//
//  Created by Patrick Smith on 11/05/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SymbolistBinaryLister.h"
#import "SymbolistBinaryError.h"

#include <mach-o/fat.h>
#include <mach-o/loader.h>
#include <mach-o/nlist.h>
#include <mach-o/swap.h>

#define TESTING 1

typedef enum {
	PSTotalBytesDescription,
	PSFreeBytesDescription
} PSBytesDescriptionType;
NSString *PSGetDescriptionForByteCount(UInt64 bytes, PSBytesDescriptionType type);

@implementation SymbolistBinaryLister

- (id)initWithPath:(NSString *)path error:(NSError **)outError
{
	self = [super init];
	if (self) {
		BOOL dirFlag;
		if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&dirFlag] == NO) {
			[NSException raise:NSInvalidArgumentException format:@"Path \"%@\" does not exist.", path];
		}
		if (dirFlag) {
			path = [path stringByStandardizingPath];
			
/*			
			CFURLRef url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)path, kCFURLPOSIXPathStyle, true);
			CFBundleRef cfBundle = CFBundleCreate(kCFAllocatorDefault, url);
			if (cfBundle != NULL) {
				CFURLRef frameworksUrl = CFBundleCopyPrivateFrameworksURL(cfBundle);
				NSLog(@"%@", frameworksUrl);
				if (frameworksUrl != NULL) {
					CFArrayRef frameworks = CFBundleCreateBundlesFromDirectory(kCFAllocatorDefault, frameworksUrl, NULL);
					if (frameworks != NULL) {
						CFBundleRef framework;
						CFURLRef frameworkExecutableUrl;
						CFIndex i, count = CFArrayGetCount(frameworks);
						for (i = 0; i < count; i++) {
							framework = (CFBundleRef)CFArrayGetValueAtIndex(frameworks, i);
							frameworkExecutableUrl = CFBundleCopyExecutableURL(framework);
							if (frameworkExecutableUrl != NULL) {
								//frameworkExecutableUrl = CFURLCopyPath(frameworkExecutableUrl);
								NSLog(@"%@", frameworkExecutableUrl);
								CFRelease(frameworkExecutableUrl);
							}
						}
					}
				}
			}*/
			
			NSBundle *bundle = [NSBundle bundleWithPath:path];
			NSLog(@"%@", bundle);
			if (bundle == nil) {
				if (outError)
					*outError = [NSError errorWithDomain:SymbolistBinaryErrorDomain code:SymbolistBinaryErrorInvalidBundle userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedStringFromTable(@"The directory is not a bundle.", @"SymbolistBinaryErrors", @"Invalid bundle reason."), NSLocalizedFailureReasonErrorKey,
					NSLocalizedStringFromTable(@"Try application/framework bundles or executable tools.", @"SymbolistBinaryErrors", @"Unknown file type suggestion."), NSLocalizedRecoverySuggestionErrorKey,
					nil]];
				
				[self release];
				return nil;
				//[NSException raise:NSInvalidArgumentException format:@"Path \"%@\" is not a bundle.", path];
			}
			
			path = [bundle executablePath];
			if (!path) {
				if (outError)
					*outError = [NSError errorWithDomain:SymbolistBinaryErrorDomain code:SymbolistBinaryErrorInvalidBundle userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedStringFromTable(@"An executable file was not found.", @"SymbolistBinaryErrors", @"Invalid bundle executable path reason."), NSLocalizedFailureReasonErrorKey,
					NSLocalizedStringFromTable(@"Try application/framework bundles or executable tools.", @"SymbolistBinaryErrors", @"Unknown file type suggestion."), NSLocalizedRecoverySuggestionErrorKey,
					nil]];
				
				[self release];
				return nil;
			}
		}
		
		_path = [path copy];
		
		if (![self isValid]) {
			NSDictionary *errorInfo;
			
			if (dirFlag) {
				errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedStringFromTable(@"The executable file is an unknown type or could be corrupt.", @"SymbolistBinaryErrors", @"Invalid executable reason."), NSLocalizedFailureReasonErrorKey,
					NSLocalizedStringFromTable(@"Try Mach-O based binaries.", @"SymbolistBinaryErrors", @"Invalid binary executable suggestion."), NSLocalizedRecoverySuggestionErrorKey,
					nil];
			}
			else {
				errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedStringFromTable(@"The file may not be an executable file or could be corrupt.", @"SymbolistBinaryErrors", @"Invalid file reason."), NSLocalizedFailureReasonErrorKey,
					NSLocalizedStringFromTable(@"Try application/framework bundles or executable tools.", @"SymbolistBinaryErrors", @"Unknown file type suggestion."), NSLocalizedRecoverySuggestionErrorKey,
					nil];
			}
			
			if (outError)
				*outError = [NSError errorWithDomain:SymbolistBinaryErrorDomain code:SymbolistBinaryErrorInvalidBinaryFile userInfo:errorInfo];
			
			[self release];
			return nil;
		}
	}
	return self;
}

- (void)dealloc
{
	[self clear];
	
	[super dealloc];
}


- (void)clear
{
	if (_infos) {
		uint32_t i;
		for (i = 0; i < _archCount; i++) {
			NSLog(@"CLEAR ARCH %u", i);
			NSLog(@"RELEASE %ul", (unsigned long)[_infos[i].symbols count]);
			[_infos[i].symbols release];
			NSLog(@"RELEASE %ul: %@", (unsigned long)[_infos[i].symbolsNames count], _infos[i].symbolsNames);
			[_infos[i].symbolsNames release];
		}
			
		free(_infos);
		_infos = NULL;
	}
}

- (BOOL)isValid
{
	_fd = open([_path fileSystemRepresentation], O_RDONLY);
	if (_fd == -1) {
		NSLog(@"Error opening file: %s", strerror(errno));
		return NO;
	}
	
	if ([self checkIsFatHeader:0])
		return YES;
	if ([self checkIsMachOHeader:0])
		return YES;
	
	return NO;
}

- (void)execute
{
	[self clear];
	
	_fd = open([_path fileSystemRepresentation], O_RDONLY);
	fcntl(_fd, F_NOCACHE, 1);
	
	if (_fd == -1) {
		NSLog(@"Error opening file: %s", strerror(errno));
		return;
	}
	
	BOOL success = [self processFatHeader:0];
	
	if (!success) {
		SymbolistBinaryListerMachOInfo info;
		success = [self processMachOHeader:0 getInfo:&info];
		
		if (success) {
			_flags.fatFlag = NO;
			_archCount = 1;
			_infos = malloc(sizeof(SymbolistBinaryListerMachOInfo));
			_infos[0] = info;
		}
	}
	
	close(_fd);
	
	if (!success) {
		NSLog(@"Execution failed.");
		return;
	}
	
	NSLog(@"Execution succeeded.");
}

- (BOOL)checkIsFatHeader:(off_t)offset
{
	struct fat_header header;
	// Read whole header.
	(void)[self readBytes:&header length:sizeof(header) offset:offset];
	
	// Check for the 'magic number'.
	if (header.magic == FAT_MAGIC)
		return YES;
	// Check again for non-host byte-order version.
	else if (header.magic == FAT_CIGAM)
		return YES;
	// Nope; some other format.
	else
		return NO;
}

- (BOOL)checkIsMachOHeader:(off_t)offset
{
	struct mach_header header;
	// Read header.
	(void)[self readBytes:&header length:sizeof(header) offset:offset];
	
	// Check host order magic number.
	if (header.magic == MH_MAGIC)
		return YES;
	// Check non-host order magic number.
	else if (header.magic == MH_CIGAM)
		return YES;
	// Check 64 bit magic number
	else if (header.magic == MH_MAGIC_64)
		return YES;
	else
	// Nope; some other format.
		return NO;
}

- (BOOL)processFatHeader:(off_t)offset
{
	const off_t originalOffset = offset;
	
	struct fat_header header;
	offset += [self readBytes:&header length:sizeof(header) offset:offset];
	
	BOOL swapFlag;
	if (header.magic == FAT_MAGIC)
		swapFlag = NO;
	else if (header.magic == FAT_CIGAM) {
		swapFlag = YES;
		swap_fat_header(&header, NXHostByteOrder());
	}
	else {
		return NO;
	}
	
	_flags.fatFlag = YES;
	_archCount = header.nfat_arch;
	_infos = malloc(sizeof(SymbolistBinaryListerMachOInfo) * _archCount);
	
	NSLog(@"Processing fat header; %@.", swapFlag ? @"did swap" : @"didn't swap");
	
	CFAbsoluteTime t = CFAbsoluteTimeGetCurrent();
	
	struct fat_arch *arch = malloc(sizeof(struct fat_arch) * header.nfat_arch);
	offset += [self readBytes:arch length:(sizeof(struct fat_arch) * header.nfat_arch) offset:offset];
	if (swapFlag)
		swap_fat_arch(arch, header.nfat_arch, NXHostByteOrder());
	
	uint32_t i;
	for (i = 0; i < header.nfat_arch; i++)
	{
		if (arch[i].cputype == CPU_TYPE_POWERPC)
			NSLog(@"# PowerPC CPU type.");
		else if (arch[i].cputype == CPU_TYPE_POWERPC64)
			NSLog(@"# PowerPC 64-bit CPU type.");
		else if (arch[i].cputype == CPU_TYPE_X86)
			NSLog(@"# x86 CPU type.");
		else if ((arch[i].cputype & ~CPU_ARCH_MASK) == CPU_TYPE_X86 && (arch[i].cputype & CPU_ARCH_ABI64))
			NSLog(@"# x86 64-bit CPU type.");
		else
			NSLog(@"# CPU type: %u.", arch[i].cputype);
		
		NSLog(@"arch offset: %u.", arch[i].offset);
		
		SymbolistBinaryListerMachOInfo info;
		BOOL success = [self processMachOHeader:(originalOffset + arch[i].offset) getInfo:&info];
		if (success) {
			_infos[i] = info;
		}
		else {
			NSLog(@"Unknown problem processing mach header.");
		}
	}
	
	free(arch);
	
	NSLog(@"%f", CFAbsoluteTimeGetCurrent() - t);
	
	return YES;
}

- (BOOL)processMachOHeader32Bit:(off_t)offset getInfo:(SymbolistBinaryListerMachOInfo *)outInfo
{
	const off_t originalOffset = offset;
	
	struct mach_header header;
	offset += [self readBytes:&header length:sizeof(header) offset:offset];
	
	BOOL swapFlag;
	if (header.magic == MH_MAGIC) {
		swapFlag = NO;
	}
	else if (header.magic == MH_CIGAM) {
		swapFlag = YES;
		swap_mach_header(&header, NXHostByteOrder());
	}
	else {
		return NO;
	}
	
	NSLog(@"Processing mach header; %@.", swapFlag ? @"did swap" : @"didn't swap");
	NSLog(@"Has %@ commands;", @(header.ncmds));
	
	bzero(outInfo, sizeof(typeof(*outInfo)));
	outInfo->cpuType = header.cputype;
	outInfo->cpuSubtype = header.cpusubtype;
	
	NSMutableArray *symbols = nil;
	
	struct load_command *commands = malloc(header.sizeofcmds);
	[self readBytes:commands length:header.sizeofcmds offset:offset];
	
	struct load_command *commandPtr;
	struct load_command loadCommand;
	uint32_t commandOffset = 0;
	uint32_t li;
	for (li = 0; li < header.ncmds; li++)
	{
		commandPtr = (struct load_command *)((void *)commands + commandOffset);
		
		loadCommand = *commandPtr;
		if (swapFlag)
			swap_load_command(&loadCommand, NXHostByteOrder());
		
		if (loadCommand.cmd == LC_SYMTAB)
		{
#if TESTING
			NSLog(@"LC_SYMTAB at %u", offset);
#endif
			struct symtab_command symtabCommand = *(struct symtab_command *)commandPtr;
			if (swapFlag)
				swap_symtab_command(&symtabCommand, NXHostByteOrder());
			
#if TESTING
			NSLog(@"string table offset:%u size:%u", symtabCommand.stroff, symtabCommand.strsize);
#endif
			if (symbols == nil)
				symbols = [[NSMutableArray alloc] initWithCapacity:symtabCommand.nsyms];
			else
				[symbols removeAllObjects];
			
			struct nlist *nlists = malloc(sizeof(struct nlist) * symtabCommand.nsyms);
			[self readBytes:(void *)nlists length:(sizeof(struct nlist) * symtabCommand.nsyms) offset:(originalOffset + symtabCommand.symoff)];
			if (swapFlag)
				swap_nlist(nlists, symtabCommand.nsyms, NXHostByteOrder());
			
			const char *stringTable = malloc(symtabCommand.strsize);
			[self readBytes:(void *)stringTable length:symtabCommand.strsize offset:(originalOffset + symtabCommand.stroff)];
			
			SymbolistBinaryEntry *entry;
			uint32_t i;
			for (i = 0; i < symtabCommand.nsyms; i++) {
				//				NSLog(@"%u %02x", nlist.n_un.n_strx, nlist.n_type);
				/*if (nlist.n_type == N_UNDF) {
				 nlistPtr++;
				 continue;
				 }*/
				if (nlists[i].n_un.n_strx == 0)
					continue;
				if ([SymbolistBinaryEntry nlist32BitIsSymbolicDebuggingEntry:&nlists[i]])
					continue;
				
				void *string = (void *)(stringTable + nlists[i].n_un.n_strx);
				entry = [SymbolistBinaryEntry newWithNList32Bit:&nlists[i] string:string];
				[symbols addObject:entry];
				[entry release];
			}
			
			free(nlists);
			free((void *)stringTable);
		}
		
		commandOffset += loadCommand.cmdsize;
	}
	
	free(commands);
	
	outInfo->symbols = [symbols copy];
	[symbols release];
	
	return YES;
}

- (BOOL)processMachOHeader64Bit:(off_t)offset getInfo:(SymbolistBinaryListerMachOInfo *)outInfo
{
	const off_t originalOffset = offset;
	
	struct mach_header_64 header;
	offset += [self readBytes:&header length:sizeof(header) offset:offset];
	
	BOOL swapFlag;
	if (header.magic == MH_MAGIC_64)
		swapFlag = NO;
	else if (header.magic == MH_CIGAM_64) {
		swapFlag = YES;
		swap_mach_header_64(&header, NXHostByteOrder());
	}
	else
		return NO;
	
	NSLog(@"Processing mach header; %@.", swapFlag ? @"did swap" : @"didn't swap");
	NSLog(@"Has %@ commands;", @(header.ncmds));
	
	bzero(outInfo, sizeof(typeof(*outInfo)));
	outInfo->cpuType = header.cputype;
	outInfo->cpuSubtype = header.cpusubtype;
	
	NSMutableArray *symbols = nil;
	NSMutableArray *symbolNames = nil;
	
	struct load_command *commands = malloc(header.sizeofcmds);
	[self readBytes:commands length:header.sizeofcmds offset:offset];
	
	struct load_command *commandPtr;
	struct load_command loadCommand;
	uint32_t commandOffset = 0;
	uint32_t li;
	for (li = 0; li < header.ncmds; li++)
	{
		commandPtr = (struct load_command *)((void *)commands + commandOffset);
		
		loadCommand = *commandPtr;
		if (swapFlag)
			swap_load_command(&loadCommand, NXHostByteOrder());
		
		if (loadCommand.cmd == LC_SYMTAB)
		{
#if TESTING
			NSLog(@"LC_SYMTAB at %u", offset);
#endif
			struct symtab_command symtabCommand = *(struct symtab_command *)commandPtr;
			if (swapFlag)
				swap_symtab_command(&symtabCommand, NXHostByteOrder());
			
#if TESTING
			NSLog(@"string table offset:%u size:%u", symtabCommand.stroff, symtabCommand.strsize);
#endif
			if (!symbols) {
				symbols = [NSMutableArray arrayWithCapacity:symtabCommand.nsyms];
				symbolNames = [NSMutableArray arrayWithCapacity:symtabCommand.nsyms];
			}
			
			struct nlist_64 *nlists = malloc(sizeof(struct nlist_64) * symtabCommand.nsyms);
			[self readBytes:(void *)nlists length:(sizeof(struct nlist_64) * symtabCommand.nsyms) offset:(originalOffset + symtabCommand.symoff)];
			if (swapFlag)
				swap_nlist_64(nlists, symtabCommand.nsyms, NXHostByteOrder());
			
			const char *stringTable = malloc(symtabCommand.strsize);
			[self readBytes:(void *)stringTable length:symtabCommand.strsize offset:(originalOffset + symtabCommand.stroff)];
			
			SymbolistBinaryEntry *entry;
			uint32_t i;
			for (i = 0; i < symtabCommand.nsyms; i++) {
				//				NSLog(@"%u %02x", nlist.n_un.n_strx, nlist.n_type);
				/*if (nlist.n_type == N_UNDF) {
				 nlistPtr++;
				 continue;
				 }*/
				if (nlists[i].n_un.n_strx == 0)
					continue;
				if ([SymbolistBinaryEntry nlist64BitIsSymbolicDebuggingEntry:&nlists[i]])
					continue;
				
				void *string = (void *)(stringTable + nlists[i].n_un.n_strx);
				entry = [SymbolistBinaryEntry newWithNList64Bit:&nlists[i] string:string];
				
				[symbols addObject:entry];
				[symbolNames addObject:[entry name]];
				
				[entry autorelease];
			}
			
			free(nlists);
			free((void *)stringTable);
		}
		
		commandOffset += loadCommand.cmdsize;
	}
	
	free(commands);
	
	if (symbols) {
		outInfo->symbols = [symbols copy];
		//outInfo->symbolsNames = [symbolNames copy];
	}
	else {
		outInfo->symbols = nil;
		outInfo->symbolsNames = nil;
	}

	
	return YES;
}

- (BOOL)processMachOHeader:(off_t)offset getInfo:(SymbolistBinaryListerMachOInfo *)outInfo;
{
	BOOL flag;
	flag = [self processMachOHeader32Bit:offset getInfo:outInfo];
	if (flag)
		return YES;
	
	flag = [self processMachOHeader64Bit:offset getInfo:outInfo];
	return flag;
}

- (BOOL)isFat
{
	return _flags.fatFlag;
}

- (uint32_t)numberOfArchitectures
{
	return _archCount;
}

- (cpu_type_t)cpuTypeForArchAtIndex:(uint32_t)index
{
	return _infos[index].cpuType;
}

- (cpu_type_t)cpuSubtypeForArchAtIndex:(uint32_t)index
{
	return _infos[index].cpuSubtype;
}

- (NSArray *)symbolsForArchAtIndex:(uint32_t)index
{
	return [[_infos[index].symbols retain] autorelease];
}

- (NSArray *)symbolNamesForArchAtIndex:(uint32_t)index
{
	return [[_infos[index].symbolsNames retain] autorelease];
}

- (ssize_t)readBytes:(void *)buffer length:(size_t)length offset:(off_t)offset
{
#if TESTING
	CFAbsoluteTime t = CFAbsoluteTimeGetCurrent();
	ssize_t size = pread(_fd, buffer, length, offset);
	printf("%f seconds to read %u bytes.\n", CFAbsoluteTimeGetCurrent() - t, length);
	return size;
#else
	return pread(_fd, buffer, length, offset);
#endif
}

@end

NSString *PSGetDescriptionForByteCount(UInt64 bytes, PSBytesDescriptionType type)
{
	if (type == PSTotalBytesDescription)
	{
		if (bytes == 0ULL)
			return NSLocalizedString(@"No bytes", @"No byte count");
		else if (bytes == 1ULL)
			return @"1 byte";
		else if (bytes < 1024ULL)
			return [NSString localizedStringWithFormat:@"%qu bytes", bytes];
		else if (bytes < 1048576ULL)
			return [NSString localizedStringWithFormat:@"%.2f kilobytes", (double)bytes / 1024.0];
		else if (bytes < 1073741824ULL)
			return [NSString localizedStringWithFormat:@"%.2f megabytes", (double)bytes / 1048576.0];
		else if (bytes < 1099511627776ULL)
			return [NSString localizedStringWithFormat:@"%.2f gigabytes", (double)bytes / 1073741824.0];
		else if (bytes < 1125899906842624ULL)
			return [NSString localizedStringWithFormat:@"%.2f terabytes", (double)bytes / 1099511627776.0];
		else
			return [NSString localizedStringWithFormat:@"%.2f petabytes", (double)bytes / 1125899906842624.0];
	}
	else
	{
		if (bytes == 0ULL)
			return @"No bytes free";
		else if (bytes == 1ULL)
			return @"1 byte free";
		else if (bytes < 1024ULL)
			return [NSString localizedStringWithFormat:@"%qu bytes free", bytes];
		else if (bytes < 1048576ULL)
			return [NSString localizedStringWithFormat:@"%.2f kilobytes free", (double)bytes / 1024.0];
		else if (bytes < 1073741824ULL)
			return [NSString localizedStringWithFormat:@"%.2f megabytes free", (double)bytes / 1048576.0];
		else if (bytes < 1099511627776ULL)
			return [NSString localizedStringWithFormat:@"%.2f gigabytes free", (double)bytes / 1073741824.0];
		else if (bytes < 1125899906842624ULL)
			return [NSString localizedStringWithFormat:@"%.2f terabytes free", (double)bytes / 1099511627776.0];
		else
			return [NSString localizedStringWithFormat:@"%.2f petabytes free", (double)bytes / 1125899906842624.0];
	}
}
