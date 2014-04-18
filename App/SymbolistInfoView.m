#import "SymbolistInfoView.h"

@implementation SymbolistInfoView

- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect])) {
		_radius = 16.0;
		[self setBordered:YES];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
	if ((self = [super initWithCoder:coder])) {
		_radius = 16.0;
		[self setBordered:YES];
	}
	return self;
}

- (BOOL)isOpaque
{
	return NO;
}

- (void)drawRect:(NSRect)rect
{
	float lineWidth = 2.0;
	
	CGContextRef c = [[NSGraphicsContext currentContext] graphicsPort];
	NSRect frame = [self frame];
	float radius;
	
	if ([self isBordered]) {
		frame.size.width -= 2 * lineWidth;
		frame.size.height -= 2 * lineWidth;
		
		radius = fminf(fminf(_radius, frame.size.height / 2), frame.size.width / 2);
		
		CGContextTranslateCTM(c, lineWidth, lineWidth);
		CGContextBeginPath(c);
		CGContextAddArc(c, radius, radius, radius, M_PI, 3 * M_PI_2, 0);
		CGContextAddArc(c, frame.size.width - radius, radius, radius, 3 * M_PI_2, 0.0, 0);
		CGContextAddArc(c, frame.size.width - radius, frame.size.height - radius, radius, 0.0, M_PI_2, 0);
		CGContextAddArc(c, radius, frame.size.height - radius, radius, M_PI_2, M_PI, 0);
		CGContextClosePath(c);
		[[NSColor colorWithCalibratedWhite:1.0 alpha:1.0] setFill];
		[[NSColor colorWithCalibratedWhite:0.0 alpha:0.875] setStroke];
		CGContextSetLineWidth(c, lineWidth);
		CGContextDrawPath(c, kCGPathFillStroke);
	}
	else {
		radius = fminf(fminf(_radius, frame.size.height / 2), frame.size.width / 2);
		
		CGContextBeginPath(c);
		CGContextAddArc(c, radius, radius, radius, M_PI, 3 * M_PI_2, 0);
		CGContextAddArc(c, frame.size.width - radius, radius, radius, 3 * M_PI_2, 0.0, 0);
		CGContextAddArc(c, frame.size.width - radius, frame.size.height - radius, radius, 0.0, M_PI_2, 0);
		CGContextAddArc(c, radius, frame.size.height - radius, radius, M_PI_2, M_PI, 0);
		CGContextClosePath(c);
		[[NSColor colorWithCalibratedWhite:1.0 alpha:1.0] setFill];
		CGContextFillPath(c);
	}
}

- (void)setBordered:(BOOL)flag
{
	if (flag != _bordered) {
		_bordered = flag;
		[self setNeedsDisplay:YES];
	}
}

- (BOOL)isBordered
{
	return _bordered;
}

@end
