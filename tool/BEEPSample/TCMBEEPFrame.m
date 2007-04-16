//
//  TCMBEEPFrame.m
//  BEEPSample
//
//  Created by Martin Ott on Wed Feb 18 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMBEEPFrame.h"
#import "TCMBEEPSession.h"
#import "TCMBEEPMessage.h"

@implementation TCMBEEPFrame

+ (TCMBEEPFrame *)frameWithMessage:(TCMBEEPMessage *)aMessage sequenceNumber:(uint32_t)aSequenceNumber
{
    return [[[TCMBEEPFrame alloc] initWithMessage:aMessage sequenceNumber:aSequenceNumber] autorelease];
}

- (id)initWithMessage:(TCMBEEPMessage *)aMessage sequenceNumber:(uint32_t)aSequenceNumber
{
    self = [super init];
    if (self) {
        [self setMessageTypeString:[aMessage messageTypeString]];
        I_channelNumber = [aMessage channelNumber];
        I_messageNumber = [aMessage messageNumber];
        I_answerNumber = [aMessage answerNumber];
        I_continuationIndicator[0] = '.';
        I_continuationIndicator[1] = 0;
        I_length = [aMessage payloadLength];
        [self setPayload:[aMessage payload]];
        I_sequenceNumber = aSequenceNumber;
    }
    return self;
}

- (id)initWithHeader:(char *)aHeaderString
{
    self = [super init];
    if (self) {
        I_answerNumber = -1;
        BOOL error = NO;
        if (sscanf(aHeaderString, "%3s %d %d %1s %d %d\r",
                    I_messageType, &I_channelNumber, &I_messageNumber,
                    I_continuationIndicator, &I_sequenceNumber, &I_length) == 6) {
            

        } else if (sscanf(aHeaderString,"%3s %d %d %1s %d %d %d\r",
                    I_messageType, &I_channelNumber, &I_messageNumber,
                    I_continuationIndicator, &I_sequenceNumber, &I_length, &I_answerNumber) == 7){
            if (!(strcmp(I_messageType, "ANS"))) {
                error = YES;
            }
        } else if (sscanf(aHeaderString, "%3s %d %d %d\r", I_messageType, &I_channelNumber, &I_sequenceNumber, &I_length) == 4) {
        
        } else {
            error = YES;
        }
        
        if (error) {
            [super dealloc];
            self = nil;
        }
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"TCMBEEPFrame: %3s %d %d %1s %d %d\nPayload length: %d", I_messageType, I_channelNumber, I_messageNumber,
                    I_continuationIndicator, I_sequenceNumber, I_length, [I_payload length]];
}

#pragma mark -

- (void)setMessageTypeString:(NSString *)aString {
    [aString getCString:I_messageType maxLength:3];
}

- (char *)messageType
{
    return I_messageType;
}

- (int32_t)channelNumber
{
    return I_channelNumber;
}

- (int32_t)messageNumber
{
    return I_messageNumber;
}

-(char *)continuationIndicator
{
    return I_continuationIndicator;
}

-(BOOL)isIntermediate
{
    return (I_continuationIndicator[0] == '*');
}

-(uint32_t)sequenceNumber
{
    return I_sequenceNumber;
}

- (int32_t)length
{
    return I_length;
}

- (int32_t)answerNumber
{
    return I_answerNumber;
}

- (void)setPayload:(NSData *)aData
{
    [I_payload autorelease];
    I_payload = [aData copy];
}

- (NSData *)payload
{
    return I_payload;
}

- (BOOL)isANS
{
    return (strcmp([self messageType], "ANS") == 0);
}

- (void)appendToMutableData:(NSMutableData *)aData {
    NSString *headerString = nil;
    if ([self isANS]) {
        headerString = [NSString stringWithFormat:@"%s %d %d %s %u %d %d\r\n", I_messageType, I_channelNumber,I_messageNumber, I_continuationIndicator, I_sequenceNumber, I_length, I_answerNumber];    
    } else {
        headerString = [NSString stringWithFormat:@"%s %d %d %s %u %d\r\n", I_messageType, I_channelNumber, I_messageNumber, I_continuationIndicator, I_sequenceNumber, I_length];
    }
    
    [aData appendData:[headerString dataUsingEncoding:NSASCIIStringEncoding]];
    [aData appendData:[self payload]];
    [aData appendData:[kTCMBEEPFrameTrailer dataUsingEncoding:NSASCIIStringEncoding]];
}


@end