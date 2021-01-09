#include "../Headers/dobby.h"
#include <substrate.h>
#include <dlfcn.h>
#include <stdio.h>

#if defined __cplusplus
extern "C" {
#endif

void openCydiaSubstrate();
void closeCydiaSubstrate();
void openDobby();
void closeDobby();

void MSHookFunction(void *symbol, void *hook, void **old);
int DobbyHook(void *symbol, void *hook, void **old);
void *MSFindSymbol(MSImageRef image, const char *name);
int DobbyInstrument(void *instr_address, DBICallTy dbi_call);
void MSHookMessageEx(Class _class, SEL sel, IMP imp, IMP *result);
void dobby_enable_near_branch_trampoline();
void dobby_disable_near_branch_trampoline();
MSImageRef MSGetImageByName(const char *file);

#if defined __cplusplus
};
#endif
