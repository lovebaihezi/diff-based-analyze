const std = @import("std");

// TODO(chaibowen): current embed IR here, add script to read from the build dir based on the source files
const before =
    \\; ModuleID = '/home/I/projects/diff-based-analyze/challenges-a/file-content-changes/variable-rename/before.c'
    \\source_filename = "/home/I/projects/diff-based-analyze/challenges-a/file-content-changes/variable-rename/before.c"
    \\target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
    \\target triple = "x86_64-pc-linux-gnu"
    \\
    \\@.str = private unnamed_addr constant [5 x i8] c"%zu\0A\00", align 1
    \\
    \\; Function Attrs: noinline nounwind optnone sspstrong uwtable
    \\define dso_local i32 @main(i32 noundef %0, ptr noundef %1) #0 {
    \\  %3 = alloca i32, align 4
    \\  %4 = alloca i32, align 4
    \\  %5 = alloca ptr, align 8
    \\  %6 = alloca i64, align 8
    \\  store i32 0, ptr %3, align 4
    \\  store i32 %0, ptr %4, align 4
    \\  store ptr %1, ptr %5, align 8
    \\  store i64 1, ptr %6, align 8
    \\  br label %7
    \\
    \\7:                                                ; preds = %15, %2
    \\  %8 = load i64, ptr %6, align 8
    \\  %9 = load i32, ptr %4, align 4
    \\  %10 = sext i32 %9 to i64
    \\  %11 = icmp ult i64 %8, %10
    \\  br i1 %11, label %12, label %18
    \\
    \\12:                                               ; preds = %7
    \\  %13 = load i64, ptr %6, align 8
    \\  %14 = call i32 (ptr, ...) @printf(ptr noundef @.str, i64 noundef %13)
    \\  br label %15
    \\
    \\15:                                               ; preds = %12
    \\  %16 = load i64, ptr %6, align 8
    \\  %17 = add i64 %16, 1
    \\  store i64 %17, ptr %6, align 8
    \\  br label %7, !llvm.loop !6
    \\
    \\18:                                               ; preds = %7
    \\  ret i32 0
    \\}
    \\
    \\declare i32 @printf(ptr noundef, ...) #1
    \\
    \\attributes #0 = { noinline nounwind optnone sspstrong uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
    \\attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
    \\
    \\!llvm.module.flags = !{!0, !1, !2, !3, !4}
    \\!llvm.ident = !{!5}
    \\
    \\!0 = !{i32 1, !"wchar_size", i32 4}
    \\!1 = !{i32 8, !"PIC Level", i32 2}
    \\!2 = !{i32 7, !"PIE Level", i32 2}
    \\!3 = !{i32 7, !"uwtable", i32 2}
    \\!4 = !{i32 7, !"frame-pointer", i32 2}
    \\!5 = !{!"clang version 18.1.8"}
    \\!6 = distinct !{!6, !7}
    \\!7 = !{!"llvm.loop.mustprogress"}
;
const after =
    \\; ModuleID = '/home/I/projects/diff-based-analyze/challenges-a/file-content-changes/variable-rename/after.c'
    \\source_filename = "/home/I/projects/diff-based-analyze/challenges-a/file-content-changes/variable-rename/after.c"
    \\target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
    \\target triple = "x86_64-pc-linux-gnu"
    \\
    \\@.str = private unnamed_addr constant [5 x i8] c"%zu\0A\00", align 1
    \\
    \\; Function Attrs: noinline nounwind optnone sspstrong uwtable
    \\define dso_local i32 @main(i32 noundef %0, ptr noundef %1) #0 {
    \\  %3 = alloca i32, align 4
    \\  %4 = alloca i32, align 4
    \\  %5 = alloca ptr, align 8
    \\  %6 = alloca i64, align 8
    \\  store i32 0, ptr %3, align 4
    \\  store i32 %0, ptr %4, align 4
    \\  store ptr %1, ptr %5, align 8
    \\  store i64 1, ptr %6, align 8
    \\  br label %7
    \\
    \\7:                                                ; preds = %15, %2
    \\  %8 = load i64, ptr %6, align 8
    \\  %9 = load i32, ptr %4, align 4
    \\  %10 = sext i32 %9 to i64
    \\  %11 = icmp ult i64 %8, %10
    \\  br i1 %11, label %12, label %18
    \\
    \\12:                                               ; preds = %7
    \\  %13 = load i64, ptr %6, align 8
    \\  %14 = call i32 (ptr, ...) @printf(ptr noundef @.str, i64 noundef %13)
    \\  br label %15
    \\
    \\15:                                               ; preds = %12
    \\  %16 = load i64, ptr %6, align 8
    \\  %17 = add i64 %16, 1
    \\  store i64 %17, ptr %6, align 8
    \\  br label %7, !llvm.loop !6
    \\
    \\18:                                               ; preds = %7
    \\  ret i32 0
    \\}
    \\
    \\declare i32 @printf(ptr noundef, ...) #1
    \\
    \\attributes #0 = { noinline nounwind optnone sspstrong uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
    \\attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
    \\
    \\!llvm.module.flags = !{!0, !1, !2, !3, !4}
    \\!llvm.ident = !{!5}
    \\
    \\!0 = !{i32 1, !"wchar_size", i32 4}
    \\!1 = !{i32 8, !"PIC Level", i32 2}
    \\!2 = !{i32 7, !"PIE Level", i32 2}
    \\!3 = !{i32 7, !"uwtable", i32 2}
    \\!4 = !{i32 7, !"frame-pointer", i32 2}
    \\!5 = !{!"clang version 18.1.8"}
    \\!6 = distinct !{!6, !7}
    \\!7 = !{!"llvm.loop.mustprogress"}
;

test "variable got renamed" {
    try std.testing.expect(false);
}
