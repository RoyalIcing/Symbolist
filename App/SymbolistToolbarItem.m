//
//  SymbolistToolbarItem.m
//  Browser
//
//  Created by Patrick Smith on 12/11/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SymbolistToolbarItem.h"


@implementation SymbolistToolbarItem

- (void)validate
{
	[NSApp sendAction:@selector(validateToolbarItem:) to:[self target] from:self];
}

@end
