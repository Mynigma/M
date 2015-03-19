//
//  ContactGroup.h
//  BlueBird
//
//  Created by Roman Priebe on 04/07/2013.
//  Copyright (c) 2013 Mynigma. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Contact;

@interface ContactGroup : NSManagedObject

@property (nonatomic, retain) NSDate * dateLastContacted;
@property (nonatomic, retain) NSString * groupName;
@property (nonatomic, retain) Contact *memberContacts;

@end
