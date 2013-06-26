//
//  SREnvironmentHelper.m
//  SRConditionsWatcher
//
//  Created by Romain Champourlier on 18/06/13.
//  Copyright (c) 2013 softRli. All rights reserved.
//

//  SREnvironmentHelper provides an interface to access iOS
//  often used environment items, such as the information from
//  the main bundle, version numbers, or main directories.
//
//  The SREnvironmentHelper is nice as a dependency-injection
//  to ease Unit Testing.

#import "SRCWEnvironmentHelper.h"

@implementation SRCWEnvironmentHelper

- (NSString *)currentVersion
{
  return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

- (NSURL *)documentDirectoryURL
{
  NSArray *URLs = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
  NSURL *documentDirectoryURL = URLs.count > 0 ? URLs[0] : nil;
  return documentDirectoryURL;
}

- (NSDate*)now
{
  return [NSDate date];
}

@end
