//
//  SymbolistRuntimeLister.h
//  Symbolist
//
//  Created by Patrick Smith on 3/01/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "SymbolistRuntimeEntry.h"
#import <objc/objc-class.h>
#import <objc/objc-runtime.h>
#import <objc/Protocol.h>
#import "SymbolistInfoView.h"


@protocol SymbolistRuntimeListerDelegate;

enum {
	SymbolistTypeObject,
	SymbolistTypeStruct,
	SymbolistTypeOther
};


@interface SymbolistRuntimeLister : NSObject
{
	SymbolistRuntimeEntry *_searchEntry;
	id _searchObject;
	NSString *_filterString;
	CFMutableArrayRef _classMethods;
	CFMutableArrayRef _instanceMethods;
	CFArrayRef _instanceVariables;
	CFArrayRef _classProtocols;
	CFMutableDictionaryRef _typeFormats;
	
	NSRange _attributeRange;
	NSMutableDictionary *_attributeBuffer;
	
	id<SymbolistRuntimeListerDelegate> _delegate;
}

+ (NSArray *)classNames;
+ (Class)classForName:(NSString *)name;

+ (NSArray *)protocolNames;
+ (Protocol *)protocolForName:(NSString *)name;

- (void)setDelegate:(id<SymbolistRuntimeListerDelegate>)anObject;
- (id<SymbolistRuntimeListerDelegate>)delegate;

- (void)setSearchEntry:(SymbolistRuntimeEntry *)entry;
- (SymbolistRuntimeEntry *)searchEntry;

- (void)setFilterString:(NSString *)string;
- (NSString *)filterString;

- (id)searchObject;

- (BOOL)loadSearchResults;

- (void)appendInterfaceToAttributedString:(NSMutableAttributedString *)attrString attributes:(NSDictionary *)attrs;

- (void)appendTypeInterfaceToAttributedString:(NSMutableAttributedString *)attrString;

- (void)loadMethodsForClass:(Class)class intoArray:(CFMutableArrayRef)array;
- (void)loadMethodsForMethodDescriptions:(NSData *)methodDescriptionsPointerData intoArray:(CFMutableArrayRef)array;

- (void)appendMethodsList:(CFArrayRef)methods toAttributedString:(NSMutableAttributedString *)attrString isMetaclass:(BOOL)meta;
- (void)appendMethod:(Method)method toAttributedString:(NSMutableAttributedString *)attrString isMeta:(BOOL)meta;
- (void)appendType:(const char *)type toAttributedString:(NSMutableAttributedString *)attrString;

@end

@protocol SymbolistRuntimeListerDelegate

- (NSDictionary *)userPrefsForLister:(SymbolistRuntimeLister *)lister;

@end
