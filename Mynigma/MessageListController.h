//
//	Copyright © 2012 - 2015 Roman Priebe
//
//	This file is part of M - Safe email made simple.
//
//	M is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	M is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
//	along with M.  If not, see <http://www.gnu.org/licenses/>.
//





#import <Cocoa/Cocoa.h>

#define RELOAD_HEIGHT_SMALL 42
#define RELOAD_HEIGHT_LARGE 72

@class SendCellView, EmailMessageInstance;

@interface MessageListController : NSViewController <NSTableViewDataSource, NSTableViewDelegate, NSPasteboardItemDataProvider>
{
    SendCellView* sendCellViewForSizing;
    NSInteger draggedMessageIndex;
}

- (void)tableView:(NSTableView *)tableView updateDraggingItemsForDrag:(id < NSDraggingInfo >)draggingInfo;
- (IBAction)doubleClick:(id)sender;
- (IBAction)deleteSelectedMessages:(id)sender;

/**Moves the selection on by one to prepare, for example, for a delete of the current selection, after which the next message in the list should be selected*/
- (void)moveSelectionOnFromMessageObject:(NSObject*)messageObject;

- (void)selectRowAtIndex:(NSInteger)index;


@end
