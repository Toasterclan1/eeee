
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <dlfcn.h>
#include <mach-o/dyld.h>
#include <string>
#include <vector>

// =============================================================================
//  MOBILESUBSTRATE / CYDIASUBSTRATE
//  Handles function hooking at runtime — works with Substrate, Substitute,
//  and libhooker. Weak-linked so the dylib loads even without a jailbreak.
// =============================================================================
extern "C" {
    void MSHookFunction(void* symbol, void* hook, void** old);
    void MSHookMessageEx(Class _class, SEL sel, IMP hook, IMP* old);
}
// Weak import — dylib still loads if Substrate isn't present
__attribute__((weak_import)) extern void MSHookFunction(void*, void*, void**);

// =============================================================================
//  ① CONFIG
//  Option A: symbol name (if the game exports it — check with nm or Ghidra)
//  Option B: raw offset (offset = fn_address - binary_base, found via Ghidra)
//  Leave SPAWN_SYMBOL as "" to use the offset instead.
// =============================================================================
static const char*     SPAWN_SYMBOL      = ""; // e.g. "_ItemSpawn"
static const uintptr_t SPAWN_FUNC_OFFSET = 0x0; // TODO: fill in if no symbol

// =============================================================================
//  ② ITEM LIST 
// =============================================================================
static NSArray<NSString*>* itemList() {
    static NSArray* list = nil;
    if (!list) {
        list = @[
            @"item_basic_fishing_rod",
            @"item_bamboo_fishing_rod",
            @"item_lava_fishing_rod",
            @"item_radioactive_fishing_rod",
            @"item_special_fishing_rod",
            @"item_golden_fishing_rod",
            @"item_fish_salmon",
            @"item_fish_tuna",
            @"item_fish_bass",
            @"item_fish_trout",
            @"item_fish_shark",
            @"item_bait_worm",
            @"item_bait_grub",
            @"item_bait_lure",
            @"item_bait_fly",
            @"item_sword_basic",
            @"item_sword_iron",
            @"item_axe_wood",
            @"item_bow_basic",
            @"item_shovel",
            @"item_pickaxe",
            @"item_hammer",
            @"item_wrench",
            @"item_tnt",
            @"item_grenade",
            @"item_landmine",
            @"item_bread",
            @"item_apple",
            @"item_cooked_fish",
            @"item_stew",
            
        ];
    }
    return list;
}

// =============================================================================
//  ③ SPAWN LOGIC + MOBILESUBSTRATE HOOK
// =============================================================================
typedef void (*SpawnFn)(const char* itemId, float x, float y, float z, int qty);

// Pointer to the original spawn function (filled in by MSHookFunction)
static SpawnFn orig_SpawnFn = nullptr;

// Our replacement — called instead of the original
// You can add logging, blocking, or modification here
static void hook_SpawnFn(const char* itemId, float x, float y, float z, int qty) {
    NSLog(@"[Spawner] hook_SpawnFn: %s @ (%.2f,%.2f,%.2f) x%d", itemId, x, y, z, qty);
    // Call the original so the game still works normally
    if (orig_SpawnFn) orig_SpawnFn(itemId, x, y, z, qty);
}

// Resolves the spawn function address (symbol or offset)
static SpawnFn resolveSpawnFn() {
    // Try symbol first
    if (SPAWN_SYMBOL && strlen(SPAWN_SYMBOL) > 0) {
        void* sym = dlsym(RTLD_DEFAULT, SPAWN_SYMBOL);
        if (sym) {
            NSLog(@"[Spawner] resolved via symbol: %s", SPAWN_SYMBOL);
            return (SpawnFn)sym;
        }
        NSLog(@"[Spawner] symbol not found: %s — falling back to offset", SPAWN_SYMBOL);
    }

    // Fall back to offset
    if (SPAWN_FUNC_OFFSET == 0x0) {
        NSLog(@"[Spawner] SPAWN_FUNC_OFFSET not set — set it in spawner.mm and rebuild");
        return nullptr;
    }
    uintptr_t base = 0;
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char* name = _dyld_get_image_name(i);
        if (name && strstr(name, "AnimalCompany")) {
            base = (uintptr_t)_dyld_get_image_header(i);
            break;
        }
    }
    if (!base) { NSLog(@"[Spawner] binary not found"); return nullptr; }
    NSLog(@"[Spawner] resolved via offset: 0x%lx", SPAWN_FUNC_OFFSET);
    return (SpawnFn)(base + SPAWN_FUNC_OFFSET);
}

// Install the Substrate hook
static void installHook() {
    SpawnFn target = resolveSpawnFn();
    if (!target) { NSLog(@"[Spawner] hook not installed — no spawn fn found"); return; }

    if (&MSHookFunction != nullptr) {
        // Substrate/Substitute/libhooker available
        MSHookFunction((void*)target, (void*)hook_SpawnFn, (void**)&orig_SpawnFn);
        NSLog(@"[Spawner] MSHookFunction installed on spawn fn");
    } else {
        // No Substrate — store fn pointer directly (no hook, just direct calls)
        orig_SpawnFn = target;
        NSLog(@"[Spawner] Substrate not found — using direct fn pointer");
    }
}

static void executeSpawn(NSString* itemId, float x, float y, float z, int qty) {
    NSLog(@"[Spawner] executeSpawn: %@ @ (%.2f,%.2f,%.2f) x%d", itemId, x, y, z, qty);
    if (!orig_SpawnFn) {
        NSLog(@"[Spawner] spawn fn not resolved yet");
        return;
    }
    for (int i = 0; i < qty; i++)
        orig_SpawnFn([itemId UTF8String], x, y, z, 1);
}

// =============================================================================
//  ④ UI — UIKit overlay window drawn on top of the game
// =============================================================================

@interface SpawnerPanel : UIView <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView*    itemTable;
@property (nonatomic, strong) NSMutableArray* filteredItems;
@property (nonatomic, strong) NSString*       selectedItem;
@property (nonatomic, strong) UITextField*    searchField;
@property (nonatomic, strong) UITextField*    coordX;
@property (nonatomic, strong) UITextField*    coordY;
@property (nonatomic, strong) UITextField*    coordZ;
@property (nonatomic, strong) UIStepper*      qtyStepper;
@property (nonatomic, strong) UILabel*        qtyLabel;
@property (nonatomic, strong) UILabel*        statusLabel;
@property (nonatomic, assign) BOOL            isPanelOpen;
@end

@implementation SpawnerPanel

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    self.filteredItems = [itemList() mutableCopy];
    self.selectedItem  = itemList().firstObject;
    self.isPanelOpen   = NO;
    [self buildUI];
    return self;
}

- (void)buildUI {
    CGFloat W   = self.bounds.size.width;
    CGFloat pad = 12;
    CGFloat y   = pad;

    // ── Background panel ──────────────────────────────────────────────────
    self.backgroundColor    = [UIColor colorWithWhite:0.92 alpha:0.97];
    self.layer.cornerRadius = 12;
    self.layer.shadowColor  = [UIColor blackColor].CGColor;
    self.layer.shadowOpacity = 0.35;
    self.layer.shadowRadius  = 12;
    self.layer.shadowOffset  = CGSizeMake(0, 4);
    self.clipsToBounds = NO;

    // ── Title bar ──────────────────────────────────────────────────────────
    UIView* titleBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, W, 40)];
    titleBar.backgroundColor = [UIColor colorWithWhite:0.82 alpha:1];
    UIBezierPath* mask = [UIBezierPath bezierPathWithRoundedRect:titleBar.bounds
                                               byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight
                                                     cornerRadii:CGSizeMake(12, 12)];
    CAShapeLayer* shape = [CAShapeLayer layer];
    shape.path = mask.CGPath;
    titleBar.layer.mask = shape;
    [self addSubview:titleBar];

    UILabel* title = [[UILabel alloc] initWithFrame:CGRectMake(pad, 0, W-60, 40)];
    title.text      = @"insert name here";
    title.font      = [UIFont boldSystemFontOfSize:13];
    title.textColor = [UIColor colorWithWhite:0.2 alpha:1];
    NSMutableAttributedString* attributed = [[NSMutableAttributedString alloc] initWithString:title.text];
    [attributed addAttribute:NSKernAttributeName           value:@(1.5)        range:NSMakeRange(0, attributed.length)];
    [attributed addAttribute:NSFontAttributeName           value:title.font    range:NSMakeRange(0, attributed.length)];
    [attributed addAttribute:NSForegroundColorAttributeName value:title.textColor range:NSMakeRange(0, attributed.length)];
    title.attributedText = attributed;
    [titleBar addSubview:title];

    UIButton* closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(W-40, 8, 28, 24);
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [closeBtn setTitleColor:[UIColor colorWithWhite:0.4 alpha:1] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(closePanel) forControlEvents:UIControlEventTouchUpInside];
    [titleBar addSubview:closeBtn];

    y = 48;

    // ── Search field ───────────────────────────────────────────────────────
    UITextField* sf = [[UITextField alloc] initWithFrame:CGRectMake(pad, y, W-pad*2, 32)];
    sf.placeholder     = @"Search items...";
    sf.font            = [UIFont systemFontOfSize:12];
    sf.borderStyle     = UITextBorderStyleRoundedRect;
    sf.backgroundColor = UIColor.whiteColor;
    sf.clearButtonMode = UITextFieldViewModeWhileEditing;
    sf.returnKeyType   = UIReturnKeyDone;
    sf.delegate        = self;
    [sf addTarget:self action:@selector(searchChanged:) forControlEvents:UIControlEventEditingChanged];
    [self addSubview:sf];
    self.searchField = sf;
    y += 38;

    // ── Item table ─────────────────────────────────────────────────────────
    UITableView* tv = [[UITableView alloc] initWithFrame:CGRectMake(pad, y, W-pad*2, 130)
                                                   style:UITableViewStylePlain];
    tv.dataSource        = self;
    tv.delegate          = self;
    tv.rowHeight         = 28;
    tv.backgroundColor   = UIColor.whiteColor;      // FIX: explicit white bg
    tv.separatorColor    = [UIColor colorWithWhite:0.85 alpha:1];
    tv.layer.borderWidth = 1;
    tv.layer.borderColor = [UIColor colorWithWhite:0.7 alpha:1].CGColor;
    tv.layer.cornerRadius = 6;
    tv.clipsToBounds     = YES;                     // FIX: clip to rounded corners
    [self addSubview:tv];
    self.itemTable = tv;
    y += 136;

    // ── Quantity row ───────────────────────────────────────────────────────
    UILabel* qLbl = [[UILabel alloc] initWithFrame:CGRectMake(pad, y+4, 70, 24)];
    qLbl.text      = @"QUANTITY";
    qLbl.font      = [UIFont boldSystemFontOfSize:10];
    qLbl.textColor = [UIColor colorWithWhite:0.4 alpha:1];
    [self addSubview:qLbl];

    UILabel* qVal = [[UILabel alloc] initWithFrame:CGRectMake(78, y, 30, 32)];
    qVal.text      = @"1";
    qVal.font      = [UIFont boldSystemFontOfSize:18];
    qVal.textColor = [UIColor colorWithWhite:0.15 alpha:1];
    [self addSubview:qVal];
    self.qtyLabel = qVal;

    UIStepper* stepper = [[UIStepper alloc] initWithFrame:CGRectMake(W-pad-100, y+4, 94, 29)];
    stepper.minimumValue = 1;
    stepper.maximumValue = 99;
    stepper.value        = 1;
    stepper.stepValue    = 1;
    stepper.tintColor    = [UIColor colorWithWhite:0.4 alpha:1];
    [stepper addTarget:self action:@selector(qtyChanged:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:stepper];
    self.qtyStepper = stepper;
    y += 40;

    // ── Coordinates ────────────────────────────────────────────────────────
    UILabel* coordTitle = [[UILabel alloc] initWithFrame:CGRectMake(pad, y, W-pad*2, 18)];
    coordTitle.text      = @"📍 SPAWN COORDINATES";
    coordTitle.font      = [UIFont boldSystemFontOfSize:10];
    coordTitle.textColor = [UIColor colorWithWhite:0.35 alpha:1];
    [self addSubview:coordTitle];
    y += 22;

    NSArray* labels = @[@"X", @"Y", @"Z"];
    NSArray* fields = @[
        (self.coordX = [self makeCoordField]),
        (self.coordY = [self makeCoordField]),
        (self.coordZ = [self makeCoordField]),
    ];
    CGFloat fw = (W - pad*2 - 16) / 3.0;
    for (int i = 0; i < 3; i++) {
        CGFloat fx = pad + i * (fw + 8);
        UILabel* lbl = [[UILabel alloc] initWithFrame:CGRectMake(fx, y, fw, 14)];
        lbl.text          = labels[i];
        lbl.font          = [UIFont boldSystemFontOfSize:10];
        lbl.textColor     = [UIColor colorWithWhite:0.5 alpha:1];
        lbl.textAlignment = NSTextAlignmentCenter;
        [self addSubview:lbl];
        UITextField* fld = fields[i];
        fld.frame = CGRectMake(fx, y+16, fw, 30);
        [self addSubview:fld];
    }
    y += 54;

    // ── Spawn button ───────────────────────────────────────────────────────
    UIButton* spawnBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    spawnBtn.frame = CGRectMake(pad, y, W-pad*2, 42);
    [spawnBtn setTitle:@"SPAWN ITEM" forState:UIControlStateNormal];
    spawnBtn.titleLabel.font    = [UIFont boldSystemFontOfSize:14];
    spawnBtn.backgroundColor    = UIColor.whiteColor;
    spawnBtn.layer.borderWidth  = 2;
    spawnBtn.layer.borderColor  = [UIColor colorWithWhite:0.65 alpha:1].CGColor;
    spawnBtn.layer.cornerRadius = 6;
    [spawnBtn setTitleColor:[UIColor colorWithWhite:0.3 alpha:1] forState:UIControlStateNormal];
    [spawnBtn addTarget:self action:@selector(spawnTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:spawnBtn];
    y += 50;

    // ── Status label ───────────────────────────────────────────────────────
    UILabel* sl = [[UILabel alloc] initWithFrame:CGRectMake(pad, y, W-pad*2, 30)];
    sl.text          = @"";
    sl.font          = [UIFont monospacedSystemFontOfSize:10 weight:UIFontWeightRegular];
    sl.textColor     = [UIColor colorWithWhite:0.5 alpha:1];
    sl.textAlignment = NSTextAlignmentCenter;
    sl.numberOfLines = 2;
    [self addSubview:sl];
    self.statusLabel = sl;
}

- (UITextField*)makeCoordField {
    UITextField* f = [[UITextField alloc] init];
    f.placeholder     = @"0";
    f.keyboardType    = UIKeyboardTypeDecimalPad;
    f.borderStyle     = UITextBorderStyleRoundedRect;
    f.font            = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
    f.textAlignment   = NSTextAlignmentCenter;
    f.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1];
    f.delegate        = self;
    return f;
}

// ── UITextFieldDelegate ────────────────────────────────────────────────────

- (BOOL)textFieldShouldReturn:(UITextField*)tf {
    [tf resignFirstResponder];
    return YES;
}

// Dismiss keyboard when tapping outside a text field
- (void)touchesBegan:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event {
    [self endEditing:YES];
}

// ── Actions ────────────────────────────────────────────────────────────────

- (void)searchChanged:(UITextField*)tf {
    NSString* q = tf.text.lowercaseString;
    if (q.length == 0) {
        self.filteredItems = [itemList() mutableCopy];
    } else {
        self.filteredItems = [[itemList() filteredArrayUsingPredicate:
            [NSPredicate predicateWithFormat:@"SELF CONTAINS[c] %@", q]] mutableCopy];
    }
    [self.itemTable reloadData];
}

- (void)qtyChanged:(UIStepper*)s {
    self.qtyLabel.text = [NSString stringWithFormat:@"%d", (int)s.value];
}

- (void)spawnTapped:(UIButton*)btn {
    [self endEditing:YES];

    if (!self.selectedItem) {
        [self showStatus:@"!! no item selected !!" color:[UIColor systemRedColor]];
        return;
    }

    NSString* xStr = self.coordX.text;
    NSString* yStr = self.coordY.text;
    NSString* zStr = self.coordZ.text;

    if (!xStr.length || !yStr.length || !zStr.length) {
        [self showStatus:@"!! fill in X, Y, Z !!" color:[UIColor systemRedColor]];
        return;
    }

    float x = xStr.floatValue;
    float y = yStr.floatValue;
    float z = zStr.floatValue;
    int   q = (int)self.qtyStepper.value;

    [btn setTitle:@"SPAWNING..." forState:UIControlStateNormal];
    btn.enabled = NO;

    executeSpawn(self.selectedItem, x, y, z, q);

    NSString* msg = [NSString stringWithFormat:@"✓ %@ → (%.1f, %.1f, %.1f)", self.selectedItem, x, y, z];
    [self showStatus:msg color:[UIColor colorWithWhite:0.2 alpha:1]];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [btn setTitle:@"SPAWN ITEM" forState:UIControlStateNormal];
        btn.enabled = YES;
    });
}

- (void)showStatus:(NSString*)msg color:(UIColor*)color {
    self.statusLabel.text      = msg;
    self.statusLabel.textColor = color;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        self.statusLabel.text = @"";
    });
}

- (void)closePanel {
    [self endEditing:YES];
    [UIView animateWithDuration:0.25 animations:^{
        self.alpha     = 0;
        self.transform = CGAffineTransformMakeScale(0.92, 0.92);
    } completion:^(BOOL done) {
        self.hidden    = YES;
        self.alpha     = 1;
        self.transform = CGAffineTransformIdentity;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SpawnerPanelClosed" object:nil];
    }];
}

// ── UITableView ────────────────────────────────────────────────────────────

- (NSInteger)tableView:(UITableView*)tv numberOfRowsInSection:(NSInteger)s {
    return self.filteredItems.count;
}

- (UITableViewCell*)tableView:(UITableView*)tv cellForRowAtIndexPath:(NSIndexPath*)ip {
    UITableViewCell* cell = [tv dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    NSString* item = self.filteredItems[ip.row];
    cell.textLabel.text      = item;
    cell.textLabel.font      = [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular];
    cell.textLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1];
    cell.backgroundColor     = [item isEqualToString:self.selectedItem]
        ? [UIColor colorWithWhite:0.85 alpha:1]
        : UIColor.whiteColor;
    return cell;
}

- (void)tableView:(UITableView*)tv didSelectRowAtIndexPath:(NSIndexPath*)ip {
    self.selectedItem = self.filteredItems[ip.row];
    [tv reloadData];
}

@end


// =============================================================================
//  ⑤ OVERLAY WINDOW + FLOATING TOGGLE BUTTON
// =============================================================================
@interface FixedOrientationVC : UIViewController
@end
@implementation FixedOrientationVC
- (BOOL)shouldAutorotate { return NO; }
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeRight;
}
@end

@interface SpawnerOverlay : NSObject
@property (nonatomic, strong) UIWindow*      overlayWindow;
@property (nonatomic, strong) SpawnerPanel*  panel;
@property (nonatomic, strong) UIButton*      toggleBtn;
@property (nonatomic)         CGRect         screenRect;
@end

@implementation SpawnerOverlay

+ (instancetype)shared {
    static SpawnerOverlay* inst = nil;
    static dispatch_once_t t;
    dispatch_once(&t, ^{ inst = [SpawnerOverlay new]; });
    return inst;
}

- (void)setup {
    CGRect screen = UIScreen.mainScreen.bounds;
    if (screen.size.width > screen.size.height) {
        screen = CGRectMake(0, 0, screen.size.height, screen.size.width);
    }
    self.screenRect = screen;

    // Overlay window sits above everything
    self.overlayWindow = [[UIWindow alloc] initWithFrame:screen];
    self.overlayWindow.windowLevel = UIWindowLevelAlert + 100;
    self.overlayWindow.backgroundColor = UIColor.clearColor;
    self.overlayWindow.userInteractionEnabled = YES;

    FixedOrientationVC* root = [FixedOrientationVC new];
    root.view.backgroundColor = UIColor.clearColor;
    self.overlayWindow.rootViewController = root;
    [self.overlayWindow makeKeyAndVisible];

    root.view.frame = screen;
    root.view.bounds = CGRectMake(0, 0, screen.size.width, screen.size.height);

    // ── Panel (hidden until toggle tapped) ────────────────────────────────
    CGFloat pw = MIN(screen.size.width * 0.85, 400);
    CGFloat ph = 460;
    CGRect  pr = CGRectMake((screen.size.width  - pw) / 2,
                            (screen.size.height - ph) / 2,
                            pw, ph);
    self.panel = [[SpawnerPanel alloc] initWithFrame:pr];
    self.panel.hidden = YES;
    [root.view addSubview:self.panel];

    // ── Floating MENU button (draggable) ─────────────────────────────────
    UIButton* btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = CGRectMake(0, screen.size.height / 2 - 40, 32, 80);
    [btn setTitle:@"M\nE\nN\nU" forState:UIControlStateNormal];
    btn.titleLabel.font          = [UIFont boldSystemFontOfSize:9];
    btn.titleLabel.numberOfLines = 4;
    btn.titleLabel.textAlignment = NSTextAlignmentCenter;
    btn.backgroundColor          = [UIColor colorWithWhite:0.83 alpha:0.95];
    btn.layer.cornerRadius       = 6;
    btn.layer.maskedCorners      = kCALayerMaxXMinYCorner | kCALayerMaxXMaxYCorner;
    btn.layer.borderWidth        = 1.5;
    btn.layer.borderColor        = [UIColor colorWithWhite:0.65 alpha:1].CGColor;
    [btn setTitleColor:[UIColor colorWithWhite:0.3 alpha:1] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(togglePanel) forControlEvents:UIControlEventTouchUpInside];

    UIPanGestureRecognizer* pan = [[UIPanGestureRecognizer alloc]
                                    initWithTarget:self action:@selector(dragBtn:)];
    [btn addGestureRecognizer:pan];
    [root.view addSubview:btn];
    self.toggleBtn = btn;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(panelClosed)
                                                 name:@"SpawnerPanelClosed"
                                               object:nil];
}

- (void)togglePanel {
    BOOL open = self.panel.hidden;
    if (open) {
        self.panel.hidden     = NO;
        self.panel.alpha      = 0;
        self.panel.transform  = CGAffineTransformMakeScale(0.9, 0.9);
        self.toggleBtn.hidden = YES;
        [UIView animateWithDuration:0.25 animations:^{
            self.panel.alpha     = 1;
            self.panel.transform = CGAffineTransformIdentity;
        }];
    }
}

- (void)panelClosed {
    self.toggleBtn.hidden = NO;
}

- (void)dragBtn:(UIPanGestureRecognizer*)pan {
    UIView* v     = pan.view;
    CGPoint delta = [pan translationInView:v.superview];
    CGRect  f     = v.frame;
    f.origin.y = MAX(0, MIN(self.screenRect.size.height - f.size.height,
                            f.origin.y + delta.y));
    v.frame = f;
    [pan setTranslation:CGPointZero inView:v.superview];
}

@end


// =============================================================================
//  ⑥ ENTRY POINT
// =============================================================================

__attribute__((constructor))
static void dylibMain() {
    NSLog(@"[Spawner] loaded");

    // Install Substrate hook immediately at load time
    installHook();

    // Then set up the UI overlay on the main thread
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [[SpawnerOverlay shared] setup];
        NSLog(@"[Spawner] overlay ready");
    });
}
