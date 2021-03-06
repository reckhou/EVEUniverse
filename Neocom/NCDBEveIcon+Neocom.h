//
//  NCDBEveIcon+Neocom.h
//  Neocom
//
//  Created by Артем Шиманский on 11.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDBEveIcon.h"

@interface NCDBEveIcon (Neocom)

+ (instancetype) defaultTypeIcon;
+ (instancetype) defaultGroupIcon;
+ (instancetype) certificateUnclaimedIcon;
+ (instancetype) eveIconWithIconFile:(NSString*) iconFile;
@end
