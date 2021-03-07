//
//  AddServerViewController.m
//  SnapClientIOS
//
//  Created by Lee Jun Kit on 7/3/21.
//

#import "AddServerViewController.h"
#import "AppDelegate.h"

@interface AddServerViewController ()

@property (strong, nonatomic) PersistentContainer *pc;
@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UITextField *hostField;
@property (weak, nonatomic) IBOutlet UITextField *portField;

@end

@implementation AddServerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // get a reference to the persistent container
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    self.pc = appDelegate.persistentContainer;
    
    self.navigationItem.title = @"Add Server";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
    
    // listen for textFieldDidChange events
    NSArray *textFields = @[self.nameField, self.hostField, self.portField];
    for (UITextField *textField in textFields) {
        [textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventValueChanged];
    }
}

- (void)textFieldDidChange:(UITextField *)sender {
    self.navigationItem.rightBarButtonItem.enabled = [self canSave];
}

- (void)save {
    [self.pc addServerWithName:self.nameField.text
                          host:self.hostField.text
                          port:self.portField.text.integerValue];
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)cancel {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (BOOL)canSave {
    NSArray *textFields = @[self.nameField, self.hostField, self.portField];
    for (UITextField *textField in textFields) {
        if (textField.text.length == 0) {
            return NO;
        }
    }
    
    return YES;
}

@end
