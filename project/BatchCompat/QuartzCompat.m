#import <Foundation/Foundation.h>
#include <stdio.h>

@interface QLSeamlessOpener : NSObject
@end

@implementation QLSeamlessOpener
+ (id)seamlessOpenerWithDelegate:(id)delegate { (void)delegate; return [[[self alloc] init] autorelease]; }
- (id)seamlessOpenerWithDelegate:(id)delegate { (void)delegate; return self; }
- (void)openLocalItems:(id)items { (void)items; }
- (void)openItems:(id)items { (void)items; }
- (int)openItemsSynchronously:(id)items { (void)items; return 0; }
- (void)beginShowingTransientWindow {}
- (void)endShowingTransientWindowShouldAnimate:(BOOL)animate { (void)animate; }
- (void)setApplicationURL:(id)value { (void)value; }
- (id)applicationURL { return nil; }
- (void)setSearchString:(id)value { (void)value; }
- (id)searchString { return nil; }
- (void)setDelegate:(id)value { (void)value; }
- (id)delegate { return nil; }
- (void)setCloserDelegate:(id)value { (void)value; }
- (id)closerDelegate { return nil; }
- (void)setLaunchFlags:(unsigned int)value { (void)value; }
- (unsigned int)launchFlags { return 0; }
@end

__attribute__((constructor))
static void ILRQuartzCompatInit(void) { fprintf(stderr,"[QuartzCompat] loaded\n"); }
