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

#import "KeyListController.h"
#import "GenericPublicKey+Category.h"
#import "MynigmaPublicKey+Category.h"
#import "PGPPublicKey+Category.h"
#import "SMIMEPublicKey+Category.h"
#import "KeyListTableViewCell.h"
#import "MynigmaPrivateKey+Category.h"




@interface KeyListController ()

@end

@implementation KeyListController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.dataArray = [GenericPublicKey listAllPublicKeyLabels];
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary* dataObject = self.dataArray[indexPath.row];

    NSString* keyLabel = [dataObject objectForKey:@"keyLabel"];

    NSString* reuseIdentifier = @"keyCellPGP";

    if([MynigmaPublicKey havePublicKeyWithLabel:keyLabel])
        reuseIdentifier = @"keyCellMynigma";
    else if([SMIMEPublicKey havePublicKeyWithLabel:keyLabel])
        reuseIdentifier = @"keyCellSMIME";


    KeyListTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    BOOL isCurrentKey = [MynigmaPublicKey isKeyWithLabelCurrentKeyForSomeEmailAddress:keyLabel];
    
    [cell.nameLabel setText:[NSString stringWithFormat:@"%@%@%@", isCurrentKey?@"c ":@"", [MynigmaPrivateKey havePrivateKeyWithLabel:keyLabel]?@"p ":@"", keyLabel]];
    
    [cell.fingerprintLabel setText:[NSString stringWithFormat:@"Fingerprint: %@", [MynigmaPublicKey fingerprintForKeyWithLabel:keyLabel]]];
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
