//
//  SRConditionsWatcherTests.m
//  SRConditionsWatcherTests
//
//  Created by Romain Champourlier on 18/06/13.
//  Copyright (c) 2013 softRli. All rights reserved.
//

#import "SRConditionsWatcherTests.h"
#import "SRConditionsWatcher.h"
#import <OCMock/OCMock.h>

static NSString const * kFileName = @"SRConditionsWatcherState.plist";

@interface SRConditionsWatcherTests () {
  SRConditionsWatcher *_watcher;
}
@end

@implementation SRConditionsWatcherTests


#pragma mark - Helpers

- (NSString *)helperTestConditionName
{
  return @"testCondition";
}

- (void)helperTestConditionCountTriggeredAdd
{
  [_watcher addCondition:self.helperTestConditionName
                    type:SRCWConditionTypeCountTriggered
                 options:nil block:^{}];
}
- (void)helperTestConditionVersionChangeAdd
{
  [_watcher addCondition:self.helperTestConditionName
                    type:SRCWConditionTypeVersionChange
                 options:nil block:^{}];
}

- (void)helperTestConditionTriggerAndEvaluate
{
  [self helperTestConditionTrigger];
  [self helperTestConditionEvaluate];
}

- (void)helperTestConditionTrigger
{
  [_watcher triggerCondition:self.helperTestConditionName];
}

- (void)helperTestConditionEvaluate
{
  [_watcher evaluateCondition:self.helperTestConditionName];
}

- (NSURL *)helperDocumentDirectoryURL
{
  NSArray *URLs = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
  NSURL *helperDocumentDirectoryURL = URLs.count > 0 ? URLs[0] : nil;
  return helperDocumentDirectoryURL;
}

- (NSString *)helperTestFilePath
{
  return [self.helperDocumentDirectoryURL URLByAppendingPathComponent:[kFileName copy]].path;
}


#pragma mark - Setup/teardown

- (void)setUp
{
  [super setUp];
  
  _watcher = [[SRConditionsWatcher alloc] init];
  BOOL result = [[NSFileManager defaultManager] createDirectoryAtURL:self.helperDocumentDirectoryURL
                                         withIntermediateDirectories:YES
                                                          attributes:nil
                                                               error:nil];
  NSAssert(result, @"Could not create document directory");
}

- (void)tearDown
{
  BOOL result = [[NSFileManager defaultManager] removeItemAtURL:self.helperDocumentDirectoryURL error:nil];
  NSAssert(result, @"Could not remove document directory");

  [super tearDown];
}

#pragma mark - #init

- (void)testInitDontThrowIfStateFileDoesntExist
{
  STAssertNoThrow({
    [[SRConditionsWatcher alloc] init];
  }, @"should not throw exception if the state file doesn't exist");
}


#pragma mark - #addCondition

- (void)testAddConditionShouldRaiseExceptionIfNoBlock
{
  SRConditionsWatcher *watcher = [[SRConditionsWatcher alloc] init];
  STAssertThrows({
    [watcher addCondition:self.helperTestConditionName
                     type:SRCWConditionTypeCountTriggered
                  options:nil
                    block:nil];
  }, @"should throw an exception when adding a condition with no block");
}


#pragma mark - #triggerCondition

- (void)testTriggerConditionShouldNotThrowExceptionInNormalCase
{
  [self helperTestConditionCountTriggeredAdd];
  STAssertNoThrow({
    [self helperTestConditionTrigger];
  }, @"#triggerCondition should not raise an exception in normal case");
}

- (void)testTriggerConditionShouldReturnTrue
{
  [self helperTestConditionCountTriggeredAdd];
  STAssertTrue([_watcher triggerCondition:self.helperTestConditionName], @"#triggerCondition should return true in normal case");
}

- (void)testTriggerConditionShouldCreateTheStateFile
{
  [self helperTestConditionCountTriggeredAdd];
  [self helperTestConditionTrigger];
  
  STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:self.helperTestFilePath], @"State file not created after triggering a conditionCountTriggered condition");
}

- (void)testTriggerConditionShouldRaiseExceptionIfTriggeringNotTriggerableCondition
{
  [self helperTestConditionVersionChangeAdd];

  STAssertThrows({
    [self helperTestConditionTrigger];
  }, @"should throw an exception if the condition is not triggerable");
}


#pragma mark - #evaluateCondition

- (void)testEvaluateConditionCountTriggeredShouldActivateOnExactCountOnly
{
  __block NSUInteger blockRunCount = 0;
  [_watcher addCondition:self.helperTestConditionName
                    type:SRCWConditionTypeCountTriggered
                 options:@{SRCWConditionOptionCountExact: @(5)}
                   block:^{
                     blockRunCount++;
                   }];

  for (int i = 0; i < 4; i++) {
    [self helperTestConditionTriggerAndEvaluate];
  }
  STAssertTrue(blockRunCount == 0, @"Condition should not have been activated before being triggered the <option exact value> number of times");
  
  [self helperTestConditionTriggerAndEvaluate];
  STAssertTrue(blockRunCount == 1, @"Condition should have been activated once triggered the <option exact value> number of times");
  
  for (int i = 0; i < 20; i++) {
    [self helperTestConditionTriggerAndEvaluate];
  }
  STAssertTrue(blockRunCount == 1, @"Condition should not be activated after having been triggered the <option exact value> number of times");
}

- (void)testEvaluateConditionCountTriggeredShouldActivateOnModuloCounts
{
  __block NSUInteger blockRunCount = 0;
  [_watcher addCondition:self.helperTestConditionName
                    type:SRCWConditionTypeCountTriggered
                 options:@{SRCWConditionOptionCountModulo: @(2)}
                   block:^{
                     blockRunCount++;
                   }];
  
  [self helperTestConditionTriggerAndEvaluate];
  STAssertTrue(blockRunCount == 0, @"Condition should not have been activated before triggered the <option modulo value> number of times");

  [self helperTestConditionTriggerAndEvaluate];
  STAssertTrue(blockRunCount == 1, @"Condition should have been activated once for the first modulo count of times");
  
  for (int i = 0; i < 20; i++) {
    [self helperTestConditionTriggerAndEvaluate];
  }
  STAssertTrue(blockRunCount == 11, @"Condition should have been activated each <modulo> number of times it was triggered");
}

- (void)testEvaluateConditionVersionChangeShouldActivateIfVersionIsDifferentFromState
{
  
}

- (void)testEvaluateConditionVersionChangeShouldNotActivateIfVersionIsSameAsState
{
  
}

- (void)testEvaluateConditionWithLimitOnMaxActivationCountShouldNotActivateIfVerifiedButLimitReached
{
  
}

- (void)testEvaluateConditionWithLimitOnMaxActivationCountShouldActivateIfVerifiedAndLimitNotReached
{
  
}


#pragma mark - #evaluationCondition:block

- (void)testEvaluateConditionBlockShouldRunThePassedBlockInsteadOfTheConditionOne
{
  __block NSUInteger conditionBlockRunCount = 0;
  __block NSUInteger passedBlockRunCount = 0;
  void (^conditionBlock)(void) = ^{ conditionBlockRunCount++; };
  void (^passedBlock)(void) = ^{ passedBlockRunCount++; };
  
  [_watcher addCondition:self.helperTestConditionName
                    type:SRCWConditionTypeCountTriggered
                 options:@{SRCWConditionOptionCountExact: @(1)}
                   block:conditionBlock];
  
  [self helperTestConditionTrigger];
  [_watcher evaluateCondition:self.helperTestConditionName block:passedBlock];
  
  STAssertTrue(conditionBlockRunCount == 0, @"Should not have run the condition's block on evaluation");
  STAssertTrue(passedBlockRunCount == 1, @"Should have run the passed block on evaluation");
}

@end
