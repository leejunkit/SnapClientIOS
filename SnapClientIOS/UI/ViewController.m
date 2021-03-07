//
//  ViewController.m
//  SnapClientIOS
//
//  Created by Lee Jun Kit on 29/12/20.
//

#import "ViewController.h"
#import "ClientSession.h"
#import "AppDelegate.h"
#import "AddServerViewController.h"

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) PersistentContainer *pc;
@property (strong, nonatomic) NSArray *servers;

@property (weak, nonatomic) UITableView *tableView;
@property (strong, nonatomic) ClientSession *session;

@end

@implementation ViewController

- (void)awakeFromNib {
    [super awakeFromNib];
    
    // get a reference to the persistent container
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    self.pc = appDelegate.persistentContainer;
    
    // get a list of saved servers
    self.servers = [self.pc servers];
}

- (void)loadView {
    self.navigationItem.title = @"Snapcast Servers";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addServer)];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    tableView.dataSource = self;
    tableView.delegate = self;
    
    self.tableView = tableView;
    self.view = tableView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerViewContextNotifications];
    
    //self.session = [[ClientSession alloc] initWithSnapServerHost:@"192.168.1.5" port:1704];
}

- (void)registerViewContextNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextUpdatedNotification:) name:NSManagedObjectContextObjectsDidChangeNotification object:self.pc.viewContext];
}

- (void)contextUpdatedNotification:(NSNotification *)notification {
    self.servers = [self.pc servers];
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.servers count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSManagedObject *obj = [self.servers objectAtIndex:indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    }
    
    cell.textLabel.text = [obj valueForKey:@"name"];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@:%ld", [obj valueForKey:@"host"], (long)[[obj valueForKey:@"port"] integerValue]];
    return cell;
}

- (void)addServer {
    AddServerViewController *controller = [AddServerViewController new];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];
    [self presentViewController:nav animated:YES completion:NULL];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
