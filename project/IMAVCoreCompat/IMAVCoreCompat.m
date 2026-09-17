#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#include <stdio.h>

/*
 * Launch-only IMAVCore compatibility shim for iChat 6.0.2 on Mac OS X 10.6.8.
 *
 * Goal: satisfy the ABI that the Lion iChat GUI imports directly from
 * IMAVCore.framework without loading Lion IMAVCore 800 and its Marco /
 * FTServices / IMFoundation 800 dependency chain.
 *
 * This is intentionally NOT a functional AV implementation yet.
 */

#define IMAV_STRING(name) NSString * const name = @#name

IMAV_STRING(IMAVActiveConferenceChangedNotification);
IMAV_STRING(IMAVChatIrisStateChangedNotification);
IMAV_STRING(IMAVChatIrisStateKey);
IMAV_STRING(IMAVChatParticipantAddedNotification);
IMAV_STRING(IMAVChatParticipantKey);
IMAV_STRING(IMAVChatParticipantMuteChangedNotification);
IMAV_STRING(IMAVChatParticipantNetworkStalledNotification);
IMAV_STRING(IMAVChatParticipantPauseChangedNotification);
IMAV_STRING(IMAVChatParticipantPreviousStateKey);
IMAV_STRING(IMAVChatParticipantStateChangedNotification);
IMAV_STRING(IMAVChatParticipantStateKey);
IMAV_STRING(IMAVChatParticipantWasRemovedNotification);
IMAV_STRING(IMAVChatParticipantsToBeRemovedKey);
IMAV_STRING(IMAVChatParticipantsWillBeRemovedNotification);
IMAV_STRING(IMAVChatStateChangedNotification);
IMAV_STRING(IMAVChatStateKey);
IMAV_STRING(IMAVQ8IrisStateChangedNotification);
IMAV_STRING(IMAVVideoCapabilitesChangedNotification);

/* These appear as direct iChat imports and are treated as preference / change
 * string constants for the launch-only shim. If runtime evidence shows a
 * different ABI, replace them with the observed implementation. */
IMAV_STRING(VCCameraPrefsChanged);
IMAV_STRING(VCChanged);
IMAV_STRING(VCDefaultCameraPref);
IMAV_STRING(VCDefaultMicPref);
IMAV_STRING(VCDefaultSoundOutputDevicePref);
IMAV_STRING(VCMaxBitratePref);

NSInteger OppositeRole(NSInteger role)
{
    return role;
}

NSString *NSStringDescriptionForIMAVChatParticipantState(NSInteger state)
{
    return [NSString stringWithFormat:@"IMAVChatParticipantState(%ld)", (long)state];
}

@interface IMAVChatFeature : NSObject {
@public
    id _avChat; /* x86_64 offset 8 */
}
- (id)initWithAVChat:(id)chat;
- (id)avChat;
- (void)setAVChat:(id)chat;
@end

@implementation IMAVChatFeature
- (id)initWithAVChat:(id)chat
{
    if ((self = [super init])) {
        _avChat = chat;
    }
    return self;
}
- (id)avChat { return _avChat; }
- (void)setAVChat:(id)chat { _avChat = chat; }
@end

@interface IMAVChat : NSObject {
@public
    unsigned char _compatPaddingToRecorder[344];
    id _recorder; /* x86_64 offset 352 */
    id _auxVideo; /* x86_64 offset 360 */
    id _ard;      /* x86_64 offset 368 */
}
+ (id)connectedChat;
+ (id)activeChat;
+ (id)nonFinalChat;
+ (NSArray *)chatList;
+ (NSArray *)connectedChats;
+ (NSArray *)connectingChats;
+ (NSArray *)outgoingInvitations;
+ (NSArray *)incomingInvitations;
+ (NSArray *)chatsWithIMAVChatState:(NSInteger)state;
+ (id)avChatWithConferenceID:(id)conferenceID;
+ (id)chatWithSessionID:(unsigned int)sessionID;
- (NSInteger)state;
- (BOOL)isActive;
- (BOOL)isStateFinal;
@end

@implementation IMAVChat
+ (id)connectedChat { return nil; }
+ (id)activeChat { return nil; }
+ (id)nonFinalChat { return nil; }
+ (NSArray *)chatList { return [NSArray array]; }
+ (NSArray *)connectedChats { return [NSArray array]; }
+ (NSArray *)connectingChats { return [NSArray array]; }
+ (NSArray *)outgoingInvitations { return [NSArray array]; }
+ (NSArray *)incomingInvitations { return [NSArray array]; }
+ (NSArray *)chatsWithIMAVChatState:(NSInteger)state { (void)state; return [NSArray array]; }
+ (id)avChatWithConferenceID:(id)conferenceID { (void)conferenceID; return nil; }
+ (id)chatWithSessionID:(unsigned int)sessionID { (void)sessionID; return nil; }
- (NSInteger)state { return 0; }
- (BOOL)isActive { return NO; }
- (BOOL)isStateFinal { return YES; }
@end

@interface IMAVChatParticipant : NSObject {
@public
    int _ardRole;                              /* 8 */
    signed char _ARDAuthorized;                /* 12 */
    unsigned char _compatPad13To16[3];
    id _ARDChannel;                            /* 16 */
    id _ARDChannelNegotiation;                 /* 24 */
    id _ARDEncryptionKey;                      /* 32 */
    id _incomingVCChannelNegotiations;         /* 40 */
    id _outgoingVCChannelNegotiations;         /* 48 */
    id _ARDFileTransferUsedIndexes;            /* 56 */
    unsigned int _ARDFileTransferIndex;        /* 64 */
    unsigned char _compatPad68To304[236];
}
- (NSInteger)state;
@end

@implementation IMAVChatParticipant
- (NSInteger)state { return 0; }
@end

@interface IMAVInterface : NSObject {
@public
    id _delegate;                              /* 8 */
    signed char _keepCameraRunning;            /* 16 */
}
+ (id)sharedInstance;
- (id)delegate;
- (void)setDelegate:(id)delegate;
- (BOOL)isAVInterfaceReady;
- (BOOL)systemCanVideoChat;
- (BOOL)systemCanAudioChat;
@end

@implementation IMAVInterface
+ (id)sharedInstance { return nil; }
- (id)delegate { return _delegate; }
- (void)setDelegate:(id)delegate { _delegate = delegate; }
- (BOOL)isAVInterfaceReady { return NO; }
- (BOOL)systemCanVideoChat { return NO; }
- (BOOL)systemCanAudioChat { return NO; }
@end

@interface VCChannelNegotiation : NSObject {
@public
    id _participant;                           /* 8 */
    id _localIMHandle;                         /* 16 */
    unsigned int _avChatSessionID;             /* 24 */
    signed char _incoming;                     /* 28 */
    unsigned char _compatPad29To32[3];
    unsigned int _requestID;                   /* 32 */
    unsigned int _channelType;                 /* 36 */
    unsigned long long _state;                 /* 40 */
    signed char _channelPrepared;              /* 48 */
    unsigned char _compatPad49To52[3];
    int _connectionError;                      /* 52 */
    id _channel;                               /* 56 */
    id _remoteData;                            /* 64 */
    unsigned int _keyExchangeMode;             /* 72 */
    unsigned char _compatPad76To80[4];
    unsigned long long _encryptionKeySize;     /* 80 */
    id _encryptionKey;                         /* 88 */
    id _validationKey;                         /* 96 */
    void *_keyExchangePublicKey;               /* 104 */
    void *_keyExchangePrivateKey;              /* 112 */
    id _negotiationQueue;                      /* 120 */
}
@end

@implementation VCChannelNegotiation
@end

@interface IMAVController : NSObject {
@public
    id _delegate;                              /* 8 */
    signed char _blockMultipleIncomingInvitations;       /* 16 */
    signed char _blockOutgoingInvitationsDuringCall;     /* 17 */
    signed char _blockIncomingInvitationsDuringCall;     /* 18 */
}
+ (id)sharedInstance;
+ (void)setupIMAVController;
+ (void)requestPendingVCInvitations;
- (id)delegate;
- (void)setDelegate:(id)delegate;
- (BOOL)hasActiveConference;
@end

@implementation IMAVController
+ (id)sharedInstance { return nil; }
+ (void)setupIMAVController { }
+ (void)requestPendingVCInvitations { }
- (id)delegate { return _delegate; }
- (void)setDelegate:(id)delegate { _delegate = delegate; }
- (BOOL)hasActiveConference { return NO; }
@end

@interface FZVideoConferenceController : NSObject
+ (id)sharedInstance;
+ (BOOL)hasBeenInitialized;
- (BOOL)isVCCReady;
@end

@implementation FZVideoConferenceController
+ (id)sharedInstance { return nil; }
+ (BOOL)hasBeenInitialized { return NO; }
- (BOOL)isVCCReady { return NO; }
@end

static void IMAVLogIvar(Class cls, const char *name)
{
    Ivar ivar = class_getInstanceVariable(cls, name);
    if (ivar) {
        fprintf(stderr, "[IMAVCoreCompat] %s.%s = %ld\n",
                class_getName(cls), name, (long)ivar_getOffset(ivar));
    }
}

__attribute__((constructor))
static void IMAVCoreCompatInitialize(void)
{
    fprintf(stderr, "[IMAVCoreCompat] loaded (launch-only, x86_64 ABI)\n");
    fprintf(stderr, "[IMAVCoreCompat] sizeof(IMAVChat)=%lu sizeof(IMAVChatParticipant)=%lu sizeof(IMAVChatFeature)=%lu\n",
            (unsigned long)class_getInstanceSize([IMAVChat class]),
            (unsigned long)class_getInstanceSize([IMAVChatParticipant class]),
            (unsigned long)class_getInstanceSize([IMAVChatFeature class]));

    IMAVLogIvar([IMAVChat class], "_recorder");
    IMAVLogIvar([IMAVChat class], "_auxVideo");
    IMAVLogIvar([IMAVChat class], "_ard");
    IMAVLogIvar([IMAVChatParticipant class], "_ARDAuthorized");
    IMAVLogIvar([IMAVChatParticipant class], "_ARDChannel");
    IMAVLogIvar([IMAVChatParticipant class], "_ARDChannelNegotiation");
    IMAVLogIvar([IMAVChatParticipant class], "_ARDEncryptionKey");
    IMAVLogIvar([IMAVChatParticipant class], "_incomingVCChannelNegotiations");
    IMAVLogIvar([IMAVChatParticipant class], "_outgoingVCChannelNegotiations");
    IMAVLogIvar([IMAVChatParticipant class], "_ARDFileTransferUsedIndexes");
    IMAVLogIvar([IMAVChatParticipant class], "_ARDFileTransferIndex");
    IMAVLogIvar([IMAVChatFeature class], "_avChat");
}
