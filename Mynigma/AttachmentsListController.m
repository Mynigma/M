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





#import "AttachmentsListController.h"
#import "AttachmentsListCell.h"
#import "FileAttachment+Category.h"



@interface AttachmentsListController ()

@end

@implementation AttachmentsListController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    self.tableView.delegate = self;
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.attachments.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AttachmentsListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"attachmentCell" forIndexPath:indexPath];

    if(indexPath.row>=0 && indexPath.row < self.attachments.count && indexPath.row < self.documentInteractionControllers.count)
    {
        FileAttachment* attachment = self.attachments[indexPath.row];

        UIDocumentInteractionController* interactionController = self.documentInteractionControllers[indexPath.row];

        [cell configureWithAttachment:attachment andDocumentInteractionController:interactionController];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

- (void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{

}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 73;
}

- (void)setupWithAttachments:(NSArray*)newAttachments
{
    self.attachments = newAttachments;

    NSMutableArray* newDocumentInteractionControllers = [NSMutableArray new];

    for(FileAttachment* attachment in newAttachments)
    {
        NSURL* attachmentURL = [attachment privateURL];

        BOOL setFileName = NO;

        if(!attachmentURL)
        {
            setFileName = YES;
            attachmentURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"~/%@", attachment.fileName]];
        }

        UIDocumentInteractionController* interactionController = [UIDocumentInteractionController interactionControllerWithURL:attachmentURL];

        if(setFileName)
            [interactionController setName:attachment.fileName];

        interactionController.delegate = self;

        [newDocumentInteractionControllers addObject:interactionController];
    }

    self.documentInteractionControllers = newDocumentInteractionControllers;

    [self.tableView reloadData];
}

@end
