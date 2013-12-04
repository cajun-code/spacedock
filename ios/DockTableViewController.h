#import <UIKit/UIKit.h>

@interface DockTableViewController : UITableViewController<NSFetchedResultsControllerDelegate>
@property (nonatomic, strong) NSManagedObjectContext* managedObjectContext;
@property (nonatomic, strong) NSFetchedResultsController* fetchedResultsController;
@property (nonatomic, strong) NSString* cellIdentifer;
-(void)setupFetch:(NSFetchRequest*)fetchRequest context:(NSManagedObjectContext*)context;
@property (strong, nonatomic) NSArray* includedSets;
@property (strong, nonatomic) NSString* faction;
-(void)clearFetch;
@end
