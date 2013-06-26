//
//  SREnvironmentHelper.h
//  SRConditionsWatcher
//
//  Created by Romain Champourlier on 18/06/13.
//  Copyright (c) 2013 softRli. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SRCWEnvironmentHelper : NSObject

- (NSString*)currentVersion;
- (NSURL*)documentDirectoryURL;
- (NSDate*)now;

@end
