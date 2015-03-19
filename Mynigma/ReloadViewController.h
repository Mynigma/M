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





#import <Foundation/Foundation.h>

@interface ReloadViewController : NSObject

@property NSMutableSet* busyFolders;

@property BOOL isReloading;

@property BOOL showSmallHeight;

@property BOOL showError;

@property BOOL showSuccess;

@property BOOL canReload;

@property BOOL isScrolling;

@property NSMutableSet* errorFolders;

@property NSString* errorMessage;

@property NSInteger pullIndex;

- (void)startReloading;

- (void)stopReloadingAndScrollOutOfView;

- (void)resetScrollPoint;


- (void)startReloadingAnimated:(BOOL)animated;

- (void)stopReloadingAndScrollOutOfViewAnimated:(BOOL)animated;

- (void)resetScrollPointAnimated:(BOOL)animated;

- (void)resetScrollPointAnimated:(BOOL)animated withCallback:(void(^)(void))callback;


- (void)showSuccessFeedback;


- (void)doneCheckingFolder:(NSManagedObjectID*)folderID;

- (void)errorCheckingFolder:(NSManagedObjectID*)folderID;

- (void)startedCheckingFolder:(NSManagedObjectID*)folderID;

@end
