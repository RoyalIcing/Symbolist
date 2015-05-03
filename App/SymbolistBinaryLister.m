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



@implementation SymbolistBinaryListerMachOInfo

@end



@interface SymbolistBinaryLister ()

@property (copy, nonatomic) NSArray *machOInfos;

@end

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
				DebugLog(@"%@", frameworksUrl);
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
								DebugLog(@"%@", frameworkExecutableUrl);
								CFRelease(frameworkExecutableUrl);
							}
						}
					}
				}
			}*/
			
			NSBundle *bundle = [NSBundle bundleWithPath:path];
			DebugLog(@"%@", bundle);
			if (bundle == nil) {
				if (outError)
					*outError = [NSError errorWithDomain:SymbolistBinaryErrorDomain code:SymbolistBinaryErrorInvalidBundle userInfo:@{NSLocalizedFailureReasonErrorKey: NSLocalizedStringFromTable(@"The directory is not a bundle.", @"SymbolistBinaryErrors", @"Invalid bundle reason."),
					NSLocalizedRecoverySuggestionErrorKey: NSLocalizedStringFromTable(@"Try application/framework bundles or executable tools.", @"SymbolistBinaryErrors", @"Unknown file type suggestion.")}];
				
				return nil;
				//[NSException raise:NSInvalidArgumentException format:@"Path \"%@\" is not a bundle.", path];
			}
			
			path = [bundle executablePath];
			if (!path) {
				if (outError)
					*outError = [NSError errorWithDomain:SymbolistBinaryErrorDomain code:SymbolistBinaryErrorInvalidBundle userInfo:@{NSLocalizedFailureReasonErrorKey: NSLocalizedStringFromTable(@"An executable file was not found.", @"SymbolistBinaryErrors", @"Invalid bundle executable path reason."),
					NSLocalizedRecoverySuggestionErrorKey: NSLocalizedStringFromTable(@"Try application/framework bundles or executable tools.", @"SymbolistBinaryErrors", @"Unknown file type suggestion.")}];
				
				return nil;
			}
		}
		
		(self.path) = path;
		
		if (![self isValid]) {
			NSDictionary *errorInfo;
			
			if (dirFlag) {
				errorInfo = @{NSLocalizedFailureReasonErrorKey: NSLocalizedStringFromTable(@"The executable file is an unknown type or could be corrupt.", @"SymbolistBinaryErrors", @"Invalid executable reason."),
					NSLocalizedRecoverySuggestionErrorKey: NSLocalizedStringFromTable(@"Try Mach-O based binaries.", @"SymbolistBinaryErrors", @"Invalid binary executable suggestion.")};
			}
			else {
				errorInfo = @{NSLocalizedFailureReasonErrorKey: NSLocalizedStringFromTable(@"The file may not be an executable file or could be corrupt.", @"SymbolistBinaryErrors", @"Invalid file reason."),
					NSLocalizedRecoverySuggestionErrorKey: NSLocalizedStringFromTable(@"Try application/framework bundles or executable tools.", @"SymbolistBinaryErrors", @"Unknown file type suggestion.")};
			}
			
			if (outError)
				*outError = [NSError errorWithDomain:SymbolistBinaryErrorDomain code:SymbolistBinaryErrorInvalidBinaryFile userInfo:errorInfo];
			
			return nil;
		}
	}
	return self;
}

- (BOOL)isValid
{
	_fd = open([(self.path) fileSystemRepresentation], O_RDONLY);
	if (_fd == -1) {
		DebugLog(@"Error opening file: %s", strerror(errno));
		return NO;
	}
	
	if ([self checkIsFatHeader:0])
		return YES;
	if ([self checkIsMachOHeader:0])
		return YES;
	
	return NO;
}

- (void)process
{
	(self.machOInfos) = nil;
	
	_fd = open([(self.path) fileSystemRepresentation], O_RDONLY);
	fcntl(_fd, F_NOCACHE, 1);
	
	if (_fd == -1) {
		DebugLog(@"Error opening file: %s", strerror(errno));
		return;
	}
	
	BOOL success = [self processFatHeader:0];
	
	if (!success) {
		SymbolistBinaryListerMachOInfo *info = [self processMachOHeader:0];
		
		if (info) {
			_flags.fatFlag = NO;
			_archCount = 1;
			(self.machOInfos) = @[info];
		}
	}
	
	close(_fd);
	
	if (!success) {
		DebugLog(@"Execution failed.");
		return;
	}
	
	DebugLog(@"Execution succeeded.");
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
	NSMutableArray *machOInfosMutable = [NSMutableArray arrayWithCapacity:_archCount];
	
	DebugLog(@"Processing fat header; %@.", swapFlag ? @"did swap" : @"didn't swap");
	
	CFAbsoluteTime t = CFAbsoluteTimeGetCurrent();
	
	struct fat_arch *arch = malloc(sizeof(struct fat_arch) * header.nfat_arch);
	offset += [self readBytes:arch length:(sizeof(struct fat_arch) * header.nfat_arch) offset:offset];
	if (swapFlag)
		swap_fat_arch(arch, header.nfat_arch, NXHostByteOrder());
	
	uint32_t i;
	for (i = 0; i < header.nfat_arch; i++)
	{
		if (arch[i].cputype == CPU_TYPE_POWERPC)
			DebugLog(@"# PowerPC CPU type.");
		else if (arch[i].cputype == CPU_TYPE_POWERPC64)
			DebugLog(@"# PowerPC 64-bit CPU type.");
		else if (arch[i].cputype == CPU_TYPE_X86)
			DebugLog(@"# x86 CPU type.");
		else if ((arch[i].cputype & ~CPU_ARCH_MASK) == CPU_TYPE_X86 && (arch[i].cputype & CPU_ARCH_ABI64))
			DebugLog(@"# x86 64-bit CPU type.");
		else
			DebugLog(@"# CPU type: %u.", arch[i].cputype);
		
		DebugLog(@"arch offset: %u.", arch[i].offset);
		
		SymbolistBinaryListerMachOInfo *info = [self processMachOHeader:(originalOffset + arch[i].offset)];
		if (info) {
			[machOInfosMutable addObject:info];
		}
		else {
			[machOInfosMutable addObject:[NSNull null]];
			DebugLog(@"Unknown problem processing mach header.");
		}
	}
	
	free(arch);
	
	(self.machOInfos) = machOInfosMutable;
	
	DebugLog(@"%f", CFAbsoluteTimeGetCurrent() - t);
	
	return YES;
}

- (SymbolistBinaryListerMachOInfo *)processMachOHeader32Bit:(off_t)offset
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
	
	DebugLog(@"Processing mach header; %@.", swapFlag ? @"did swap" : @"didn't swap");
	DebugLog(@"Has %@ commands;", @(header.ncmds));
	
	SymbolistBinaryListerMachOInfo *info = [SymbolistBinaryListerMachOInfo new];
	(info.cpuType) = header.cputype;
	(info.cpuSubtype) = header.cpusubtype;
	
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
			DebugLog(@"LC_SYMTAB at %lld", offset);
#endif
			struct symtab_command symtabCommand = *(struct symtab_command *)commandPtr;
			if (swapFlag)
				swap_symtab_command(&symtabCommand, NXHostByteOrder());
			
#if TESTING
			DebugLog(@"string table offset:%u size:%u", symtabCommand.stroff, symtabCommand.strsize);
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
				//				DebugLog(@"%u %02x", nlist.n_un.n_strx, nlist.n_type);
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
			}
			
			free(nlists);
			free((void *)stringTable);
		}
		
		commandOffset += loadCommand.cmdsize;
	}
	
	free(commands);
	
	(info.symbols) = symbols;
	
	return info;
}

- (SymbolistBinaryListerMachOInfo *)processMachOHeader64Bit:(off_t)offset
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
	
	DebugLog(@"Processing mach header; %@.", swapFlag ? @"did swap" : @"didn't swap");
	DebugLog(@"Has %@ commands;", @(header.ncmds));
	
	SymbolistBinaryListerMachOInfo *info = [SymbolistBinaryListerMachOInfo new];
	(info.cpuType) = header.cputype;
	(info.cpuSubtype) = header.cpusubtype;
	
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
		if (swapFlag) {
			swap_load_command(&loadCommand, NXHostByteOrder());
		}
		
		if (loadCommand.cmd == LC_SYMTAB)
		{
#if TESTING
			DebugLog(@"LC_SYMTAB at %lld", offset);
#endif
			struct symtab_command symtabCommand = *(struct symtab_command *)commandPtr;
			if (swapFlag)
				swap_symtab_command(&symtabCommand, NXHostByteOrder());
			
#if TESTING
			DebugLog(@"string table offset:%u size:%u", symtabCommand.stroff, symtabCommand.strsize);
#endif
			if (!symbols) {
				symbols = [NSMutableArray arrayWithCapacity:symtabCommand.nsyms];
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
				//				DebugLog(@"%u %02x", nlist.n_un.n_strx, nlist.n_type);
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
				
			}
			
			free(nlists);
			free((void *)stringTable);
		}
		
		commandOffset += loadCommand.cmdsize;
	}
	
	free(commands);
	
	if (symbols) {
		(info.symbols) = symbols;
	}

	
	return info;
}

- (SymbolistBinaryListerMachOInfo *)processMachOHeader:(off_t)offset
{
	SymbolistBinaryListerMachOInfo *info;
	
	info = [self processMachOHeader32Bit:offset];
	if (info) {
		return info;
	}
	else {
		info = [self processMachOHeader64Bit:offset];
	}
	
	return info;
}

- (BOOL)isFat
{
	return _flags.fatFlag;
}

- (uint32_t)numberOfArchitectures
{
	return _archCount;
}

- (SymbolistBinaryListerMachOInfo *)machOInfoForArchAtIndex:(NSUInteger)index
{
	id<NSObject> info = (self.machOInfos)[index];
	if ([info isKindOfClass:[SymbolistBinaryListerMachOInfo class]]) {
		return info;
	}
	else { // NSNull
		return nil;
	}
}

- (cpu_type_t)cpuTypeForArchAtIndex:(uint32_t)index
{
	return [self machOInfoForArchAtIndex:index].cpuType;
}

- (cpu_type_t)cpuSubtypeForArchAtIndex:(uint32_t)index
{
	return [self machOInfoForArchAtIndex:index].cpuSubtype;
}

- (NSArray *)symbolsForArchAtIndex:(uint32_t)index
{
	return [self machOInfoForArchAtIndex:index].symbols;
}

- (ssize_t)readBytes:(void *)buffer length:(size_t)length offset:(off_t)offset
{
#if TESTING
	CFAbsoluteTime t = CFAbsoluteTimeGetCurrent();
	ssize_t size = pread(_fd, buffer, length, offset);
	printf("%f seconds to read %zu bytes.\n", CFAbsoluteTimeGetCurrent() - t, length);
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
