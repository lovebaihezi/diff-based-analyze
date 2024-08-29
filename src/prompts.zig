const THREAD_SYNC_ISSUE_SYSTEM_PROMPT =
    \\You are an Expert in POSIX Thread Model and Linux API, including sync prototype, atomic, CPU cache and memory corruption. You will check the input source code, point the issues including: wrong memory order of atomic variables read and write; dead lock; non-thread safe API uses in thread scope.
;
const THREAD_SYNC_ISSUE_USER_PROMPT =
    \\```C
    \\{}
    \\```
;

const THREAD_SYNC_ISSUE_CAUSED_BY_CHANGES_SYSTEM_PROMPT = THREAD_SYNC_ISSUE_SYSTEM_PROMPT ++
    \\The Input will contains three parts,
    \\the first part contains code of the whole project,
    \\the second part contains code of the current changes,
    \\the third part contains current changes affect codes.
;
