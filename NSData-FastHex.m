//
//  NSData-FastHex.m
//  Pods
//
//  Created by Jonathon Mah on 2015-05-13.
//
//

#import "NSData-FastHex.h"


@implementation NSData (FastHex)

const uint8_t invalidNibble = UINT8_MAX;

static uint8_t nibbleFromChar(unichar c) {
    if (c >= '0' && c <= '9') {
        return c - '0';
    } else if (c >= 'A' && c <= 'F') {
        return 10 + c - 'A';
    } else if (c >= 'a' && c <= 'f') {
        return 10 + c - 'a';
    } else {
        return invalidNibble;
    }
}

+ (instancetype)dataWithHexString:(NSString *)hexString
{ return [[self alloc] initWithHexString:hexString ignoreOtherCharacters:YES]; }

- (nullable instancetype)initWithHexString:(NSString *)hexString ignoreOtherCharacters:(BOOL)ignoreOtherCharacters
{
    if (!hexString)
        return nil;

    const NSUInteger charLength = hexString.length;
    const NSUInteger maxByteLength = charLength / 2;
    uint8_t *const bytes = malloc(maxByteLength);
    uint8_t *bytePtr = bytes;

    CFStringInlineBuffer inlineBuffer;
    CFStringInitInlineBuffer((CFStringRef)hexString, &inlineBuffer, CFRangeMake(0, charLength));

    uint8_t hiNibble = invalidNibble;
    for (CFIndex i = 0; i < charLength; ++i) {
        uint8_t nextNibble = nibbleFromChar(CFStringGetCharacterFromInlineBuffer(&inlineBuffer, i));

        if (nextNibble == invalidNibble && !ignoreOtherCharacters) {
            free(bytes);
            return nil;
        } else if (hiNibble == invalidNibble) {
            hiNibble = nextNibble;
        } else if (nextNibble != invalidNibble) {
            // Have next full byte
            *bytePtr++ = (hiNibble << 4) | nextNibble;
            hiNibble = invalidNibble;
        }
    }

    if (hiNibble != invalidNibble && !ignoreOtherCharacters) { // trailing hex character
        free(bytes);
        return nil;
    }

    return [self initWithBytesNoCopy:bytes length:(bytePtr - bytes) freeWhenDone:YES];
}

static char charFromNibble(uint8_t i) {
    if (i < 10) {
        return '0' + i;
    } else {
        return 'A' + (i - 10);
    }
}

- (NSString *)hexString
{
    const NSUInteger byteLength = self.length;
    const NSUInteger charLength = byteLength * 2;
    const uint8_t *bytes = self.bytes;

    char *const hexChars = malloc(charLength * sizeof(char));
    char *charPtr = hexChars;
    const uint8_t *bytePtr = bytes;
    while (bytePtr < bytes + byteLength) {
        const uint8_t byte = *bytePtr++;
        *charPtr++ = charFromNibble((byte >> 4) & 0xF);
        *charPtr++ = charFromNibble(byte & 0xF);
    }
    return [[NSString alloc] initWithBytesNoCopy:hexChars length:charLength encoding:NSASCIIStringEncoding freeWhenDone:YES];
}

@end
