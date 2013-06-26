//
//  SRConditionsWatcherTests.m
//  SRConditionsWatcherTests
//
//  Created by Romain Champourlier on 18/06/13.
//  Copyright (c) 2013 softRli. All rights reserved.
//

#import "SRConditionsWatcher.h"
#import "SRCWEnvironmentHelper.h"

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
  SRCWEnvironmentHelper *original = [[SRCWEnvironmentHelper alloc] init];
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

#pragma mark - #triggerCondition - Normal case

- (void)testTriggerConditionShouldReturnTrue
{
  [_watcher addCondition:self.helperTestConditionName
                    type:SRCWConditionTypeCountTriggered
                 options:nil block:^(NSDictionary* conditionState, NSDictionary* globalState) {}];
  [_watcher evaluateCondition:self.helperTestConditionName];
  GHAssertTrue([_watcher triggerCondition:self.helperTestConditionName], @"#triggerCondition should return true in normal case");
}

- (void)testTriggerConditionShouldCreateTheStateFile
{
  [_watcher addCondition:self.helperTestConditionName
                    type:SRCWConditionTypeCountTriggered
                 options:nil block:^(NSDictionary* conditionState, NSDictionary* globalState) {}];
  [_watcher evaluateCondition:self.helperTestConditionName];
  [_watcher triggerCondition:self.helperTestConditionName];
  
  GHAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:self.helperTestFilePath], @"State file not created after triggering a conditionCountTriggered condition");
}


#pragma mark - #triggerCondition - Triggerable conditions

- (void)testTriggerConditionShouldNotRaiseExceptionIfTriggeringCountTriggeredCondition
{
  [_watcher addCondition:self.helperTestConditionName
                    type:SRCWConditionTypeCountTriggered
                 options:nil block:^(NSDictionary* conditionState, NSDictionary* globalState) {}];
  [_watcher evaluateCondition:self.helperTestConditionName];
  GHAssertNoThrow({
    [_watcher triggerCondition:self.helperTestConditionName];
    [_watcher evaluateCondition:self.helperTestConditionName];
    
  }, @"#triggerCondition should not raise an exception for a CountTriggered condition");
}

- (void)testTriggerConditionShouldNotRaiseExceptionIfTriggeringLastTimeTriggeredCondition
{
  [_watcher addCondition:self.helperTestConditionName
                    type:SRCWConditionTypeLastTimeTriggered
                 options:nil block:^(NSDictionary* conditionState, NSDictionary* globalState) {}];
  [_watcher evaluateCondition:self.helperTestConditionName];
  GHAssertNoThrow({
    [_watcher triggerCondition:self.helperTestConditionName];
    [_watcher evaluateCondition:self.helperTestConditionName];
    
  }, @"#triggerCondition should not raise an exception for a LastTimeTriggered condition");
}


#pragma mark - #triggerCondition - Non-triggerable conditions

- (void)testTriggerConditionShouldRaiseExceptionIfTriggeringVersionChangeCondition
{
  [_watcher addCondition:self.helperTestConditionName
                    type:SRCWConditionTypeVersionChange
                 options:nil block:^(NSDictionary* conditionState, NSDictionary* globalState) {}];

  GHAssertThrows({
  [_watcher triggerCondition:self.helperTestConditionName];
  [_watcher evaluateCondition:self.helperTestConditionName];

  }, @"should throw an exception if the condition is not triggerable");
}

- (void)testTriggerConditionShouldRaiseExceptionIfTriggeringCountLaunchCondition
{
  [_watcher addCondition:self.helperTestConditionName
                    type:SRCWConditionTypeCountLaunch
                 options:nil block:^(NSDictionary* conditionState, NSDictionary* globalState) {}];
  
  GHAssertThrows({
  [_watcher triggerCondition:self.helperTestConditionName];
  [_watcher evaluateCondition:self.helperTestConditionName];

  }, @"should throw an exception if the condition is not triggerable");
}

- (void)testTriggerConditionShouldRaiseExceptionIfTriggeringCountOpenCondition
{
  [_watcher addCondition:self.helperTestConditionName
                    type:SRCWConditionTypeCountOpen
                 options:nil block:^(NSDictionary* conditionState, NSDictionary* globalState) {}];
  
  GHAssertThrows({
  [_watcher triggerCondition:self.helperTestConditionName];
  [_watcher evaluateCondition:self.helperTestConditionName];

  }, @"should throw an exception if the condition is not triggerable");
}

- (void)testTriggerConditionShouldRaiseExceptionIfTriggeringCountReactivationCondition
{
  [_watcher addCondition:self.helperTestConditionName
                    type:SRCWConditionTypeCountReactivation
                 options:nil block:^(NSDictionary* conditionState, NSDictionary* globalState) {}];
  GHAssertThrows({
  [_watcher triggerCondition:self.helperTestConditionName];
  [_watcher evaluateCondition:self.helperTestConditionName];

  }, @"should throw an exception if the condition is not triggerable");
}


#pragma mark - #limitCondition

- (void)testLimitConditionShouldPreventActivationOfConditionEvenIfVerified
{
  __block NSUInteger blockRunCount = 0;
  [_watcher addCondition:self.helperTestConditionName
                    type:SRCWConditionTypeCountTriggered
                 options:@{SRCWConditionOptionCountModulo: @(1)}
                   block:^(NSDictionary* conditionState, NSDictionary* globalState) {
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
                   block:^(NSDictionary* conditionState, NSDictionary* globalState) {
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

#pragma mark - #evaluateCondition - ConditionCountTriggered

- (void)testEvaluateConditionCountTriggeredShouldActivateOnExactCountOnly
{
  __block NSUInteger blockRunCount = 0;
  [_watcher addCondition:self.helperTestConditionName
                    type:SRCWConditionTypeCountTriggered
                 options:@{SRCWConditionOptionCountExact: @(5)}
                   block:^(NSDictionary* conditionState, NSDictionary* globalState) {
                     blockRunCount++;
                   }];

  for (int i = 0; i < 4; i++) {
  [_watcher triggerCondition:self.helperTestConditionName];
  [_watcher evaluateCondition:self.helperTestConditionName];

  }
  GHAssertTrue(blockRunCount == 0, @"Condition should not have been activated before being triggered the <option exact value> number of times");
  
  [_watcher triggerCondition:self.helperTestConditionName];
  [_watcher evaluateCondition:self.helperTestConditionName];
  GHAssertTrue(blockRunCount == 1, @"Condition should have been activated once triggered the <option exact value> number of times");
  
  for (int i = 0; i < 20; i++) {
  [_watcher triggerCondition:self.helperTestConditionName];
  [_watcher evaluateCondition:self.helperTestConditionName];

  }
  GHAssertTrue(blockRunCount == 1, @"Condition should not be activated after having been triggered the <option exact value> number of times");
}

- (void)testEvaluateConditionCountTriggeredShouldActivateOnModuloCounts
{
  __block NSUInteger blockRunCount = 0;
  [_watcher addCondition:self.helperTestConditionName
                    type:SRCWConditionTypeCountTriggered
                 options:@{SRCWConditionOptionCountModulo: @(2)}
                   block:^(NSDictionary* conditionState, NSDictionary* globalState) {
                     blockRunCount++;
                   }];
  
  [_watcher triggerCondition:self.helperTestConditionName];
  [_watcher evaluateCondition:self.helperTestConditionName];
  GHAssertTrue(blockRunCount == 0, @"Condition should not have been activated before triggered the <option modulo value> number of times");

  [_watcher triggerCondition:self.helperTestConditionName];
  [_watcher evaluateCondition:self.helperTestConditionName];
  GHAssertTrue(blockRunCount == 1, @"Condition should have been activated once for the first modulo count of times");
  
  for (int i = 0; i < 20; i++) {
  [_watcher triggerCondition:self.helperTestConditionName];
  [_watcher evaluateCondition:self.helperTestConditionName];

  }
  GHAssertTrue(blockRunCount == 11, @"Condition should have been activated each <modulo> number of times it was triggered");
}

#pragma mark - #evaluateCondition - ConditionVersionChange

- (void)testEvaluateConditionVersionChangeShouldNotActivateOnFirstEvaluation
{
  __block NSUInteger blockRunCount = 0;
  [_watcher addCondition: self.helperTestConditionName
                    type: SRCWConditionTypeVersionChange
                 options: nil
                   block: ^(NSDictionary* conditionState, NSDictionary* globalState) {blockRunCount++;}];
  
  id mockEnvironmentHelper = self.mockEnvironmentHelper;
  _watcher.environmentHelper = mockEnvironmentHelper;
  [[[mockEnvironmentHelper stub] andReturn:@"1.2.3"] currentVersion];
  
  [_watcher evaluateCondition:self.helperTestConditionName];
  [_watcher evaluateCondition:self.helperTestConditionName];
  GHAssertTrue(blockRunCount == 0, @"Version change condition should not activate the first time it is evaluated");
}

- (void)testEvaluateConditionVersionChangeShouldActivateIfVersionIsDifferentFromState
{
  __block NSUInteger blockRunCount = 0;
  [_watcher addCondition: self.helperTestConditionName
                    type: SRCWConditionTypeVersionChange
                 options: nil
                   block: ^(NSDictionary* conditionState, NSDictionary* globalState) {blockRunCount++;}];
  
  id mockEnvironmentHelper = self.mockEnvironmentHelper;
  _watcher.environmentHelper = mockEnvironmentHelper;
  [[[mockEnvironmentHelper expect] andReturn:@"1.2.3"] currentVersion];
  [_watcher evaluateCondition:self.helperTestConditionName];
  // Evaluating a first time to set the version
  
  [[[mockEnvironmentHelper expect] andReturn:@"1.2.4"] currentVersion];
  [_watcher evaluateCondition:self.helperTestConditionName];

  GHAssertTrue(blockRunCount == 1, @"Version change condition should have activated on version change");
}

- (void)testEvaluateConditionVersionChangeShouldNotActivateIfVersionIsSameAsState
{
  __block NSUInteger blockRunCount = 0;
  [_watcher addCondition: self.helperTestConditionName
                    type: SRCWConditionTypeVersionChange
                 options: nil
                   block: ^(NSDictionary* conditionState, NSDictionary* globalState) {blockRunCount++;}];
  
  id mockEnvironmentHelper = self.mockEnvironmentHelper;
  _watcher.environmentHelper = mockEnvironmentHelper;
  [[[mockEnvironmentHelper expect] andReturn:@"1.2.3"] currentVersion];
  [_watcher evaluateCondition:self.helperTestConditionName];
  
  [[[mockEnvironmentHelper expect] andReturn:@"1.2.3"] currentVersion];
  [_watcher evaluateCondition:self.helperTestConditionName];
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
                   block: ^(NSDictionary* conditionState, NSDictionary* globalState) {blockRunCount++;}];
  
  [_watcher addCondition: condition2Name
                    type: SRCWConditionTypeVersionChange
                 options: nil
                   block: ^(NSDictionary* conditionState, NSDictionary* globalState) {blockRunCount++;}];

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

#pragma mark - #evaluateCondition - CountLaunch

- (void)testEvaluateConditionCountLaunch
{
  __block NSUInteger blockRunCount = 0;
  [_watcher addCondition:self.helperTestConditionName
                    type:SRCWConditionTypeCountLaunch
                 options:@{SRCWConditionOptionCountExact: @(5)}
                   block:^(NSDictionary* conditionState, NSDictionary* globalState) {
                     blockRunCount++;
                   }];
  
  for (int i = 0; i < 4; i++) {
    [_watcher triggerLaunch];
    [_watcher evaluateCondition:self.helperTestConditionName];
  }
  GHAssertTrue(blockRunCount == 0, @"Condition should not have been activated before 5 launches");
  
  [_watcher triggerLaunch];
  [_watcher evaluateCondition:self.helperTestConditionName];
  GHAssertTrue(blockRunCount == 1, @"Condition should have been activated once after 5th launch");
  
  for (int i = 0; i < 20; i++) {
    [_watcher triggerLaunch];
    [_watcher evaluateCondition:self.helperTestConditionName];
  }
  GHAssertTrue(blockRunCount == 1, @"Condition should not be activated after 6th launch");
}

#pragma mark - #evaluateCondition - CountReactivation

- (void)testEvaluateConditionCountReactivation
{
  __block NSUInteger blockRunCount = 0;
  [_watcher addCondition:self.helperTestConditionName
                    type:SRCWConditionTypeCountReactivation
                 options:@{SRCWConditionOptionCountExact: @(5)}
                   block:^(NSDictionary* conditionState, NSDictionary* globalState) {
                     blockRunCount++;
                   }];
  
  for (int i = 0; i < 4; i++) {
    [_watcher triggerReactivation];
    [_watcher evaluateCondition:self.helperTestConditionName];
  }
  GHAssertTrue(blockRunCount == 0, @"Condition should not have been activated before 5 reactivations");
  
  [_watcher triggerReactivation];
  [_watcher evaluateCondition:self.helperTestConditionName];
  GHAssertTrue(blockRunCount == 1, @"Condition should have been activated once after 5th reactivation");
  
  for (int i = 0; i < 20; i++) {
    [_watcher triggerReactivation];
    [_watcher evaluateCondition:self.helperTestConditionName];
  }
  GHAssertTrue(blockRunCount == 1, @"Condition should not be activated after 6th reactivations");
}

#pragma mark - #evaluateCondition - CountOpen

- (void)testEvaluationConditionCountOpen
{
  __block NSUInteger blockRunCount = 0;
  [_watcher addCondition:self.helperTestConditionName
                    type:SRCWConditionTypeCountOpen
                 options:@{SRCWConditionOptionCountExact: @(5)}
                   block:^(NSDictionary* conditionState, NSDictionary* globalState) {
                     blockRunCount++;
                   }];
  
  for (int i = 0; i < 2; i++) {
    [_watcher triggerLaunch];
    [_watcher triggerReactivation];
    [_watcher evaluateCondition:self.helperTestConditionName];
  }
  GHAssertTrue(blockRunCount == 0, @"Condition should not have been activated after 2 launches and 2 reactivations");
  
  [_watcher triggerReactivation];
  [_watcher evaluateCondition:self.helperTestConditionName];
  GHAssertTrue(blockRunCount == 1, @"Condition should have been activated once after 2 launches and 3 reactivations");
  
  for (int i = 0; i < 5; i++) {
    [_watcher triggerLaunch];
    [_watcher triggerReactivation];
    [_watcher evaluateCondition:self.helperTestConditionName];
  }
  GHAssertTrue(blockRunCount == 1, @"Condition should not be activated after more launches/reactivations");
}

#pragma mark - #evaluationCondition - LastTimeTriggered

- (void)testEvaluateConditionLastTimeTriggeredWithMoreThanAgoOptionShouldActivateIfNeverTriggered
{
  __block NSUInteger blockRunCount = 0;
  [_watcher addCondition:self.helperTestConditionName
                    type:SRCWConditionTypeLastTimeTriggered
                 options:@{SRCWConditionOptionLastTimeMoreThanAgo: @(60)}
                   block:^(NSDictionary* conditionState, NSDictionary* globalState) {
                     blockRunCount++;
                   }];
      
  [_watcher evaluateCondition:self.helperTestConditionName];
  GHAssertTrue(blockRunCount == 1, @"Condition should have been activated on evaluation if it was never triggered");
}

- (void)testEvaluateConditionLastTimeTriggeredWithMoreThanAgoOptionShouldActivateIfLastTriggerIsMoreThanSpecifiedValueAgo
{
  __block NSUInteger blockRunCount = 0;
  [_watcher addCondition:self.helperTestConditionName
                    type:SRCWConditionTypeLastTimeTriggered
                 options:@{SRCWConditionOptionLastTimeMoreThanAgo: @(60)}
                   block:^(NSDictionary* conditionState, NSDictionary* globalState) {
                     blockRunCount++;
                   }];
  
  NSDate* timeNow = [NSDate date];
  NSDate* time61SecondsAgo = [timeNow dateByAddingTimeInterval:-61];
  
  id mockEnvironmentHelper = self.mockEnvironmentHelper;
  _watcher.environmentHelper = mockEnvironmentHelper;

  [[[mockEnvironmentHelper expect] andReturn:time61SecondsAgo] now]; // setting last trigger time
  [_watcher triggerCondition:self.helperTestConditionName];
  
  [[[mockEnvironmentHelper expect] andReturn:timeNow] now]; // setting evaluation time
  [_watcher evaluateCondition:self.helperTestConditionName];
  GHAssertTrue(blockRunCount == 1, @"Condition should have been activated on evaluation 61 seconds after last trigger");
}

- (void)testEvaluateConditionLastTimeTriggeredWithMoreThanAgoOptionShouldNotActivateIfLastTriggerIsLessThanSpecifiedValueAgo
{
  __block NSUInteger blockRunCount = 0;
  [_watcher addCondition:self.helperTestConditionName
                    type:SRCWConditionTypeLastTimeTriggered
                 options:@{SRCWConditionOptionLastTimeMoreThanAgo: @(60)}
                   block:^(NSDictionary* conditionState, NSDictionary* globalState) {
                     blockRunCount++;
                   }];
  
  NSDate* timeNow = [NSDate date];
  NSDate* time30SecondsAgo = [timeNow dateByAddingTimeInterval:-30];
  
  id mockEnvironmentHelper = self.mockEnvironmentHelper;
  _watcher.environmentHelper = mockEnvironmentHelper;
  
  [[[mockEnvironmentHelper expect] andReturn:time30SecondsAgo] now]; // setting last trigger time
  [_watcher triggerCondition:self.helperTestConditionName];
  
  [[[mockEnvironmentHelper expect] andReturn:timeNow] now]; // setting evaluation time
  [_watcher evaluateCondition:self.helperTestConditionName];
  GHAssertTrue(blockRunCount == 0, @"Condition should not have been activated on evaluation 30 seconds after last trigger");
}


#pragma mark - #evaluateCondition - Conditions with limits

- (void)testEvaluateConditionWithLimitOnMaxActivationCountShouldNotActivateIfVerifiedButLimitReached
{
  __block NSUInteger blockRunCount = 0;
  [_watcher addCondition: self.helperTestConditionName
                    type: SRCWConditionTypeCountTriggered
                 options: @{SRCWConditionOptionCountModulo: @(1),
                            SRCWConditionOptionLimitingActivationCount: @(1)}
                   block:^(NSDictionary* conditionState, NSDictionary* globalState) {
                     blockRunCount++;
                   }];
  
  [_watcher triggerCondition:self.helperTestConditionName];
  [_watcher evaluateCondition:self.helperTestConditionName];
  GHAssertTrue(blockRunCount == 1, @"Condition should have been activated the first time it's triggered");

  for (int i = 0; i < 10; i++) {
  [_watcher triggerCondition:self.helperTestConditionName];
  [_watcher evaluateCondition:self.helperTestConditionName];

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
                   block:^(NSDictionary* conditionState, NSDictionary* globalState) {
                     blockRunCount++;
                   }];
    
  for (int i = 0; i < 10; i++) {
  [_watcher triggerCondition:self.helperTestConditionName];
  [_watcher evaluateCondition:self.helperTestConditionName];

  }
  GHAssertTrue(blockRunCount == 3, @"Condition should have been activated 3 times, the number enabled by the limit even if always verified");
}


#pragma mark - #evaluateCondition - Called block

- (void)testEvaluateConditionCalledBlockShouldBePassedConditionAndGlobalStates
{
  NSDictionary* options = @{SRCWConditionOptionCountModulo: @(1)};
  
  [_watcher addCondition: self.helperTestConditionName
                    type: SRCWConditionTypeCountTriggered
                 options: options
                   block:^(NSDictionary* conditionState, NSDictionary* globalState) {
                     GHAssertNotNil(conditionState, @"Block should be passed condition state dictionary which should not be nil");
                     GHAssertNotNil(globalState, @"Block should be passed global state dictionary which should not be nil");

                     GHAssertTrue(((NSNumber*)[globalState objectForKey:@"launchCount"]).unsignedIntValue == 3, @"Global state should contain the expected launchCount value (3)");

                     GHAssertTrue(((NSNumber*)[globalState objectForKey:@"reactivationCount"]).unsignedIntValue == 5, @"Global state should contain the expected reactivationCount value (5)");

                     GHAssertTrue(((NSNumber*)[conditionState objectForKey:@"triggerCount"]).unsignedIntValue == 10, @"Condition state should contain the expected triggerCount value (10)");
                   }];
  
  for (int i = 0; i < 3; i++) {[_watcher triggerLaunch];}
  for (int i = 0; i < 5; i++) {[_watcher triggerReactivation];}
  for (int i = 0; i < 10; i++) {[_watcher triggerCondition:self.helperTestConditionName];}

  [_watcher evaluateCondition:self.helperTestConditionName];
}


#pragma mark - #evaluationCondition:block

- (void)testEvaluateConditionBlockShouldRunThePassedBlockInsteadOfTheConditionOne
{
  __block NSUInteger conditionBlockRunCount = 0;
  __block NSUInteger passedBlockRunCount = 0;
  void (^conditionBlock)(NSDictionary* conditionState, NSDictionary* globalState) = ^(NSDictionary* conditionState, NSDictionary* globalState) {
    conditionBlockRunCount++;
  };
  void (^passedBlock)(NSDictionary* conditionState, NSDictionary* globalState) = ^(NSDictionary* conditionState, NSDictionary* globalState) {
    passedBlockRunCount++;
  };
  
  [_watcher addCondition:self.helperTestConditionName
                    type:SRCWConditionTypeCountTriggered
                 options:@{SRCWConditionOptionCountExact: @(1)}
                   block:conditionBlock];
  
  [_watcher triggerCondition:self.helperTestConditionName];
  [_watcher evaluateCondition:self.helperTestConditionName block:passedBlock];
  
  GHAssertTrue(conditionBlockRunCount == 0, @"Should not have run the condition's block on evaluation");
  GHAssertTrue(passedBlockRunCount == 1, @"Should have run the passed block on evaluation");
}


- (void)testEvaluateConditionBlockShouldBePassedConditionAndGlobalStates
{
  NSDictionary* options = @{SRCWConditionOptionCountModulo: @(1)};
  
  void (^conditionBlock)(NSDictionary* conditionState, NSDictionary* globalState) = ^(NSDictionary* conditionState, NSDictionary* globalState) {};
  void (^passedBlock)(NSDictionary* conditionState, NSDictionary* globalState) = ^(NSDictionary* conditionState, NSDictionary* globalState) {
    GHAssertNotNil(conditionState, @"Block should be passed condition state dictionary which should not be nil");
    GHAssertNotNil(globalState, @"Block should be passed global state dictionary which should not be nil");
    
    GHAssertTrue(((NSNumber*)[globalState objectForKey:@"launchCount"]).unsignedIntValue == 3, @"Global state should contain the expected launchCount value (3)");
    
    GHAssertTrue(((NSNumber*)[globalState objectForKey:@"reactivationCount"]).unsignedIntValue == 5, @"Global state should contain the expected reactivationCount value (5)");
    
    GHAssertTrue(((NSNumber*)[conditionState objectForKey:@"triggerCount"]).unsignedIntValue == 10, @"Condition state should contain the expected triggerCount value (10)");
    
  };
  
  [_watcher addCondition: self.helperTestConditionName
                    type: SRCWConditionTypeCountTriggered
                 options: options
                   block:conditionBlock];
  
  for (int i = 0; i < 3; i++) {[_watcher triggerLaunch];}
  for (int i = 0; i < 5; i++) {[_watcher triggerReactivation];}
  for (int i = 0; i < 10; i++) {[_watcher triggerCondition:self.helperTestConditionName];}
  
  [_watcher evaluateCondition:self.helperTestConditionName block:passedBlock];
}

@end
