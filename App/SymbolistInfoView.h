/* SymbolistInfoView */

#import <Cocoa/Cocoa.h>

@interface SymbolistInfoView : NSView
{
	float _radius;
	BOOL _bordered;
}

- (void)setBordered:(BOOL)flag;
- (BOOL)isBordered;

@end
