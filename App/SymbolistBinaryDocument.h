//
//  SymbolistBinaryDocument.h
//  Symbolist
//
//  Created by Patrick Smith on 7/05/07.
//  Copyright __MyCompanyName__ 2007 . All rights reserved.
//


#import <Cocoa/Cocoa.h>

#import "SymbolistBinaryLister.h"
#import "SymbolistBinaryError.h"

@interface SymbolistBinaryDocument : NSDocument
{
	IBOutlet NSTableView *_table;
	IBOutlet NSPopUpButton *archPopup;
	IBOutlet NSSearchField *searchField;
	IBOutlet NSTextField *itemCountField;
	IBOutlet NSArrayController *symbolsController;
	
	SymbolistBinaryLister *symbolLister;
	unsigned long selectedArch;
	NSArray *_architectures;
	NSMutableArray *_symbols;
	
	NSString *_searchString;
}

- (NSArray *)symbols;
- (NSArray *)symbolNames;

- (void)setSelectedArch:(unsigned long)arch;
- (unsigned long)selectedArch;

- (NSArray *)architectures;

- (void)setupToolbar;
- (void)filterSearchResults;

- (IBAction)changeSearchString:(id)sender;

- (IBAction)focusSearch:(id)sender;

@end
