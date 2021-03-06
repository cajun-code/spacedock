#import "DockEquippedShip+Addons.h"

#import "DockAdmiral+Addons.h"
#import "DockCaptain+Addons.h"
#import "DockConstants.h"
#import "DockEquippedShip+Addons.h"
#import "DockEquippedUpgrade+Addons.h"
#import "DockEquippedUpgrade.h"
#import "DockEquippedFlagship.h"
#import "DockErrors.h"
#import "DockFleetCaptain+Addons.h"
#import "DockFlagship+Addons.h"
#import "DockResource+Addons.h"
#import "DockSet+Addons.h"
#import "DockSetItem+Addons.h"
#import "DockShip+Addons.h"
#import "DockSideboard+Addons.h"
#import "DockSquad+Addons.h"
#import "DockUpgrade+Addons.h"
#import "DockUtils.h"

#import "NSMutableDictionary+Addons.h"

@implementation DockEquippedShip (Addons)

+(NSSet*)keyPathsForValuesAffectingSortedUpgrades
{
    return [NSSet setWithObjects: @"upgrades", @"ship", @"flagship", nil];
}

+(NSSet*)keyPathsForValuesAffectingSortedUpgradesWithFlagship
{
    return [NSSet setWithObjects: @"upgrades", @"ship", @"flagship", nil];
}

+(NSSet*)keyPathsForValuesAffectingCost
{
    return [NSSet setWithObjects: @"upgrades", @"ship", @"flagship", nil];
}

+(NSSet*)keyPathsForValuesAffectingStyledDescription
{
    return [NSSet setWithObjects: @"ship", @"flagship", nil];
}

+(NSSet*)keyPathsForValuesAffectingFormattedCost
{
    return [NSSet setWithObjects: @"cost", nil];
}

-(NSString*)title
{
    if ([self isResourceSideboard]) {
        return self.squad.resource.title;
    }

    return self.ship.title;
}

-(NSString*)plainDescription
{
    if ([self isResourceSideboard]) {
        return self.squad.resource.title;
    }

    return [self.ship plainDescription];
}

-(NSString*)descriptiveTitle
{
    if ([self isResourceSideboard]) {
        return self.squad.resource.title;
    }

    NSString* s = [self.ship descriptiveTitle];
    return s;
}

-(NSString*)descriptiveTitleWithSet
{
    if ([self isResourceSideboard]) {
        return [NSString stringWithFormat: @"%@ [%@]", [self descriptiveTitle], [self.squad.resource setCode]];
    }
    return [NSString stringWithFormat: @"%@ [%@]", [self descriptiveTitle], [self.ship setCode]];
}

-(NSString*)upgradesDescription
{
    NSArray* sortedUpgrades = [self sortedUpgrades];
    NSMutableArray* upgradeTitles = [NSMutableArray arrayWithCapacity: sortedUpgrades.count];

    for (DockEquippedUpgrade* eu in sortedUpgrades) {
        DockUpgrade* upgrade = eu.upgrade;

        if (![upgrade isPlaceholder]) {
            [upgradeTitles addObject: upgrade.title];
        }
    }
    return [upgradeTitles componentsJoinedByString: @", "];
}

-(NSDictionary*)asJSON
{
    NSMutableDictionary* json = [[NSMutableDictionary alloc] init];
    DockShip* ship = self.ship;
    if (ship == nil) {
        [json setObject: @YES forKey: @"sideboard"];
    } else {
        [json setObject: ship.externalId forKey: @"shipId"];
        [json setObject: ship.title forKey: @"shipTitle"];
        DockFlagship* flagship = self.flagship;
        if (flagship != nil) {
            [json setObject: flagship.externalId forKey: @"flagship"];
        }
    }
    [json setObject: [NSNumber numberWithInt: self.cost] forKey: @"calculatedCost"];
    DockEquippedUpgrade* equippedCaptain = self.equippedCaptain;
    if (equippedCaptain) {
        [json setObject: [equippedCaptain asJSON]  forKey: @"captain"];
    }
    NSArray* upgrades = [self sortedUpgrades];
    if (upgrades.count > 0) {
        NSMutableArray* upgradesArray = [[NSMutableArray alloc] initWithCapacity: upgrades.count];
        for (DockEquippedUpgrade* eu in upgrades) {
            if (![eu isPlaceholder] && ![eu.upgrade isCaptain]) {
                [upgradesArray addObject: [eu asJSON]];
            }
        }
        [json setObject: upgradesArray forKey: @"upgrades"];
    }
    return [NSDictionary dictionaryWithDictionary: json];
}

-(NSString*)asPlainTextFormat
{
    NSMutableString* textFormat = [[NSMutableString alloc] init];

    DockResource* resource = self.squad.resource;

    NSString* s = [NSString stringWithFormat: @"%@ [%@] (%d)", self.plainDescription, self.ship.setCode, [self baseCost]];
    [textFormat appendString: s];
    [textFormat appendString: @"\n"];

    DockFlagship* fs = [self flagship];
    if (fs) {
        s = [NSString stringWithFormat: @"%@ [%@] (%@)\n", [fs plainDescription], fs.setCode, [resource cost]];
        [textFormat appendString: s];
    }
    for (DockEquippedUpgrade* upgrade in self.sortedUpgrades) {
        if (![upgrade isPlaceholder]) {
            [textFormat appendString: [upgrade asPlainTextFormat]];
        }
    }

    if (![self isResourceSideboard]) {
        s = [NSString stringWithFormat: @"Total (%d)\n", self.cost];
        [textFormat appendString: s];
    }

    [textFormat appendString: @"\n"];

    return [NSString stringWithString: textFormat];
}

-(NSString*)factionCode
{
    return factionCode(self.ship);
}

-(int)baseCost
{
    if ([self isResourceSideboard]) {
        return [self.squad.resource.cost intValue];
    }

    return [self.ship.cost intValue];
}

-(int)attack
{
    int attack = [self.ship.attack intValue] + [self.flagship attackAdd];
    for (DockEquippedUpgrade* eu in self.upgrades) {
        DockUpgrade* upgrade = eu.upgrade;
        attack += [upgrade additionalAttack];
    }
    return attack;
}

-(int)agility
{
    return [self.ship.agility intValue] + [self.flagship agilityAdd];
}

-(int)hull
{
    int hull = [self.ship.hull intValue] + [self.flagship hullAdd];
    for (DockEquippedUpgrade* eu in self.upgrades) {
        DockUpgrade* upgrade = eu.upgrade;
        hull += [upgrade additionalHull];
    }
    return hull;
}

-(int)shield
{
    return [self.ship.shield intValue] + [self.flagship shieldAdd];
}

-(NSString*)attackString
{
    return [[NSNumber numberWithInt: self.attack] stringValue];
}

-(NSString*)agilityString
{
    return [[NSNumber numberWithInt: self.agility] stringValue];
}

-(NSString*)hullString
{
    return [[NSNumber numberWithInt: self.hull] stringValue];
}

-(NSString*)shieldString
{
    return [[NSNumber numberWithInt: self.shield] stringValue];
}

-(int)cost
{
    int cost = [self.ship.cost intValue];

    for (DockEquippedUpgrade* upgrade in self.upgrades) {
        cost += [upgrade cost];
    }
    
    if (self.flagship != nil) {
        cost += 10;
    }

    return cost;
}

-(DockEquippedUpgrade*)equippedCaptain
{
    if (self.ship.isFighterSquadron) {
        return nil;
    }
    
    for (DockEquippedUpgrade* eu in self.upgrades) {
        DockUpgrade* upgrade = eu.upgrade;

        if ([upgrade.upType isEqualToString: @"Captain"]) {
            return eu;
        }
    }
    return nil;
}

-(DockCaptain*)captain
{
    return (DockCaptain*)[[self equippedCaptain] upgrade];
}

-(DockAdmiral*)admiral
{
    return (DockAdmiral*)[[self equippedAdmiral] upgrade];
}

-(BOOL)isResourceSideboard
{
    return self.ship == nil;
}

-(BOOL)isFighterSquadron
{
    return [self.ship isFighterSquadron];
}

+(DockEquippedShip*)equippedShipWithShip:(DockShip*)ship
{
    NSManagedObjectContext* context = ship.managedObjectContext;
    NSEntityDescription* entity = [NSEntityDescription entityForName: @"EquippedShip"
                                              inManagedObjectContext: context];
    DockEquippedShip* es = [[DockEquippedShip alloc] initWithEntity: entity
                                     insertIntoManagedObjectContext: context];
    es.ship = ship;
    [es establishPlaceholders];
    return es;
}

+(DockEquippedShip*)import:(NSDictionary*)esDict context:(NSManagedObjectContext *)context
{
    DockShip* ship = [DockShip shipForId: esDict[@"shipId"] context: context];
    DockEquippedShip* es = [DockEquippedShip equippedShipWithShip: ship];
    NSString* flagshipId = esDict[@"flagship"];
    if (flagshipId) {
        DockFlagship* flagship = [DockFlagship flagshipForId: flagshipId context: context];
        es.flagship = flagship;
    }
    [es importUpgrades: esDict];
    return es;
}

-(void)importUpgrades:(NSDictionary*)esDict
{
    [self removeAllUpgrades];
    NSManagedObjectContext* context = self.managedObjectContext;
    NSDictionary* upgradeDict = esDict[@"captain"];
    NSString* captainId = upgradeDict[@"upgradeId"];
    [self addUpgrade: [DockCaptain captainForId: captainId context: context]];
    NSArray* upgrades = esDict[@"upgrades"];
    for (upgradeDict in upgrades) {
        NSString* upgradeId = upgradeDict[@"upgradeId"];
        DockUpgrade* upgrade = [DockUpgrade upgradeForId: upgradeId context: context];
        DockEquippedUpgrade* eu = [self addUpgrade: upgrade maybeReplace: nil establishPlaceholders: NO respectLimits: NO];
        NSNumber* overriddenNumber = upgradeDict[@"costIsOverridden"];
        BOOL overridden = [overriddenNumber boolValue];
        if (overridden) {
            eu.overridden = overriddenNumber;
            eu.overriddenCost = upgradeDict[@"overriddenCost"];
        }
    }
    [self removeIllegalUpgrades];
    [self establishPlaceholders];
}

-(DockEquippedShip*)duplicate
{
    DockEquippedShip* newShip;
    if (self.isResourceSideboard) {
        newShip = [DockSideboard sideboard: self.managedObjectContext];
        [newShip removeAllUpgrades];
    } else {
        newShip = [DockEquippedShip equippedShipWithShip: self.ship];
        newShip.flagship = self.flagship;
    }

    DockCaptain* captain = [self captain];
    [newShip addUpgrade: captain maybeReplace: nil establishPlaceholders: NO respectLimits: YES];

    for (DockEquippedUpgrade* equippedUpgrade in self.sortedUpgrades) {
        DockUpgrade* upgrade = [equippedUpgrade upgrade];

        if (![upgrade isPlaceholder] && ![upgrade isCaptain]) {
            DockEquippedUpgrade* duppedUpgrade = [newShip addUpgrade: equippedUpgrade.upgrade maybeReplace: nil establishPlaceholders: NO respectLimits: NO];
            duppedUpgrade.overridden = equippedUpgrade.overridden;
            duppedUpgrade.overriddenCost = equippedUpgrade.overriddenCost;
        }
    }
    [newShip establishPlaceholders];
    return newShip;
}

-(int)equipped:(NSString*)upType
{
    int count = 0;

    for (DockEquippedUpgrade* eu in self.upgrades) {
        if ([eu.upgrade.upType isEqualToString: upType]) {
            count += 1;
        }
    }
    return count;
}

-(void)removeOverLimit:(NSString*)upType current:(int)current limit:(int)limit
{
    int amountToRemove = current - limit;
    [self removeUpgradesOfType: upType targetCount: amountToRemove];
}

-(void)establishPlaceholdersForType:(NSString*)upType limit:(int)limit
{
    NSManagedObjectContext* context = self.managedObjectContext;
    int current = [self equipped: upType];

    if (current > limit) {
        [self removeOverLimit: upType current: current limit: limit];
    } else {
        for (int i = current; i < limit; ++i) {
            DockUpgrade* upgrade = [DockUpgrade placeholder: upType inContext: context];
            [self addUpgrade: upgrade maybeReplace: nil establishPlaceholders: NO];
        }
    }
}

-(NSString*)shipFaction
{
    return self.ship.faction;
}

-(void)establishPlaceholders
{
    if (self.captainCount > 0) {
        DockCaptain* captain = [self captain];

        if (captain == nil) {
            NSString* faction = self.shipFaction;

            if ([faction isEqualToString: @"Independent"] || [faction isEqualToString: @"Bajoran"]) {
                faction = @"Federation";
            }

            DockUpgrade* zcc = nil;
            if (self.isResourceSideboard) {
                zcc = [DockCaptain zeroCostCaptain: faction context: self.managedObjectContext];
            } else {
                zcc = [DockCaptain zeroCostCaptainForShip: self.ship];
            }
            [self addUpgrade: zcc maybeReplace: nil establishPlaceholders: NO];
        }
    }

    [self establishPlaceholdersForType: @"Talent" limit: self.talentCount];
    [self establishPlaceholdersForType: @"Crew" limit: self.crewCount];
    [self establishPlaceholdersForType: @"Weapon" limit: self.weaponCount];
    [self establishPlaceholdersForType: @"Tech" limit: self.techCount];
    [self establishPlaceholdersForType: @"Borg" limit: self.borgCount];
}

-(DockEquippedUpgrade*)findPlaceholder:(NSString*)upType
{
    for (DockEquippedUpgrade* eu in self.upgrades) {
        if ([eu isPlaceholder] && [eu.upgrade.upType isEqualToString: upType]) {
            return eu;
        }
    }
    return nil;
}

-(void)removeAllTalents
{
    NSMutableSet* onesToRemove = [NSMutableSet setWithCapacity: 0];

    for (DockEquippedUpgrade* eu in self.upgrades) {
        if ([eu.upgrade isTalent]) {
            [onesToRemove addObject: eu];
        }
    }

    for (DockEquippedUpgrade* eu in onesToRemove) {
        [self removeUpgradeInternal: eu];
    }
}

-(void)removeAllUpgrades
{
    NSMutableSet* onesToRemove = [NSMutableSet setWithCapacity: 0];

    for (DockEquippedUpgrade* eu in self.upgrades) {
        [onesToRemove addObject: eu];
    }

    for (DockEquippedUpgrade* eu in onesToRemove) {
        [self removeUpgradeInternal: eu];
    }
}

-(BOOL)canAddUpgrade:(DockUpgrade*)upgrade ignoreInstalled:(BOOL)ignoreInstalled
{
    return [self canAddUpgrade: upgrade ignoreInstalled: NO validating: YES];
}

-(BOOL)canAddUpgrade:(DockUpgrade*)upgrade ignoreInstalled:(BOOL)ignoreInstalled validating:(BOOL)validating
{
    DockCaptain* captain = [self captain];

    if ([upgrade isFleetCaptain]) {
        DockFleetCaptain* fleetCaptain = (DockFleetCaptain*)upgrade;
        return [self canAddFleetCaptain: fleetCaptain error: nil];
    }
    
    if ([upgrade isTalent]) {
        if ([captain.special isEqualToString: @"lore_71522"]) {
            return [upgrade isRestrictedOnlyByFaction];
        }
    }

    NSString* upgradeSpecial = upgrade.special;

    if ([upgrade.title isEqualToString: @"Hugh"]) {
        if ([self.squad containsUpgradeWithSpecial: @"not_with_hugh"] != nil) {
            return NO;
        }
    }

    if ([upgrade isBorg]) {
        if ([self.ship isScoutCube]) {
            return [[upgrade cost] intValue] <= 5;
        }
    }

    if ([upgradeSpecial isEqualToString: @"OnlyJemHadarShips"]) {
        if (![self.ship isJemhadar]) {
            return NO;
        }
    }

    if ([upgradeSpecial isEqualToString: @"OnlyTholianShip"]) {
        if (![self.ship isTholian]) {
            return NO;
        }
    }

    if ([upgradeSpecial isEqualToString: @"OnlyForKlingonCaptain"]) {
        if (![self.captain isKlingon]) {
            return NO;
        }
    }

    if ([upgradeSpecial isEqualToString: @"OnlyBajoranCaptain"]) {
        if (![self.captain isBajoran]) {
            return NO;
        }
    }

    if ([upgradeSpecial isEqualToString: @"OnlyDominionCaptain"]) {
        if (![self.captain isDominion]) {
            return NO;
        }
    }

    if ([upgradeSpecial isEqualToString: @"OnlyTholianCaptain"]) {
        if (![self.captain isTholian]) {
            return NO;
        }
    }

    if ([upgradeSpecial isEqualToString: @"OnlyBorgCaptain"]) {
        if (![captain isFactionBorg]) {
            return NO;
        }
    }

    if ([upgradeSpecial isEqualToString: @"OnlySpecies8472Ship"]) {
        if (![self.ship isSpecies8472]) {
            return NO;
        }
    }

    if ([upgradeSpecial isEqualToString: @"OnlyKazonShip"]) {
        if (![self.ship isKazon]) {
            return NO;
        }
    }

    if ([upgradeSpecial isEqualToString: @"OnlyBorgShip"] || [upgradeSpecial isEqualToString: @"OnlyBorgShipAndNoMoreThanOnePerShip"]) {
        if (![self.ship isBorg]) {
            return NO;
        }
    }

    if ([upgradeSpecial isEqualToString: @"OnlyBorgShip"] || [upgradeSpecial isEqualToString: @"OnlyBorgShipAndNoMoreThanOnePerShip"]) {
        if (![self.ship isBorg]) {
            return NO;
        }
    }

    if ([upgradeSpecial isEqualToString: @"OnlyFederationShip"] || [upgradeSpecial isEqualToString: @"ony_federation_ship_limited"]) {
        if (![self.ship isFederation]) {
            return NO;
        }
    }

    if ([upgradeSpecial isEqualToString: @"only_vulcan_ship"]) {
        if (![self.ship isVulcan]) {
            return NO;
        }
    }

    if ([upgradeSpecial isEqualToString: @"only_suurok_class_limited_weapon_hull_plus_1"]) {
        if (![self.ship isSuurokClass]) {
            return NO;
        }
    }

    if ([upgradeSpecial isEqualToString: @"OnlyVoyager"]) {
        if (![self.ship isVoyager]) {
            return NO;
        }
    }

    if ([upgradeSpecial isEqualToString: @"OnlyFerengiShip"]) {
        if (![self.ship isFerengi]) {
            return NO;
        }
    }

    if ([upgradeSpecial isEqualToString: @"OnlyFerengiCaptainFerengiShip"]) {
        if (![self.ship isFerengi] || ![captain isFerengi]) {
            return NO;
        }
    }

    if ([upgradeSpecial isEqualToString: @"OnlyVulcanCaptainVulcanShip"]) {
        if (![self.ship isVulcan] || ![captain isVulcan]) {
            return NO;
        }
    }

    if ([upgradeSpecial isEqualToString: @"OnlyBattleshipOrCruiser"]) {
        if (![self.ship isBattleshipOrCruiser]) {
            return NO;
        }
    }

    if ([upgradeSpecial isEqualToString: @"OnlyNonBorgShipAndNonBorgCaptain"]) {
        if ([self.ship isBorg] || [captain isBorg]) {
            return NO;
        }
    }

    if ([upgradeSpecial isEqualToString: @"PhaserStrike"] || [upgradeSpecial isEqualToString: @"OnlyHull3OrLess"]) {
        if ([[self.ship hull] intValue] > 3) {
            return NO;
        }
    }

    if (!validating) {
        if ([upgradeSpecial isEqualToString: @"OnlyBorgShipAndNoMoreThanOnePerShip"] || [upgradeSpecial isEqualToString: @"NoMoreThanOnePerShip"] || [upgradeSpecial isEqualToString: @"ony_federation_ship_limited"] || [upgradeSpecial isEqualToString: @"only_suurok_class_limited_weapon_hull_plus_1"]) {
            DockEquippedUpgrade* existing = [self containsUpgradeWithId: upgrade.externalId];
            if (existing != nil) {
                return NO;
            }
        }
    }

    if ([upgradeSpecial isEqualToString: @"not_with_hugh"]) {
        if ([self.squad containsUpgradeWithName: @"Hugh"] != nil) {
            return NO;
        }
    }


    if ([upgradeSpecial isEqualToString: @"OnlyForRomulanScienceVessel"] || [upgradeSpecial isEqualToString: @"OnlyForRaptorClassShips"]) {
        NSString* legalShipClass = upgrade.targetShipClass;

        if (![legalShipClass isEqualToString: self.ship.shipClass]) {
            return NO;
        }
    }

    if ([upgradeSpecial isEqualToString: @"OnlyFedShipHV4CostPWVP1"]) {
        if (![self.ship isFederation] || [self.ship.hull intValue] < 4) {
            return NO;
        }
    }


    if (ignoreInstalled) {
        return YES;
    }

    int limit = [upgrade limitForShip: self];
    return limit > 0;
}

-(BOOL)canAddUpgrade:(DockUpgrade*)upgrade
{
    return [self canAddUpgrade: upgrade ignoreInstalled: NO];
}

-(NSDictionary*)explainCantAddUpgrade:(DockUpgrade*)upgrade
{
    NSString* msg = [NSString stringWithFormat: @"Can't add %@ to %@", [upgrade plainDescription], [self plainDescription]];
    NSString* info = @"";
    if ([self isFighterSquadron]) {
        info = @"Fighter Squadrons cannot accept upgrades.";
    } else {
        int limit = [upgrade limitForShip: self];
        
        if (limit == 0) {
            NSString* targetClass = [upgrade targetShipClass];
            
            if (targetClass != nil) {
                info = [NSString stringWithFormat: @"This upgrade can only be installed on ships of class %@.", targetClass];
            } else {
                if ([upgrade isTalent]) {
                    info = [NSString stringWithFormat: @"This ship's captain has no %@ upgrade symbols.", [upgrade.upType lowercaseString]];
                } else {
                    info = [NSString stringWithFormat: @"This ship has no %@ upgrade symbols on its ship card.", [upgrade.upType lowercaseString]];
                }
            }
        } else {
            NSString* upgradeSpecial = upgrade.special;
            
            if ([upgradeSpecial isEqualToString: @"OnlyJemHadarShips"]) {
                info = @"This upgrade can only be added to Jem'hadar ships.";
            } else if ([upgradeSpecial isEqualToString: @"OnlyForKlingonCaptain"]) {
                info = @"This upgrade can only be added to a Klingon Captain.";
            } else if ([upgradeSpecial isEqualToString: @"OnlyBajoranCaptain"]) {
                info = @"This upgrade can only be added to a Bajoran Captain.";
            } else if ([upgradeSpecial isEqualToString: @"OnlyDominionCaptain"]) {
                info = @"This upgrade can only be added to a Dominion Captain.";
            } else if ([upgradeSpecial isEqualToString: @"OnlySpecies8472Ship"]) {
                info = @"This upgrade can only be added to Species 8472 ships.";
            } else if ([upgradeSpecial isEqualToString: @"OnlyKazonShip"]) {
                info = @"This upgrade can only be added to Kazon ships.";
            } else if ([upgradeSpecial isEqualToString: @"OnlyBorgShip"]) {
                info = @"This upgrade can only be added to Borg ships.";
            } else if ([upgradeSpecial isEqualToString: @"only_vulcan_ship"]) {
                info = @"This upgrade can only be added to Vulcan ships.";
            } else if ([upgradeSpecial isEqualToString: @"OnlyFederationShip"]) {
                info = @"This upgrade can only be added to Federation ships.";
            } else if ([upgradeSpecial isEqualToString: @"OnlyVoyager"]) {
                info = @"This upgrade can only be added to Voyager.";
            } else if ([upgradeSpecial isEqualToString: @"OnlyTholianShip"]) {
                info = @"This upgrade can only be added to a Tholian ship.";
            } else if ([upgradeSpecial isEqualToString: @"OnlyTholianCaptain"]) {
                info = @"This upgrade can only be added to a Tholian captain.";
            } else if ([upgradeSpecial isEqualToString: @"OnlyBorgCaptain"]) {
                info = @"This upgrade may only be purchased for a Borg Captain.";
            } else if ([upgradeSpecial isEqualToString: @"OnlyVulcanCaptainVulcanShip"]) {
                info = @"This upgrade can only be added to a Vulcan captain on a Vulcan ship.";
            } else if ([upgradeSpecial isEqualToString: @"PhaserStrike"] || [upgradeSpecial isEqualToString: @"OnlyHull3OrLess"]) {
                info = @"This upgrade may only be purchased for a ship with a Hull value of 3 or less.";
            } else if ([upgradeSpecial isEqualToString: @"NoMoreThanOnePerShip"] || [upgradeSpecial isEqualToString: @"ony_federation_ship_limited"] || [upgradeSpecial isEqualToString: @"OnlyBorgShipAndNoMoreThanOnePerShip"]) {
                info = @"No ship may be equipped with more than one of these upgrades.";
            } else if ([upgradeSpecial isEqualToString: @"OnlyBattleshipOrCruiser"]) {
                info = @"This upgrade may only be purchased for a Jem'Hadar Battle Cruiser or Battleship.";
            } else if ([upgradeSpecial isEqualToString: @"OnlyFerengiShip"]) {
                info = @"This Upgrade may only be purchased for a Ferengi ship.";
            } else if ([upgradeSpecial isEqualToString: @"OnlyFerengiCaptainFerengiShip"]) {
                info = @"This Upgrade may only be purchased for a Ferengi Captain assigned to a Ferengi ship.";
            } else if ([upgradeSpecial isEqualToString: @"not_with_hugh"]) {
                info = @"You cannot deploy this card to the same ship or fleet as Hugh.";
            } else if ([upgradeSpecial isEqualToString: @"OnlyFedShipHV4CostPWVP1"]) {
                info = @"This Upgrade may only be purchased for a Federation ship with a Hull Value of 4 or greater.";
            } else if ([upgradeSpecial isEqualToString: @"OnlyNonBorgShipAndNonBorgCaptain"]) {
                info = @"This Upgrade may only be purchased for a non-Borg ship with a non-Borg Captain.";
            }
        }
    }

    return @{
             @"info": info, @"message": msg
             };
}

-(void)makeError:(NSError**)error msg:(NSString*)msg info:(NSString*)info
{
    if (error) {
        NSDictionary* d = @{
            NSLocalizedDescriptionKey: msg,
            NSLocalizedFailureReasonErrorKey: info
        };
        *error = [NSError errorWithDomain: DockErrorDomain code: kUniqueConflict userInfo: d];
    }
}

-(BOOL)canAddFleetCaptain:(DockFleetCaptain*)fleetCaptain error:(NSError**)error
{
    DockCaptain* captain = [self captain];
    NSString* msg = [NSString stringWithFormat: @"Can't make %@ the Fleet Captain.", captain.title];
    if ([captain.skill intValue] < 2) {
        NSString* info = @"You may not assign a non-unique Captain as your Fleet Captain.";
        [self makeError: error msg:msg info: info];
        return NO;
    }

    NSString* fleetCaptainFaction = fleetCaptain.faction;
    if (![fleetCaptainFaction isEqualToString: @"Independent"]) {
        if (!factionsMatch(self.ship, fleetCaptain)) {
            NSString* info = @"The ship's faction must be the same as the Fleet Captain.";
            [self makeError: error msg:msg info: info];
            return NO;
        }
        if (!factionsMatch(captain, fleetCaptain)) {
            NSString* info = @"The Captain's faction must be the same as the Fleet Captain.";
            [self makeError: error msg:msg info: info];
            return NO;
        }
    }

    return YES;
}

-(DockEquippedUpgrade*)addUpgradeInternal:(DockEquippedUpgrade *)equippedUpgrade
{
    [self willChangeValueForKey: @"cost"];
    [self addUpgrades: [NSSet setWithObject: equippedUpgrade]];
    [self didChangeValueForKey: @"cost"];
    return equippedUpgrade;
}

-(DockEquippedUpgrade*)addUpgrade:(DockUpgrade*)upgrade maybeReplace:(DockEquippedUpgrade*)maybeReplace establishPlaceholders:(BOOL)establish
{
    return [self addUpgrade: upgrade maybeReplace: maybeReplace establishPlaceholders: establish respectLimits: YES];
}

-(DockEquippedUpgrade*)addUpgrade:(DockUpgrade*)upgrade maybeReplace:(DockEquippedUpgrade*)maybeReplace establishPlaceholders:(BOOL)establish respectLimits:(BOOL)respectLimits
{
    NSManagedObjectContext* context = [self managedObjectContext];
    NSEntityDescription* entity = [NSEntityDescription entityForName: @"EquippedUpgrade"
                                              inManagedObjectContext: context];
    DockEquippedUpgrade* equippedUpgrade = [[DockEquippedUpgrade alloc] initWithEntity: entity
                                                        insertIntoManagedObjectContext: context];
    equippedUpgrade.upgrade = upgrade;

    if (establish && ![upgrade isPlaceholder]) {
        DockEquippedUpgrade* ph = [self findPlaceholder: upgrade.upType];

        if (ph) {
            [self removeUpgrade: ph];
        }
    }

    NSString* upType = [upgrade upType];
    int limit = [upgrade limitForShip: self];
    int current = [self equipped: upType];

    if (respectLimits && current == limit) {
        if (maybeReplace == nil || ![maybeReplace.upgrade.upType isEqualToString: upType]) {
            maybeReplace = [self firstUpgrade: upType];
        }

        [self removeUpgrade: maybeReplace establishPlaceholders: NO];
    }

    [self addUpgradeInternal: equippedUpgrade];

    if (establish) {
        [self establishPlaceholders];
    }

    [[self squad] squadCompositionChanged];
    return equippedUpgrade;
}

-(DockEquippedUpgrade*)addUpgrade:(DockUpgrade*)upgrade maybeReplace:(DockEquippedUpgrade*)maybeReplace
{
    return [self addUpgrade: upgrade maybeReplace: maybeReplace establishPlaceholders: YES];
}

-(DockEquippedUpgrade*)firstUpgrade:(NSString*)upType
{
    for (DockEquippedUpgrade* eu in self.sortedUpgrades) {
        if ([upType isEqualToString: eu.upgrade.upType]) {
            return eu;
        }
    }
    return nil;
}

-(DockEquippedUpgrade*)mostExpensiveUpgradeOfFaction:(NSString*)faction upType:(NSString*)upType
{
    DockEquippedUpgrade* mostExpensive = nil;
    NSArray* allUpgrades = [self allUpgradesOfFaction: faction upType: upType];

    if (allUpgrades.count > 0) {
        mostExpensive = allUpgrades[0];
    }

    return mostExpensive;
}

-(NSArray*)allUpgradesOfFaction:(NSString*)faction upType:(NSString*)upType
{
    NSMutableArray* allUpgrades = [[NSMutableArray alloc] init];

    for (DockEquippedUpgrade* eu in self.sortedUpgrades) {
        DockUpgrade* upgrade = eu.upgrade;
        if (![upgrade isCaptain] && ![upgrade isPlaceholder]) {
            if (upType == nil || [upType isEqualToString: upgrade.upType]) {
                if (faction == nil || [faction isEqualToString: upgrade.faction]) {
                    [allUpgrades addObject: eu];
                }
            }
        }
    }

    if (allUpgrades.count > 0) {
        if (allUpgrades.count > 1) {
            id cmp = ^(DockEquippedUpgrade* a, DockEquippedUpgrade* b) {
                int aCost = [a rawCost];
                int bCost = [b rawCost];

                if (aCost == bCost) {
                    return NSOrderedSame;
                } else if (aCost > bCost) {
                    return NSOrderedAscending;
                }

                return NSOrderedDescending;
            };
            [allUpgrades sortUsingComparator: cmp];
        }

    }

    return [NSArray arrayWithArray: allUpgrades];
}

-(DockEquippedUpgrade*)addUpgrade:(DockUpgrade*)upgrade
{
    return [self addUpgrade: upgrade maybeReplace: nil];
}

-(void)removeUpgradeInternal:(DockEquippedUpgrade*)upgrade
{
    [self willChangeValueForKey: @"cost"];
    [self removeUpgrades: [NSSet setWithObject: upgrade]];
    [self didChangeValueForKey: @"cost"];
}

-(void)removeUpgrade:(DockEquippedUpgrade*)upgrade establishPlaceholders:(BOOL)doEstablish
{
    if (upgrade != nil) {
        [self removeUpgradeInternal: upgrade];

        if (doEstablish) {
            [self establishPlaceholders];
        }

        [self removeIllegalUpgrades];

        [[self squad] squadCompositionChanged];
    }
}

-(void)removeUpgrade:(DockEquippedUpgrade*)upgrade
{
    [self removeUpgrade: upgrade establishPlaceholders: NO];
}

-(void)removeUpgradesOfType:(NSString*)upType targetCount:(int)targetCount
{
    NSMutableArray* onesToRemove = [[NSMutableArray alloc] initWithCapacity: 0];

    for (DockEquippedUpgrade* eu in self.sortedUpgrades) {
        if ([eu.upgrade isPlaceholder] && [upType isEqualToString: eu.upgrade.upType]) {
            [onesToRemove addObject: eu];
        }

        if (onesToRemove.count == targetCount) {
            break;
        }
    }

    if (onesToRemove.count != targetCount) {
        for (DockEquippedUpgrade* eu in self.sortedUpgrades) {
            if ([upType isEqualToString: eu.upgrade.upType]) {
                [onesToRemove addObject: eu];
            }

            if (onesToRemove.count == targetCount) {
                break;
            }
        }
    }

    for (DockEquippedUpgrade* eu in onesToRemove) {
        [self removeUpgrade: eu establishPlaceholders: NO];
    }
}

-(void)removeIllegalUpgrades
{
    NSMutableArray* onesToRemove = [[NSMutableArray alloc] initWithCapacity: 0];

    for (DockEquippedUpgrade* eu in self.sortedUpgrades) {
        if (![self canAddUpgrade: eu.upgrade ignoreInstalled: NO validating: YES]) {
            [self canAddUpgrade: eu.upgrade];
            [onesToRemove addObject: eu];
        }
    }

    for (DockEquippedUpgrade* eu in onesToRemove) {
        [self removeUpgrade: eu establishPlaceholders: NO];
    }
}

-(NSArray*)sortedUpgrades
{
    NSArray* items = [self.upgrades allObjects];
    return [items sortedArrayUsingComparator: ^(DockEquippedUpgrade* a, DockEquippedUpgrade* b) {
                return [a compareTo: b];
            }

    ];
}

-(NSArray*)sortedUpgradesWithFlagship
{
    NSArray* items = [self.upgrades allObjects];
#if !TARGET_OS_IPHONE
    if (self.flagship) {
        DockEquippedFlagship* efs = [DockEquippedFlagship equippedFlagship: self.flagship forShip: self];
        items = [@[efs] arrayByAddingObjectsFromArray: items];
    }
#endif
    return [items sortedArrayUsingComparator: ^(DockEquippedUpgrade* a, DockEquippedUpgrade* b) {
                return [a compareTo: b];
            }

    ];
}

-(NSArray*)sortedUpgradesWithoutPlaceholders
{
    NSMutableArray* result = [[NSMutableArray alloc] initWithCapacity: 0];
    NSArray* sortedUpgrades = [self sortedUpgrades];
    for (DockUpgrade* upgrade in sortedUpgrades) {
        if (!upgrade.isPlaceholder && !upgrade.isCaptain) {
            [result addObject: upgrade];
        }
    }
    return [NSArray arrayWithArray: result];
}

-(void)removeCaptain
{
    [self removeUpgrade: [self equippedCaptain]];
}

-(int)talentCount
{
    int talentCount = 0;
    talentCount += [self.flagship talentAdd];
    for (DockEquippedUpgrade* eu in self.upgrades) {
        DockUpgrade* upgrade = eu.upgrade;
        talentCount += [upgrade additionalTalentSlots];
    }

    return talentCount;

#if 0
    DockCaptain* captain = [self captain];
    int talentCount = [captain talentCount];
    DockAdmiral* admiral = [self admiral];
    talentCount += admiral.admiralTalentCount;
    talentCount += [self.flagship talentAdd];
    return talentCount;
#endif
}

-(int)shipPropertyCount:(NSString*)propertyName
{
    return [[self.ship valueForKey: propertyName] intValue];
}

-(int)techCount
{
    int techCount = [self shipPropertyCount: @"tech"];
    techCount += [self.flagship techAdd];
    for (DockEquippedUpgrade* eu in self.upgrades) {
        DockUpgrade* upgrade = eu.upgrade;
        techCount += [upgrade additionalTechSlots];
    }

    return techCount;
}

-(int)weaponCount
{
    int weaponCount = [self shipPropertyCount: @"weapon"];
    weaponCount += [self.flagship weaponAdd];

    for (DockEquippedUpgrade* eu in self.upgrades) {
        DockUpgrade* upgrade = eu.upgrade;
        weaponCount += [upgrade additionalWeaponSlots];
    }

    return weaponCount;
}

-(int)crewCount
{
    int crewCount = [self shipPropertyCount: @"crew"];
    crewCount += [self.flagship crewAdd];
    for (DockEquippedUpgrade* eu in self.upgrades) {
        DockUpgrade* upgrade = eu.upgrade;
        crewCount += [upgrade additionalCrewSlots];
    }

    return crewCount;
}

-(int)upgradeCount
{
    int count = 0;

    for (DockEquippedUpgrade* eu in[self sortedUpgrades]) {
        DockUpgrade* upgrade = eu.upgrade;

        if (![upgrade isPlaceholder] && ![upgrade isCaptain]) {
            count += 1;
        }
    }
    return count;
}

-(int)captainCount
{
    return self.ship.captainCount;
}

-(int)admiralCount
{
    return self.ship.admiralCount;
}

-(int)fleetCaptainCount
{
    return self.ship.fleetCaptainCount;
}

-(int)borgCount
{
    int borgCount = self.ship.borgCount;
    for (DockEquippedUpgrade* eu in self.upgrades) {
        DockUpgrade* upgrade = eu.upgrade;
        borgCount += [upgrade additionalBorgSlots];
    }

    return borgCount;
}

-(int)officerLimit
{
    NSArray* crewUpgrades = [self allUpgradesOfFaction: nil upType: @"Crew"];
    NSInteger limit = crewUpgrades.count * 2;
    return (int)limit;
}

-(NSString*)ability
{
    return self.ship.ability;
}

-(DockEquippedUpgrade*)containsUpgrade:(DockUpgrade*)theUpgrade
{
    for (DockEquippedUpgrade* eu in self.sortedUpgrades) {
        if (eu.upgrade == theUpgrade) {
            return eu;
        }
    }
    return nil;
}

-(DockEquippedUpgrade*)containsUpgradeWithName:(NSString*)theName
{
    for (DockEquippedUpgrade* eu in self.sortedUpgrades) {
        if ([eu.upgrade.title isEqualToString: theName]) {
            return eu;
        }
    }
    return nil;
}

-(DockEquippedUpgrade*)containsUniqueUpgradeWithName:(NSString*)theName
{
    for (DockEquippedUpgrade* eu in self.sortedUpgrades) {
        DockUpgrade* upgrade = eu.upgrade;
        if (upgrade.isUnique && [upgrade.title isEqualToString: theName]) {
            return eu;
        }
    }
    return nil;
}

-(DockEquippedUpgrade*)containsMirrorUniverseUniqueUpgradeWithName:(NSString*)theName
{
    for (DockEquippedUpgrade* eu in self.sortedUpgrades) {
        DockUpgrade* upgrade = eu.upgrade;
        if (upgrade.isMirrorUniverseUnique && [upgrade.title isEqualToString: theName]) {
            return eu;
        }
    }
    return nil;
}


-(DockEquippedUpgrade*)containsUpgradeWithSpecial:(NSString*)special
{
    for (DockEquippedUpgrade* eu in self.sortedUpgrades) {
        if ([eu.upgrade.special isEqualToString: special]) {
            return eu;
        }
    }
    return nil;
}

-(DockEquippedUpgrade*)containsUpgradeWithId:(NSString*)theId
{
    for (DockEquippedUpgrade* eu in self.sortedUpgrades) {
        if ([eu.upgrade.externalId isEqualToString: theId]) {
            return eu;
        }
    }
    return nil;
}

-(void)changeShip:(DockShip*)newShip
{
    BOOL wasFighter = [self isFighterSquadron];
    self.ship = newShip;
    [self removeIllegalUpgrades];
    [self establishPlaceholders];
    if (wasFighter) {
        self.squad.resource = nil;
    } else if (newShip.isFighterSquadron) {
        self.squad.resource = newShip.associatedResource;
    }
}

-(NSDictionary*)becomeFlagship:(DockFlagship*)flagship
{
    if (![flagship compatibleWithShip: self.ship]) {
        if (self.ship.isFighterSquadron) {
            NSString* msg = [NSString stringWithFormat: @"Can't add %@ to %@", [flagship plainDescription], [self.ship plainDescription]];
            NSString* info = @"It is illogical to try to make a figher squadron into a flagship.";
            return @{@"info": info, @"message": msg};
        }
        NSString* msg = [NSString stringWithFormat: @"Can't add %@ to %@", [flagship plainDescription], [self.ship plainDescription]];
        NSString* info = @"The faction of the flagship must be independent or match the faction of the target ship.";
        return @{@"info": info, @"message": msg};
    }
    if (self.flagship != flagship) {
        for (DockEquippedShip* equippedShip in self.squad.equippedShips) {
            if (equippedShip != self) {
                [equippedShip removeFlagship];
            }
        }
        self.flagship = flagship;
        self.squad.resource = [DockResource flagshipResource: self.managedObjectContext];
        [self establishPlaceholders];
    }
    
    return nil;
}

-(void)removeFlagship
{
    if (self.flagship != nil) {
        self.flagship = nil;
        [self establishPlaceholders];
    }
}

-(void)handleNewInsertedOrReplaced:(NSDictionary*)change
{
    NSArray* newInsertedOrReplaced = [change objectForKey: NSKeyValueChangeNewKey];
    if (newInsertedOrReplaced != (NSArray*)[NSNull null]) {
        for (DockEquippedUpgrade* upgrade in newInsertedOrReplaced) {
            [upgrade addObserver: self forKeyPath: @"cost" options: 0 context: 0];
        }
    }
}

-(void)handleOldRemovedOrReplaced:(NSDictionary*)change
{
    NSArray* oldRemovedOrReplaced = [change objectForKey: NSKeyValueChangeOldKey];
    if (oldRemovedOrReplaced != (NSArray*)[NSNull null]) {
        for (DockEquippedUpgrade* upgrade in oldRemovedOrReplaced) {
            [upgrade removeObserver: self forKeyPath: @"cost"];
        }
    }
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if (![self isFault]) {
        if ([keyPath isEqualToString: @"cost"]) {
            [self willChangeValueForKey: @"cost"];
            [self didChangeValueForKey: @"cost"];
        } else {
            NSUInteger kind = [[change valueForKey: NSKeyValueChangeKindKey] integerValue];
            switch (kind) {
            case NSKeyValueChangeInsertion:
                [self handleNewInsertedOrReplaced: change];
                break;
            case NSKeyValueChangeRemoval:
                [self handleOldRemovedOrReplaced: change];
                break;
            case NSKeyValueChangeSetting:
                [self handleNewInsertedOrReplaced: change];
                [self handleOldRemovedOrReplaced: change];
                break;
            default:
                NSLog(@"unhandled kind in observeValueForKeyPath: %@", change);
                break;
            }
        }
    }
}

-(void)watchForCostChange
{
    for (DockEquippedUpgrade* upgrade in self.upgrades) {
        [upgrade addObserver: self forKeyPath: @"cost" options: 0 context: 0];
    }
    [self addObserver: self forKeyPath: @"upgrades" options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context: 0];
}

-(void)stopWatchingForCostChange
{
    for (DockEquippedUpgrade* upgrade in self.upgrades) {
        [upgrade removeObserver: self forKeyPath: @"cost"];
    }
    [self removeObserver: self forKeyPath: @"upgrades"];
}

-(void)awakeFromInsert
{
    [super awakeFromInsert];
    [self watchForCostChange];
}

-(void)awakeFromFetch
{
    [super awakeFromFetch];
    [self watchForCostChange];
}

- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flags
{
    [super awakeFromSnapshotEvents: flags];
    [self watchForCostChange];
}

- (void)willTurnIntoFault
{
    [self stopWatchingForCostChange];
}

-(void)willSave
{
    [self.squad updateModificationDate];
}

-(DockEquippedUpgrade*)addAdmiral:(DockAdmiral*)admiral
{
    [self removeAdmiral];
    return [self addUpgrade: admiral];
}

-(void)removeAdmiral
{
    DockEquippedUpgrade* admiral = [self equippedAdmiral];
    if (admiral != nil) {
        [self removeUpgrade: admiral];
    }
}

-(DockEquippedUpgrade*)equippedAdmiral
{
    if (self.ship.isFighterSquadron) {
        return nil;
    }
    
    for (DockEquippedUpgrade* eu in self.upgrades) {
        DockUpgrade* upgrade = eu.upgrade;

        if ([upgrade.upType isEqualToString: kAdmiralUpgradeType]) {
            return eu;
        }
    }
    return nil;
}

-(DockEquippedUpgrade*)equippedFleetCaptain
{
    if (self.ship.isFighterSquadron) {
        return nil;
    }
    
    for (DockEquippedUpgrade* eu in self.upgrades) {
        DockUpgrade* upgrade = eu.upgrade;

        if ([upgrade.upType isEqualToString: kFleetCaptainUpgradeType]) {
            return eu;
        }
    }
    return nil;
}

-(void)purgeUpgrade:(DockUpgrade*)upgrade
{
    NSMutableSet* onesToRemove = [NSMutableSet setWithCapacity: 0];

    for (DockEquippedUpgrade* eu in self.upgrades) {
        if (eu.upgrade == upgrade) {
            [onesToRemove addObject: eu];
        }
    }

    for (DockEquippedUpgrade* eu in onesToRemove) {
        [self removeUpgradeInternal: eu];
    }
}

@end
