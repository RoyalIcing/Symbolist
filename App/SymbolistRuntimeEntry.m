//
//  SymbolistRuntimeEntry.m
//  Symbolist
//
//  Created by Patrick Smith on 2/01/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "SymbolistRuntimeEntry.h"


@interface SymbolistRuntimeEntry ()

@property (readwrite, copy, nonatomic) NSString *name;

@end

@implementation SymbolistRuntimeEntry

+ (id)entryWithName:(NSString *)name mode:(unsigned int)mode
{
	return [[self alloc] initWithName:name mode:mode];
}

- (id)initWithName:(NSString *)name mode:(unsigned int)mode
{
	self = [super init];
	if (self) {
		(self.name) = name;
		_mode = mode;
	}
	return self;
}

- (unsigned int)mode
{
	return _mode;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ name:\"%@\" mode:%u", [super description], (self.name), [self mode]];
}

@end
