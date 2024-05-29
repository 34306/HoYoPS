#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
//#include <roothide.h>

BOOL enabled;
NSString *host;
NSNumber *port;
BOOL usePort;
BOOL useHTTPS;

static void createPrefs(NSURL *prefsPath) {
    NSDictionary *newPrefs = @{
        @"enabled": @NO,
        @"host": @"127.0.0.1",
        @"port": @443,
        @"usePort": @YES,
        @"useHTTPS": @YES
    };

    NSLog(@"[HoYoPS] Created prefs file");

    NSError *error;
    [newPrefs writeToURL:prefsPath error:&error];
    if (error) NSLog(@"[HoYoPS] %@",error.localizedDescription);
}

static UIWindow *getActiveWindow() {
    for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive) {
            for (UIWindow *window in scene.windows) {
                if (window.isKeyWindow) {
                    return window;
                }
            }
        }
    }
    return nil;
}

static void showHostInputAlert(NSURL *prefsPath, NSMutableDictionary *prefs) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *activeWindow = getActiveWindow();
        if (activeWindow == nil) {
            NSLog(@"[HoYoPS] No active window found.");
            return;
        }
        
        UIAlertController *inputHostAlert = [UIAlertController alertControllerWithTitle:@"Enter the host"
                                                                                message:@"Remove 'https://', just type directly the host\nRestart the game to take effect!"
                                                                         preferredStyle:UIAlertControllerStyleAlert];
        [inputHostAlert addTextFieldWithConfigurationHandler:nil];
        UIAlertAction *saveAction = [UIAlertAction actionWithTitle:@"Save"
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction *action) {
            UITextField *textField = inputHostAlert.textFields.firstObject;
            host = textField.text;
            [prefs setValue:host forKey:@"host"];
            [prefs writeToURL:prefsPath error:nil];
        }];
        [inputHostAlert addAction:saveAction];
        [activeWindow.rootViewController presentViewController:inputHostAlert animated:YES completion:nil];
    });
}

static void showEnablePrivateServerAlert(NSURL *prefsPath, NSMutableDictionary *prefs) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *activeWindow = getActiveWindow();
        if (activeWindow == nil) {
            NSLog(@"[HoYoPS] No active window found.");
            return;
        }
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"HoYo Private Server\n(GI & HSR)"
                                                                                 message:@"Original by @biD3V\nFix and add config by Little34306\n\nDo you want to enable Private Server?"
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"Yes"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
            enabled = YES;
            [prefs setValue:@(enabled) forKey:@"enabled"];
            [prefs writeToURL:prefsPath error:nil];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                showHostInputAlert(prefsPath, prefs);
            });
        }];
        UIAlertAction *noAction = [UIAlertAction actionWithTitle:@"No"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action) {
            enabled = NO;
            [prefs setValue:@(enabled) forKey:@"enabled"];
            [prefs writeToURL:prefsPath error:nil];
        }];
        [alertController addAction:yesAction];
        [alertController addAction:noAction];
        [activeWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
    });
}

static void showAlertForHostChange(NSURL *prefsPath, NSMutableDictionary *prefs) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *activeWindow = getActiveWindow();
        if (activeWindow == nil) {
            NSLog(@"[HoYoPS] No active window found.");
            return;
        }
        
        if (enabled) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Host Configuration"
                                                                                         message:@"You can use previous input host or new one\nOr just disable Private Server!\nRestart the game to take effect!"
                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *changeHostAction = [UIAlertAction actionWithTitle:@"Change Host"
                                                                           style:UIAlertActionStyleDefault
                                                                         handler:^(UIAlertAction *action) {
                    showHostInputAlert(prefsPath, prefs);
                }];
                UIAlertAction *continueAction = [UIAlertAction actionWithTitle:@"Use Existed (Previous host)"
                                                                         style:UIAlertActionStyleCancel
                                                                       handler:nil];
                UIAlertAction *noPS = [UIAlertAction actionWithTitle:@"Disable Private Server"
                                                               style:UIAlertActionStyleDestructive
                                                             handler:^(UIAlertAction *action) {
                    enabled = NO;
                    [prefs setValue:@(enabled) forKey:@"enabled"];
                    [prefs writeToURL:prefsPath error:nil];
                }];

                [alertController addAction:changeHostAction];
                [alertController addAction:continueAction];
                [alertController addAction:noPS];
                [activeWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
            });
        } else {
            showEnablePrivateServerAlert(prefsPath, prefs);
        }
    });
}

// Normal tweak preferences didn't work, might be something to do with RootHide.
static void reloadPrefs() {
    // Get app's local library directory
    NSArray<NSURL *> *paths = [[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask];
    NSURL *libraryDir = paths[0];

    NSURL *prefsPath = [libraryDir URLByAppendingPathComponent:@"server_config.plist"];

    NSError *error;
    NSMutableDictionary *prefs = [[NSDictionary dictionaryWithContentsOfURL:prefsPath error:&error] mutableCopy];
    if (error) NSLog(@"[HoYoPS] %@",error.localizedDescription);

    // Check if prefs already exist
    if (!prefs) {
        createPrefs(prefsPath);
        prefs = [NSMutableDictionary new];
    }

    enabled = prefs[@"enabled"] ? [prefs[@"enabled"] boolValue] : false;
    host = prefs[@"host"] ? prefs[@"host"] : @"127.0.0.1";
    port = prefs[@"port"] ? [NSNumber numberWithInt:[prefs[@"port"] intValue]] : @443;
    usePort = prefs[@"usePort"] ? [prefs[@"usePort"] boolValue] : YES;
    useHTTPS = prefs[@"useHTTPS"] ? [prefs[@"useHTTPS"] boolValue] : YES;

    // Show alert to change host or use existing one
    showAlertForHostChange(prefsPath, prefs);
}

NSString *injectServer(NSString *string) {
    // Check against all hoyo api hosts
    BOOL inject = [string containsString:@"hoyoverse.com"] ||
                  [string containsString:@"mihoyo.com"] ||
                  [string containsString:@"starrails.com"] ||
                  [string containsString:@"bhsr.com"] ||
                  [string containsString:@"yuanshen.com"];

    if (inject) {
        NSURLComponents *components = [NSURLComponents componentsWithString:string];

        if (!useHTTPS) components.scheme = @"http";
        components.host = host;
        if (usePort) components.port = port;

        #if DEBUG
        NSLog(@"[HoYoPS] Found: %@\nRewrote: %@", string, components.URL.absoluteString);
        #endif

        string = components.URL.absoluteString;
    }

    return string;
}

// There's probably a better place to hook this, NSURLRequest and NSURLSession didn't fully work
%hook NSURL

+ (instancetype)URLWithString:(NSString *)string {

    if (!enabled) return %orig(string);
    return %orig(injectServer(string));
}

- (instancetype)initWithString:(NSString *)string {

    if (!enabled) return %orig(string);
    return %orig(injectServer(string));
}

%end

%ctor {
    // Only do this on app launch
    reloadPrefs();
}
