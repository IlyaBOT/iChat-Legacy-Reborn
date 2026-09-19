#import <AppKit/AppKit.h>
#include <stdio.h>

/*
 * Narrow Lion AppKit ABI compatibility layer for Snow Leopard.
 * Only symbols observed in the iChat 6 runtime audit belong here.
 */

@interface NSTableCellView : NSView
{
    id _ilrObjectValue;
    NSTextField *_ilrTextField;
    NSImageView *_ilrImageView;
    NSInteger _ilrBackgroundStyle;
    NSInteger _ilrRowSizeStyle;
}
- (id)objectValue;
- (void)setObjectValue:(id)value;
- (NSTextField *)textField;
- (void)setTextField:(NSTextField *)value;
- (NSImageView *)imageView;
- (void)setImageView:(NSImageView *)value;
- (NSInteger)backgroundStyle;
- (void)setBackgroundStyle:(NSInteger)value;
- (NSInteger)rowSizeStyle;
- (void)setRowSizeStyle:(NSInteger)value;
- (NSArray *)draggingImageComponents;
@end

@implementation NSTableCellView
- (void)dealloc { [_ilrObjectValue release]; [_ilrTextField release]; [_ilrImageView release]; [super dealloc]; }
- (id)objectValue { return _ilrObjectValue; }
- (void)setObjectValue:(id)value { if (_ilrObjectValue != value) { [_ilrObjectValue release]; _ilrObjectValue=[value retain]; } }
- (NSTextField *)textField { return _ilrTextField; }
- (void)setTextField:(NSTextField *)value { if (_ilrTextField != value) { [_ilrTextField removeFromSuperview]; [_ilrTextField release]; _ilrTextField=[value retain]; if (_ilrTextField) [self addSubview:_ilrTextField]; } }
- (NSImageView *)imageView { return _ilrImageView; }
- (void)setImageView:(NSImageView *)value { if (_ilrImageView != value) { [_ilrImageView removeFromSuperview]; [_ilrImageView release]; _ilrImageView=[value retain]; if (_ilrImageView) [self addSubview:_ilrImageView]; } }
- (NSInteger)backgroundStyle { return _ilrBackgroundStyle; }
- (void)setBackgroundStyle:(NSInteger)value { _ilrBackgroundStyle=value; }
- (NSInteger)rowSizeStyle { return _ilrRowSizeStyle; }
- (void)setRowSizeStyle:(NSInteger)value { _ilrRowSizeStyle=value; }
- (NSArray *)draggingImageComponents { return [NSArray array]; }
@end

@interface NSTableRowView : NSView
{
    NSMutableArray *_ilrColumnViews;
    NSColor *_ilrBackgroundColor;
    NSInteger _ilrSelectionHighlightStyle;
    NSInteger _ilrDraggingDestinationFeedbackStyle;
    CGFloat _ilrDropOperationIndentation;
    CGFloat _ilrSelectionAlpha;
    BOOL _ilrSelected;
    BOOL _ilrEmphasized;
    BOOL _ilrGroupRowStyle;
    BOOL _ilrFloating;
}
- (NSInteger)numberOfColumns;
- (NSView *)viewAtColumn:(NSInteger)column;
- (void)setView:(NSView *)view atColumn:(NSInteger)column;
- (void)insertColumnAtIndex:(NSInteger)column;
- (void)removeColumnAtIndex:(NSInteger)column;
- (BOOL)isSelected;
- (void)setSelected:(BOOL)value;
- (BOOL)isEmphasized;
- (void)setEmphasized:(BOOL)value;
- (BOOL)isGroupRowStyle;
- (void)setGroupRowStyle:(BOOL)value;
- (BOOL)isFloating;
- (void)setFloating:(BOOL)value;
- (NSColor *)backgroundColor;
- (void)setBackgroundColor:(NSColor *)value;
- (NSInteger)selectionHighlightStyle;
- (void)setSelectionHighlightStyle:(NSInteger)value;
- (NSInteger)draggingDestinationFeedbackStyle;
- (void)setDraggingDestinationFeedbackStyle:(NSInteger)value;
- (CGFloat)indentationForDropOperation;
- (void)setIndentationForDropOperation:(CGFloat)value;
- (CGFloat)selectionAlpha;
- (void)setSelectionAlpha:(CGFloat)value;
- (NSInteger)interiorBackgroundStyle;
- (void)drawBackgroundInRect:(NSRect)dirtyRect;
- (void)drawSelectionInRect:(NSRect)dirtyRect;
- (void)drawSeparatorInRect:(NSRect)dirtyRect;
- (void)drawDraggingDestinationFeedbackInRect:(NSRect)dirtyRect;
@end

@implementation NSTableRowView
- (id)initWithFrame:(NSRect)frame { if ((self=[super initWithFrame:frame])) { _ilrColumnViews=[[NSMutableArray alloc] init]; _ilrSelectionAlpha=1.0; } return self; }
- (id)initWithCoder:(NSCoder *)coder { if ((self=[super initWithCoder:coder])) { _ilrColumnViews=[[NSMutableArray alloc] init]; _ilrSelectionAlpha=1.0; } return self; }
- (void)dealloc { [_ilrColumnViews release]; [_ilrBackgroundColor release]; [super dealloc]; }
- (NSInteger)numberOfColumns { return [_ilrColumnViews count]; }
- (NSView *)viewAtColumn:(NSInteger)column { return (column>=0 && column<(NSInteger)[_ilrColumnViews count]) ? [_ilrColumnViews objectAtIndex:(NSUInteger)column] : nil; }
- (void)setView:(NSView *)view atColumn:(NSInteger)column { if (column<0) return; while ((NSInteger)[_ilrColumnViews count]<=column) [_ilrColumnViews addObject:[NSNull null]]; id old=[_ilrColumnViews objectAtIndex:(NSUInteger)column]; if (old!=[NSNull null] && old!=view) [old removeFromSuperview]; [_ilrColumnViews replaceObjectAtIndex:(NSUInteger)column withObject:(view ? (id)view : (id)[NSNull null])]; if (view && [view superview]!=self) [self addSubview:view]; }
- (void)insertColumnAtIndex:(NSInteger)column { if (column<0) return; NSUInteger i=(NSUInteger)MIN(column,(NSInteger)[_ilrColumnViews count]); [_ilrColumnViews insertObject:[NSNull null] atIndex:i]; }
- (void)removeColumnAtIndex:(NSInteger)column { if (column<0 || column>=(NSInteger)[_ilrColumnViews count]) return; id v=[_ilrColumnViews objectAtIndex:(NSUInteger)column]; if (v!=[NSNull null]) [v removeFromSuperview]; [_ilrColumnViews removeObjectAtIndex:(NSUInteger)column]; }
- (BOOL)isSelected { return _ilrSelected; }
- (void)setSelected:(BOOL)value { _ilrSelected=value; [self setNeedsDisplay:YES]; }
- (BOOL)isEmphasized { return _ilrEmphasized; }
- (void)setEmphasized:(BOOL)value { _ilrEmphasized=value; [self setNeedsDisplay:YES]; }
- (BOOL)isGroupRowStyle { return _ilrGroupRowStyle; }
- (void)setGroupRowStyle:(BOOL)value { _ilrGroupRowStyle=value; }
- (BOOL)isFloating { return _ilrFloating; }
- (void)setFloating:(BOOL)value { _ilrFloating=value; }
- (NSColor *)backgroundColor { return _ilrBackgroundColor; }
- (void)setBackgroundColor:(NSColor *)value { if (_ilrBackgroundColor!=value) { [_ilrBackgroundColor release]; _ilrBackgroundColor=[value retain]; } [self setNeedsDisplay:YES]; }
- (NSInteger)selectionHighlightStyle { return _ilrSelectionHighlightStyle; }
- (void)setSelectionHighlightStyle:(NSInteger)value { _ilrSelectionHighlightStyle=value; }
- (NSInteger)draggingDestinationFeedbackStyle { return _ilrDraggingDestinationFeedbackStyle; }
- (void)setDraggingDestinationFeedbackStyle:(NSInteger)value { _ilrDraggingDestinationFeedbackStyle=value; }
- (CGFloat)indentationForDropOperation { return _ilrDropOperationIndentation; }
- (void)setIndentationForDropOperation:(CGFloat)value { _ilrDropOperationIndentation=value; }
- (CGFloat)selectionAlpha { return _ilrSelectionAlpha; }
- (void)setSelectionAlpha:(CGFloat)value { _ilrSelectionAlpha=value; }
- (NSInteger)interiorBackgroundStyle { return _ilrSelected ? 1 : 0; }
- (void)drawBackgroundInRect:(NSRect)dirtyRect { if (_ilrBackgroundColor) { [_ilrBackgroundColor set]; NSRectFill(dirtyRect); } }
- (void)drawSelectionInRect:(NSRect)dirtyRect { if (_ilrSelected) { [[[NSColor alternateSelectedControlColor] colorWithAlphaComponent:_ilrSelectionAlpha] set]; NSRectFillUsingOperation(dirtyRect,NSCompositeSourceOver); } }
- (void)drawSeparatorInRect:(NSRect)dirtyRect { (void)dirtyRect; }
- (void)drawDraggingDestinationFeedbackInRect:(NSRect)dirtyRect { (void)dirtyRect; }
- (void)drawRect:(NSRect)dirtyRect { [self drawBackgroundInRect:dirtyRect]; [self drawSelectionInRect:dirtyRect]; [super drawRect:dirtyRect]; }
@end

__attribute__((constructor))
static void ILRAppKitCompatInit(void) { fprintf(stderr,"[AppKitCompat] loaded\n"); }
