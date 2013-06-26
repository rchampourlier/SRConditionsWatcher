//
//  SRConditionsWatcher.m
//  Cultiwords
//
//  Created by Romain Champourlier on 27/04/13.
//  Copyright (c) 2013 softRli. All rights reserved.
//

#import "SRConditionsWatcher.h"

// Libraries
#import "SRCWEnvironmentHelper.h"


NSString const * SRCWConditionOptionCountExact                  = @"countExact";
NSString const * SRCWConditionOptionCountModulo                 = @"countModulo";
NSString const * SRCWConditionOptionLimitingActivationCount     = @"maxActivationCount";

static NSString const * kFileName                               = @"SRConditionsWatcherState.plist";
static NSString const * kStateDictionaryCounter                 = @"counter";
static NSString const * kStateDictionaryActivationCount         = @"activationCount";
static NSString const * kStateDictionaryVersion                 = @"version";
static NSString const * kStateDictionaryManualLimit             = @"manualLimit";

static NSString const * kStateDictionaryGlobalConditionsName    = @"__GlobalConditions";
static NSString const * kStateDictionaryGlobalLaunchCount       = @"launchCount";
static NSString const * kStateDictionaryGlobalReactivationCount = @"reactivationCount";

static NSString const * kConditionDictionaryBlock               = @"block";
static NSString const * kConditionDictionaryOptions             = @"options";
static NSString const * kConditionDictionaryType                = @"type";

@interface SRConditionsWatcher () {
  NSMutableDictionary *_state;
  NSMutableDictionary *_conditions;
}
@end

@interface SRConditionsWatcher (PrivateMethods)

#pragma mark - Specific type evaluation

- (BOOL)evaluateConditionOfTypeVersionChangeWithState:(NSMutableDictionary *)conditionState
                                              options:(NSDictionary *)conditionOptions;

- (BOOL)evaluateConditionOfTypeCountTriggeredWithState:(NSMutableDictionary *)conditionState
                                               options:(NSDictionary *)conditionOptions;

- (BOOL)evaluateConditionOfTypeCountLaunchWithState:(NSMutableDictionary *)conditionState
                                            options:(NSDictionary *)conditionOptions;

- (BOOL)evaluateConditionOfTypeCountReactivationWithState:(NSMutableDictionary *)conditionState
                                                  options:(NSDictionary *)conditionOptions;

- (BOOL)evaluateConditionOfTypeCountOpenWithState:(NSMutableDictionary *)conditionState
                                          options:(NSDictionary *)conditionOptions;

#pragma mark - Handling limiting options
- (BOOL)evaluateLimitingOptionsInConditionState:(NSMutableDictionary *)conditionState
                                        options:(NSDictionary *)conditionOptions;

#pragma mark - Condition and state helpers
- (NSDictionary *)condition:(NSString *)conditionName;
- (NSMutableDictionary *)conditionState:(NSString *)conditionName;
- (BOOL)updateCondition:(NSString *)conditionName
                  state:(NSDictionary *)conditionState;
- (NSMutableDictionary*)globalConditionsState;
- (BOOL)updateGlobalConditionsState:(NSDictionary*)globalConditionsState;

#pragma mark - Read/write state
- (void)readState;
- (BOOL)writeState;
- (NSURL *)fileURL;

@end


@implementation SRConditionsWatcher
@synthesize environmentHelper;


#pragma mark - Life cycle

- (id)init
{
  self = [super init];
  if (self) {
    self.environmentHelper = [[SRCWEnvironmentHelper alloc] init];
    _conditions = [NSMutableDictionary dictionary];
    [self readState];
  }
  return self;
}


#pragma mark - Setup conditions

// Adds the condition with the given name, type, options, and evaluation
// block.
- (void)addCondition:(NSString *)conditionName
                type:(SRCWConditionType)conditionType
             options:(NSDictionary *)conditionOptions
               block:(void (^)(void))conditionBlock
{
  if (conditionBlock == nil) {
    NSException* myException = [NSException exceptionWithName:@"InvalidConditionException"
                                                       reason:@"Condition's block can't be nil"
                                                     userInfo:nil];
    @throw myException;
  }
  
  conditionOptions = conditionOptions ? conditionOptions : @{};
  NSDictionary *conditionDictionary = @{kConditionDictionaryType:     @(conditionType),
                                        kConditionDictionaryOptions:  conditionOptions,
                                        kConditionDictionaryBlock:    conditionBlock
                                        };
  [_conditions setObject:conditionDictionary forKey:conditionName];
}


#pragma mark - Trigger and evaluate conditions

// Evaluates the specified condition. If the condition is verified, the associated
// block is run.
- (BOOL)evaluateCondition:(NSString *)conditionName
{
  return [self evaluateCondition:conditionName block:nil];
}

// Like #evaluate: but evaluationBlock is run instead of the block associated
// to the condition when it was defined. This is only valable for this call,
// other calls to #evaluate without a specific block will run the original block.
- (BOOL)evaluateCondition:(NSString *)conditionName
                    block:(void (^)(void))evaluationBlock
{
  NSDictionary*         condition         = [self condition:conditionName];
  NSMutableDictionary*  conditionState    = [self conditionState:conditionName];
  
  SRCWConditionType     conditionType     = ((NSNumber *)[condition objectForKey:kConditionDictionaryType]).unsignedIntValue;
  NSDictionary *        conditionOptions  = [condition objectForKey:kConditionDictionaryOptions];
  void (^conditionBlock)(void)            = evaluationBlock ? evaluationBlock : (void (^)(void))[condition objectForKey:kConditionDictionaryBlock];
  
  BOOL result;
  
  if (![self evaluateLimitingOptionsInConditionState:conditionState
                                             options:conditionOptions]) {

    switch (conditionType) {
        
      case SRCWConditionTypeVersionChange:
        result = [self evaluateConditionOfTypeVersionChangeWithState:conditionState
                                                             options:conditionOptions];
        break;
        
      case SRCWConditionTypeCountTriggered: {
        result = [self evaluateConditionOfTypeCountTriggeredWithState:conditionState
                                                              options:conditionOptions];
        break;
      }
        
      case SRCWConditionTypeCountLaunch: {
        result = [self evaluateConditionOfTypeCountLaunchWithState:conditionState
                                                           options:conditionOptions];
        break;
      }
        
      case SRCWConditionTypeCountReactivation: {
        result = [self evaluateConditionOfTypeCountReactivationWithState:conditionState
                                                                 options:conditionOptions];
        break;
      }
        
      case SRCWConditionTypeCountOpen: {
        result = [self evaluateConditionOfTypeCountOpenWithState:conditionState
                                                         options:conditionOptions];
        break;
      }
    }
  }
  else result = NO;
  
  if (result) {
    // Activating!
    NSNumber* activationCountNumber = [conditionState objectForKey:kStateDictionaryActivationCount];
    NSUInteger activationCount = activationCountNumber ? activationCountNumber.unsignedIntValue : 0;
    [conditionState setObject:@(activationCount+1) forKey:kStateDictionaryActivationCount];
    conditionBlock();
  }
  
  [self updateCondition:conditionName state:conditionState];
  return result;
}


// Notifies the watcher that the triggering event for the specified
// (trigger) condition occurred.
// Only applicable for conditions of type SRCWConditionTypeCountTriggered.
- (BOOL)triggerCondition:(NSString *)conditionName
{
  NSDictionary*         condition         = [self condition:conditionName];
  NSMutableDictionary*  conditionState    = [self conditionState:conditionName];
  SRCWConditionType     conditionType     = ((NSNumber *)[condition objectForKey:kConditionDictionaryType]).unsignedIntValue;
  
  switch (conditionType) {
      
    case SRCWConditionTypeCountTriggered: {
      NSNumber*   counterNumber = [conditionState objectForKey:kStateDictionaryCounter];
      NSUInteger  counter = (counterNumber ? counterNumber.unsignedIntValue : 0) + 1;
      [conditionState setObject:@(counter) forKey:kStateDictionaryCounter];
      break;
    }
      
    default:
      NSAssert(false, @"Only CountTriggered conditions can be triggered");
  }
  
  return [self updateCondition:conditionName state:conditionState];
}

- (BOOL)triggerLaunch
{
  NSMutableDictionary* globalConditionsState = [self globalConditionsState];
  
  NSNumber* counterNumber = [globalConditionsState objectForKey:kStateDictionaryGlobalLaunchCount];
  NSUInteger  counter = (counterNumber ? counterNumber.unsignedIntValue : 0) + 1;
  [globalConditionsState setObject:@(counter) forKey:kStateDictionaryGlobalLaunchCount];
  [self updateGlobalConditionsState:globalConditionsState];
  
  return [self writeState];
}

- (BOOL)triggerReactivation
{
  NSMutableDictionary* globalConditionsState = [self globalConditionsState];
  NSNumber* counterNumber = [globalConditionsState objectForKey:kStateDictionaryGlobalReactivationCount];
  NSUInteger  counter = (counterNumber ? counterNumber.unsignedIntValue : 0) + 1;
  [globalConditionsState setObject:@(counter) forKey:kStateDictionaryGlobalReactivationCount];
  [self updateGlobalConditionsState:globalConditionsState];
  return [self writeState];
}


#pragma mark - Limit conditions


- (BOOL)limitCondition:(NSString *)conditionName
{
  NSMutableDictionary* conditionState = [self conditionState:conditionName];
  [conditionState setObject:@(YES) forKey:kStateDictionaryManualLimit];
  return [self updateCondition:conditionName state:conditionState];
}

- (BOOL)unlimitCondition:(NSString *)conditionName
{
  NSMutableDictionary* conditionState = [self conditionState:conditionName];
  [conditionState setObject:@(NO) forKey:kStateDictionaryManualLimit];
  return [self updateCondition:conditionName state:conditionState];
}


#pragma mark - PrivateMethods

- (BOOL)evaluateConditionOfTypeVersionChangeWithState:(NSMutableDictionary *)conditionState
                                              options:(NSDictionary *)conditionOptions
{
  NSString *savedVersion = [conditionState objectForKey:kStateDictionaryVersion];
  NSString *currentVersion = [self.environmentHelper currentVersion];
  [conditionState setObject:currentVersion forKey:kStateDictionaryVersion];
  
  if (savedVersion == nil || [savedVersion isEqualToString:currentVersion]) {
    return NO;
  }
  else return YES;
}

- (BOOL)evaluateConditionOfTypeCountTriggeredWithState:(NSMutableDictionary *)conditionState
                                               options:(NSDictionary *)conditionOptions
{
  NSNumber *countNumber = [conditionState objectForKey:kStateDictionaryCounter];
  NSUInteger count = countNumber ? countNumber.unsignedIntValue : 0;
  
  for (NSString *optionName in conditionOptions.allKeys)
  {
    if (optionName == SRCWConditionOptionCountExact)
    {
      NSNumber *exactValueNumber = [conditionOptions objectForKey:optionName];
      NSAssert([exactValueNumber isKindOfClass:[NSNumber class]], @"CountExact option value must be NSNumber");
      
      NSUInteger exactValue = exactValueNumber.unsignedIntValue;
      if (count == exactValue) return YES;
    }
    else if (optionName == SRCWConditionOptionCountModulo)
    {
      NSNumber *moduloValueNumber = [conditionOptions objectForKey:optionName];
      NSAssert([moduloValueNumber isKindOfClass:[NSNumber class]], @"CountModulo option value must be NSNumber");
      
      NSUInteger moduloValue = moduloValueNumber.unsignedIntValue;
      if (count % moduloValue == 0) return YES;
    }
  }
  return NO;
}

- (BOOL)evaluateConditionOfTypeCountLaunchWithState:(NSMutableDictionary *)conditionState
                                            options:(NSDictionary *)conditionOptions
{
  NSDictionary* globalState = [self globalConditionsState];
  NSNumber *countNumber = [globalState objectForKey:kStateDictionaryGlobalLaunchCount];
  NSUInteger count = countNumber ? countNumber.unsignedIntValue : 0;
  
  for (NSString *optionName in conditionOptions.allKeys)
  {
    if (optionName == SRCWConditionOptionCountExact)
    {
      NSNumber *exactValueNumber = [conditionOptions objectForKey:optionName];
      NSAssert([exactValueNumber isKindOfClass:[NSNumber class]], @"CountExact option value must be NSNumber");
      
      NSUInteger exactValue = exactValueNumber.unsignedIntValue;
      if (count == exactValue) return YES;
    }
    else if (optionName == SRCWConditionOptionCountModulo)
    {
      NSNumber *moduloValueNumber = [conditionOptions objectForKey:optionName];
      NSAssert([moduloValueNumber isKindOfClass:[NSNumber class]], @"CountModulo option value must be NSNumber");
      
      NSUInteger moduloValue = moduloValueNumber.unsignedIntValue;
      if (count % moduloValue == 0) return YES;
    }
  }
  return NO;
}

- (BOOL)evaluateConditionOfTypeCountReactivationWithState:(NSMutableDictionary *)conditionState
                                                  options:(NSDictionary *)conditionOptions
{
  NSDictionary* globalState = [self globalConditionsState];
  NSNumber *countNumber = [globalState objectForKey:kStateDictionaryGlobalReactivationCount];
  NSUInteger count = countNumber ? countNumber.unsignedIntValue : 0;
  
  for (NSString *optionName in conditionOptions.allKeys)
  {
    if (optionName == SRCWConditionOptionCountExact)
    {
      NSNumber *exactValueNumber = [conditionOptions objectForKey:optionName];
      NSAssert([exactValueNumber isKindOfClass:[NSNumber class]], @"CountExact option value must be NSNumber");
      
      NSUInteger exactValue = exactValueNumber.unsignedIntValue;
      if (count == exactValue) return YES;
    }
    else if (optionName == SRCWConditionOptionCountModulo)
    {
      NSNumber *moduloValueNumber = [conditionOptions objectForKey:optionName];
      NSAssert([moduloValueNumber isKindOfClass:[NSNumber class]], @"CountModulo option value must be NSNumber");
      
      NSUInteger moduloValue = moduloValueNumber.unsignedIntValue;
      if (count % moduloValue == 0) return YES;
    }
  }
  return NO;
}

- (BOOL)evaluateConditionOfTypeCountOpenWithState:(NSMutableDictionary *)conditionState
                                          options:(NSDictionary *)conditionOptions
{
  NSDictionary* globalState = [self globalConditionsState];
  NSNumber *launchCountNumber = [globalState objectForKey:kStateDictionaryGlobalLaunchCount];
  NSNumber *reactivationCountNumber = [globalState objectForKey:kStateDictionaryGlobalReactivationCount];
  NSUInteger count = (launchCountNumber ? launchCountNumber.unsignedIntValue : 0) + (reactivationCountNumber ? reactivationCountNumber.unsignedIntValue : 0);
  
  for (NSString *optionName in conditionOptions.allKeys)
  {
    if (optionName == SRCWConditionOptionCountExact)
    {
      NSNumber *exactValueNumber = [conditionOptions objectForKey:optionName];
      NSAssert([exactValueNumber isKindOfClass:[NSNumber class]], @"CountExact option value must be NSNumber");
      
      NSUInteger exactValue = exactValueNumber.unsignedIntValue;
      if (count == exactValue) return YES;
    }
    else if (optionName == SRCWConditionOptionCountModulo)
    {
      NSNumber *moduloValueNumber = [conditionOptions objectForKey:optionName];
      NSAssert([moduloValueNumber isKindOfClass:[NSNumber class]], @"CountModulo option value must be NSNumber");
      
      NSUInteger moduloValue = moduloValueNumber.unsignedIntValue;
      if (count % moduloValue == 0) return YES;
    }
  }
  return NO;
}


#pragma mark - Handling limiting options

- (BOOL)evaluateLimitingOptionsInConditionState:(NSMutableDictionary *)conditionState
                                        options:(NSDictionary *)conditionOptions
{
  // Manual limit
  NSNumber* manualLimitNumber = [conditionState objectForKey:kStateDictionaryManualLimit];
  if (manualLimitNumber && manualLimitNumber.boolValue) {
    return YES;
  }
  
  // Options limits
  for (NSString *option in conditionOptions.allKeys) {
    if (option == SRCWConditionOptionLimitingActivationCount) {
      NSNumber *maxActivationCountNumber = [conditionOptions objectForKey:option];
      NSAssert([maxActivationCountNumber isKindOfClass:[NSNumber class]], @"MaxActivationCount option value must be NSNumber");
      NSUInteger maxActivationCount = maxActivationCountNumber.unsignedIntValue;
      
      NSNumber *activationCountNumber = [conditionState objectForKey:kStateDictionaryActivationCount];
      NSUInteger activationCount = activationCountNumber ? activationCountNumber.unsignedIntValue : 0;
      
      if (activationCount >= maxActivationCount) return YES;
    }
  }
  return NO;
}


#pragma mark - Condition and state helpers

- (NSDictionary *)condition:(NSString *)conditionName
{
  return [_conditions objectForKey:conditionName];
}

- (NSMutableDictionary *)conditionState:(NSString *)conditionName
{
  NSDictionary *existingState = [_state objectForKey:conditionName];
  return [NSMutableDictionary dictionaryWithDictionary:existingState ? existingState : @{}];
}

- (BOOL)updateCondition:(NSString *)conditionName
                  state:(NSDictionary *)conditionState
{
  [_state setObject:conditionState forKey:conditionName];
  return [self writeState];
}

- (NSMutableDictionary*)globalConditionsState
{
  return [self conditionState:[kStateDictionaryGlobalConditionsName copy]];
}

- (BOOL)updateGlobalConditionsState:(NSDictionary*)globalConditionsState
{
  return [self updateCondition:[kStateDictionaryGlobalConditionsName copy]
                         state:globalConditionsState];
}

#pragma mark - Read/write state

- (void)readState
{
  _state = [[NSMutableDictionary alloc] initWithContentsOfURL:self.fileURL];
  _state = _state ? _state : [NSMutableDictionary dictionary];
}

- (BOOL)writeState
{
  BOOL result = [_state writeToURL:self.fileURL atomically:YES];
  return result;
}

- (NSURL *)fileURL
{
  return [self.environmentHelper.documentDirectoryURL URLByAppendingPathComponent:[kFileName copy]];
}

@end



