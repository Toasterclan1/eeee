#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <dlfcn.h>
#include <mach-o/dyld.h>
#include <string>
#include <vector>

// =============================================================================
//  MOBILESUBSTRATE / CYDIASUBSTRATE
// =============================================================================
extern "C" {
    void MSHookFunction(void* symbol, void* hook, void** old);
    void MSHookMessageEx(Class _class, SEL sel, IMP hook, IMP* old);
}
__attribute__((weak_import)) extern void MSHookFunction(void*, void*, void**);

// =============================================================================
//  ① CONFIG
// =============================================================================
static const char*     SPAWN_SYMBOL      = "";
static const uintptr_t SPAWN_FUNC_OFFSET = 0x0;

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
static SpawnFn orig_SpawnFn = nullptr;

static void hook_SpawnFn(const char* itemId, float x, float y, float z, int qty) {
    NSLog(@"[Spawner] hook_SpawnFn: %s @ (%.2f,%.2f,%.2f) x%d", itemId, x, y, z, qty);
    if (orig_SpawnFn) orig_SpawnFn(itemId, x, y, z, qty);
}

static SpawnFn resolveSpawnFn() {
    if (SPAWN_SYMBOL && strlen(SPAWN_SYMBOL) > 0) {
        void* sym = dlsym(RTLD_DEFAULT, SPAWN_SYMBOL);
        if (sym) { NSLog(@"[Spawner] resolved via symbol: %s", SPAWN_SYMBOL); return (SpawnFn)sym; }
        NSLog(@"[Spawner] symbol not found: %s — falling back to offset", SPAWN_SYMBOL);
    }
    if (SPAWN_FUNC_OFFSET == 0x0) { NSLog(@"[Spawner] SPAWN_FUNC_OFFSET not set"); return nullptr; }
    uintptr_t base = 0;
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char* name = _dyld_get_image_name(i);
        if (name && strstr(name, "AnimalCompany")) { base = (uintptr_t)_dyld_get_image_header(i); break; }
    }
    if (!base) { NSLog(@"[Spawner] binary not found"); return nullptr; }
    return (SpawnFn)(base + SPAWN_FUNC_OFFSET);
}

static void installHook() {
    SpawnFn target = resolveSpawnFn();
    if (!target) { NSLog(@"[Spawner] hook not installed — no spawn fn found"); return; }
    if (&MSHookFunction != nullptr) {
        MSHookFunction((void*)target, (void*)hook_SpawnFn, (void**)&orig_SpawnFn);
        NSLog(@"[Spawner] MSHookFunction installed");
    } else {
        orig_SpawnFn = target;
        NSLog(@"[Spawner] Substrate not found — using direct fn pointer");
    }
}

static void executeSpawn(NSString* itemId, float x, float y, float z, int qty) {
    if (!orig_SpawnFn) { NSLog(@"[Spawner] spawn fn not resolved yet"); return; }
    for (int i = 0; i < qty; i++) orig_SpawnFn([itemId UTF8String], x, y, z, 1);
}

// =============================================================================

// =============================================================================
//  smth
// =============================================================================
#import <AudioToolbox/AudioToolbox.h>

static NSInteger spawnQuantity = 1;
static float customSpawnX = 0.0f;
static float customSpawnY = 3.0f;
static float customSpawnZ = 0.0f;
static BOOL useCustomLocation = NO;
static NSInteger selectedItemIndex = 0;
static NSInteger selectedPresetLocation = 0;
static NSArray *availableItems = nil;
static NSArray *filteredItems = nil;

static void *il2cppHandle = nil;
static BOOL isInitialized = NO;

static init64_t (*il2cpp_domain_get)(void);
static init64_t (*il2cpp_domain_get_assemblies)(init64_t, init64_t *);
static init64_t (*il2cpp_assembly_get_image)(init64_t);
static const char *(*il2cpp_image_get_name)(init64_t);
static init64_t (*il2cpp_class_from_name)(init64_t, const char *, const char *);
static init64_t (*il2cpp_class_get_method_from_name)(init64_t, const char *, int);
static init64_t (*il2cpp_runtime_invoke)(init64_t, init64_t, void **, init64_t *);
static init64_t (*il2cpp_resolve_icall)(const char *);
static init64_t (*il2cpp_class_get_field_from_name)(init64_t, const char *);
static void (*il2cpp_field_set_value)(init64_t, init64_t, void *);
static init64_t (*il2cpp_field_get_value)(init64_t, init64_t, void *);
static init64_t (*il2cpp_class_get_type)(init64_t);
static init64_t (*il2cpp_type_get_object)(init64_t);
static init64_t (*il2cpp_string_new)(const char *);

static init64_t gameImage = 0;
static init64_t unityImage = 0;
static init64_t netPlayerClass = 0;
static init64_t prefabGeneratorClass = 0;
static init64_t gameObjectClass = 0;
static init64_t transformClass = 0;
static init64_t objectClass = 0;
static init64_t gameManagerClass = 0;
static init64_t getLocalPlayerMethod = 0;
static init64_t giveSelfMoneyMethod = 0;
static init64_t spawnItemMethod = 0;
static init64_t findObjectOfTypeMethod = 0;
static init64_t itemSellingMachineClass = 0;
static init64_t rpcAddPlayerMoneyToAllMethod = 0;
static init64_t gameManagerAddPlayerMoneyMethod = 0;
static init64_t Transform_get_position_Injected = 0;

static UIButton *menuButton = nil;
static id menuController = nil;

typedef struct { float x; float y; float z; } Vec3;

static NSArray *presetLocationNames;
static Vec3 presetLocationCoords[13];


static init64_t getImage(const char *name) {
    if (!isInitialized) return 0;
    init64_t domain = il2cpp_domain_get();
    if (!domain) return 0;
    init64_t count = 0;
    init64_t assemblies = il2cpp_domain_get_assemblies(domain, &count);
    for (init64_t i = 0; i < count; i++) {
        init64_t assembly = *((init64_t *)(assemblies + 8 * i));
        init64_t image = il2cpp_assembly_get_image(assembly);
        const char *imgName = il2cpp_image_get_name(image);
        if (imgName && strcmp(imgName, name) == 0) return image;
    }
    return 0;
}

static BOOL initializeIL2CPP(void) {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, "UnityFramework")) {
            il2cppHandle = dlopen(name, RTLD_NOW);
            break;
        }
    }
    if (!il2cppHandle) il2cppHandle = dlopen(0, 2);
    if (!il2cppHandle) return NO;

    il2cpp_domain_get = dlsym(il2cppHandle, "il2cpp_domain_get");
    il2cpp_domain_get_assemblies = dlsym(il2cppHandle, "il2cpp_domain_get_assemblies");
    il2cpp_assembly_get_image = dlsym(il2cppHandle, "il2cpp_assembly_get_image");
    il2cpp_image_get_name = dlsym(il2cppHandle, "il2cpp_image_get_name");
    il2cpp_class_from_name = dlsym(il2cppHandle, "il2cpp_class_from_name");
    il2cpp_class_get_method_from_name = dlsym(il2cppHandle, "il2cpp_class_get_method_from_name");
    il2cpp_string_new = dlsym(il2cppHandle, "il2cpp_string_new");
    il2cpp_runtime_invoke = dlsym(il2cppHandle, "il2cpp_runtime_invoke");
    il2cpp_resolve_icall = dlsym(il2cppHandle, "il2cpp_resolve_icall");
    il2cpp_class_get_field_from_name = dlsym(il2cppHandle, "il2cpp_class_get_field_from_name");
    il2cpp_field_get_value = dlsym(il2cppHandle, "il2cpp_field_get_value");
    il2cpp_field_set_value = dlsym(il2cppHandle, "il2cpp_field_set_value");
    il2cpp_class_get_type = dlsym(il2cppHandle, "il2cpp_class_get_type");
    il2cpp_type_get_object = dlsym(il2cppHandle, "il2cpp_type_get_object");

    if (il2cpp_domain_get && il2cpp_class_from_name && il2cpp_class_get_method_from_name && il2cpp_class_get_type && il2cpp_type_get_object) {
        Transform_get_position_Injected = il2cpp_resolve_icall("UnityEngine.Transform::get_position_Injected");
        isInitialized = YES;
        return YES;
    }
    return NO;
}

static BOOL initializeGameClasses(void) {
    if (!isInitialized) return NO;
    gameImage = getImage("AnimalCompany.dll");
    if (!gameImage) return NO;
    unityImage = getImage("UnityEngine.CoreModule.dll");
    netPlayerClass = il2cpp_class_from_name(gameImage, "AnimalCompany", "NetPlayer");
    prefabGeneratorClass = il2cpp_class_from_name(gameImage, "AnimalCompany", "PrefabGenerator");
    if (unityImage) {
        gameObjectClass = il2cpp_class_from_name(unityImage, "UnityEngine", "GameObject");
        transformClass = il2cpp_class_from_name(unityImage, "UnityEngine", "Transform");
    }
    if (!netPlayerClass) return NO;
    getLocalPlayerMethod = il2cpp_class_get_method_from_name(netPlayerClass, "get_localPlayer", 0);
    giveSelfMoneyMethod = il2cpp_class_get_method_from_name(netPlayerClass, "AddPlayerMoney", 1);
    if (prefabGeneratorClass)
        spawnItemMethod = il2cpp_class_get_method_from_name(prefabGeneratorClass, "SpawnItem", 4);
    if (unityImage) {
        objectClass = il2cpp_class_from_name(unityImage, "UnityEngine", "Object");
        if (objectClass)
            findObjectOfTypeMethod = il2cpp_class_get_method_from_name(objectClass, "FindObjectOfType", 1);
    }
    itemSellingMachineClass = il2cpp_class_from_name(gameImage, "AnimalCompany", "ItemSellingMachineController");
    if (itemSellingMachineClass) {
        rpcAddPlayerMoneyToAllMethod = il2cpp_class_get_method_from_name(itemSellingMachineClass, "RPC_AddPlayerMoneyToAll", 1);
        if (!rpcAddPlayerMoneyToAllMethod)
            rpcAddPlayerMoneyToAllMethod = il2cpp_class_get_method_from_name(itemSellingMachineClass, "RPC_AddPlayerMoneyToAll", 2);
    }
    gameManagerClass = il2cpp_class_from_name(gameImage, "AnimalCompany", "GameManager");
    if (gameManagerClass)
        gameManagerAddPlayerMoneyMethod = il2cpp_class_get_method_from_name(gameManagerClass, "AddPlayerMoney", 1);
    return YES;
}

static init64_t getLocalPlayer(void) {
    if (!netPlayerClass) netPlayerClass = il2cpp_class_from_name(gameImage, "AnimalCompany", "NetPlayer");
    if (!netPlayerClass) return 0;
    if (!getLocalPlayerMethod) getLocalPlayerMethod = il2cpp_class_get_method_from_name(netPlayerClass, "get_localPlayer", 0);
    if (!getLocalPlayerMethod) return 0;
    init64_t exc = 0;
    init64_t result = il2cpp_runtime_invoke(getLocalPlayerMethod, 0, nil, &exc);
    if (exc) return 0;
    return result;
}

static float getPlayerPosition(void) {
    return 0.0f;
}

static float getSpawnPosition(void) {
    if (useCustomLocation) return customSpawnX;
    if (getLocalPlayer()) return getPlayerPosition();
    return 0.0f;
}

static void giveSelfMoney(unsigned int amount) {
    if (!giveSelfMoneyMethod) {
        NSLog(@"[ACMod] giveSelfMoney: AddPlayerMoney method not found, initializing...");
        if (netPlayerClass)
            giveSelfMoneyMethod = il2cpp_class_get_method_from_name(netPlayerClass, "AddPlayerMoney", 1);
    }
    if (!giveSelfMoneyMethod) {
        NSLog(@"[ACMod] Failed to initialize AddPlayerMoney method");
        return;
    }
    init64_t player = getLocalPlayer();
    if (!player) { NSLog(@"[ACMod] Could not get local player instance"); return; }
    unsigned int val = amount;
    void *args[] = { &val };
    init64_t exc = 0;
    il2cpp_runtime_invoke(giveSelfMoneyMethod, player, args, &exc);
    if (exc) NSLog(@"[ACMod] Exception while giving money: %p", (void *)exc);
    else NSLog(@"[ACMod] Successfully gave %u money to local player", amount);
}

static void giveAllPlayersMoney(int amount) {
    if (rpcAddPlayerMoneyToAllMethod && findObjectOfTypeMethod && il2cpp_class_get_type && il2cpp_type_get_object) {
        init64_t type = il2cpp_class_get_type(itemSellingMachineClass);
        init64_t obj = il2cpp_type_get_object(type);
        init64_t exc = 0;
        void *findArgs[] = { &obj };
        init64_t controller = il2cpp_runtime_invoke(findObjectOfTypeMethod, 0, findArgs, &exc);
        if (!controller || exc) {
            NSLog(@"[ACMod] ItemSellingMachine controller not found or findObjectOfType had exception");
        } else {
            NSLog(@"[ACMod] Found ItemSellingMachine controller, trying RPC_AddPlayerMoneyToAll");
            int val = amount;
            void *args1[] = { &val };
            exc = 0;
            il2cpp_runtime_invoke(rpcAddPlayerMoneyToAllMethod, controller, args1, &exc);
            if (!exc) { NSLog(@"[ACMod] RPC_AddPlayerMoneyToAll invoked successfully with single int param"); return; }
            NSLog(@"[ACMod] RPC_AddPlayerMoneyToAll (int) exception occurred, trying (int,RpcInfo) fallback");
            void *args2[] = { &val, nil };
            exc = 0;
            il2cpp_runtime_invoke(rpcAddPlayerMoneyToAllMethod, controller, args2, &exc);
            if (!exc) { NSLog(@"[ACMod] RPC_AddPlayerMoneyToAll invoked successfully with (int,RpcInfo=NULL)"); return; }
            NSLog(@"[ACMod] RPC_AddPlayerMoneyToAll fallback also failed");
        }
    } else {
        NSLog(@"[ACMod] RPC_AddPlayerMoneyToAll method or helpers not available");
    }
    if (gameManagerAddPlayerMoneyMethod) {
        NSLog(@"[ACMod] Trying GameManager.AddPlayerMoney as fallback");
        int val = amount;
        void *args[] = { &val };
        init64_t exc = 0;
        il2cpp_runtime_invoke(gameManagerAddPlayerMoneyMethod, 0, args, &exc);
        if (!exc) { NSLog(@"[ACMod] GameManager.AddPlayerMoney invoked successfully"); return; }
        NSLog(@"[ACMod] GameManager.AddPlayerMoney invocation threw an exception");
    } else {
        NSLog(@"[ACMod] GameManager.AddPlayerMoney method not found");
    }
    NSLog(@"[ACMod] Falling back to giveSelfMoney for amount %d", amount);
    giveSelfMoney(amount);
}

static void spawnItem(NSString *itemName, int quantity, float x, float y, float z) {
    if (!spawnItemMethod || !il2cpp_string_new) return;
    init64_t nameStr = il2cpp_string_new([itemName UTF8String]);
    float scale = 1.0f;
    void *args[] = { &nameStr, &quantity, &x, &y, &z };
    init64_t exc = 0;
    il2cpp_runtime_invoke(spawnItemMethod, 0, args, &exc);
}

static id loadSettings(void) {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    spawnQuantity = [d integerForKey:@"ACMod_spawnQuantity"] ?: 1;
    customSpawnX = [d floatForKey:@"ACMod_customSpawnX"];
    customSpawnY = [d floatForKey:@"ACMod_customSpawnY"] ?: 3.0f;
    customSpawnZ = [d floatForKey:@"ACMod_customSpawnZ"];
    useCustomLocation = [d boolForKey:@"ACMod_useCustomLocation"];
    selectedItemIndex = [d integerForKey:@"ACMod_selectedItemIndex"];
    selectedPresetLocation = [d integerForKey:@"ACMod_selectedPresetLocation"];
    return nil;
}

static BOOL saveSettings(void) {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    [d setInteger:spawnQuantity forKey:@"ACMod_spawnQuantity"];
    [d setFloat:customSpawnX forKey:@"ACMod_customSpawnX"];
    [d setFloat:customSpawnY forKey:@"ACMod_customSpawnY"];
    [d setFloat:customSpawnZ forKey:@"ACMod_customSpawnZ"];
    [d setBool:useCustomLocation forKey:@"ACMod_useCustomLocation"];
    [d setInteger:selectedItemIndex forKey:@"ACMod_selectedItemIndex"];
    [d setInteger:selectedPresetLocation forKey:@"ACMod_selectedPresetLocation"];
    [d synchronize];
    return YES;
}



// =============================================================================
//  ④b UI — overlay panel (ITEMS / PLAYERS / CHEATS tabs)
// =============================================================================

@interface SpawnerPanel : UIView <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
// Items tab
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
// Players tab
@property (nonatomic, strong) UITableView*                   playerTable;
@property (nonatomic, strong) NSMutableArray<NSDictionary*>* playerList;
@property (nonatomic, strong) NSDictionary*                  selectedPlayer;
// Tabs
@property (nonatomic, strong) UIButton* tabItems;
@property (nonatomic, strong) UIButton* tabPlayers;
@property (nonatomic, strong) UIButton* tabCheats;
@property (nonatomic, strong) UIView*   itemsContainer;
@property (nonatomic, strong) UIView*   playersContainer;
@property (nonatomic, strong) UIView*   cheatsContainer;
@property (nonatomic, assign) NSInteger activeTab; // 0=items 1=players 2=cheats
@end


@implementation SpawnerPanel


- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    self.filteredItems = [itemList() mutableCopy];
    self.selectedItem  = itemList().firstObject;
    self.playerList    = [NSMutableArray array];
    self.activeTab     = 0;
    self.isPanelOpen   = NO;
    loadSettings();
    [self buildUI];
    return self;
}


- (void)buildUI {
    CGFloat W = self.bounds.size.width, pad = 12;
    self.backgroundColor = [UIColor colorWithWhite:0.92 alpha:0.97];
    self.layer.cornerRadius = 12; self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOpacity = 0.35; self.layer.shadowRadius = 12;
    self.layer.shadowOffset = CGSizeMake(0,4); self.clipsToBounds = NO;

    // Title bar
    UIView* tb = [[UIView alloc] initWithFrame:CGRectMake(0,0,W,40)];
    tb.backgroundColor = [UIColor colorWithWhite:0.82 alpha:1];
    UIBezierPath* bp = [UIBezierPath bezierPathWithRoundedRect:tb.bounds byRoundingCorners:UIRectCornerTopLeft|UIRectCornerTopRight cornerRadii:CGSizeMake(12,12)];
    CAShapeLayer* sl = [CAShapeLayer layer]; sl.path = bp.CGPath; tb.layer.mask = sl;
    [self addSubview:tb];
    UILabel* ttl = [[UILabel alloc] initWithFrame:CGRectMake(pad,0,W-60,40)];
    ttl.text = @"insert name here"; ttl.font = [UIFont boldSystemFontOfSize:13]; ttl.textColor = UIColor.blackColor;
    NSMutableAttributedString* as = [[NSMutableAttributedString alloc] initWithString:ttl.text];
    [as addAttribute:NSKernAttributeName value:@(1.5) range:NSMakeRange(0,as.length)];
    [as addAttribute:NSFontAttributeName value:ttl.font range:NSMakeRange(0,as.length)];
    [as addAttribute:NSForegroundColorAttributeName value:ttl.textColor range:NSMakeRange(0,as.length)];
    ttl.attributedText = as; [tb addSubview:ttl];
    UIButton* xb = [UIButton buttonWithType:UIButtonTypeSystem];
    xb.frame = CGRectMake(W-40,8,28,24); [xb setTitle:@"✕" forState:UIControlStateNormal];
    xb.titleLabel.font = [UIFont systemFontOfSize:14]; [xb setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    [xb addTarget:self action:@selector(closePanel) forControlEvents:UIControlEventTouchUpInside]; [tb addSubview:xb];

    // 3-tab bar
    CGFloat tabY=44, tabH=30, tabW=(W-pad*2-4)/3.0;
    NSArray* tabTitles = @[@"ITEMS",@"PLAYERS",@"CHEATS"];
    NSArray* tabSels   = @[@"showItemsTab",@"showPlayersTab",@"showCheatsTab"];
    NSMutableArray* tabBtns = [NSMutableArray array];
    for (int ti=0; ti<3; ti++) {
        UIButton* tb2 = [UIButton buttonWithType:UIButtonTypeSystem];
        tb2.frame = CGRectMake(pad+ti*(tabW+2), tabY, tabW, tabH);
        [tb2 setTitle:tabTitles[ti] forState:UIControlStateNormal];
        tb2.titleLabel.font = [UIFont boldSystemFontOfSize:11]; tb2.layer.cornerRadius = 5;
        [tb2 addTarget:self action:NSSelectorFromString(tabSels[ti]) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:tb2]; [tabBtns addObject:tb2];
    }
    self.tabItems = tabBtns[0]; self.tabPlayers = tabBtns[1]; self.tabCheats = tabBtns[2];

    CGFloat cY = tabY+tabH+6, cH = self.bounds.size.height-cY;

    // ── ITEMS CONTAINER ────────────────────────────────────────────────
    UIView* ic = [[UIView alloc] initWithFrame:CGRectMake(0,cY,W,cH)];
    ic.backgroundColor = UIColor.clearColor; [self addSubview:ic]; self.itemsContainer = ic;
    CGFloat y = 4;
    UITextField* sf = [[UITextField alloc] initWithFrame:CGRectMake(pad,y,W-pad*2,32)];
    sf.placeholder = @"Search items..."; sf.font = [UIFont systemFontOfSize:12];
    sf.borderStyle = UITextBorderStyleRoundedRect; sf.backgroundColor = UIColor.whiteColor;
    sf.clearButtonMode = UITextFieldViewModeWhileEditing; sf.returnKeyType = UIReturnKeyDone; sf.delegate = self;
    [sf addTarget:self action:@selector(searchChanged:) forControlEvents:UIControlEventEditingChanged];
    [ic addSubview:sf]; self.searchField = sf; y += 38;
    UITableView* tv = [[UITableView alloc] initWithFrame:CGRectMake(pad,y,W-pad*2,115) style:UITableViewStylePlain];
    tv.dataSource=self; tv.delegate=self; tv.rowHeight=28; tv.backgroundColor=UIColor.whiteColor;
    tv.separatorColor=[UIColor colorWithWhite:0.85 alpha:1]; tv.layer.borderWidth=1;
    tv.layer.borderColor=[UIColor colorWithWhite:0.7 alpha:1].CGColor; tv.layer.cornerRadius=6; tv.clipsToBounds=YES; tv.tag=1;
    [ic addSubview:tv]; self.itemTable=tv; y+=121;
    UILabel* qLbl=[[UILabel alloc] initWithFrame:CGRectMake(pad,y+4,70,24)];
    qLbl.text=@"QUANTITY"; qLbl.font=[UIFont boldSystemFontOfSize:10]; qLbl.textColor=UIColor.blackColor; [ic addSubview:qLbl];
    UILabel* qVal=[[UILabel alloc] initWithFrame:CGRectMake(78,y,40,32)];
    qVal.text=[NSString stringWithFormat:@"%ld",(long)spawnQuantity]; qVal.font=[UIFont boldSystemFontOfSize:18]; qVal.textColor=UIColor.blackColor;
    [ic addSubview:qVal]; self.qtyLabel=qVal;
    UIStepper* stp=[[UIStepper alloc] initWithFrame:CGRectMake(W-pad-100,y+4,94,29)];
    stp.minimumValue=1; stp.maximumValue=99; stp.value=spawnQuantity; stp.stepValue=1;
    stp.tintColor=[UIColor colorWithWhite:0.4 alpha:1];
    [stp addTarget:self action:@selector(qtyChanged:) forControlEvents:UIControlEventValueChanged];
    [ic addSubview:stp]; self.qtyStepper=stp; y+=40;
    UILabel* cLbl=[[UILabel alloc] initWithFrame:CGRectMake(pad,y,W-pad*2,18)];
    cLbl.text=@"📍 SPAWN COORDINATES"; cLbl.font=[UIFont boldSystemFontOfSize:10]; cLbl.textColor=UIColor.blackColor;
    [ic addSubview:cLbl]; y+=22;
    NSArray* axLabels=@[@"X",@"Y",@"Z"]; float cv[3]={customSpawnX,customSpawnY,customSpawnZ};
    NSArray* cFields=@[(self.coordX=[self makeCoordField]),(self.coordY=[self makeCoordField]),(self.coordZ=[self makeCoordField])];
    CGFloat fw=(W-pad*2-16)/3.0;
    for(int ci=0;ci<3;ci++){
        CGFloat fx=pad+ci*(fw+8);
        UILabel* al=[[UILabel alloc] initWithFrame:CGRectMake(fx,y,fw,14)];
        al.text=axLabels[ci]; al.font=[UIFont boldSystemFontOfSize:10]; al.textColor=UIColor.blackColor; al.textAlignment=NSTextAlignmentCenter; [ic addSubview:al];
        UITextField* af=cFields[ci]; af.text=[NSString stringWithFormat:@"%.2f",cv[ci]]; af.frame=CGRectMake(fx,y+16,fw,30); [ic addSubview:af];
    }
    y+=54;
    UIButton* spawnBtn=[UIButton buttonWithType:UIButtonTypeSystem];
    spawnBtn.frame=CGRectMake(pad,y,W-pad*2,36); [spawnBtn setTitle:@"SPAWN ITEM" forState:UIControlStateNormal];
    spawnBtn.titleLabel.font=[UIFont boldSystemFontOfSize:14]; spawnBtn.backgroundColor=UIColor.whiteColor;
    spawnBtn.layer.borderWidth=2; spawnBtn.layer.borderColor=[UIColor colorWithWhite:0.65 alpha:1].CGColor; spawnBtn.layer.cornerRadius=6;
    [spawnBtn setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    [spawnBtn addTarget:self action:@selector(spawnTapped:) forControlEvents:UIControlEventTouchUpInside];
    [ic addSubview:spawnBtn]; y+=44;
    UILabel* stl=[[UILabel alloc] initWithFrame:CGRectMake(pad,y,W-pad*2,26)];
    stl.font=[UIFont monospacedSystemFontOfSize:10 weight:UIFontWeightRegular]; stl.textColor=UIColor.blackColor;
    stl.textAlignment=NSTextAlignmentCenter; stl.numberOfLines=2; [ic addSubview:stl]; self.statusLabel=stl;

    // ── PLAYERS CONTAINER ──────────────────────────────────────────────
    UIView* pc=[[UIView alloc] initWithFrame:CGRectMake(0,cY,W,cH)];
    pc.backgroundColor=UIColor.clearColor; pc.hidden=YES; [self addSubview:pc]; self.playersContainer=pc;
    CGFloat py2=4;
    UILabel* ph=[[UILabel alloc] initWithFrame:CGRectMake(pad,py2+4,W-pad*2-70,20)];
    ph.text=@"👥 LOBBY PLAYERS"; ph.font=[UIFont boldSystemFontOfSize:10]; ph.textColor=UIColor.blackColor; [pc addSubview:ph];
    UIButton* rfBtn=[UIButton buttonWithType:UIButtonTypeSystem];
    rfBtn.frame=CGRectMake(W-pad-64,py2,64,28); [rfBtn setTitle:@"⟳ REFRESH" forState:UIControlStateNormal];
    rfBtn.titleLabel.font=[UIFont boldSystemFontOfSize:9]; rfBtn.backgroundColor=[UIColor colorWithWhite:0.82 alpha:1];
    rfBtn.layer.cornerRadius=5; rfBtn.layer.borderWidth=1; rfBtn.layer.borderColor=[UIColor colorWithWhite:0.65 alpha:1].CGColor;
    [rfBtn setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    [rfBtn addTarget:self action:@selector(refreshPlayers) forControlEvents:UIControlEventTouchUpInside];
    [pc addSubview:rfBtn]; py2+=32;
    UITableView* ptv=[[UITableView alloc] initWithFrame:CGRectMake(pad,py2,W-pad*2,175) style:UITableViewStylePlain];
    ptv.dataSource=self; ptv.delegate=self; ptv.rowHeight=44; ptv.backgroundColor=UIColor.whiteColor;
    ptv.separatorColor=[UIColor colorWithWhite:0.85 alpha:1]; ptv.layer.borderWidth=1;
    ptv.layer.borderColor=[UIColor colorWithWhite:0.7 alpha:1].CGColor; ptv.layer.cornerRadius=6; ptv.clipsToBounds=YES; ptv.tag=2;
    [pc addSubview:ptv]; self.playerTable=ptv; py2+=181;
    UIButton* satBtn=[UIButton buttonWithType:UIButtonTypeSystem];
    satBtn.frame=CGRectMake(pad,py2,W-pad*2,36); [satBtn setTitle:@"SPAWN AT PLAYER" forState:UIControlStateNormal];
    satBtn.titleLabel.font=[UIFont boldSystemFontOfSize:14]; satBtn.backgroundColor=UIColor.whiteColor;
    satBtn.layer.borderWidth=2; satBtn.layer.borderColor=[UIColor colorWithWhite:0.65 alpha:1].CGColor; satBtn.layer.cornerRadius=6;
    [satBtn setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    [satBtn addTarget:self action:@selector(spawnAtPlayerTapped:) forControlEvents:UIControlEventTouchUpInside];
    [pc addSubview:satBtn];

    // ── CHEATS CONTAINER ───────────────────────────────────────────────
    UIView* cc=[[UIView alloc] initWithFrame:CGRectMake(0,cY,W,cH)];
    cc.backgroundColor=UIColor.clearColor; cc.hidden=YES; [self addSubview:cc]; self.cheatsContainer=cc;
    CGFloat cy2=4, bh=36, gap=8;
    // Helper block to make a cheat button
    void (^addBtn)(NSString*, NSString*) = ^(NSString* lbl, NSString* sel) {
        UIButton* b=[UIButton buttonWithType:UIButtonTypeSystem];
        b.frame=CGRectMake(pad,cy2,W-pad*2,bh);
        [b setTitle:lbl forState:UIControlStateNormal];
        b.titleLabel.font=[UIFont boldSystemFontOfSize:13]; b.backgroundColor=UIColor.whiteColor;
        b.layer.borderWidth=1.5; b.layer.borderColor=[UIColor colorWithWhite:0.65 alpha:1].CGColor; b.layer.cornerRadius=6;
        [b setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
        [b addTarget:self action:NSSelectorFromString(sel) forControlEvents:UIControlEventTouchUpInside];
        [cc addSubview:b]; cy2+=bh+gap;
    };
    UILabel* mh=[[UILabel alloc] initWithFrame:CGRectMake(pad,cy2,W-pad*2,16)];
    mh.text=@"💰 MONEY"; mh.font=[UIFont boldSystemFontOfSize:10]; mh.textColor=UIColor.blackColor; [cc addSubview:mh]; cy2+=20;
    addBtn(@"Give Self 9,999,999",        @"giveBigMoney");
    addBtn(@"Give All Players 9,999,999", @"giveAllPlayersBigMoney");
    cy2+=gap;
    UILabel* ch=[[UILabel alloc] initWithFrame:CGRectMake(pad,cy2,W-pad*2,16)];
    ch.text=@"⚡ CHEATS"; ch.font=[UIFont boldSystemFontOfSize:10]; ch.textColor=UIColor.blackColor; [cc addSubview:ch]; cy2+=20;
    addBtn(@"Infinite Ammo",      @"giveInfAmmo");
    addBtn(@"No Shop Cooldown",   @"removeShopCooldown");
    addBtn(@"Reset Spawn Coords", @"resetLocationSettings");
    cy2+=gap;
    UILabel* comh=[[UILabel alloc] initWithFrame:CGRectMake(pad,cy2,W-pad*2,16)];
    comh.text=@"🌐 COMMUNITY"; comh.font=[UIFont boldSystemFontOfSize:10]; comh.textColor=UIColor.blackColor; [cc addSubview:comh]; cy2+=20;
    addBtn(@"Join Discord", @"openDiscord");

    [self updateTabColors];
}


- (UITextField*)makeCoordField {
    UITextField* f = [[UITextField alloc] init];
    f.placeholder = @"0"; f.keyboardType = UIKeyboardTypeDecimalPad;
    f.borderStyle = UITextBorderStyleRoundedRect;
    f.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
    f.textAlignment = NSTextAlignmentCenter;
    f.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1]; f.delegate = self;
    return f;
}


- (BOOL)textFieldShouldReturn:(UITextField*)tf { [tf resignFirstResponder]; return YES; }
- (void)touchesBegan:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event { [self endEditing:YES]; }



- (void)updateTabColors {
    NSArray* btns  = @[self.tabItems, self.tabPlayers, self.tabCheats];
    NSArray* views = @[self.itemsContainer, self.playersContainer, self.cheatsContainer];
    for (NSInteger ti=0; ti<3; ti++) {
        UIButton* b = btns[ti]; BOOL active = (ti == self.activeTab);
        b.backgroundColor = active ? [UIColor colorWithWhite:0.3 alpha:1] : [UIColor colorWithWhite:0.75 alpha:1];
        [b setTitleColor:active ? UIColor.whiteColor : UIColor.blackColor forState:UIControlStateNormal];
        ((UIView*)views[ti]).hidden = !active;
    }
}
- (void)showItemsTab   { self.activeTab=0; [self updateTabColors]; }
- (void)showPlayersTab { self.activeTab=1; [self updateTabColors]; [self refreshPlayers]; }
- (void)showCheatsTab  { self.activeTab=2; [self updateTabColors]; }


- (void)searchChanged:(UITextField*)tf {
    NSString* q = tf.text.lowercaseString;
    self.filteredItems = q.length == 0
        ? [itemList() mutableCopy]
        : [[itemList() filteredArrayUsingPredicate:
            [NSPredicate predicateWithFormat:@"SELF CONTAINS[c] %@", q]] mutableCopy];
    [self.itemTable reloadData];
}


- (void)qtyChanged:(UIStepper*)s {
    spawnQuantity = (NSInteger)s.value;
    self.qtyLabel.text = [NSString stringWithFormat:@"%ld", (long)spawnQuantity];
    saveSettings();
}


- (void)spawnTapped:(UIButton*)btn {
    [self endEditing:YES];
    if (!self.selectedItem) { [self showStatus:@"!! no item selected !!" color:[UIColor systemRedColor]]; return; }
    NSString* xStr = self.coordX.text, *yStr = self.coordY.text, *zStr = self.coordZ.text;
    if (!xStr.length || !yStr.length || !zStr.length) {
        [self showStatus:@"!! fill in X, Y, Z !!" color:[UIColor systemRedColor]]; return;
    }
    float x = xStr.floatValue, y = yStr.floatValue, z = zStr.floatValue;
    int   q = (int)self.qtyStepper.value;
    [btn setTitle:@"SPAWNING..." forState:UIControlStateNormal]; btn.enabled = NO;

    if (op_spawnItemMethod && op_il2cpp_string_new)
        [NSObject op_spawnItem:self.selectedItem quantity:q x:x y:y z:z];
    else
        executeSpawn(self.selectedItem, x, y, z, q);

    [self showStatus:[NSString stringWithFormat:@"✓ %@ → (%.1f, %.1f, %.1f)", self.selectedItem, x, y, z]
               color:[UIColor colorWithWhite:0.2 alpha:1]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [btn setTitle:@"SPAWN ITEM" forState:UIControlStateNormal]; btn.enabled = YES;
    });
}


- (void)refreshPlayers {
    NSArray* list = [NSObject op_getPlayerList];
    self.playerList     = [list mutableCopy];
    self.selectedPlayer = self.playerList.firstObject;
    [self.playerTable reloadData];
    NSLog(@"[Spawner] refreshPlayers: %d players", (int)self.playerList.count);
}


- (void)spawnAtPlayerTapped:(UIButton*)btn {
    if (!self.selectedItem) {
        [self showStatus:@"!! pick an item in ITEMS tab first !!" color:[UIColor systemRedColor]]; return;
    }
    if (!self.selectedPlayer) {
        [self showStatus:@"!! no player selected !!" color:[UIColor systemRedColor]]; return;
    }
    float x = [self.selectedPlayer[@"x"] floatValue];
    float y = [self.selectedPlayer[@"y"] floatValue];
    float z = [self.selectedPlayer[@"z"] floatValue];
    int   q = (int)self.qtyStepper.value;
    [btn setTitle:@"SPAWNING..." forState:UIControlStateNormal]; btn.enabled = NO;

    if (op_spawnItemMethod && op_il2cpp_string_new)
        [NSObject op_spawnItem:self.selectedItem quantity:q x:x y:y z:z];
    else
        executeSpawn(self.selectedItem, x, y, z, q);

    NSString* pname = self.selectedPlayer[@"name"];
    [self showStatus:[NSString stringWithFormat:@"✓ %@ → %@ (%.1f,%.1f,%.1f)", self.selectedItem, pname, x, y, z]
               color:[UIColor colorWithWhite:0.2 alpha:1]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [btn setTitle:@"SPAWN AT PLAYER" forState:UIControlStateNormal]; btn.enabled = YES;
    });
}


- (void)showStatus:(NSString*)msg color:(UIColor*)color {
    self.statusLabel.text = msg; self.statusLabel.textColor = color;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.statusLabel.text = @"";
    });
}


- (void)closePanel {
    [self endEditing:YES];
    [UIView animateWithDuration:0.25 animations:^{
        self.alpha = 0; self.transform = CGAffineTransformMakeScale(0.92, 0.92);
    } completion:^(BOOL done) {
        self.hidden = YES; self.alpha = 1; self.transform = CGAffineTransformIdentity;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SpawnerPanelClosed" object:nil];
    }];
}


// ── action methods ──────────────

- (void)giveBigMoney {
    giveSelfMoney(0x98967F);
    AudioServicesPlaySystemSound(0x5EFu);
    [self showStatus:@"Added 9,999,999 money!" color:UIColor.blackColor];
}

- (void)giveAllPlayersBigMoney {
    NSLog(@"[ACMod] Giving all players 9,999,999 money");
    giveAllPlayersMoney(9999999);
    AudioServicesPlaySystemSound(0x5EFu);
    [self showStatus:@"All players received 9,999,999 Money!" color:UIColor.blackColor];
}

- (void)giveInfAmmo {
    init64_t player = getLocalPlayer();
    if (!player) {
    [self showStatus:@"Could not find local player" color:UIColor.blackColor];
        return;
    }
    if (!netPlayerClass) { return; }
    init64_t field = il2cpp_class_get_field_from_name(netPlayerClass, "ammo");
    if (field) {
        int val = 9999;
        il2cpp_field_set_value(player, field, &val);
        AudioServicesPlaySystemSound(0x5EFu);
    [self showStatus:@"Infinite ammo activated!" color:UIColor.blackColor];
    } else {
    [self showStatus:@"Could not find ammo field" color:UIColor.blackColor];
    }
}

- (void)removeShopCooldown {
    init64_t player = getLocalPlayer();
    if (!player) {
    [self showStatus:@"Could not find local player" color:UIColor.blackColor];
        return;
    }
    if (!netPlayerClass) return;
    init64_t field = il2cpp_class_get_field_from_name(netPlayerClass, "shopCooldown");
    if (!field) field = il2cpp_class_get_field_from_name(netPlayerClass, "lastBuyTime");
    if (!field) field = il2cpp_class_get_field_from_name(netPlayerClass, "buyTimer");
    if (field) {
        int val = 0;
        il2cpp_field_set_value(player, field, &val);
        AudioServicesPlaySystemSound(0x5EFu);
    [self showStatus:@"Shop cooldown removed!" color:UIColor.blackColor];
    } else {
    [self showStatus:@"Could not find cooldown field" color:UIColor.blackColor];
    }
}

- (void)openDiscord {
    NSURL *url = [NSURL URLWithString:@"https://discord.gg/3QzJmfjKSw"];
    if ([[UIApplication sharedApplication] canOpenURL:url])
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}






- (void)resetLocationSettings {
    useCustomLocation=NO; customSpawnX=0.f; customSpawnY=3.f; customSpawnZ=0.f;
    saveSettings();
    self.coordX.text=@"0.00"; self.coordY.text=@"3.00"; self.coordZ.text=@"0.00";
    [self showStatus:@"Spawn coords reset to 0, 3, 0" color:UIColor.blackColor];
}

- (NSInteger)tableView:(UITableView*)tv numberOfRowsInSection:(NSInteger)s {
    return tv.tag == 2 ? (NSInteger)self.playerList.count : (NSInteger)self.filteredItems.count;
}

- (UITableViewCell*)tableView:(UITableView*)tv cellForRowAtIndexPath:(NSIndexPath*)ip {
    if (tv.tag == 2) {
        UITableViewCell* cell = [tv dequeueReusableCellWithIdentifier:@"pcell"];
        if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"pcell"];
        NSDictionary* p = self.playerList[ip.row];
        cell.textLabel.text = p[@"name"];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:12];
        cell.textLabel.textColor = UIColor.blackColor;
        float px = [p[@"x"] floatValue], py = [p[@"y"] floatValue], pz = [p[@"z"] floatValue];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"x:%.1f  y:%.1f  z:%.1f", px, py, pz];
        cell.detailTextLabel.font = [UIFont monospacedSystemFontOfSize:10 weight:UIFontWeightRegular];
        cell.detailTextLabel.textColor = UIColor.blackColor;
        BOOL sel = [p[@"name"] isEqualToString:self.selectedPlayer[@"name"]];
        cell.backgroundColor = sel ? [UIColor colorWithWhite:0.85 alpha:1] : UIColor.whiteColor;
        return cell;
    }
    UITableViewCell* cell = [tv dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    NSString* item = self.filteredItems[ip.row];
    cell.textLabel.text = item;
    cell.textLabel.font = [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular];
    cell.textLabel.textColor = UIColor.blackColor;
    cell.backgroundColor = [item isEqualToString:self.selectedItem]
        ? [UIColor colorWithWhite:0.85 alpha:1] : UIColor.whiteColor;
    return cell;
}

- (void)tableView:(UITableView*)tv didSelectRowAtIndexPath:(NSIndexPath*)ip {
    if (tv.tag == 2) {
        self.selectedPlayer = self.playerList[ip.row];
        // Auto-fill coord fields with this player's position
        self.coordX.text = [NSString stringWithFormat:@"%.2f", [self.selectedPlayer[@"x"] floatValue]];
        self.coordY.text = [NSString stringWithFormat:@"%.2f", [self.selectedPlayer[@"y"] floatValue]];
        self.coordZ.text = [NSString stringWithFormat:@"%.2f", [self.selectedPlayer[@"z"] floatValue]];
        [tv reloadData];
        return;
    }
    self.selectedItem = self.filteredItems[ip.row];
    [tv reloadData];
}

@end




// =============================================================================
//  ⑤ OVERLAY WINDOW + FLOATING TOGGLE BUTTON
//
//  
// =============================================================================

// ── Passthrough window — only captures touches aimed at our own views ─────────
@interface PassthroughWindow : UIWindow
@end
@implementation PassthroughWindow
- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent*)event {
    UIView* hit = [super hitTest:point withEvent:event];
    // If the hit view is the root view itself (i.e. transparent background,
    // nothing interactive underneath), return nil so the game gets the touch.
    if (hit == self.rootViewController.view) return nil;
    return hit;
}
@end

@interface FixedOrientationVC : UIViewController
@end
@implementation FixedOrientationVC
- (BOOL)shouldAutorotate { return NO; }
- (UIInterfaceOrientationMask)supportedInterfaceOrientations { return UIInterfaceOrientationMaskPortrait; }
@end

@interface SpawnerOverlay : NSObject
@property (nonatomic, strong) PassthroughWindow* overlayWindow;
@property (nonatomic, strong) SpawnerPanel*       panel;
@property (nonatomic, strong) UIButton*            toggleBtn;
@property (nonatomic)         CGRect               screenRect;
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

    // Use PassthroughWindow instead of plain UIWindow
    self.overlayWindow = [[PassthroughWindow alloc] initWithFrame:screen];
    self.overlayWindow.windowLevel = UIWindowLevelAlert + 100;
    self.overlayWindow.backgroundColor = UIColor.clearColor;
    self.overlayWindow.userInteractionEnabled = YES;

    FixedOrientationVC* root = [FixedOrientationVC new];
    root.view.backgroundColor = UIColor.clearColor;
    self.overlayWindow.rootViewController = root;
    [self.overlayWindow makeKeyAndVisible];

    root.view.frame = screen;
    root.view.bounds = CGRectMake(0, 0, screen.size.width, screen.size.height);

    // Panel
    CGFloat pw = MIN(screen.size.width * 0.85, 400);
    CGFloat ph = 560;
    CGRect  pr = CGRectMake((screen.size.width - pw) / 2, (screen.size.height - ph) / 2, pw, ph);
    self.panel = [[SpawnerPanel alloc] initWithFrame:pr];
    self.panel.hidden = YES;
    [root.view addSubview:self.panel];

    // Floating MENU button (draggable)
    UIButton* btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = CGRectMake(0, screen.size.height / 2 - 40, 32, 80);
    [btn setTitle:@"M\nE\nN\nU" forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont boldSystemFontOfSize:9];
    btn.titleLabel.numberOfLines = 4; btn.titleLabel.textAlignment = NSTextAlignmentCenter;
    btn.backgroundColor = [UIColor colorWithWhite:0.83 alpha:0.95];
    btn.layer.cornerRadius = 6;
    btn.layer.maskedCorners = kCALayerMaxXMinYCorner | kCALayerMaxXMaxYCorner;
    btn.layer.borderWidth = 1.5; btn.layer.borderColor = [UIColor colorWithWhite:0.65 alpha:1].CGColor;
    [btn setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(togglePanel) forControlEvents:UIControlEventTouchUpInside];

    UIPanGestureRecognizer* pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragBtn:)];
    [btn addGestureRecognizer:pan];
    [root.view addSubview:btn];
    self.toggleBtn = btn;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(panelClosed)
                                                 name:@"SpawnerPanelClosed" object:nil];
}

- (void)togglePanel {
    if (self.panel.hidden) {
        self.panel.hidden = NO; self.panel.alpha = 0;
        self.panel.transform = CGAffineTransformMakeScale(0.9, 0.9);
        self.toggleBtn.hidden = YES;
        [UIView animateWithDuration:0.25 animations:^{
            self.panel.alpha = 1; self.panel.transform = CGAffineTransformIdentity;
        }];
    }
}

- (void)panelClosed { self.toggleBtn.hidden = NO; }

- (void)dragBtn:(UIPanGestureRecognizer*)pan {
    UIView* v = pan.view;
    CGPoint delta = [pan translationInView:v.superview];
    CGRect f = v.frame;
    f.origin.y = MAX(0, MIN(self.screenRect.size.height - f.size.height, f.origin.y + delta.y));
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
    installHook();
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[SpawnerOverlay shared] setup];
        NSLog(@"[Spawner] overlay ready");
        initializeLists();
        presetLocationNames = @[@"Custom",@"Spawn",@"Forest",@"Mountain",@"Beach",@"Cave",@"Village",@"Ruins",@"River",@"Swamp",@"Desert",@"Tundra",@"Sky"];
        for (int _i=0;_i<13;_i++) presetLocationCoords[_i]=(Vec3){0.f,3.f,0.f};
        if ([NSObject op_initializeIL2CPP]) {
            NSLog(@"[Spawner] IL2CPP initialized");
            if ([NSObject op_initializeGameClasses])
                NSLog(@"[Spawner] game classes initialized — op_ methods ready");
            else
                NSLog(@"[Spawner] WARNING: game classes failed to initialize");
        } else {
            NSLog(@"[Spawner] WARNING: IL2CPP failed to initialize");
        }
    });
}


// =============================================================================
//  ⑦ CATEGORY: op — IL2CPP / RPC helpers
// =============================================================================

// ── IL2CPP function pointers ──────────────────────────────────────────────────
static void* op_il2cppHandle    = nil;
static BOOL  op_isInitialized   = NO;

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
static int64_t (*op_il2cpp_object_get_class)(int64_t);

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
static int64_t op_findObjectsOfTypeMethod         = 0;
static int64_t op_itemSellingMachineClass         = 0;
static int64_t op_rpcAddPlayerMoneyToAllMethod    = 0;
static int64_t op_gameManagerAddPlayerMoneyMethod = 0;
static int64_t op_Transform_get_position_Injected = 0;
static int64_t op_netPlayer_get_playerNameMethod  = 0;
static int64_t op_netPlayer_get_transformMethod   = 0;

typedef struct { float x; float y; float z; } OpVec3;

@interface NSObject (op)
+ (BOOL)op_initializeIL2CPP;
+ (BOOL)op_initializeGameClasses;
+ (int64_t)op_getImageNamed:(const char *)name;
+ (int64_t)op_getLocalPlayer;
+ (void)op_giveSelfMoney:(unsigned int)amount;
+ (void)op_giveAllPlayersMoney:(int)amount;
+ (void)op_spawnItem:(NSString *)itemName quantity:(int)quantity x:(float)x y:(float)y z:(float)z;
+ (NSArray<NSDictionary*>*)op_getPlayerList;
@end

@implementation NSObject (op)

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

+ (BOOL)op_initializeIL2CPP {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, "UnityFramework")) { op_il2cppHandle = dlopen(name, RTLD_NOW); break; }
    }
    if (!op_il2cppHandle) op_il2cppHandle = dlopen(0, 2);
    if (!op_il2cppHandle) return NO;

    op_il2cpp_domain_get                 = (int64_t (*)(void))                                dlsym(op_il2cppHandle, "il2cpp_domain_get");
    op_il2cpp_domain_get_assemblies      = (int64_t (*)(int64_t, int64_t *))                  dlsym(op_il2cppHandle, "il2cpp_domain_get_assemblies");
    op_il2cpp_assembly_get_image         = (int64_t (*)(int64_t))                             dlsym(op_il2cppHandle, "il2cpp_assembly_get_image");
    op_il2cpp_image_get_name             = (const char *(*)(int64_t))                         dlsym(op_il2cppHandle, "il2cpp_image_get_name");
    op_il2cpp_class_from_name            = (int64_t (*)(int64_t, const char *, const char *)) dlsym(op_il2cppHandle, "il2cpp_class_from_name");
    op_il2cpp_class_get_method_from_name = (int64_t (*)(int64_t, const char *, int))          dlsym(op_il2cppHandle, "il2cpp_class_get_method_from_name");
    op_il2cpp_string_new                 = (int64_t (*)(const char *))                        dlsym(op_il2cppHandle, "il2cpp_string_new");
    op_il2cpp_runtime_invoke             = (int64_t (*)(int64_t, int64_t, void **, int64_t *))dlsym(op_il2cppHandle, "il2cpp_runtime_invoke");
    op_il2cpp_resolve_icall              = (int64_t (*)(const char *))                        dlsym(op_il2cppHandle, "il2cpp_resolve_icall");
    op_il2cpp_class_get_field_from_name  = (int64_t (*)(int64_t, const char *))               dlsym(op_il2cppHandle, "il2cpp_class_get_field_from_name");
    op_il2cpp_field_get_value            = (int64_t (*)(int64_t, int64_t, void *))            dlsym(op_il2cppHandle, "il2cpp_field_get_value");
    op_il2cpp_field_set_value            = (void (*)(int64_t, int64_t, void *))               dlsym(op_il2cppHandle, "il2cpp_field_set_value");
    op_il2cpp_class_get_type             = (int64_t (*)(int64_t))                             dlsym(op_il2cppHandle, "il2cpp_class_get_type");
    op_il2cpp_type_get_object            = (int64_t (*)(int64_t))                             dlsym(op_il2cppHandle, "il2cpp_type_get_object");
    op_il2cpp_object_get_class           = (int64_t (*)(int64_t))                             dlsym(op_il2cppHandle, "il2cpp_object_get_class");

    if (op_il2cpp_domain_get && op_il2cpp_class_from_name &&
        op_il2cpp_class_get_method_from_name && op_il2cpp_class_get_type && op_il2cpp_type_get_object) {
        op_Transform_get_position_Injected = op_il2cpp_resolve_icall("UnityEngine.Transform::get_position_Injected");
        op_isInitialized = YES;
        return YES;
    }
    return NO;
}

+ (BOOL)op_initializeGameClasses {
    if (!op_isInitialized) return NO;

    op_gameImage = [self op_getImageNamed:"AnimalCompany.dll"];
    if (!op_gameImage) return NO;

    op_unityImage           = [self op_getImageNamed:"UnityEngine.CoreModule.dll"];
    op_netPlayerClass       = op_il2cpp_class_from_name(op_gameImage, "AnimalCompany", "NetPlayer");
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
        if (op_objectClass) {
            op_findObjectOfTypeMethod  = op_il2cpp_class_get_method_from_name(op_objectClass, "FindObjectOfType", 1);
            op_findObjectsOfTypeMethod = op_il2cpp_class_get_method_from_name(op_objectClass, "FindObjectsOfType", 1);
        }
    }

    op_itemSellingMachineClass = op_il2cpp_class_from_name(op_gameImage, "AnimalCompany", "ItemSellingMachineController");
    if (op_itemSellingMachineClass) {
        op_rpcAddPlayerMoneyToAllMethod = op_il2cpp_class_get_method_from_name(op_itemSellingMachineClass, "RPC_AddPlayerMoneyToAll", 1);
        if (!op_rpcAddPlayerMoneyToAllMethod)
            op_rpcAddPlayerMoneyToAllMethod = op_il2cpp_class_get_method_from_name(op_itemSellingMachineClass, "RPC_AddPlayerMoneyToAll", 2);
    }

    op_gameManagerClass = op_il2cpp_class_from_name(op_gameImage, "AnimalCompany", "GameManager");
    if (op_gameManagerClass)
        op_gameManagerAddPlayerMoneyMethod = op_il2cpp_class_get_method_from_name(op_gameManagerClass, "AddPlayerMoney", 1);

    // ── Player name + transform ───────────────────────────────────────────
    if (op_netPlayerClass) {
        op_netPlayer_get_playerNameMethod = op_il2cpp_class_get_method_from_name(op_netPlayerClass, "get_playerUsername", 0);
        if (!op_netPlayer_get_playerNameMethod)
            op_netPlayer_get_playerNameMethod = op_il2cpp_class_get_method_from_name(op_netPlayerClass, "get_playerName", 0);
        if (!op_netPlayer_get_playerNameMethod)
            op_netPlayer_get_playerNameMethod = op_il2cpp_class_get_method_from_name(op_netPlayerClass, "get_name", 0);
    }
    int64_t componentClass = op_il2cpp_class_from_name(op_unityImage, "UnityEngine", "Component");
    if (componentClass)
        op_netPlayer_get_transformMethod = op_il2cpp_class_get_method_from_name(componentClass, "get_transform", 0);

    return YES;
}

+ (int64_t)op_getLocalPlayer {
    if (!op_netPlayerClass)
        op_netPlayerClass = op_il2cpp_class_from_name(op_gameImage, "AnimalCompany", "NetPlayer");
    if (!op_netPlayerClass) return 0;
    if (!op_getLocalPlayerMethod)
        op_getLocalPlayerMethod = op_il2cpp_class_get_method_from_name(op_netPlayerClass, "get_localPlayer", 0);
    if (!op_getLocalPlayerMethod) return 0;
    int64_t exc = 0;
    int64_t result = op_il2cpp_runtime_invoke(op_getLocalPlayerMethod, 0, nil, &exc);
    return exc ? 0 : result;
}

+ (void)op_giveSelfMoney:(unsigned int)amount {
    if (!op_giveSelfMoneyMethod) {
        if (op_netPlayerClass)
            op_giveSelfMoneyMethod = op_il2cpp_class_get_method_from_name(op_netPlayerClass, "AddPlayerMoney", 1);
    }
    if (!op_giveSelfMoneyMethod) { NSLog(@"[op] AddPlayerMoney method not found"); return; }
    int64_t player = [self op_getLocalPlayer];
    if (!player) { NSLog(@"[op] Could not get local player"); return; }
    unsigned int val = amount; void *args[] = { &val }; int64_t exc = 0;
    op_il2cpp_runtime_invoke(op_giveSelfMoneyMethod, player, args, &exc);
    if (exc) NSLog(@"[op] Exception giving money"); else NSLog(@"[op] Gave %u to local player", amount);
}

+ (void)op_giveAllPlayersMoney:(int)amount {
    if (op_rpcAddPlayerMoneyToAllMethod && op_findObjectOfTypeMethod && op_il2cpp_class_get_type && op_il2cpp_type_get_object) {
        int64_t type = op_il2cpp_class_get_type(op_itemSellingMachineClass);
        int64_t obj  = op_il2cpp_type_get_object(type);
        int64_t exc  = 0; void *findArgs[] = { &obj };
        int64_t controller = op_il2cpp_runtime_invoke(op_findObjectOfTypeMethod, 0, findArgs, &exc);
        if (controller && !exc) {
            int val = amount; void *args1[] = { &val }; exc = 0;
            op_il2cpp_runtime_invoke(op_rpcAddPlayerMoneyToAllMethod, controller, args1, &exc);
            if (!exc) { NSLog(@"[op] RPC_AddPlayerMoneyToAll OK"); return; }
            void *args2[] = { &val, nil }; exc = 0;
            op_il2cpp_runtime_invoke(op_rpcAddPlayerMoneyToAllMethod, controller, args2, &exc);
            if (!exc) { NSLog(@"[op] RPC_AddPlayerMoneyToAll (fallback) OK"); return; }
        }
    }
    if (op_gameManagerAddPlayerMoneyMethod) {
        int val = amount; void *args[] = { &val }; int64_t exc = 0;
        op_il2cpp_runtime_invoke(op_gameManagerAddPlayerMoneyMethod, 0, args, &exc);
        if (!exc) { NSLog(@"[op] GameManager.AddPlayerMoney OK"); return; }
    }
    [self op_giveSelfMoney:(unsigned int)amount];
}

+ (void)op_spawnItem:(NSString *)itemName quantity:(int)quantity x:(float)x y:(float)y z:(float)z {
    if (!op_spawnItemMethod || !op_il2cpp_string_new) return;
    int64_t nameStr = op_il2cpp_string_new([itemName UTF8String]);
    void *args[] = { &nameStr, &quantity, &x, &y, &z };
    int64_t exc = 0;
    op_il2cpp_runtime_invoke(op_spawnItemMethod, 0, args, &exc);
    if (exc) NSLog(@"[op] SpawnItem exception for %@", itemName);
    else     NSLog(@"[op] Spawned %d x %@ at (%.2f, %.2f, %.2f)", quantity, itemName, x, y, z);
}

// ── Get all lobby players with names and positions ────────────────────────────
+ (NSArray<NSDictionary*>*)op_getPlayerList {
    NSMutableArray* result = [NSMutableArray array];
    if (!op_isInitialized || !op_netPlayerClass) return result;

    // Helper macro: read IL2CPP managed string → NSString
    // Layout: int32 length @ 0x10, UTF-16 chars @ 0x14
    #define READ_IL2CPP_STRING(obj) ({\
        NSString* _s = nil;\
        if (obj) {\
            int32_t _len = *(int32_t *)((obj) + 0x10);\
            if (_len > 0 && _len < 256)\
                _s = [NSString stringWithCharacters:(unichar *)((obj) + 0x14) length:(NSUInteger)_len];\
        }\
        _s;\
    })

    // ── Strategy 1: FindObjectsOfType(NetPlayer) ──────────────────────────
    if (op_findObjectsOfTypeMethod && op_il2cpp_class_get_type && op_il2cpp_type_get_object) {
        int64_t type    = op_il2cpp_class_get_type(op_netPlayerClass);
        int64_t typeObj = op_il2cpp_type_get_object(type);
        int64_t exc = 0; void *args[] = { &typeObj };
        int64_t arr = op_il2cpp_runtime_invoke(op_findObjectsOfTypeMethod, 0, args, &exc);

        if (!exc && arr) {
            int32_t count = *(int32_t *)(arr + 0x18);
            for (int32_t i = 0; i < count && i < 32; i++) {
                int64_t player = *((int64_t *)(arr + 0x20 + i * 8));
                if (!player) continue;

                // ── Name: 3-strategy resolution ──────────────────────────
                NSString* pname = nil;

                // A) Property getter
                if (!pname && op_netPlayer_get_playerNameMethod) {
                    int64_t exc2 = 0;
                    int64_t nameObj = op_il2cpp_runtime_invoke(op_netPlayer_get_playerNameMethod, player, nil, &exc2);
                    if (!exc2) pname = READ_IL2CPP_STRING(nameObj);
                }

                // B) Direct field scan (covers auto-property backing fields too)
                if (!pname && op_il2cpp_class_get_field_from_name && op_il2cpp_field_get_value) {
                    int64_t playerClass = op_netPlayerClass;
                    if (op_il2cpp_object_get_class) playerClass = op_il2cpp_object_get_class(player);
                    const char* fieldNames[] = {
                        "playerUsername", "playerName", "userName", "username",
                        "m_playerName", "_playerName", "displayName", "steamName",
                        "<playerUsername>k__BackingField", "<playerName>k__BackingField", nullptr
                    };
                    for (int fi = 0; fieldNames[fi] && !pname; fi++) {
                        int64_t field = op_il2cpp_class_get_field_from_name(playerClass, fieldNames[fi]);
                        if (!field) continue;
                        int64_t strObj = 0;
                        op_il2cpp_field_get_value(player, field, &strObj);
                        if (strObj) pname = READ_IL2CPP_STRING(strObj);
                    }
                }

                // C) Unity Object.get_name fallback
                if (!pname) {
                    static int64_t objNameMethod = 0;
                    if (!objNameMethod && op_objectClass)
                        objNameMethod = op_il2cpp_class_get_method_from_name(op_objectClass, "get_name", 0);
                    if (objNameMethod) {
                        int64_t exc2 = 0;
                        int64_t nameObj = op_il2cpp_runtime_invoke(objNameMethod, player, nil, &exc2);
                        if (!exc2) pname = READ_IL2CPP_STRING(nameObj);
                    }
                }
                if (!pname || pname.length == 0) pname = @"Player";

                // ── Position ─────────────────────────────────────────────
                float px = 0, py = 0, pz = 0;
                if (op_netPlayer_get_transformMethod && op_Transform_get_position_Injected) {
                    int64_t exc3 = 0;
                    int64_t transform = op_il2cpp_runtime_invoke(op_netPlayer_get_transformMethod, player, nil, &exc3);
                    if (!exc3 && transform) {
                        OpVec3 pos = {0,0,0};
                        typedef void (*GetPosFn)(int64_t, OpVec3 *);
                        ((GetPosFn)op_Transform_get_position_Injected)(transform, &pos);
                        px = pos.x; py = pos.y; pz = pos.z;
                    }
                }
                [result addObject:@{ @"name": pname, @"x": @(px), @"y": @(py), @"z": @(pz) }];
            }
            if (result.count > 0) {
                NSLog(@"[op] getPlayerList: %d players", (int)result.count);
                return result;
            }
        }
    }

    #undef READ_IL2CPP_STRING

    // ── Strategy 2: local player only (fallback) ──────────────────────────
    int64_t local = [self op_getLocalPlayer];
    if (local) {
        float px = 0, py = 0, pz = 0;
        if (op_netPlayer_get_transformMethod && op_Transform_get_position_Injected) {
            int64_t exc = 0;
            int64_t transform = op_il2cpp_runtime_invoke(op_netPlayer_get_transformMethod, local, nil, &exc);
            if (!exc && transform) {
                OpVec3 pos = {0,0,0};
                typedef void (*GetPosFn)(int64_t, OpVec3 *);
                ((GetPosFn)op_Transform_get_position_Injected)(transform, &pos);
                px = pos.x; py = pos.y; pz = pos.z;
            }
        }
        NSString* localName = @"(you)";
        if (op_netPlayer_get_playerNameMethod) {
            int64_t exc2 = 0;
            int64_t nameObj = op_il2cpp_runtime_invoke(op_netPlayer_get_playerNameMethod, local, nil, &exc2);
            if (!exc2 && nameObj) {
                int32_t len = *(int32_t *)(nameObj + 0x10);
                if (len > 0 && len < 256)
                    localName = [NSString stringWithCharacters:(unichar *)(nameObj + 0x14) length:(NSUInteger)len];
            }
        }
        [result addObject:@{ @"name": localName, @"x": @(px), @"y": @(py), @"z": @(pz) }];
        NSLog(@"[op] getPlayerList: fallback — local player only");
    }
    return result;
}

@end
