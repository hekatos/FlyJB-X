#import <substrate.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "../Headers/FJPattern.h"
#import "../Headers/LibraryHooks.h"
#import "../Headers/ObjCHooks.h"
#import "../Headers/DisableInjector.h"
#import "../Headers/SysHooks.h"
#import "../Headers/NoSafeMode.h"
#import "../Headers/MemHooks.h"
#import "../Headers/OptimizeHooks.h"
#import "../Headers/CheckHooks.h"
#import "../Headers/PatchFinder.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <spawn.h>
extern "C" void BKSTerminateApplicationForReasonAndReportWithDescription(NSString *bundleID, int reasonID, bool report, NSString *description);

@interface SBHomeScreenViewController : UIViewController
@end

@interface LSApplicationProxy
+(LSApplicationProxy *)applicationProxyForIdentifier:(NSString *)bundleId;
-(NSString *)bundleExecutable;
@end

%group NoFile
%hook SpringBoard
-(void)applicationDidFinishLaunching: (id)arg1 {
	%orig;
	UIAlertController *alertController = [UIAlertController
	                                      alertControllerWithTitle:@"공중제비"
	                                      message:@"FJMemory 파일을 불러올 수 없습니다. 트윅을 재설치하십시오."
	                                      preferredStyle:UIAlertControllerStyleAlert
	                                     ];

	[alertController addAction:[UIAlertAction actionWithTitle:@"확인" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
	                                    [((UIApplication*)self).keyWindow.rootViewController dismissViewControllerAnimated:YES completion:NULL];
				    }]];

	[((UIApplication*)self).keyWindow.rootViewController presentViewController:alertController animated:YES completion:NULL];
}
%end
%end

%group ReachItIntegrityFail
%hook SpringBoard
-(void)applicationDidFinishLaunching: (id)arg1 {
	%orig;
	UIAlertController *alertController = [UIAlertController
	                                      alertControllerWithTitle:@"공중제비"
	                                      message:@"현재 설치된 공중제비 트윅은 신뢰되지 않거나 크랙, 또는 불법 소스로부터 설치된 것으로 판단됩니다.\n제거하시고 아래 소스로부터 설치하시기 바랍니다.\nhttps://repo.xsf1re.kr/"
	                                      preferredStyle:UIAlertControllerStyleAlert
	                                     ];

	[alertController addAction:[UIAlertAction actionWithTitle:@"에휴" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
	                                    [((UIApplication*)self).keyWindow.rootViewController dismissViewControllerAnimated:YES completion:NULL];
				    }]];

	[((UIApplication*)self).keyWindow.rootViewController presentViewController:alertController animated:YES completion:NULL];
}
%end
%end

%ctor{

	NSLog(@"[FlyJB] Loaded!!!");

	NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/kr.xsf1re.flyjb.plist"];
	NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
	BOOL isSubstitute = ([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/lib/libsubstitute.dylib"] && ![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/lib/substrate"] && ![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/lib/libhooker.dylib"]);
	BOOL DobbyHook = [prefs[@"enableDobby"] boolValue];

	if([bundleID isEqualToString:@"com.vivarepublica.cash"]) {
		loadNoSafeMode();

		if(![prefs[@"enabled"] boolValue] || ![prefs[@"com.vivarepublica.cash"] boolValue]) {
			exit(0);
		}
	}

	if (![[NSFileManager defaultManager] fileExistsAtPath:@"/var/lib/dpkg/info/kr.xsf1re.flyjbx.list"]) {
		%init(ReachItIntegrityFail);
		return;
	}

	if(![[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/Preferences/FJMemory"]) {
		%init(NoFile);
		return;
	}

	loadDisableInjector();

	NSMutableDictionary *prefs_crashfix = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/kr.xsf1re.flyjb_crashfix.plist"];
	if(prefs_crashfix && [prefs[@"enabled"] boolValue] && [prefs_crashfix[bundleID] boolValue]) {
		loadOptimizeHooks();
	}

	if(![bundleID hasPrefix:@"com.apple"] && prefs && [prefs[@"enabled"] boolValue]) {
		if(([prefs[bundleID] boolValue])
		   || ([bundleID hasPrefix:@"com.ibk.ios.ionebank"] && [prefs[@"com.ibk.ios.ionebank"] boolValue])
		   || ([bundleID hasPrefix:@"com.lguplus.mobile.cs"] && [prefs[@"com.lguplus.mobile.cs"] boolValue]))
		{
			if([bundleID isEqualToString:@"com.kbstar.kbbank"])
				loadNoSafeMode();

			loadFJMemoryHooks();

//Arxan 메모리 패치
			if([bundleID isEqualToString:@"com.hana.hanamembers"] || [bundleID isEqualToString:@"com.lottecard.mobilepay"])
				loadFJMemoryIntegrityRecover();

//Arxan 심볼 패치
			if([bundleID isEqualToString:@"com.kakaobank.channel"]) {
				//loadFJMemorySymbolHooks();
				//kakaoBankPatch();
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

//락인컴퍼니 솔루션 LiApp - 차이, 랜덤다이스, 아시아나항공, 코인원
			NSArray *LiApps = [NSArray arrayWithObjects:
																@"finance.chai.app",
																@"com.percent.royaldice",
																@"com.asiana.asianaapp",
																@"kr.co.coinone.officialapp",
																nil
																];

			for(NSString* app in LiApps) {
				if([bundleID isEqualToString:app]) {
					loadSysHooks4();
					break;
				}
			}

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

//AppSolid - 코레일톡
			if([bundleID isEqualToString:@"com.korail.KorailTalk"])
				loadAppSolidMemHooks();

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

//NSHC ixShield 또는 변종? - 엘페이, 엘포인트, 현대카드, 온통대전, 고향사랑페이, Seezn, KT패밀리박스, 모바일 관세청, KT 콘텐츠박스, KT멤버쉽, 마이케이티, 원네비, KT PASS, KT스팸차단, KT스마트명세서, 기가지니 홈 IoT, 올레 tv play
//NSHC Sanne? - 티머니페이, 티머니페이 비즈페이(업무택시)
/*
			if([bundleID isEqualToString:@"com.lotte.mybee.lpay"] || [bundleID isEqualToString:@"com.lottecard.LotteMembers"]
			   || [bundleID isEqualToString:@"kr.co.nmcs.ontongdaejeon"] || [bundleID isEqualToString:@"kr.co.nmcs.lpay"] || [bundleID isEqualToString:@"kr.co.show.ollehtv"]
			   || [bundleID isEqualToString:@"com.kt.ollehfamilybox"] || [bundleID isEqualToString:@"kr.go.kcs.mobile.pubservice"] || [bundleID isEqualToString:@"com.kt.contentsbox"]
			   || [bundleID isEqualToString:@"kr.co.show.ollehclub2"] || [bundleID isEqualToString:@"kr.co.show.cs.full"] || [bundleID isEqualToString:@"kr.co.show.shownavi"]
			   || [bundleID isEqualToString:@"com.kt.ios.dongbaekpay"] || [bundleID isEqualToString:@"com.kt.ktauth"] || [bundleID isEqualToString:@"kr.co.show.showspamfilter"]
			 	 || [bundleID isEqualToString:@"co.kr.show.ollehsmartspecs"] || [bundleID isEqualToString:@"kr.co.show.cert"] || [bundleID isEqualToString:@"kr.co.show.ollehmywallet"]
			 	 || [bundleID isEqualToString:@"co.kr.olleh.ollehgigageniehomeiphone"] || [bundleID isEqualToString:@"co.kr.show.ollehtvguideiphone"])
*/
			NSArray *NSHCApps = [NSArray arrayWithObjects:
																@"com.lotte.mybee.lpay",
																@"com.lottecard.LotteMembers",
																@"kr.co.nmcs.lpay",
																@"com.tmoney.tmpay",
																@"com.kscc.t-gift",
																nil
																];
			Class NSHCExist = objc_getClass("__ns_d");

			for(NSString* app in NSHCApps) {
				if([bundleID isEqualToString:app] || NSHCExist) {
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

//NSHC lxShield - 가디언테일즈
			if([bundleID isEqualToString:@"com.kakaogames.gdtskr"])
				loadlxShieldMemHooks();

//NSHC lxShield v2 - 현대카드
			if([bundleID isEqualToString:@"com.hyundaicard.hcappcard"])
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
						loadSVC80MemHooks();
					}
					else {
						//Disabled DobbyHook...
						loadSVC80MemPatch();
					}
					break;
				}
			}

//Arxan - 스마일페이, THE POP, 나만의 냉장고(GS25), GS수퍼마켓, BC카드, 삼성카드 마이홈,  페이코
			NSArray *ArxanApps = [NSArray arrayWithObjects:
																@"com.mysmilepay.app",
																@"com.gsretail.ios.thepop",
																@"com.gsretail.gscvs",
																@"com.bccard.iphoneapp",
																@"com.samsungCard.samsungCard",
																@"com.nhnent.TOASTPAY",
																nil
																];

			for(NSString* app in ArxanApps) {
				if([bundleID isEqualToString:app]) {
					if(DobbyHook) {
						loadSVC80MemHooks();
					}
					else {
						//Disabled DobbyHook...
						NSLog(@"[FlyJB] Disabled DobbyHook for Arxan Apps... You must manually patch with FJMemory!!!");
					}
					break;
				}
			}

//하나카드, NEW하나은행은 우회가 좀 까다로운 듯? 하면 안되는 시스템 후킹이 있음
			if(![bundleID isEqualToString:@"com.hanaskcard.mobileportal"] && ![bundleID isEqualToString:@"com.kebhana.hanapush"]) {
				loadSysHooks2();
				if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0"))
					loadSysHooks3();
			}

			if(isSubstitute)
				loadOpendirMemHooks();
			else
				loadOpendirSysHooks();

			loadObjCHooks();
			loadSysHooks();
			loadLibraryHooks();

//토스 탈옥감지 확인
			if([bundleID isEqualToString:@"com.vivarepublica.cash"])
				loadCheckHooks();

		}
	}
}
