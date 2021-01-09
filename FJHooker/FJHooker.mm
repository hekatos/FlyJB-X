#import <UIKit/UIKit.h>
#import "FJHooker.h"
#import "FJHImportHooker.h"
#import "../Headers/FJPattern.h"
#import "../Headers/SysHooks.h"
#import "../Headers/MemHooks.h"
#import "../Headers/PatchFinder.h"
#import "../Headers/ObjCHooks.h"
#import "../Headers/LibraryHooks.h"
#import "../Headers/AeonLucid.h"

@implementation FJHooker
+(void)load {
    NSLog(@"[FJHooker] Hello, FJHooker!");
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/kr.xsf1re.flyjb.plist"];
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    BOOL isSubstitute = ([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/lib/libsubstitute.dylib"] && ![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/lib/substrate"] && ![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/lib/libhooker.dylib"]);
    BOOL isLibHooker = [[NSFileManager defaultManager] fileExistsAtPath:@"/usr/lib/libhooker.dylib"];
    BOOL DobbyHook = [prefs[@"enableDobby"] boolValue];
    
    // ==== START HOOK ====
    if (isSubstitute && access("/var/tmp/.substitute_disable_loader", F_OK) == 0) {
        remove("/var/tmp/.substitute_disable_loader");
    }
    openCydiaSubstrate();
    openDobby();
    
    loadFJMemoryHooks();
    
    //Arxan 메모리 패치
    if([bundleID isEqualToString:@"com.hana.hanamembers"] || [bundleID isEqualToString:@"com.lottecard.mobilepay"])
        loadFJMemoryIntegrityRecover();
    
//    Arxan 심볼 패치
    if([bundleID isEqualToString:@"com.kakaobank.channel"]) {
        NSLog(@"[FlyJB] kakaoBankPatch: %d", kakaoBankPatch());
    }
    
    //AhnLab Mobile Security - NH올원페이, 하나카드, NH스마트뱅킹, NH농협카드, 하나카드 원큐페이(앱카드), NH스마트알림, NH올원뱅크
    NSArray *AMSApps = [NSArray arrayWithObjects:
                        @"com.nonghyup.card.NHAllonePay",
                        @"com.hanaskcard.mobileportal",
                        @"com.nonghyup.newsmartbanking",
                        @"com.nonghyup.nhcard",
                        @"com.hanaskcard.paycli",
                        @"com.nonghyup.nhsmartpush",
                        @"com.nonghyup.allonebank",
                        nil
                        ];
    
    for(NSString* app in AMSApps) {
        if([bundleID isEqualToString:app]) {
            loadAhnLabMemHooks();
            break;
        }
    }
    
    //락인컴퍼니 솔루션 LiApp - 차이, 랜덤다이스, 아시아나항공, 코인원, blind...
    Class LiappExist = objc_getClass("Liapp");
    if(LiappExist)
        loadSysHooks4();
    
    //스틸리언
    Class stealienExist = objc_getClass("StockNewsdmManager");
    Class stealienExist2 = objc_getClass("FactoryConfigurati");
    if((stealienExist || stealienExist2) && ![bundleID isEqualToString:@"com.vivarepublica.cash"])
        loadStealienObjCHooks();
    
    //스틸리언2 - 케이뱅크, 보험파트너, 토스, 사이다뱅크(SBI저축은행), 티머니페이, 티머니 비즈페이, 애큐온저축은행
    NSArray *StealienApps = [NSArray arrayWithObjects:
                             @"com.kbankwith.smartbank",
                             @"im.toss.app.insurp",
                             @"com.vivarepublica.cash",
                             @"com.sbi.saidabank",
                             @"com.tmoney.tmpay",
                             @"com.kscc.t-gift",
                             @"com.kismobile.pay",
                             @"co.kr.acuonsavingsbank.acuonsb",
                             nil
                             ];
    
    for(NSString* app in StealienApps) {
        if([bundleID isEqualToString:app]) {
            loadSysHooks4();
            break;
        }
    }
    
    //배달요기요앱은 한번 탈옥감지하면 설정파일에 colorChecker key에 TRUE 값이 기록됨.
    if([bundleID isEqualToString:@"com.yogiyo.yogiyoapp"])
        loadYogiyoObjcHooks();
    
    //AppSolid - 코레일톡, NICE지키미, 나이스아이핀
    NSArray *AppSolidApps = [NSArray arrayWithObjects:
                             @"com.korail.KorailTalk",
                             @"com.nice.MyCreditManager",
                             @"com.niceid.niceipin",
                             nil
                             ];
    for(NSString* app in AppSolidApps) {
        if([bundleID isEqualToString:app]) {
            loadAppSolidMemHooks();
            break;
        }
    }
    
    //광주은행
    if([bundleID isEqualToString:@"com.kjbank.smart.public.pbanking"])
        loadKJBankMemHooks();
    
    //따로 제작? 불명 - KB손해보험; AppDefense? - 우체국예금 스마트 뱅킹, 바이오인증공동앱, 모바일증권 나무, 디지털OTP(스마트보안카드)
    NSArray *UnkApps = [NSArray arrayWithObjects:
                        @"com.kbinsure.kbinsureapp",
                        @"com.epost.psf.sd",
                        @"org.kftc.fido.lnk.lnkApp",
                        @"com.wooriwm.txsmart",
                        @"kr.or.kftc.fsc.dist",
                        nil
                        ];
    
    for(NSString* app in UnkApps) {
        if([bundleID isEqualToString:app]) {
            if(DobbyHook) {
                loadSVC80MemHooks();
            }
            else {
                //Disabled DobbyHook...
                loadSVC80MemPatch();
            }
            break;
        }
    }
    
    NSArray *NSHCApps = [NSArray arrayWithObjects:
                         @"com.lotte.mybee.lpay",
                         @"com.lottecard.LotteMembers",
                         @"kr.co.nmcs.lpay",
                         @"com.tmoney.tmpay",
                         @"com.kscc.t-gift",
                         nil
                         ];
    Class NSHCExist = objc_getClass("__ns_d");
    
    //블랙리스트: 빗썸
    for(NSString* app in NSHCApps) {
        if([bundleID isEqualToString:app] || (NSHCExist && ![bundleID isEqualToString:@"com.btckorea.bithumb"])) {
            loadSVC80MemPatch();
            break;
        }
    }
    
    //NSHC lxShield - 가디언테일즈
    if([bundleID isEqualToString:@"com.kakaogames.gdtskr"])
        loadlxShieldMemHooks();
    
    //NSHC lxShield v2 - 현대카드, 달빛조각사
    if([bundleID isEqualToString:@"com.hyundaicard.hcappcard"]  || [bundleID isEqualToString:@"com.kakaogames.moonlight"])
        loadlxShieldMemHooks2();
    
    //RaonSecure TouchEn mVaccine - 비플제로페이, 하나은행(+Arxan?), 하나알리미(+Arxan?, 메모리 패치 있음), 미래에셋생명 모바일창구
    NSArray *mVaccineApps = [NSArray arrayWithObjects:
                             @"com.bizplay.zeropay",
                             @"com.hanabank.smart.HanaNBank",
                             @"com.kebhana.hanapush",
                             @"com.miraeasset.mobilewindow",
                             nil
                             ];
    
    for(NSString* app in mVaccineApps) {
        if([bundleID isEqualToString:app]) {
            if(DobbyHook) {
                if(isSubstitute || isLibHooker)
                    loadSVC80MemHooks();
                else
                    loadSVC80AccessMemHooks();
            }
            else {
                //Disabled DobbyHook...
                loadSVC80MemPatch();
            }
            break;
        }
    }
    
    //Arxan - 스마일페이, THE POP, 나만의 냉장고(GS25), GS수퍼마켓, BC카드, 페이코
    NSArray *ArxanApps = [NSArray arrayWithObjects:
                          @"com.mysmilepay.app",
                          @"com.gsretail.ios.thepop",
                          @"com.gsretail.gscvs",
                          @"com.gsretail.supermarket",
                          @"com.bccard.iphoneapp",
                          @"com.nhnent.TOASTPAY",
                          nil
                          ];
    
    for(NSString* app in ArxanApps) {
        if([bundleID isEqualToString:app]) {
            if(DobbyHook) {
                if(isSubstitute || isLibHooker)
                    loadSVC80MemHooks();
                else
                    loadSVC80AccessMemHooks();
            }
            else {
                //Disabled DobbyHook...
                NSLog(@"[FlyJB] Disabled DobbyHook for Arxan Apps... You must manually patch with FJMemory!!!");
            }
            break;
        }
    }
    
    //XignCode - 좀비고
    if([bundleID isEqualToString:@"net.kernys.aooni"])
        loadXignCodeHooks();
    
    //하나카드, NEW하나은행, Arxan 앱은 우회가 좀 까다로운 듯? 하면 안되는 시스템 후킹이 있음
    NSMutableArray *blacklistApps = [NSMutableArray arrayWithObjects:
                                     @"com.hanaskcard.mobileportal",
                                     @"com.kebhana.hanapush",
                                     nil
                                     ];
    
    [blacklistApps addObjectsFromArray: ArxanApps];
    
    BOOL enableSysHook = true;
    for(NSString* app in blacklistApps) {
        if([bundleID isEqualToString:app]) {
            enableSysHook = false;
            break;
        }
    }
    
    
    if(enableSysHook) {
        loadSysHooks2();
        if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0"))
            loadSysHooks3();
    }
    
    
    loadOpendirSysHooks();
    //loadDlsymSysHooks();

    loadObjCHooks();
    loadSysHooks();
    loadLibraryHooks();
    
    // ==== END HOOK ====
    closeCydiaSubstrate();
    closeDobby();
    
}
@end
