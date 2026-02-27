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
           @"item_ac_cola", @"item_alphablade", @"item_anti_gravity_grenade", @"item_apple",
        @"item_arena_pistol", @"item_arena_shotgun", @"item_arrow", @"item_arrow_bomb",
        @"item_arrow_heart", @"item_arrow_lightbulb", @"item_arrow_teleport", @"item_axe",
        @"item_backpack", @"item_backpack_black", @"item_backpack_green", @"item_backpack_large_base",
        @"item_backpack_large_basketball", @"item_backpack_large_clover", @"item_backpack_pink",
        @"item_backpack_realistic", @"item_backpack_small_base", @"item_backpack_white",
        @"item_backpack_with_flashlight", @"item_balloon", @"item_balloon_heart", @"item_banana",
        @"item_banana_chips", @"item_baseball_bat", @"item_basic_fishing_rod", @"item_beans",
        @"item_big_cup", @"item_bighead_larva", @"item_bloodlust_vial", @"item_boombox",
        @"item_boombox_neon", @"item_boomerang", @"item_box_fan", @"item_brain_chunk",
        @"item_brick", @"item_broccoli_grenade", @"item_broccoli_shrink_grenade", @"item_broom",
        @"item_broom_halloween", @"item_burrito", @"item_calculator", @"item_cardboard_box",
        @"item_ceo_plaque", @"item_clapper", @"item_cluster_grenade", @"item_coconut_shell",
        @"item_cola", @"item_cola_large", @"item_company_ration", @"item_company_ration_heal",
        @"item_cracker", @"item_crate", @"item_crossbow", @"item_crossbow_heart", @"item_crowbar",
        @"item_cutie_dead", @"item_d20", @"item_demon_sword", @"item_disc",
        @"item_disposable_camera", @"item_drill", @"item_drill_neon", @"item_dynamite",
        @"item_dynamite_cube", @"item_egg", @"item_electrical_tape", @"item_eraser",
        @"item_film_reel", @"item_finger_board", @"item_fish_dumb_fish", @"item_flamethrower",
        @"item_flamethrower_skull", @"item_flamethrower_skull_ruby", @"item_flaregun",
        @"item_flashbang", @"item_flashlight", @"item_flashlight_mega", @"item_flashlight_red",
        @"item_flipflop_realistic", @"item_floppy3", @"item_floppy5", @"item_football",
        @"item_friend_launcher", @"item_frying_pan", @"item_gameboy", @"item_glowstick",
        @"item_goldbar", @"item_goldcoin", @"item_goop", @"item_goopfish", @"item_great_sword",
        @"item_grenade", @"item_grenade_gold", @"item_grenade_launcher", @"item_guided_boomerang",
        @"item_harddrive", @"item_hatchet", @"item_hawaiian_drum", @"item_heart_chunk",
        @"item_heart_gun", @"item_heartchocolatebox", @"item_hh_key", @"item_hookshot",
        @"item_hookshot_sword", @"item_hot_cocoa", @"item_hoverpad", @"item_impulse_grenade",
        @"item_jetpack", @"item_joystick", @"item_joystick_inv_y", @"item_keycard",
        @"item_lance", @"item_landmine", @"item_large_banana", @"item_megaphone",
        @"item_metal_ball", @"item_metal_ball_x", @"item_metal_plate", @"item_metal_plate_2",
        @"item_metal_rod", @"item_metal_rod_xmas", @"item_metal_triangle", @"item_momboss_box",
        @"item_moneygun", @"item_motor", @"item_mountain_key", @"item_mug", @"item_needle",
        @"item_nut", @"item_nut_drop", @"item_ogre_hands", @"item_ore_copper_large",
        @"item_ore_copper_medium", @"item_ore_copper_small", @"item_ore_gold_large",
        @"item_ore_gold_medium", @"item_ore_gold_small", @"item_ore_iron_large",
        @"item_ore_iron_medium", @"item_ore_iron_small", @"item_paintball_gun",
        @"item_paper_bag", @"item_pepper_spray", @"item_pie", @"item_pillow",
        @"item_ping_pong_ball", @"item_ping_pong_paddle", @"item_pipe", @"item_plank",
        @"item_playing_card", @"item_popcorn", @"item_potato", @"item_potato_chips",
        @"item_present", @"item_present_1", @"item_present_2", @"item_present_3",
        @"item_pumpkin", @"item_rainstick", @"item_remote_bomb", @"item_remote_bomb_detonator",
        @"item_revolver", @"item_rock", @"item_rock_large", @"item_rope",
        @"item_rpg", @"item_rpg_rocket", @"item_rubber_duck", @"item_salt",
        @"item_scissors", @"item_shield", @"item_shovel", @"item_shuriken",
        @"item_skateboard", @"item_ski_mask", @"item_skull", @"item_slime",
        @"item_slime_ball", @"item_smoke_grenade", @"item_snowball", @"item_snowball_launcher",
        @"item_soda_can", @"item_spear", @"item_spike_trap", @"item_spring",
        @"item_staff", @"item_stink_bomb", @"item_stopwatch", @"item_sword",
        @"item_table_leg", @"item_tape", @"item_tazer", @"item_tennis_ball",
        @"item_tennis_racket", @"item_tire", @"item_tomato", @"item_torch",
        @"item_toy_car", @"item_trampoline", @"item_trophy", @"item_umbrella",
        @"item_vacuum", @"item_volleyball", @"item_watering_can", @"item_whip",
        @"item_whistle", @"item_wrench", @"item_xmas_sword", @"item_xmas_tree",
        @"item_yo_yo"
            
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

@interface SpawnerPanel : UIView <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
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
    return UIInterfaceOrientationMaskPortrait;
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
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [[SpawnerOverlay shared] setup];
        NSLog(@"[Spawner] overlay ready");
    });
}


// =============================================================================
//  ⑦ CATEGORY: op — IL2CPP / RPC helpers (ported from XDMenu.xm)
// =============================================================================

// ── IL2CPP function pointers ─────────────────────────────────────────────────
static void*       op_il2cppHandle                        = nil;
static BOOL        op_isInitialized                       = NO;

static int64_t (*op_il2cpp_domain_get)(void);
static int64_t (*op_il2cpp_domain_get_assemblies)(int64_t, int64_t *);
static int64_t (*op_il2cpp_assembly_get_image)(int64_t);
static const char *(*op_il2cpp_image_get_name)(int64_t);
static int64_t (*op_il2cpp_class_from_name)(int64_t, const char *, const char *);
static int64_t (*op_il2cpp_class_get_method_from_name)(int64_t, const char *, int);
static int64_t (*op_il2cpp_runtime_invoke)(int64_t, int64_t, void **, int64_t *);
static int64_t (*op_il2cpp_resolve_icall)(const char *);
static int64_t (*op_il2cpp_class_get_field_from_name)(int64_t, const char *);
static void    (*op_il2cpp_field_set_value)(int64_t, int64_t, void *);
static int64_t (*op_il2cpp_field_get_value)(int64_t, int64_t, void *);
static int64_t (*op_il2cpp_class_get_type)(int64_t);
static int64_t (*op_il2cpp_type_get_object)(int64_t);
static int64_t (*op_il2cpp_string_new)(const char *);

// ── Cached game class / method handles ───────────────────────────────────────
static int64_t op_gameImage                       = 0;
static int64_t op_unityImage                      = 0;
static int64_t op_netPlayerClass                  = 0;
static int64_t op_prefabGeneratorClass            = 0;
static int64_t op_gameObjectClass                 = 0;
static int64_t op_transformClass                  = 0;
static int64_t op_objectClass                     = 0;
static int64_t op_gameManagerClass                = 0;
static int64_t op_getLocalPlayerMethod            = 0;
static int64_t op_giveSelfMoneyMethod             = 0;
static int64_t op_spawnItemMethod                 = 0;
static int64_t op_findObjectOfTypeMethod          = 0;
static int64_t op_itemSellingMachineClass         = 0;
static int64_t op_rpcAddPlayerMoneyToAllMethod    = 0;
static int64_t op_gameManagerAddPlayerMoneyMethod = 0;
static int64_t op_Transform_get_position_Injected = 0;

// ── Vec3 helper (shared with op category) ────────────────────────────────────
typedef struct { float x; float y; float z; } OpVec3;

@interface NSObject (op)

// Initialisation
+ (BOOL)op_initializeIL2CPP;
+ (BOOL)op_initializeGameClasses;

// Internal helpers
+ (int64_t)op_getImageNamed:(const char *)name;
+ (int64_t)op_getLocalPlayer;

// RPC / game actions
+ (void)op_giveSelfMoney:(unsigned int)amount;
+ (void)op_giveAllPlayersMoney:(int)amount;
+ (void)op_spawnItem:(NSString *)itemName quantity:(int)quantity x:(float)x y:(float)y z:(float)z;

@end

@implementation NSObject (op)

// ── Image lookup ─────────────────────────────────────────────────────────────
+ (int64_t)op_getImageNamed:(const char *)name {
    if (!op_isInitialized) return 0;
    int64_t domain = op_il2cpp_domain_get();
    if (!domain) return 0;
    int64_t count = 0;
    int64_t assemblies = op_il2cpp_domain_get_assemblies(domain, &count);
    for (int64_t i = 0; i < count; i++) {
        int64_t assembly = *((int64_t *)(assemblies + 8 * i));
        int64_t image    = op_il2cpp_assembly_get_image(assembly);
        const char *imgName = op_il2cpp_image_get_name(image);
        if (imgName && strcmp(imgName, name) == 0) return image;
    }
    return 0;
}

// ── Bootstrap IL2CPP function pointers ───────────────────────────────────────
+ (BOOL)op_initializeIL2CPP {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, "UnityFramework")) {
            op_il2cppHandle = dlopen(name, RTLD_NOW);
            break;
        }
    }
    if (!op_il2cppHandle) op_il2cppHandle = dlopen(0, 2);
    if (!op_il2cppHandle) return NO;

		op_il2cpp_domain_get                 = (int64_t (*)(void))                               dlsym(op_il2cppHandle, "il2cpp_domain_get");
		op_il2cpp_domain_get_assemblies      = (int64_t (*)(int64_t, int64_t *))                 dlsym(op_il2cppHandle, "il2cpp_domain_get_assemblies");
		op_il2cpp_assembly_get_image         = (int64_t (*)(int64_t))                            dlsym(op_il2cppHandle, "il2cpp_assembly_get_image");
		op_il2cpp_image_get_name             = (const char *(*)(int64_t))                        dlsym(op_il2cppHandle, "il2cpp_image_get_name");
		op_il2cpp_class_from_name            = (int64_t (*)(int64_t, const char *, const char *))dlsym(op_il2cppHandle, "il2cpp_class_from_name");
		op_il2cpp_class_get_method_from_name = (int64_t (*)(int64_t, const char *, int))         dlsym(op_il2cppHandle, "il2cpp_class_get_method_from_name");
		op_il2cpp_string_new                 = (int64_t (*)(const char *))                       dlsym(op_il2cppHandle, "il2cpp_string_new");
		op_il2cpp_runtime_invoke             = (int64_t (*)(int64_t, int64_t, void **, int64_t *))dlsym(op_il2cppHandle, "il2cpp_runtime_invoke");
		op_il2cpp_resolve_icall              = (int64_t (*)(const char *))                       dlsym(op_il2cppHandle, "il2cpp_resolve_icall");
		op_il2cpp_class_get_field_from_name  = (int64_t (*)(int64_t, const char *))              dlsym(op_il2cppHandle, "il2cpp_class_get_field_from_name");
		op_il2cpp_field_get_value            = (int64_t (*)(int64_t, int64_t, void *))           dlsym(op_il2cppHandle, "il2cpp_field_get_value");
		op_il2cpp_field_set_value            = (void (*)(int64_t, int64_t, void *))              dlsym(op_il2cppHandle, "il2cpp_field_set_value");
		op_il2cpp_class_get_type             = (int64_t (*)(int64_t))                            dlsym(op_il2cppHandle, "il2cpp_class_get_type");
		op_il2cpp_type_get_object            = (int64_t (*)(int64_t))                            dlsym(op_il2cppHandle, "il2cpp_type_get_object");

    if (op_il2cpp_domain_get &&
        op_il2cpp_class_from_name &&
        op_il2cpp_class_get_method_from_name &&
        op_il2cpp_class_get_type &&
        op_il2cpp_type_get_object) {
        op_Transform_get_position_Injected =
            op_il2cpp_resolve_icall("UnityEngine.Transform::get_position_Injected");
        op_isInitialized = YES;
        return YES;
    }
    return NO;
}

// ── Resolve game-specific classes and methods ─────────────────────────────────
+ (BOOL)op_initializeGameClasses {
    if (!op_isInitialized) return NO;

    op_gameImage = [self op_getImageNamed:"AnimalCompany.dll"];
    if (!op_gameImage) return NO;

    op_unityImage          = [self op_getImageNamed:"UnityEngine.CoreModule.dll"];
    op_netPlayerClass      = op_il2cpp_class_from_name(op_gameImage, "AnimalCompany", "NetPlayer");
    op_prefabGeneratorClass = op_il2cpp_class_from_name(op_gameImage, "AnimalCompany", "PrefabGenerator");

    if (op_unityImage) {
        op_gameObjectClass = op_il2cpp_class_from_name(op_unityImage, "UnityEngine", "GameObject");
        op_transformClass  = op_il2cpp_class_from_name(op_unityImage, "UnityEngine", "Transform");
    }
    if (!op_netPlayerClass) return NO;

    op_getLocalPlayerMethod = op_il2cpp_class_get_method_from_name(op_netPlayerClass, "get_localPlayer", 0);
    op_giveSelfMoneyMethod  = op_il2cpp_class_get_method_from_name(op_netPlayerClass, "AddPlayerMoney", 1);

    if (op_prefabGeneratorClass)
        op_spawnItemMethod = op_il2cpp_class_get_method_from_name(op_prefabGeneratorClass, "SpawnItem", 4);

    if (op_unityImage) {
        op_objectClass = op_il2cpp_class_from_name(op_unityImage, "UnityEngine", "Object");
        if (op_objectClass)
            op_findObjectOfTypeMethod = op_il2cpp_class_get_method_from_name(op_objectClass, "FindObjectOfType", 1);
    }

    op_itemSellingMachineClass = op_il2cpp_class_from_name(op_gameImage, "AnimalCompany", "ItemSellingMachineController");
    if (op_itemSellingMachineClass) {
        op_rpcAddPlayerMoneyToAllMethod =
            op_il2cpp_class_get_method_from_name(op_itemSellingMachineClass, "RPC_AddPlayerMoneyToAll", 1);
        if (!op_rpcAddPlayerMoneyToAllMethod)
            op_rpcAddPlayerMoneyToAllMethod =
                op_il2cpp_class_get_method_from_name(op_itemSellingMachineClass, "RPC_AddPlayerMoneyToAll", 2);
    }

    op_gameManagerClass = op_il2cpp_class_from_name(op_gameImage, "AnimalCompany", "GameManager");
    if (op_gameManagerClass)
        op_gameManagerAddPlayerMoneyMethod =
            op_il2cpp_class_get_method_from_name(op_gameManagerClass, "AddPlayerMoney", 1);

    return YES;
}

// ── Get the local NetPlayer instance ─────────────────────────────────────────
+ (int64_t)op_getLocalPlayer {
    if (!op_netPlayerClass)
        op_netPlayerClass = op_il2cpp_class_from_name(op_gameImage, "AnimalCompany", "NetPlayer");
    if (!op_netPlayerClass) return 0;
    if (!op_getLocalPlayerMethod)
        op_getLocalPlayerMethod = op_il2cpp_class_get_method_from_name(op_netPlayerClass, "get_localPlayer", 0);
    if (!op_getLocalPlayerMethod) return 0;
    int64_t exc = 0;
    int64_t result = op_il2cpp_runtime_invoke(op_getLocalPlayerMethod, 0, nil, &exc);
    if (exc) return 0;
    return result;
}

// ── Give money to the local player via NetPlayer.AddPlayerMoney ───────────────
+ (void)op_giveSelfMoney:(unsigned int)amount {
    if (!op_giveSelfMoneyMethod) {
        NSLog(@"[op] giveSelfMoney: AddPlayerMoney method not found, initializing...");
        if (op_netPlayerClass)
            op_giveSelfMoneyMethod =
                op_il2cpp_class_get_method_from_name(op_netPlayerClass, "AddPlayerMoney", 1);
    }
    if (!op_giveSelfMoneyMethod) {
        NSLog(@"[op] Failed to initialize AddPlayerMoney method");
        return;
    }
    int64_t player = [self op_getLocalPlayer];
    if (!player) { NSLog(@"[op] Could not get local player instance"); return; }
    unsigned int val = amount;
    void *args[] = { &val };
    int64_t exc = 0;
    op_il2cpp_runtime_invoke(op_giveSelfMoneyMethod, player, args, &exc);
    if (exc) NSLog(@"[op] Exception while giving money: %p", (void *)exc);
    else     NSLog(@"[op] Successfully gave %u money to local player", amount);
}

// ── Give money to all players via RPC_AddPlayerMoneyToAll ────────────────────
+ (void)op_giveAllPlayersMoney:(int)amount {
    if (op_rpcAddPlayerMoneyToAllMethod &&
        op_findObjectOfTypeMethod &&
        op_il2cpp_class_get_type &&
        op_il2cpp_type_get_object) {

        int64_t type = op_il2cpp_class_get_type(op_itemSellingMachineClass);
        int64_t obj  = op_il2cpp_type_get_object(type);
        int64_t exc  = 0;
        void *findArgs[] = { &obj };
        int64_t controller =
            op_il2cpp_runtime_invoke(op_findObjectOfTypeMethod, 0, findArgs, &exc);

        if (!controller || exc) {
            NSLog(@"[op] ItemSellingMachine controller not found or findObjectOfType had exception");
        } else {
            NSLog(@"[op] Found ItemSellingMachine controller, trying RPC_AddPlayerMoneyToAll");
            int val = amount;
            void *args1[] = { &val };
            exc = 0;
            op_il2cpp_runtime_invoke(op_rpcAddPlayerMoneyToAllMethod, controller, args1, &exc);
            if (!exc) {
                NSLog(@"[op] RPC_AddPlayerMoneyToAll invoked successfully (int)");
                return;
            }
            NSLog(@"[op] RPC_AddPlayerMoneyToAll (int) exception, trying (int, RpcInfo=NULL) fallback");
            void *args2[] = { &val, nil };
            exc = 0;
            op_il2cpp_runtime_invoke(op_rpcAddPlayerMoneyToAllMethod, controller, args2, &exc);
            if (!exc) {
                NSLog(@"[op] RPC_AddPlayerMoneyToAll invoked successfully (int, RpcInfo=NULL)");
                return;
            }
            NSLog(@"[op] RPC_AddPlayerMoneyToAll fallback also failed");
        }
    } else {
        NSLog(@"[op] RPC_AddPlayerMoneyToAll method or helpers not available");
    }

    // Fallback 1: GameManager.AddPlayerMoney
    if (op_gameManagerAddPlayerMoneyMethod) {
        NSLog(@"[op] Trying GameManager.AddPlayerMoney as fallback");
        int val = amount;
        void *args[] = { &val };
        int64_t exc = 0;
        op_il2cpp_runtime_invoke(op_gameManagerAddPlayerMoneyMethod, 0, args, &exc);
        if (!exc) {
            NSLog(@"[op] GameManager.AddPlayerMoney invoked successfully");
            return;
        }
        NSLog(@"[op] GameManager.AddPlayerMoney threw an exception");
    } else {
        NSLog(@"[op] GameManager.AddPlayerMoney method not found");
    }

    // Fallback 2: self-only money
    NSLog(@"[op] Falling back to giveSelfMoney for amount %d", amount);
    [self op_giveSelfMoney:(unsigned int)amount];
}

// ── Spawn an item via PrefabGenerator.SpawnItem ──────────────────────────────
+ (void)op_spawnItem:(NSString *)itemName quantity:(int)quantity x:(float)x y:(float)y z:(float)z {
    if (!op_spawnItemMethod || !op_il2cpp_string_new) return;
    int64_t nameStr = op_il2cpp_string_new([itemName UTF8String]);
    void *args[] = { &nameStr, &quantity, &x, &y, &z };
    int64_t exc = 0;
    op_il2cpp_runtime_invoke(op_spawnItemMethod, 0, args, &exc);
    if (exc) NSLog(@"[op] SpawnItem exception for %@", itemName);
    else     NSLog(@"[op] Spawned %d x %@ at (%.2f, %.2f, %.2f)", quantity, itemName, x, y, z);
}

@end
