//
//  SymbolistRuntimeEntry.h
//  Symbolist
//
//  Created by Patrick Smith on 2/01/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


enum {
	SymbolistRuntimeModeClass,
	SymbolistRuntimeModeProtocol
};

@interface SymbolistRuntimeEntry : NSObject
{
	NSString *_name;
	unsigned int _mode;
}

+ (id)entryWithName:(NSString *)name mode:(unsigned int)mode;

- (id)initWithName:(NSString *)name mode:(unsigned int)mode;

@property (readonly, copy, nonatomic) NSString *name;

- (unsigned int)mode;

@end
