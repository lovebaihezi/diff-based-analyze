; ModuleID = 'tests/basic.c'
source_filename = "tests/basic.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Function Attrs: noinline nounwind optnone
define dso_local void @f() #0 {
entry:
  %x = alloca i32, align 4
  %y = alloca i32, align 4
  store i32 1, ptr %x, align 4
  store i32 2, ptr %x, align 4
  %0 = load i32, ptr %x, align 4
  %add = add nsw i32 %0, 3
  store i32 %add, ptr %x, align 4
  store i32 2, ptr %y, align 4
  %1 = load i32, ptr %x, align 4
  store i32 %1, ptr %y, align 4
  ret void
}

attributes #0 = { noinline nounwind optnone "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-features"="+cx8,+mmx,+sse,+sse2,+x87" }

!llvm.module.flags = !{!0}
!llvm.ident = !{!1}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{!"clang version 16.0.6"}
