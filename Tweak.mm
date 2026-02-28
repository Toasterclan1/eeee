#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

// This interface allows your Tweak to listen to the HTML buttons
@interface JackzMenuHandler : NSObject <WKScriptMessageHandler>
@property (nonatomic, strong) WKWebView *webView;
@end

@implementation JackzMenuHandler
// This function runs when you click "SPAWN" in the HTML
- (void)userContentController:(WKUserContentController *)userContentController 
      didReceiveScriptMessage:(WKScriptMessage *)message {
    
    if ([message.name isEqualToString:@"spawnHandler"]) {
        NSDictionary *data = message.body;
        NSString *itemName = data[@"name"];
        int quantity = [data[@"qty"] intValue];
        
        NSLog(@"[JackzMenu] Native Spawning: %d x %@", quantity, itemName);
        // INSERT YOUR GAME SPAWN LOGIC HERE
    }
}
@end

static JackzMenuHandler *handler;

static void jackzInit(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        // 1. Setup Configuration & Bridge
        WKUserContentController *contentController = [[WKUserContentController alloc] init];
        handler = [[JackzMenuHandler alloc] init];
        [contentController addScriptMessageHandler:handler name:@"spawnHandler"];

        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        config.userContentController = contentController;

        // 2. Create the WebView
        handler.webView = [[WKWebView alloc] initWithFrame:[UIScreen mainScreen].bounds configuration:config];
        handler.webView.opaque = NO;
        handler.webView.backgroundColor = [UIColor clearColor];
        
        // 3. Your HTML as a properly escaped String
        NSString *html = @"<!DOCTYPE html><html><head><meta name='viewport' content='width=device-width, initial-scale=1.0'></head><body style='background:transparent; margin:0; padding:0;'>"
        "<button onclick='openMenu()' style='background:#000; color:#fff; padding:12px; border:none; width:100%;'>Open Jackz Menu</button>"
        "<div id='spawnModal' style='display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(0,0,0,0.8); align-items:center; justify-content:center;'>"
        "  <div style='background:#fff; width:90%; height:80%; border:3px solid #000; display:flex; flex-direction:column;'>"
        "    <div style='background:#000; color:#fff; padding:10px; display:flex; justify-content:space-between;'>"
        "      <span>JACKZ MOD MENU</span><button onclick='closeMenu()'>X</button>"
        "    </div>"
        "    <div id='list' style='overflow-y:auto; flex:1; padding:10px;'></div>"
        "  </div>"
        "</div>"
        "<script>"
        "  const ids = ['item_apple', 'item_revolver', 'item_rpg'];" // Shortened for example
        "  const list = document.getElementById('list');"
        "  ids.forEach(id => {"
        "    list.innerHTML += `<div style='display:flex; justify-content:space-between; margin-bottom:5px; border-bottom:1px solid #ccc; padding:5px;'>"
        "      <span style='font-size:12px;'>${id}</span>"
        "      <button onclick=\"sendSpawn('${id}')\" style='background:#000; color:#fff;'>SPAWN</button>"
        "    </div>`;"
        "  });"
        "  function sendSpawn(name) {"
        "    window.webkit.messageHandlers.spawnHandler.postMessage({name: name, qty: 1});"
        "  }"
        "  function openMenu() { document.getElementById('spawnModal').style.display = 'flex'; }"
        "  function closeMenu() { document.getElementById('spawnModal').style.display = 'none'; }"
        "</script></body></html>";

        [handler.webView loadHTMLString:html baseURL:nil];
        
        // 4. Add to the top-most window
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        [window addSubview:handler.webView];
    });
}

// Ensure the tweak initializes
%ctor {
    jackzInit();
}
