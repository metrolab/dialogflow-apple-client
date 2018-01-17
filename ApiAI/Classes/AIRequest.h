/**
 * Copyright 2017 Google Inc. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
 
#import <Foundation/Foundation.h>

#import "AIRequestEntity.h"
#import "AIRequestEntry.h"
#import "AIRequestContext.h"

@class AIDataService;
@class AIRequest;

/*!
 * Succesfull handler definition for AIRequest.
 *
 * @param request The request called handler.
 * @param response Server responce (Serialized JSON).
 */
typedef void(^SuccesfullResponseBlock)(AIRequest *request, id response);

/*!
 * Failure handler definition for AIRequest.
 *
 * @param request The request called handler.
 * @param error The response error.
 */
typedef void(^FailureResponseBlock)(AIRequest *request, NSError *error);

@protocol AIRequest <NSObject>

/*!
 
 @property dataTask
 
 @discussion NSURLSessionDataTask.
 
 */
@property(nonatomic, strong) NSURLSessionDataTask *dataTask;

/*!
 
 @property dataService
 
 @discussion private property, don't use it.
 
 */
@property(nonatomic, weak) AIDataService *dataService;

@end

@interface AIRequest : NSOperation <AIRequest>

/*!
 
 @property error
 
 @discussion Contain error (optional) after getting response
 
 */
@property(nonatomic, copy) NSError *error;

/*!
 
 @property response
 
 @discussion Contain server response.
 
 */
@property(nonatomic, strong) id response;

/**
 Set completion handlers.
 @param succesfullBlock A block object to be executed when the task finishes successfully.
 @param failureBlock A block object to be executed when the task finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data.
 */
- (void)setCompletionBlockSuccess:(SuccesfullResponseBlock)succesfullBlock failure:(FailureResponseBlock)failureBlock;

- (instancetype)init __unavailable;

@end
