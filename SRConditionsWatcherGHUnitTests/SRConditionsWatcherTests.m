//
//  SRConditionsWatcherTests.m
//  SRConditionsWatcherTests
//
//  Created by Romain Champourlier on 18/06/13.
//  Copyright (c) 2013 softRli. All rights reserved.
//

#import "SRConditionsWatcher.h"
#import "SREnvironmentHelper.h"

#import <GHUnitIOS/GHUnit.h>
#import <OCMock/OCMock.h>

static NSString const * kFileName = @"SRConditionsWatcherState.plist";

@interface SRConditionsWatcherTests : GHTestCase { }
@end

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

- (void)helperTestConditionCountLaunchAdd
{
  [_watcher addCondition:self.helperTestConditionName
                    type:SRCWConditionTypeCountLaunch
                 options:nil block:^{}];
}

- (void)helperTestConditionCountReactivationAdd
{
  [_watcher addCondition:self.helperTestConditionName
                    type:SRCWConditionTypeCountReactivation
                 options:nil block:^{}];
}

- (void)helperTestConditionCountOpenAdd
{
  [_watcher addCondition:self.helperTestConditionName
                    type:SRCWConditionTypeCountOpen
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

- (id)mockEnvironmentHelper
{
  SREnvironmentHelper *original = [[SREnvironmentHelper alloc] init];
  id mock = [OCMockObject partialMockForObject:original];
  [[[mock stub] andForwardToRealObject] documentDirectoryURL];
  return mock;
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
  GHAssertNoThrow({
    [[SRConditionsWatcher alloc] init];
  }, @"should not throw exception if the state file doesn't exist");
}


#pragma mark - #addCondition

- (void)testAddConditionShouldRaiseExceptionIfNoBlock
{
  SRConditionsWatcher *watcher = [[SRConditionsWatcher alloc] init];
  GHAssertThrows({
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
  GHAssertNoThrow({
    [self helperTestConditionTrigger];
  }, @"#triggerCondition should not raise an exception in normal case");
}

- (void)testTriggerConditionShouldReturnTrue
{
  [self helperTestConditionCountTriggeredAdd];
  GHAssertTrue([_watcher triggerCondition:self.helperTestConditionName], @"#triggerCondition should return true in normal case");
}

- (void)testTriggerConditionShouldCreateTheStateFile
{
  [self helperTestConditionCountTriggeredAdd];
  [self helperTestConditionTrigger];
  
  GHAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:self.helperTestFilePath], @"State file not created after triggering a conditionCountTriggered condition");
}

- (void)testTriggerConditionShouldRaiseExceptionIfTriggeringVersionChangeCondition
{
  [self helperTestConditionVersionChangeAdd];

  GHAssertThrows({
    [self helperTestConditionTrigger];
  }, @"should throw an exception if the condition is not triggerable");
}

- (void)testTriggerConditionShouldRaiseExceptionIfTriggeringCountLaunchCondition
{
  [self helperTestConditionCountLaunchAdd];
  
  GHAssertThrows({
    [self helperTestConditionTrigger];
  }, @"should throw an exception if the condition is not triggerable");
}

- (void)testTriggerConditionShouldRaiseExceptionIfTriggeringCountOpenCondition
{
  [self helperTestConditionCountOpenAdd];
  
  GHAssertThrows({
    [self helperTestConditionTrigger];
  }, @"should throw an exception if the condition is not triggerable");
}

- (void)testTriggerConditionShouldRaiseExceptionIfTriggeringCountReactivationCondition
{
  [self helperTestConditionCountReactivationAdd];
  
  GHAssertThrows({
    [self helperTestConditionTrigger];
  }, @"should throw an exception if the condition is not triggerable");
}


#pragma mark - #limitCondition

- (void)testLimitConditionShouldPreventActivationOfConditionEvenIfVerified
{
  __block NSUInteger blockRunCount = 0;
  [_watcher addCondition:self.helperTestConditionName
                    type:SRCWConditionTypeCountTriggered
                 options:@{SRCWConditionOptionCountModulo: @(1)}
                   block:^{
                     blockRunCount++;
                   }];
  
  [_watcher limitCondition:self.helperTestConditionName];
  [_watcher triggerCondition:self.helperTestConditionName];
  [_watcher evaluateCondition:self.helperTestConditionName];
  GHAssertTrue(blockRunCount == 0, @"#limitCondition should prevent verified condition from being activated when evaluated");
}

#pragma mark - #unlimitCondition

- (void)testUnlimitConditionShouldRestoreActivationOfCondition
{
  __block NSUInteger blockRunCount = 0;
  [_watcher addCondition:self.helperTestConditionName
                    type:SRCWConditionTypeCountTriggered
                 options:@{SRCWConditionOptionCountModulo: @(1)}
                   block:^{
                     blockRunCount++;
                   }];
  
  [_watcher limitCondition:self.helperTestConditionName];
  [_watcher triggerCondition:self.helperTestConditionName];
  [_watcher evaluateCondition:self.helperTestConditionName];
  GHAssertTrue(blockRunCount == 0, @"#limitCondition should prevent verified condition from being activated when evaluated");
  
  [_watcher unlimitCondition:self.helperTestConditionName];
  [_watcher triggerCondition:self.helperTestConditionName];
  [_watcher evaluateCondition:self.helperTestConditionName];
  GHAssertTrue(blockRunCount == 1, @"#limitCondition should restore activation of previously limited condition");
}


#pragma mark - #triggerLaunch

- (void)testTriggerLaunchShouldIncreaseGlobalConditionsLaunchCount
{
  [_watcher triggerLaunch];
  NSDictionary* state = [NSDictionary dictionaryWithContentsOfFile:self.helperTestFilePath];
  NSUInteger launchCount = ((NSNumber*)[[state valueForKey:@"__GlobalConditions"] valueForKey:@"launchCount"]).unsignedIntValue;

  GHAssertTrue(launchCount == 1, @"should have incremented the global launch count");
}

#pragma mark - #triggerReactivation

- (void)testTriggerReactivationShouldIncreaseTheReactivationCount
{
  [_watcher triggerReactivation];
  NSDictionary* state = [NSDictionary dictionaryWithContentsOfFile:self.helperTestFilePath];
  NSUInteger reactivationCount = ((NSNumber*)[[state valueForKey:@"__GlobalConditions"] valueForKey:@"reactivationCount"]).unsignedIntValue;

  GHAssertTrue(reactivationCount == 1, @"should have incremented the global reactivation count");
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
  GHAssertTrue(blockRunCount == 0, @"Condition should not have been activated before being triggered the <option exact value> number of times");
  
  [self helperTestConditionTriggerAndEvaluate];
  GHAssertTrue(blockRunCount == 1, @"Condition should have been activated once triggered the <option exact value> number of times");
  
  for (int i = 0; i < 20; i++) {
    [self helperTestConditionTriggerAndEvaluate];
  }
  GHAssertTrue(blockRunCount == 1, @"Condition should not be activated after having been triggered the <option exact value> number of times");
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
  GHAssertTrue(blockRunCount == 0, @"Condition should not have been activated before triggered the <option modulo value> number of times");

  [self helperTestConditionTriggerAndEvaluate];
  GHAssertTrue(blockRunCount == 1, @"Condition should have been activated once for the first modulo count of times");
  
  for (int i = 0; i < 20; i++) {
    [self helperTestConditionTriggerAndEvaluate];
  }
  GHAssertTrue(blockRunCount == 11, @"Condition should have been activated each <modulo> number of times it was triggered");
}

- (void)testEvaluateConditionVersionChangeShouldNotActivateOnFirstEvaluation
{
  __block NSUInteger blockRunCount = 0;
  [_watcher addCondition: self.helperTestConditionName
                    type: SRCWConditionTypeVersionChange
                 options: nil
                   block: ^{blockRunCount++;}];
  
  id mockEnvironmentHelper = self.mockEnvironmentHelper;
  _watcher.environmentHelper = mockEnvironmentHelper;
  [[[mockEnvironmentHelper stub] andReturn:@"1.2.3"] currentVersion];
  
  [self helperTestConditionEvaluate];
  GHAssertTrue(blockRunCount == 0, @"Version change condition should not activate the first time it is evaluated");
}

- (void)testEvaluateConditionVersionChangeShouldActivateIfVersionIsDifferentFromState
{
  __block NSUInteger blockRunCount = 0;
  [_watcher addCondition: self.helperTestConditionName
                    type: SRCWConditionTypeVersionChange
                 options: nil
                   block: ^{blockRunCount++;}];
  
  id mockEnvironmentHelper = self.mockEnvironmentHelper;
  _watcher.environmentHelper = mockEnvironmentHelper;
  [[[mockEnvironmentHelper expect] andReturn:@"1.2.3"] currentVersion];
  [self helperTestConditionEvaluate];
  // Evaluating a first time to set the version
  
  [[[mockEnvironmentHelper expect] andReturn:@"1.2.4"] currentVersion];
  [self helperTestConditionEvaluate];

  GHAssertTrue(blockRunCount == 1, @"Version change condition should have activated on version change");
}

- (void)testEvaluateConditionVersionChangeShouldNotActivateIfVersionIsSameAsState
{
  __block NSUInteger blockRunCount = 0;
  [_watcher addCondition: self.helperTestConditionName
                    type: SRCWConditionTypeVersionChange
                 options: nil
                   block: ^{blockRunCount++;}];
  
  id mockEnvironmentHelper = self.mockEnvironmentHelper;
  _watcher.environmentHelper = mockEnvironmentHelper;
  [[[mockEnvironmentHelper expect] andReturn:@"1.2.3"] currentVersion];
  [self helperTestConditionEvaluate];
  
  [[[mockEnvironmentHelper expect] andReturn:@"1.2.3"] currentVersion];
  [self helperTestConditionEvaluate];
  GHAssertTrue(blockRunCount == 0, @"Version change condition should not activate if same as the saved one");
}

- (void)testEvaluationConditionVersionChangeShouldActivateMultipleConditions
{
  __block NSUInteger blockRunCount = 0;
  NSString* condition1Name = [self.helperTestConditionName stringByAppendingFormat:@"_1"];
  NSString* condition2Name = [self.helperTestConditionName stringByAppendingFormat:@"_2"];

  [_watcher addCondition: condition1Name
                    type: SRCWConditionTypeVersionChange
                 options: nil
                   block: ^{blockRunCount++;}];
  
  [_watcher addCondition: condition2Name
                    type: SRCWConditionTypeVersionChange
                 options: nil
                   block: ^{blockRunCount++;}];

  id mockEnvironmentHelper = self.mockEnvironmentHelper;
  _watcher.environmentHelper = mockEnvironmentHelper;

  [[[mockEnvironmentHelper expect] andReturn:@"1.2.3"] currentVersion];
  [_watcher evaluateCondition:condition1Name];
  
  [[[mockEnvironmentHelper expect] andReturn:@"1.2.3"] currentVersion];
  [_watcher evaluateCondition:condition2Name];
  // Evaluating a first time to set the saved version

  [[[mockEnvironmentHelper expect] andReturn:@"1.2.4"] currentVersion];
  [_watcher evaluateCondition:condition1Name];
  
  [[[mockEnvironmentHelper expect] andReturn:@"1.2.4"] currentVersion];
  [_watcher evaluateCondition:condition2Name];

  GHAssertTrue(blockRunCount == 2, @"Version change condition should have been activated for each version change condition");
}

- (void)testEvaluateConditionCountLaunch
{
  __block NSUInteger blockRunCount = 0;
  [_watcher addCondition:self.helperTestConditionName
                    type:SRCWConditionTypeCountLaunch
                 options:@{SRCWConditionOptionCountExact: @(5)}
                   block:^{
                     blockRunCount++;
                   }];
  
  for (int i = 0; i < 4; i++) {
    [_watcher triggerLaunch];
    [self helperTestConditionEvaluate];
  }
  GHAssertTrue(blockRunCount == 0, @"Condition should not have been activated before 5 launches");
  
  [_watcher triggerLaunch];
  [self helperTestConditionEvaluate];
  GHAssertTrue(blockRunCount == 1, @"Condition should have been activated once after 5th launch");
  
  for (int i = 0; i < 20; i++) {
    [_watcher triggerLaunch];
    [self helperTestConditionEvaluate];
  }
  GHAssertTrue(blockRunCount == 1, @"Condition should not be activated after 6th launch");
}

- (void)testEvaluateConditionCountReactivation
{
  __block NSUInteger blockRunCount = 0;
  [_watcher addCondition:self.helperTestConditionName
                    type:SRCWConditionTypeCountReactivation
                 options:@{SRCWConditionOptionCountExact: @(5)}
                   block:^{
                     blockRunCount++;
                   }];
  
  for (int i = 0; i < 4; i++) {
    [_watcher triggerReactivation];
    [self helperTestConditionEvaluate];
  }
  GHAssertTrue(blockRunCount == 0, @"Condition should not have been activated before 5 reactivations");
  
  [_watcher triggerReactivation];
  [self helperTestConditionEvaluate];
  GHAssertTrue(blockRunCount == 1, @"Condition should have been activated once after 5th reactivation");
  
  for (int i = 0; i < 20; i++) {
    [_watcher triggerReactivation];
    [self helperTestConditionEvaluate];
  }
  GHAssertTrue(blockRunCount == 1, @"Condition should not be activated after 6th reactivations");
}

- (void)testEvaluationConditionCountOpen
{
  __block NSUInteger blockRunCount = 0;
  [_watcher addCondition:self.helperTestConditionName
                    type:SRCWConditionTypeCountOpen
                 options:@{SRCWConditionOptionCountExact: @(5)}
                   block:^{
                     blockRunCount++;
                   }];
  
  for (int i = 0; i < 2; i++) {
    [_watcher triggerLaunch];
    [_watcher triggerReactivation];
    [self helperTestConditionEvaluate];
  }
  GHAssertTrue(blockRunCount == 0, @"Condition should not have been activated after 2 launches and 2 reactivations");
  
  [_watcher triggerReactivation];
  [self helperTestConditionEvaluate];
  GHAssertTrue(blockRunCount == 1, @"Condition should have been activated once after 2 launches and 3 reactivations");
  
  for (int i = 0; i < 5; i++) {
    [_watcher triggerLaunch];
    [_watcher triggerReactivation];
    [self helperTestConditionEvaluate];
  }
  GHAssertTrue(blockRunCount == 1, @"Condition should not be activated after more launches/reactivations");
}

- (void)testEvaluateConditionWithLimitOnMaxActivationCountShouldNotActivateIfVerifiedButLimitReached
{
  __block NSUInteger blockRunCount = 0;
  [_watcher addCondition: self.helperTestConditionName
                    type: SRCWConditionTypeCountTriggered
                 options: @{SRCWConditionOptionCountModulo: @(1),
                            SRCWConditionOptionLimitingActivationCount: @(1)}
                   block:^{
                     blockRunCount++;
                   }];
  
  [self helperTestConditionTriggerAndEvaluate];
  GHAssertTrue(blockRunCount == 1, @"Condition should have been activated the first time it's triggered");

  for (int i = 0; i < 10; i++) {
    [self helperTestConditionTriggerAndEvaluate];
  }
  GHAssertTrue(blockRunCount == 1, @"Condition should not be activated after it has been activated the limiting max number of times");
}

- (void)testEvaluateConditionWithLimitOnMaxActivationCountShouldActivateAsManyTimesAsPermittedByTheLimit
{
  __block NSUInteger blockRunCount = 0;
  [_watcher addCondition: self.helperTestConditionName
                    type: SRCWConditionTypeCountTriggered
                 options: @{SRCWConditionOptionCountModulo: @(1),
                            SRCWConditionOptionLimitingActivationCount: @(3)}
                   block:^{
                     blockRunCount++;
                   }];
    
  for (int i = 0; i < 10; i++) {
    [self helperTestConditionTriggerAndEvaluate];
  }
  GHAssertTrue(blockRunCount == 3, @"Condition should have been activated 3 times, the number enabled by the limit even if always verified");
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
  
  GHAssertTrue(conditionBlockRunCount == 0, @"Should not have run the condition's block on evaluation");
  GHAssertTrue(passedBlockRunCount == 1, @"Should have run the passed block on evaluation");
}

@end
