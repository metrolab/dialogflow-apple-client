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
 
#import "AIStreamBuffer.h"

@interface AIStreamBuffer () <NSStreamDelegate>

@property(nonatomic, strong) NSOutputStream *outputStream;
@property(nonatomic, strong) NSMutableData *data;

@property(nonatomic, assign) BOOL waitForFlush;
@property(nonatomic, assign) BOOL opened;

@end

@implementation AIStreamBuffer
{
    NSUInteger _offset;
    dispatch_queue_t mutex;
}

- (instancetype)initWithOutputStream:(NSOutputStream *)outputStream
{
    self = [super init];
    if (self) {
        mutex = dispatch_queue_create(NULL, 0);
        
        self.outputStream = outputStream;
        _outputStream.delegate = self;
    }
    
    return self;
}

- (void)open
{
    self.opened = NO;
    
    if ([_delegate respondsToSelector:@selector(willOpenStreamBuffer:)]) {
        [_delegate willOpenStreamBuffer:self];
    }
    
    self.data = [NSMutableData data];
    _offset = 0;
    self.waitForFlush = NO;
    
    [_outputStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [_outputStream open];
}

- (void)write:(NSData *)data
{
    dispatch_sync(mutex, ^{
        [self->_data appendData:data];
    });
    
    if ([_outputStream hasSpaceAvailable] && _opened) {
        [self flush];
    }
}

- (BOOL)hasBytesForWriting
{
    __block BOOL can = NO;
    can = (_data.length - _offset) > 0;
    
    return can;
}

- (void)flush
{
    dispatch_sync(mutex, ^{
    if ([self hasBytesForWriting]) {
        NSUInteger availableLen = self->_data.length - self->_offset;
        
        uint8_t *buffer = (uint8_t *)self->_data.mutableBytes + self->_offset;
        NSInteger writtenBytes = [self->_outputStream write:buffer maxLength:availableLen];
        
        if (writtenBytes < 0) {
            NSError *error = self->_outputStream.streamError;
            
            if ([self->_delegate respondsToSelector:@selector(streamBuffer:error:)]) {
                [self->_delegate streamBuffer:self error:error];
            }
            
            [self close];
            
        } else {
            self->_offset += writtenBytes;
        }
    }
    });
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    if (eventCode != NSStreamEventHasSpaceAvailable) {
        NSLog(@"");
    }
    switch (eventCode) {
        case NSStreamEventOpenCompleted:
            self.opened = YES;
            if ([_delegate respondsToSelector:@selector(didOpenStreamBuffer:)]) {
                [_delegate didOpenStreamBuffer:self];
            }
            
            break;
        case NSStreamEventHasSpaceAvailable:
            [self flush];
            
            if (_waitForFlush && ![self hasBytesForWriting]) {
                [self close];
            }
            
            break;
        case NSStreamEventErrorOccurred:
        {
            NSError *error = _outputStream.streamError;
            
            if ([_delegate respondsToSelector:@selector(streamBuffer:error:)]) {
                [_delegate streamBuffer:self error:error];
            }
            
            [self close];
            
            break;
        }
        case NSStreamEventEndEncountered: {
            NSLog(@"");
            break;
        }
        default:
            break;
    }
}

- (void)close
{
    if ([_delegate respondsToSelector:@selector(willCloseStreamBuffer:)]) {
        [_delegate willCloseStreamBuffer:self];
    }
    
    [_outputStream close];
    [_outputStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    
    if ([_delegate respondsToSelector:@selector(didCloseStreamBuffer:)]) {
        [_delegate didCloseStreamBuffer:self];
    }
}

- (void)flushAndClose
{
    self.waitForFlush = YES;
    
    if ([self hasBytesForWriting] && [_outputStream hasSpaceAvailable]) {
        [self flush];
    }
}

- (void)dealloc
{
    self.delegate = nil;
    [self close];
}

@end
