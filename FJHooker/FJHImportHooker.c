#include "FJHImportHooker.h"

void *handlerCS = NULL;
void *handlerD = NULL;

void openCydiaSubstrate() {
    handlerCS = dlopen("/Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate", RTLD_NOW);
}

void closeCydiaSubstrate() {
    dlclose(handlerCS);
}

void openDobby() {
    handlerD = dlopen("/usr/lib/FJDobby", RTLD_NOW);
}

void closeDobby() {
    dlclose(handlerD);
}

void MSHookFunction(void *symbol, void *hook, void **old) {
    void (*MSHookFunction)(void *symbol, void *hook, void **old) = NULL;
    MSHookFunction = (void (*)(void *, void *, void **))dlsym(handlerCS, "MSHookFunction");
    MSHookFunction(symbol, hook, old);
}

int DobbyHook(void *symbol, void *hook, void **old) {
    int (*DobbyHook)(void *symbol, void *hook, void **old) = NULL;
    DobbyHook = (int (*)(void *, void *, void **))dlsym(handlerD, "DobbyHook");
    return DobbyHook(symbol, hook, old);
}

void *MSFindSymbol(MSImageRef image, const char *name) {
    void* (*MSFindSymbol)(MSImageRef image, const char *name) = NULL;
    MSFindSymbol = (void* (*)(MSImageRef image, const char *name))dlsym(handlerCS, "MSFindSymbol");
    return MSFindSymbol(image, name);
}

int DobbyInstrument(void *instr_address, DBICallTy dbi_call) {
    int (*DobbyInstrument)(void *instr_address, DBICallTy dbi_call) = NULL;
    DobbyInstrument = (int (*)(void *instr_address, DBICallTy dbi_call))dlsym(handlerD, "DobbyInstrument");
    return DobbyInstrument(instr_address, dbi_call);
}

void MSHookMessageEx(Class _class, SEL sel, IMP imp, IMP *result) {
    void (*MSHookMessageEx)(Class _class, SEL sel, IMP imp, IMP *result) = NULL;
    MSHookMessageEx = (void (*)(Class _class, SEL sel, IMP imp, IMP *result))dlsym(handlerCS, "MSHookMessageEx");
    MSHookMessageEx(_class, sel, imp, result);
}

void dobby_enable_near_branch_trampoline() {
    void (*dobby_enable_near_branch_trampoline)() = NULL;
    dobby_enable_near_branch_trampoline = (void (*)())dlsym(handlerD, "dobby_enable_near_branch_trampoline");
    dobby_enable_near_branch_trampoline();
}

void dobby_disable_near_branch_trampoline() {
    void (*dobby_disable_near_branch_trampoline)() = NULL;
    dobby_disable_near_branch_trampoline = (void (*)())dlsym(handlerD, "dobby_disable_near_branch_trampoline");
    dobby_disable_near_branch_trampoline();
}
