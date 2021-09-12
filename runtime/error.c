#include <string.h>
#include <stdlib.h>
#include <stdio.h>

#include "balrt.h"
#include "third-party/libbacktrace/backtrace.h"

#define INITIAL_PC_COUNT 1
#define MAX_PC_COUNT 256
#define THREAD 0
#define SUCCESS 0
#define FAIL 1

#define NO_DEBUG_INFO -1
// The reason to pick these negative numbers is that 
// the libstacktrace already has error codes starting from -1
#define NO_ERROR -2
#define EXCEEDS_MAX_PC_COUNT -3
#define OUT_OF_MEMORY -4

struct backtrace_state *state = NULL;

typedef struct {
    int code;
    char *message;
} BacktraceError;

// The lineNumber of the first backtrace entry is passed
// via _bal_panic. This lineNumber should be passed to the
// callback function
typedef struct {
    BacktraceError error;
    int64_t lineNumber;
} BacktraceStartLine;

typedef struct {
    // This must be first so we can use same error callback
    BacktraceError error;
    uint32_t nPCs;
    uint32_t szPCs;
    PC *pcs;
} SimpleBacktrace;

static void storeBacktraceError(void *data, const char *msg, int errnum);
static int printBacktraceLine(void *data, PC pc, const char *filename, int lineno, const char *function);
static void printMissingSymbols(void *data, uintptr_t pc, const char *symname, uintptr_t symval, uintptr_t symsize);
static void printLine(const char *filename, int64_t lineNumber, const char *function);
static int storePC(void *data, PC pc);
static void getSimpleBacktrace(SimpleBacktrace *p);
static char *saveMessage(const char *msg);
static void processPCs(GC PC* pcs, uint32_t nPCs, uint32_t start, int64_t lineNumber, BacktraceError *error);
static void processInitialPC(PC pc, int64_t lineNumber, BacktraceStartLine *backtraceStartLine);

TaggedPtr _bal_error_construct(TaggedPtr message, int64_t lineNumber) {
    SimpleBacktrace simpleBacktrace;
    getSimpleBacktrace(&simpleBacktrace);
    uint32_t nPCs = simpleBacktrace.nPCs;
    size_t errorSize = sizeof(struct Error) + sizeof(PC)*nPCs;
    if (simpleBacktrace.error.message != NULL) {
        // store the error message after the PCs
        errorSize += strlen(simpleBacktrace.error.message) + 1;
    }
    ErrorPtr ep = _bal_alloc(errorSize);
    ep->message = message;
    ep->lineNumber = lineNumber;
    ep->nPCs = nPCs;
    PC *pcs = simpleBacktrace.pcs;
    if (pcs != NULL) {
        memcpy(ep->pcs, pcs, sizeof(PC) * nPCs);
        free(pcs);
    }
    ep->backtraceErrorCode = simpleBacktrace.error.code;
    char *errorMessage = simpleBacktrace.error.message;
    if (errorMessage != NULL) {
        // we allocated extra space for the string above
        char *str = (char *)(ep->pcs + nPCs);
        strcpy(str, errorMessage);
        ep->backtraceErrorMessage = str;
        free(errorMessage);
    }
    else {
        ep->backtraceErrorMessage = NULL;
    }
    return ptrAddFlags(ep, (uint64_t)TAG_ERROR << TAG_SHIFT);
}

// p is uninitialized on entry and will be fully initialized on return
static void getSimpleBacktrace(SimpleBacktrace *p) {
    p->error.message = NULL;
    p->nPCs = 0;
    p->pcs = malloc(sizeof(PC) * INITIAL_PC_COUNT);
    if (p->pcs == NULL) {
        p->szPCs = 0;
        p->error.code = OUT_OF_MEMORY;
        return;
    }
    p->szPCs = INITIAL_PC_COUNT;
    p->error.code = NO_ERROR;
    if (state == NULL) {
        state = backtrace_create_state(NULL, THREAD, storeBacktraceError, p);
        if (state == NULL) {
            return;
        }
    }
    backtrace_simple(state, 0, storePC, storeBacktraceError, p);
}

// Implementation of backtrace_simple_callback
static int storePC(void *data, PC pc) {
    SimpleBacktrace *simpleBacktrace = data;
    uint32_t nPCs = simpleBacktrace->nPCs;
    uint32_t szPCs = simpleBacktrace->szPCs;
    if (nPCs == szPCs) {
        if (szPCs == MAX_PC_COUNT) {
            simpleBacktrace->error.code = EXCEEDS_MAX_PC_COUNT;
            return FAIL;
        }
        szPCs *= 2;
        void *p = realloc(simpleBacktrace->pcs, sizeof(PC) * szPCs);
        if (p == NULL) {
            simpleBacktrace->error.code = OUT_OF_MEMORY;
            return FAIL;
        }
        simpleBacktrace->szPCs = szPCs;
        simpleBacktrace->pcs = p;
    }
    simpleBacktrace->pcs[nPCs] = pc;
    simpleBacktrace->nPCs = nPCs + 1;
    return SUCCESS;
}

void _bal_error_backtrace_print(ErrorPtr ep, uint32_t start) {
    uint32_t nPCs = ep->nPCs;
    BacktraceError err = { ep->backtraceErrorCode, ep->backtraceErrorMessage };
    if (start < nPCs) {
        processPCs(ep->pcs, nPCs, start, ep->lineNumber, &err);
    }

    if (err.code == NO_ERROR) {
        return;
    }
    if (err.code == EXCEEDS_MAX_PC_COUNT) {
        fputs("...\n", stderr);       
    }
    else if (err.code == OUT_OF_MEMORY) {
        fputs("out of memory to store backtrace\n", stderr);
    }
    else {
        fputs("libbacktrace", stderr);
        if (err.message != NULL) {
            fprintf(stderr, ": %s", err.message);
            if (err.message != ep->backtraceErrorMessage) {
                free(err.message);
            }
        }
        if (err.code > 0) {
            fprintf (stderr, ": %s", strerror(err.code));
        }
        fputc('\n', stderr);
    }
    fflush(stderr);
}

static void processPCs(GC PC* pcs, uint32_t nPCs, uint32_t start, int64_t lineNumber, BacktraceError *error) {
    // Handle the starting pc seperately
    BacktraceStartLine backtraceStartLine = { { error->code, error->message }, lineNumber };
    processInitialPC(pcs[start], lineNumber, &backtraceStartLine);
    backtraceStartLine.lineNumber = 0;
    if (backtraceStartLine.error.code == NO_DEBUG_INFO) {
        for (uint32_t i = start + 1; i < nPCs; i++) {
            // We do not need to pass error_callback because, already we have an error.
            backtrace_syminfo(state, pcs[i], printMissingSymbols, NULL, &backtraceStartLine);
        }
    }
    else {
        for (uint32_t i = start + 1; i < nPCs; i++) {
            backtrace_pcinfo(state, pcs[i], printBacktraceLine, storeBacktraceError, &backtraceStartLine);
        }
    }
    error->code = backtraceStartLine.error.code;
    error->message = backtraceStartLine.error.message;
}

static void processInitialPC(PC pc, int64_t lineNumber, BacktraceStartLine *backtraceStartLine) {
    backtrace_pcinfo(state, pc, printBacktraceLine, storeBacktraceError, backtraceStartLine);
    if (backtraceStartLine->error.code == NO_DEBUG_INFO) {
        // We do not need to pass error_callback because, already we have an error
        backtrace_syminfo(state, pc, printMissingSymbols, NULL, backtraceStartLine);
    }
}

// Implementation of backtrace_full_callback
static int printBacktraceLine(void *data, PC pc, const char *filename, int lineno, const char *function) {
    BacktraceStartLine *backtraceStartLine = data;
    if (backtraceStartLine->lineNumber != 0) {
        lineno = backtraceStartLine->lineNumber;
    }
    printLine(filename, lineno, function);
    return SUCCESS;
}

// Implementation of backtrace_syminfo_callback
static void printMissingSymbols(void *data, uintptr_t pc, const char *symname, uintptr_t symval, uintptr_t symsize) {
    BacktraceStartLine *backtraceStartLine = data;
    printLine(NULL, backtraceStartLine->lineNumber, symname);
}

static void printLine(const char *filename, int64_t lineNumber, const char *function) {
    // API docs say any of filename, lineno and function may be 0 meaning unavailable
    const char *sep = "    ";
    if (function != NULL) {
        fprintf(stderr, "%s%s", sep, function);
        sep = " ";
    }
    if (filename != NULL) {
        fprintf(stderr, "%s%s", sep, filename);
        sep = ":";
    }
    if (lineNumber != 0) {
        fprintf(stderr, "%s%" PRId64, sep, lineNumber);
    }
    else if (sep[1] != '\0') {
        fprintf(stderr, "%s(no info about stack frame)", sep);
    }
    putc('\n', stderr);
    fflush(stderr);
}

// Implementation of backtrace_error_callback
static void storeBacktraceError(void *data, const char *msg, int errnum) {
    BacktraceError *err = data;
    // the error that is created first is tracked
    if (err->code != NO_ERROR) {
        return;
    }
    err->code = errnum;
    err->message = saveMessage(msg);
}

static char *saveMessage(const char *msg) {
    char *str = malloc(strlen(msg) + 1);
    if (str == NULL) {
        return NULL;
    }
    strcpy(str, msg);
    return str;
}

TaggedPtr BAL_LANG_ERROR_NAME(message)(TaggedPtr error) {
    ErrorPtr ep = taggedToPtr(error);
    return ep->message;
}
