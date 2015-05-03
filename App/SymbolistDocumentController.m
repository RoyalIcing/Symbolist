//
//  SymbolistDocumentController.m
//  Symbolist
//
//  Created by Patrick Smith on 12/05/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SymbolistDocumentController.h"

#import "SymbolistRuntimeDocument.h"


@implementation SymbolistDocumentController

- (NSString *)defaultType
{
	return @"Runtime";
}

- (NSInteger)runModalOpenPanel:(NSOpenPanel *)openPanel forTypes:(NSArray *)extensions
{
	[openPanel setCanChooseDirectories:YES];
	[openPanel setTreatsFilePackagesAsDirectories:YES];
	
	DebugLog(@"%@", extensions);
	
	return [super runModalOpenPanel:openPanel forTypes:extensions];
}

@end
