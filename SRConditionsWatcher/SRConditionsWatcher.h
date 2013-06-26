//
//  SRConditionsWatcher.h
//  Cultiwords
//
//  Created by Romain Champourlier on 27/04/13.
//  Copyright (c) 2013 softRli. All rights reserved.
//
//
// How to conditions work?
// -----------------------
//
// Each condition is independent, even for "global" ones like version change.
// This means you can setup multiple version change conditions, as soon as their
// name differs, you will be able to evaluate each condition at different times
// and detect the version change for each condition you set up.
//
// Triggered count
//
//    - Evaluation:
//      When the evaluation is performed, the watchers checks the condition's
//      options against its counter value. If any of the options is verified,
//      the condition is considered as verified and the evaluation block is run.
//
//    - Options:
//
//      - Exact value (SRCWConditionOptionCountExact):
//        The counter value must be equal to the specified value
//
//      - Modulo (SRCWConditionOptionCountModulo):
//        The counter module the specified value must be equal to 0.
//        NB: if you evaluate the condition before activating it, a
//        modulo option will always be verified (0 % anything => 0)
//
//    - Activation:
//      You need to activate the condition each time you want it to increment
//      its counter.
//
// Version change
//
//    - Evaluation:
//      - At the first evaluation, the current version is saved. The condition
//        is considered as not verified (the first version is not technically
//        a version change!).
//      - For the next evaluations, the current version is checked against the
//        saved one. If it differs, the condition is considered as verified, and
//        the evaluation block is performed.
//
//    - Activation:
//      The version change condition doesn't need to be activated since the version
//      change is passively detected on evaluation time.
//
// Global options
// Some options may be used with any condition type:
//
//    - Limiting activation count (SRCWConditionOptionLimitingActivationCount):
//      Once the condition has been activated the specified number
//      of times, it will never be activated anymore.
//
//
// Example usage for a triggered count condition:
// ----------------------------------------------
//
// SRConditionsWatcher *watcher = [[SRConditionsWatcher alloc] init];
//
// [watcher addCondition:@"my triggered condition"
//                  type:SRCWConditionTypeCountTriggered
//               options:@{SRCWConditionOptionCountExact:  @(3),
//                         SRCWConditionOptionCountModulo: @(10)}
//                 block:^{NSLog(@"activated triggered condition")}];
//
// for (int i = 1; i <= 3; i++) {
//   [watcher triggerCondition:@"my triggered condition"]; // because this is a CountTriggered condition
//   5watcher evaluateCondition:@"my triggered condition"];
// }
// // this will have output "activated triggered condition"
//
// for (int i = 4; i <= 20; i++) {
//   [watcher triggerCondition:@"my triggered condition"];
//   [watcher evaluateCondition:@"my triggered condition" block:^{NSLog(@"activated triggered condition with i=%u", i)}];
// }
// // output:
// // activated triggered condition with i=10
// // activated triggered condition with i=20
//
//
// Example for the version change condition:
// -----------------------------------------
//
// [watcher addCondition:@"my version change condition"
//                  type:SRCWConditionTypeVersionChange
//               options:nil // this type supports no options
//                 block:^{NSLog(@"activated version change condition")}];
//
// // To determine when you want the condition's block executed, you just call
// // the #evaluate method with the specified condition. The watcher will determine
// // if the condition is verified, and run the block if it is.
//
// [watcher evaluateCondition:@"my version change condition"];
// // Assuming there was a version change, this would have output "activated version change condition" and returned YES.
// // Else, it would just have returned NO.
//

typedef enum {
  SRCWConditionTypeVersionChange      = 1 << 0, // condition is triggered on version change
  SRCWConditionTypeCountTriggered     = 1 << 1, // condition is triggered on manual trigger count
  SRCWConditionTypeCountLaunch        = 1 << 2,
  SRCWConditionTypeCountReactivation  = 1 << 3,
  SRCWConditionTypeCountOpen          = 1 << 4
} SRCWConditionType;

extern NSString const * SRCWConditionOptionCountExact;
extern NSString const * SRCWConditionOptionCountModulo;
extern NSString const * SRCWConditionOptionLimitingActivationCount;


@class SRCWEnvironmentHelper;

@interface SRConditionsWatcher : NSObject

@property (retain) SRCWEnvironmentHelper *environmentHelper;


// Adds the condition with the given name, type, options, and evaluation
// block.
- (void)addCondition:(NSString *)conditionName
                type:(SRCWConditionType)conditionType
             options:(NSDictionary *)conditionOptions
               block:(void (^)(void))conditionBlock;

// Evaluates the specified condition. If the condition is verified, the associated
// block is run.
- (BOOL)evaluateCondition:(NSString *)conditionName;

// Like #evaluate: but evaluationBlock is run instead of the block associated
// to the condition when it was defined. This is only valable for this call,
// other calls to #evaluate without a specific block will run the original block.
- (BOOL)evaluateCondition:(NSString *)conditionName block:(void (^)(void))evaluationBlock;

// Notifies the watcher that the triggering event for the specified
// (trigger) condition occurred.
// Only applicable for conditions of type SRCWConditionTypeCountTriggered.
//
// @returns YES if the condition could be triggered and the state was successfully
//          updated and saved.
- (BOOL)triggerCondition:(NSString *)conditionName;

- (BOOL)triggerLaunch;
- (BOOL)triggerReactivation;

#pragma mark - Limit conditions

- (BOOL)limitCondition:(NSString *)conditionName;
- (BOOL)unlimitCondition:(NSString *)conditionName;


@end