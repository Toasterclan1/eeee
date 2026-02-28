// =============================================================================
//  jackz.mm — Jackz Mod Menu for Animal Company
//  Converted from acmen7.html — UIKit overlay, no web view needed.
//
//  BUILD (WSL2 on Windows):
//    clang++ -std=c++17 -dynamiclib -fobjc-arc \
//      -arch arm64 -target arm64-apple-ios14.0 \
//      -isysroot ~/sdk/iPhoneOS14.5.sdk \
//      -framework UIKit -framework Foundation \
//      -lobjc -lc++ -O2 \
//      -install_name @rpath/jackz.dylib \
//      -o jackz.dylib jackz.mm
//
//  INJECT: Esign → import IPA → Signature → Inject → jackz.dylib
// =============================================================================

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <dlfcn.h>
#include <mach-o/dyld.h>

// MobileSubstrate — weak linked so dylib loads without jailbreak too
extern "C" {
    void MSHookFunction(void* symbol, void* hook, void** old);
    void MSHookMessageEx(Class _class, SEL sel, IMP hook, IMP* old);
}
__attribute__((weak_import)) extern void MSHookFunction(void*, void*, void**);

// =============================================================================
//  SPAWN FUNCTION — fill in offset after reversing the binary
// =============================================================================
static const uintptr_t SPAWN_FUNC_OFFSET = 0x0; // TODO

typedef void (*SpawnFn)(const char* itemId, int qty);
static SpawnFn g_spawnFn = nullptr;

static void resolveSpawnFn() {
    uint32_t n = _dyld_image_count();
    for (uint32_t i = 0; i < n; i++) {
        const char* name = _dyld_get_image_name(i);
        if (name && strstr(name, "AnimalCompany")) {
            uintptr_t base = (uintptr_t)_dyld_get_image_header(i);
            if (SPAWN_FUNC_OFFSET != 0x0)
                g_spawnFn = (SpawnFn)(base + SPAWN_FUNC_OFFSET);
            return;
        }
    }
}

static void doSpawn(NSString* itemId, int qty) {
    NSLog(@"[Jackz] spawn: %@ x%d", itemId, qty);
    if (g_spawnFn) {
        for (int i = 0; i < qty; i++)
            g_spawnFn([itemId UTF8String], 1);
    }
}

// =============================================================================
//  ITEM + PREFAB LISTS  (from acmen7.html)
// =============================================================================
static NSArray<NSString*>* allItems() {
    static NSArray* list = nil;
    if (!list) list = @[
        @"item_anti_gravity_grenade", @"item_apple", @"item_arena_pistol",
        @"item_arena_shotgun", @"item_arrow", @"item_arrow_bomb",
        @"item_arrow_heart", @"item_arrow_lightbulb", @"item_arrow_teleport",
        @"item_backpack", @"item_backpack_black", @"item_backpack_green",
        @"item_backpack_large_base", @"item_backpack_large_basketball",
        @"item_backpack_large_clover", @"item_backpack_pink",
        @"item_backpack_small_base", @"item_backpack_white",
        @"item_backpack_with_flashlight", @"item_balloon", @"item_balloon_heart",
        @"item_banana", @"item_baseball_bat", @"item_big_cup", @"item_boombox",
        @"item_boombox_neon", @"item_box_fan", @"item_brain_chunk",
        @"item_broccoli_grenade", @"item_broccoli_shrink_grenade",
        @"item_calculator", @"item_cardboard_box", @"item_ceo_plaque",
        @"item_clapper", @"item_cluster_grenade", @"item_cola",
        @"item_cola_large", @"item_company_ration", @"item_company_ration_heal",
        @"item_cracker", @"item_crate", @"item_crossbow", @"item_crossbow_heart",
        @"item_crowbar", @"item_cutie_dead", @"item_d20", @"item_disc",
        @"item_disposable_camera", @"item_drill", @"item_dynamite",
        @"item_dynamite_cube", @"item_egg", @"item_electrical_tape",
        @"item_eraser", @"item_finger_board", @"item_flaregun",
        @"item_flashbang", @"item_flashlight", @"item_flashlight_mega",
        @"item_flashlight_red", @"item_floppy3", @"item_floppy5",
        @"item_football", @"item_friend_launcher", @"item_frying_pan",
        @"item_gameboy", @"item_glowstick", @"item_goldbar", @"item_goldcoin",
        @"item_goop", @"item_goopfish", @"item_grenade", @"item_grenade_gold",
        @"item_grenade_launcher", @"item_harddrive", @"item_hawaiian_drum",
        @"item_heart_chunk", @"item_heart_gun", @"item_heartchocolatebox",
        @"item_hh_key", @"item_hookshot", @"item_hookshot_sword",
        @"item_hoverpad", @"item_impulse_grenade", @"item_jetpack",
        @"item_keycard", @"item_lance", @"item_landmine", @"item_large_banana",
        @"item_mug", @"item_nut", @"item_nut_drop", @"item_ogre_hands",
        @"item_ore_copper_l", @"item_ore_copper_m", @"item_ore_copper_s",
        @"item_ore_gold_l", @"item_ore_gold_m", @"item_ore_gold_s",
        @"item_ore_hell", @"item_ore_silver_l", @"item_ore_silver_m",
        @"item_ore_silver_s", @"item_painting_canvas", @"item_paperpack",
        @"item_pelican_case", @"item_pickaxe", @"item_pickaxe_cny",
        @"item_pickaxe_cube", @"item_pinata_bat", @"item_pipe",
        @"item_plunger", @"item_pogostick", @"item_police_baton",
        @"item_portable_teleporter", @"item_pumpkin_pie", @"item_pumpkinjack",
        @"item_pumpkinjack_small", @"item_quiver", @"item_quiver_heart",
        @"item_radioactive_broccoli", @"item_randombox_mobloot_big",
        @"item_randombox_mobloot_medium", @"item_randombox_mobloot_small",
        @"item_randombox_mobloot_weapons", @"item_randombox_mobloot_zombie",
        @"item_rare_card", @"item_revolver", @"item_revolver_ammo",
        @"item_revolver_gold", @"item_robo_monke", @"item_rope", @"item_rpg",
        @"item_rpg_ammo", @"item_rpg_ammo_egg", @"item_rpg_ammo_spear",
        @"item_rpg_cny", @"item_rpg_easter", @"item_rpg_spear",
        @"item_rubberducky", @"item_ruby", @"item_saddle", @"item_scanner",
        @"item_scissors", @"item_server_pad", @"item_shield",
        @"item_shield_bones", @"item_shield_police", @"item_shield_viking_1",
        @"item_shield_viking_2", @"item_shield_viking_3", @"item_shield_viking_4",
        @"item_shotgun", @"item_shotgun_ammo", @"item_shredder",
        @"item_shrinking_broccoli", @"item_snowball", @"item_stapler",
        @"item_stash_grenade", @"item_stick_armbones", @"item_stick_bone",
        @"item_sticker_dispenser", @"item_sticky_dynamite", @"item_stinky_cheese",
        @"item_tablet", @"item_tapedispenser", @"item_tele_grenade",
        @"item_teleport_gun", @"item_theremin", @"item_timebomb",
        @"item_toilet_paper", @"item_toilet_paper_mega",
        @"item_toilet_paper_roll_empty", @"item_treestick",
        @"item_tripwire_explosive", @"item_trophy", @"item_turkey_leg",
        @"item_turkey_whole", @"item_ukulele", @"item_ukulele_gold",
        @"item_umbrella", @"item_umbrella_clover", @"item_upsidedown_loot",
        @"item_uranium_chunk_l", @"item_uranium_chunk_m", @"item_uranium_chunk_s",
        @"item_viking_hammer", @"item_viking_hammer_twilight", @"item_whoopie",
        @"item_zipline_gun", @"item_zombie_meat"
    ];
    return list;
}

static NSArray<NSString*>* allPrefabs() {
    static NSArray* list = nil;
    if (!list) list = @[ @"machine" ];
    return list;
}

// =============================================================================
//  SPAWN ROW VIEW  — item label + qty stepper + SPAWN button
// =============================================================================

@interface SpawnRow : UIView
@property (nonatomic, strong) NSString*   itemId;
@property (nonatomic, strong) UILabel*    nameLabel;
@property (nonatomic, strong) UILabel*    qtyLabel;
@property (nonatomic, assign) int         qty;
@end

@implementation SpawnRow

- (instancetype)initWithItem:(NSString*)itemId width:(CGFloat)w {
    self = [super initWithFrame:CGRectMake(0, 0, w, 34)];
    if (!self) return nil;
    self.itemId = itemId;
    self.qty    = 1;

    self.backgroundColor = UIColor.whiteColor;

    // Name
    UILabel* lbl = [[UILabel alloc] initWithFrame:CGRectMake(6, 0, w - 130, 34)];
    lbl.text      = itemId;
    lbl.font      = [UIFont fontWithName:@"Courier" size:9] ?: [UIFont monospacedSystemFontOfSize:9 weight:UIFontWeightRegular];
    lbl.textColor = UIColor.blackColor;
    lbl.adjustsFontSizeToFitWidth = YES;
    lbl.minimumScaleFactor = 0.7;
    [self addSubview:lbl];
    self.nameLabel = lbl;

    // Qty minus
    UIButton* minus = [UIButton buttonWithType:UIButtonTypeCustom];
    minus.frame = CGRectMake(w - 124, 7, 20, 20);
    [minus setTitle:@"−" forState:UIControlStateNormal];
    [minus setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    minus.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    minus.layer.borderWidth = 1;
    minus.layer.borderColor = UIColor.blackColor.CGColor;
    [minus addTarget:self action:@selector(decQty) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:minus];

    // Qty label
    UILabel* ql = [[UILabel alloc] initWithFrame:CGRectMake(w - 102, 7, 24, 20)];
    ql.text      = @"1";
    ql.font      = [UIFont fontWithName:@"Courier" size:10] ?: [UIFont monospacedSystemFontOfSize:10 weight:UIFontWeightRegular];
    ql.textColor = UIColor.blackColor;
    ql.textAlignment = NSTextAlignmentCenter;
    ql.layer.borderWidth = 1;
    ql.layer.borderColor = UIColor.blackColor.CGColor;
    [self addSubview:ql];
    self.qtyLabel = ql;

    // Qty plus
    UIButton* plus = [UIButton buttonWithType:UIButtonTypeCustom];
    plus.frame = CGRectMake(w - 76, 7, 20, 20);
    [plus setTitle:@"+" forState:UIControlStateNormal];
    [plus setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    plus.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    plus.layer.borderWidth = 1;
    plus.layer.borderColor = UIColor.blackColor.CGColor;
    [plus addTarget:self action:@selector(incQty) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:plus];

    // SPAWN button
    UIButton* spawnBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    spawnBtn.frame = CGRectMake(w - 52, 6, 46, 22);
    spawnBtn.backgroundColor = UIColor.blackColor;
    [spawnBtn setTitle:@"SPAWN" forState:UIControlStateNormal];
    [spawnBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    spawnBtn.titleLabel.font = [UIFont boldSystemFontOfSize:8];
    [spawnBtn addTarget:self action:@selector(spawnTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:spawnBtn];

    // Bottom separator
    UIView* sep = [[UIView alloc] initWithFrame:CGRectMake(0, 33, w, 1)];
    sep.backgroundColor = [UIColor colorWithWhite:0.88 alpha:1];
    [self addSubview:sep];

    return self;
}

- (void)incQty { self.qty = MIN(999, self.qty + 1); self.qtyLabel.text = [NSString stringWithFormat:@"%d", self.qty]; }
- (void)decQty { self.qty = MAX(1,   self.qty - 1); self.qtyLabel.text = [NSString stringWithFormat:@"%d", self.qty]; }
- (void)spawnTapped { doSpawn(self.itemId, self.qty); }

@end

// =============================================================================
//  PANEL VIEW CONTROLLER
// =============================================================================

@interface JackzPanel : UIViewController
@end

@implementation JackzPanel

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.85];

    // Tap backdrop to close
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(closePanel)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];

    CGFloat W    = MIN(360, self.view.bounds.size.width  - 20);
    CGFloat H    = MIN(540, self.view.bounds.size.height - 60);
    CGFloat X    = (self.view.bounds.size.width  - W) / 2;
    CGFloat Y    = (self.view.bounds.size.height - H) / 2;

    // ── Outer panel ──────────────────────────────────────────────────────────
    UIView* panel = [[UIView alloc] initWithFrame:CGRectMake(X, Y, W, H)];
    panel.backgroundColor   = UIColor.whiteColor;
    panel.layer.borderWidth  = 3;
    panel.layer.borderColor  = UIColor.blackColor.CGColor;
    panel.clipsToBounds      = YES;
    UITapGestureRecognizer* pt = [[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(noop)];
    [panel addGestureRecognizer:pt];
    [self.view addSubview:panel];

    // ── Header bar ───────────────────────────────────────────────────────────
    UIView* header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, W, 36)];
    header.backgroundColor = UIColor.blackColor;
    [panel addSubview:header];

    UILabel* title = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, W - 60, 36)];
    title.text      = @"JACKZ MOD MENU";
    title.font      = [UIFont fontWithName:@"Courier-Bold" size:13] ?: [UIFont boldSystemFontOfSize:13];
    title.textColor = UIColor.whiteColor;
    title.letterSpacing = 1;
    [header addSubview:title];

    UIButton* xBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    xBtn.frame           = CGRectMake(W - 36, 8, 22, 20);
    xBtn.backgroundColor = [UIColor colorWithRed:1 green:0.27 blue:0.27 alpha:1];
    [xBtn setTitle:@"X" forState:UIControlStateNormal];
    [xBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    xBtn.titleLabel.font = [UIFont boldSystemFontOfSize:11];
    [xBtn addTarget:self action:@selector(closePanel) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:xBtn];

    CGFloat y = 36;

    // ── SPAWNER section (65%) ─────────────────────────────────────────────────
    CGFloat spawnerH = (H - 36) * 0.65;

    UIView* spawnerHeader = [[UIView alloc] initWithFrame:CGRectMake(0, y, W, 22)];
    spawnerHeader.backgroundColor = [UIColor colorWithWhite:0.93 alpha:1];
    UILabel* shl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, W, 22)];
    shl.text      = @"SPAWNER";
    shl.font      = [UIFont fontWithName:@"Courier-Bold" size:11] ?: [UIFont boldSystemFontOfSize:11];
    shl.textColor = UIColor.blackColor;
    shl.textAlignment = NSTextAlignmentCenter;
    [spawnerHeader addSubview:shl];
    // Bottom border
    UIView* shb = [[UIView alloc] initWithFrame:CGRectMake(0, 21, W, 1)];
    shb.backgroundColor = UIColor.blackColor;
    [spawnerHeader addSubview:shb];
    [panel addSubview:spawnerHeader];
    y += 22;

    UIScrollView* spawnerScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, y, W, spawnerH - 22)];
    spawnerScroll.backgroundColor = [UIColor colorWithWhite:0.99 alpha:1];
    spawnerScroll.showsVerticalScrollIndicator = YES;
    [panel addSubview:spawnerScroll];

    // Build item rows
    CGFloat rowY = 0;
    for (NSString* item in allItems()) {
        SpawnRow* row = [[SpawnRow alloc] initWithItem:item width:W];
        row.frame = CGRectMake(0, rowY, W, 34);
        [spawnerScroll addSubview:row];
        rowY += 34;
    }
    spawnerScroll.contentSize = CGSizeMake(W, rowY);
    y += spawnerH - 22;

    // Divider
    UIView* div = [[UIView alloc] initWithFrame:CGRectMake(0, y, W, 2)];
    div.backgroundColor = UIColor.blackColor;
    [panel addSubview:div];
    y += 2;

    // ── PREFABS section (35%) ─────────────────────────────────────────────────
    CGFloat prefabH = H - y;

    UIView* prefabHeader = [[UIView alloc] initWithFrame:CGRectMake(0, y, W, 22)];
    prefabHeader.backgroundColor = [UIColor colorWithWhite:0.93 alpha:1];
    UILabel* phl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, W, 22)];
    phl.text      = @"PREFABS";
    phl.font      = [UIFont fontWithName:@"Courier-Bold" size:11] ?: [UIFont boldSystemFontOfSize:11];
    phl.textColor = UIColor.blackColor;
    phl.textAlignment = NSTextAlignmentCenter;
    [prefabHeader addSubview:phl];
    UIView* phb = [[UIView alloc] initWithFrame:CGRectMake(0, 21, W, 1)];
    phb.backgroundColor = UIColor.blackColor;
    [prefabHeader addSubview:phb];
    [panel addSubview:prefabHeader];
    y += 22;

    UIScrollView* prefabScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, y, W, prefabH - 22)];
    prefabScroll.backgroundColor = UIColor.whiteColor;
    [panel addSubview:prefabScroll];

    CGFloat pRowY = 0;
    for (NSString* item in allPrefabs()) {
        SpawnRow* row = [[SpawnRow alloc] initWithItem:item width:W];
        row.frame = CGRectMake(0, pRowY, W, 34);
        [prefabScroll addSubview:row];
        pRowY += 34;
    }
    prefabScroll.contentSize = CGSizeMake(W, pRowY);
}

- (void)noop {}

- (void)closePanel {
    [UIView animateWithDuration:0.15 animations:^{ self.view.alpha = 0; }
                     completion:^(BOOL f) {
        [self dismissViewControllerAnimated:NO completion:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"JackzPanelClosed" object:nil];
    }];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations { return UIInterfaceOrientationMaskAll; }
- (BOOL)prefersStatusBarHidden { return NO; }

@end

// =============================================================================
//  FLOATING "Open Jackz Menu" BUTTON
// =============================================================================

static UIButton* g_menuBtn   = nil;
static CGPoint   g_dragStart;

static void createMenuButton(void) {
    if (g_menuBtn) return;
    UIWindow* win = nil;
    for (UIScene* s in [UIApplication sharedApplication].connectedScenes) {
        if ([s isKindOfClass:[UIWindowScene class]]) {
            for (UIWindow* w in ((UIWindowScene*)s).windows)
                if (w.isKeyWindow) { win = w; break; }
            if (win) break;
        }
    }
    if (!win) return;

    g_menuBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    g_menuBtn.frame           = CGRectMake(0, win.bounds.size.height / 2 - 20, 34, 40);
    g_menuBtn.backgroundColor = UIColor.blackColor;
    g_menuBtn.layer.maskedCorners  = kCALayerMaxXMinYCorner | kCALayerMaxXMaxYCorner;
    g_menuBtn.layer.cornerRadius   = 4;
    g_menuBtn.titleLabel.font      = [UIFont boldSystemFontOfSize:7];
    g_menuBtn.titleLabel.numberOfLines = 3;
    g_menuBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
    [g_menuBtn setTitle:@"JACKZ\nMENU" forState:UIControlStateNormal];
    [g_menuBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];

    [g_menuBtn addTarget:[JackzPanel class]
                  action:@selector(openPanel)
        forControlEvents:UIControlEventTouchUpInside];

    UIPanGestureRecognizer* pan = [[UIPanGestureRecognizer alloc]
        initWithTarget:[JackzPanel class] action:@selector(handleDrag:)];
    [g_menuBtn addGestureRecognizer:pan];
    [win addSubview:g_menuBtn];

    [[NSNotificationCenter defaultCenter] addObserverForName:@"JackzPanelClosed"
        object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification* n) {
            g_menuBtn.hidden = NO;
        }];
}

@implementation JackzPanel (Toggle)

+ (void)openPanel {
    UIWindow* win = g_menuBtn.window;
    if (!win) return;
    UIViewController* root = win.rootViewController;
    while (root.presentedViewController) root = root.presentedViewController;
    JackzPanel* p = [[JackzPanel alloc] init];
    p.modalPresentationStyle = UIModalPresentationOverFullScreen;
    p.modalTransitionStyle   = UIModalTransitionStyleCrossDissolve;
    g_menuBtn.hidden = YES;
    [root presentViewController:p animated:YES completion:nil];
}

+ (void)handleDrag:(UIPanGestureRecognizer*)g {
    UIView* v = g.view, *sv = v.superview;
    if (!sv) return;
    if (g.state == UIGestureRecognizerStateBegan)
        g_dragStart = [g locationInView:v];
    else if (g.state == UIGestureRecognizerStateChanged) {
        CGPoint loc = [g locationInView:sv];
        CGFloat ny  = MAX(40, MIN(loc.y - g_dragStart.y,
                                  sv.bounds.size.height - v.frame.size.height - 20));
        v.frame = CGRectMake(v.frame.origin.x, ny, v.frame.size.width, v.frame.size.height);
    }
}

@end

// =============================================================================
//  ENTRY POINT
// =============================================================================

__attribute__((constructor))
static void jackzInit(void) {
    NSLog(@"[Jackz] loaded");
    resolveSpawnFn();
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        createMenuButton();
        NSLog(@"[Jackz] ready");
    });
