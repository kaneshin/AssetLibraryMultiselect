//
//  AssetLibraryMultiSelect
//
//  Copyright (c) 2013 Alexander Belliotti. All rights reserved.
//

#import "ADBAssetStore.h"

#import "ADBAssetItem.h"
#import "ADBGroupItem.h"

#import "ADBHelpers.h"

NSString *const kNotificationSendAssetsUpdated = @"assetsToSendUpdated";
NSString *const kKeyNewToSendAssetsCount       = @"newCountNumber";
NSString *const kKeyTouchedItem                = @"item";
NSString *const kKeyAddedOrRemoved             = @"addedOrRemoved";

NSUInteger kMaxAssetsForUnpurchased            = 5;

@interface ADBAssetStore ()

@property (nonatomic) NSMutableArray *items;

- (void)sendItemsUpdatedNotification:(ADBAssetItem *)touchedItem addedOrRemovedFlag:(BOOL)flag;

@end

@implementation ADBAssetStore

+ (ADBAssetStore *)instance {
    
    static ADBAssetStore *_instance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[ADBAssetStore alloc] init];
    });
    
    return _instance;
}

- (NSArray *)assetItems {
    return self.items;
}

- (NSUInteger)count {
    return self.items.count;
}

- (NSUInteger)countForSelectedAssetsInGroup:(ADBGroupItem *)groupItem {
    if (!groupItem) return 0;
    NSUInteger count = 0;
    
    for (ADBAssetItem *item in self.items) {
        if ([item.groupURL isEqual:groupItem.groupURL]) {
            count++;
        }
    }
    
    return count;
}

- (void)addAssetItem:(ADBAssetItem *)asset {
    if (![self.items containsObject:asset]) {
        [self.items addObject:asset];
        
        [self.items sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            ADBAssetItem *item1 = obj1;
            ADBAssetItem *item2 = obj2;
            
            return [item1.creationDate compare:item2.creationDate];
        }];
        
        [self sendItemsUpdatedNotification:asset addedOrRemovedFlag:YES];
    }
}

- (void)removeAssetItem:(ADBAssetItem *)asset {
    [self.items removeObject:asset];
    [self sendItemsUpdatedNotification:asset addedOrRemovedFlag:NO];
}

- (void)removeAllItems {
    @synchronized (self) {
        [self.items removeAllObjects];
    }
}

- (ADBAssetItem *)itemAtIndex:(NSUInteger)index {
    if (!ADBIsCollectionWithObjects(self.items)) return nil;
    
    if ((self.items.count - 1) >= index) {
        return self.items[index];
    }
    
    return nil;
}

- (BOOL)containsAssetItem:(ADBAssetItem *)asset {
    if ([self.items containsObject:asset]) return YES;
    else return NO;
}

- (BOOL)canAddAsset {
    return YES;
}

- (NSString *)selectedTitleString {
    if (ADBIsCollectionWithObjects(self.items)) {
        NSString *itemsString = (self.items.count > 1) ? @"Items" : @"Item";
        return [NSString stringWithFormat:@"%lu %@ Selected", (unsigned long)self.items.count, itemsString];
    } else {
        return nil;
    }
}

#pragma mark Private

- (NSMutableArray *)items {
    if (!_items) { _items = [NSMutableArray array]; }
    
    return _items;
}

- (void)sendItemsUpdatedNotification:(ADBAssetItem *)item addedOrRemovedFlag:(BOOL)flag {
    if (!item) return;
    
    NSDictionary *userInfo = @{kKeyNewToSendAssetsCount: @(self.items.count), kKeyTouchedItem: item, kKeyAddedOrRemoved: @(flag)};
    NSNotification *notif = [NSNotification notificationWithName:kNotificationSendAssetsUpdated
                                                          object:self
                                                        userInfo:userInfo];
    [[NSNotificationCenter defaultCenter] postNotification:notif];
}

@end
