// Declarações de API privada do IOKit usadas para ler os sensores de temperatura.
// Não estão nos headers públicos do SDK, mas existem no IOKit.framework.

#include <IOKit/hidsystem/IOHIDEventSystemClient.h>
#include <IOKit/hidsystem/IOHIDServiceClient.h>

typedef struct CF_BRIDGED_TYPE(id) __IOHIDEvent *IOHIDEventRef;

#define kIOHIDEventTypeTemperature 15

CF_RETURNS_RETAINED
IOHIDEventSystemClientRef _Nullable IOHIDEventSystemClientCreate(CFAllocatorRef _Nullable allocator);

int IOHIDEventSystemClientSetMatching(IOHIDEventSystemClientRef _Nonnull client, CFDictionaryRef _Nonnull match);

CF_RETURNS_RETAINED
IOHIDEventRef _Nullable IOHIDServiceClientCopyEvent(IOHIDServiceClientRef _Nonnull service, int64_t type, int32_t options, int64_t timestamp);

double IOHIDEventGetFloatValue(IOHIDEventRef _Nonnull event, int32_t field);
