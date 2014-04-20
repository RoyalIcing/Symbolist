//
//  SymbolistRuntimeDocument.h
//  Symbolist
//
//  Created by Patrick Smith on 19/11/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "SymbolistRuntimeLister.h"
#import "SymbolistRuntimeEntry.h"

#import "SymbolistInfoView.h"


@interface SymbolistRuntimeDocument : NSDocument <SymbolistRuntimeListerDelegate, NSTextViewDelegate, NSToolbarDelegate, NSAnimationDelegate>
{
	SymbolistRuntimeLister *_lister;
	NSString *_searchString;
	unsigned int _searchMode;
	
	NSMutableDictionary *_userPrefs;
	
	NSMutableDictionary *_structNames;
	CFMutableDictionaryRef _structPointerCount;
	
	const char *_structType;
	
	NSString *_filterString;
	NSMutableArray *_filteredClassNames;
	NSMutableArray *_filteredProtocolNames;
	
	NSMutableArray *_historyBack;
	NSMutableArray *_historyForward;
	
	NSToolbar *_toolbar;
	IBOutlet NSPopUpButton *_typePopup;
	IBOutlet NSComboBox *_searchField;
	IBOutlet NSSegmentedControl *_navigationControl;
	
	IBOutlet NSTextView *_textView;
	
	IBOutlet NSView *_filterBarView;
	IBOutlet NSTextField *_filterField;
	NSViewAnimation *_filterBarAnimation;
	BOOL _isFilterBarVisible;
	
	IBOutlet SymbolistInfoView *_structInfoView;
	IBOutlet NSTextView *_structTextView;
	
	NSString *_oldSearchString;
	BOOL _advancedSearchFlag;
}

- (void)setSearchString:(NSString *)string;
- (NSString *)searchString;

- (void)setSearchMode:(unsigned int)mode;
- (unsigned int)searchMode;

- (void)setupToolbar;

- (BOOL)updateSearch:(BOOL)addOldToHistory;
- (BOOL)loadSearchResults;
- (void)clear;

- (void)filterSearchCompletes:(NSString *)filter;

- (void)gotoHistoryIndex:(unsigned long)index goBack:(BOOL)back;

- (IBAction)goBack:(id)sender;
- (IBAction)goForward:(id)sender;
- (BOOL)canGoBack;
- (BOOL)canGoForward;

- (IBAction)navigate:(id)sender;
- (IBAction)changeMode:(id)sender;
- (IBAction)search:(id)sender;
- (IBAction)filter:(id)sender;

- (IBAction)showInfoView:(id)sender;
- (IBAction)hideInfoView:(id)sender;

- (IBAction)showFilterBar:(id)sender;
- (IBAction)hideFilterBar:(id)sender;

- (IBAction)focusSearch:(id)sender;

- (NSRect)adjustedInfoWindowFrame;

@end
