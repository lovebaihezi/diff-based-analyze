const std = @import("std");
const llvm = @import("llvm_wrap.zig");

// TODO(chaibowen): current embed IR here, add script to read from the build dir based on the source files
const before =
    \\; ModuleID = '/home/I/projects/diff-based-analyze/challenges-a/file-content-changes/variable-rename/before.c'
    \\source_filename = "/home/I/projects/diff-based-analyze/challenges-a/file-content-changes/variable-rename/before.c"
    \\target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
    \\target triple = "x86_64-pc-linux-gnu"
    \\
    \\@.str = private unnamed_addr constant [5 x i8] c"%zu\0A\00", align 1
    \\
    \\; Function Attrs: nofree nounwind sspstrong uwtable
    \\define dso_local noundef i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
    \\  %3 = sext i32 %0 to i64
    \\  %4 = icmp ugt i32 %0, 1
    \\  br i1 %4, label %6, label %5
    \\
    \\5:                                                ; preds = %6, %2
    \\  ret i32 0
    \\
    \\6:                                                ; preds = %2, %6
    \\  %7 = phi i64 [ %9, %6 ], [ 1, %2 ]
    \\  %8 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i64 noundef %7)
    \\  %9 = add nuw i64 %7, 1
    \\  %10 = icmp eq i64 %9, %3
    \\  br i1 %10, label %5, label %6, !llvm.loop !5
    \\}
    \\
    \\; Function Attrs: nofree nounwind
    \\declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #1
    \\
    \\attributes #0 = { nofree nounwind sspstrong uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
    \\attributes #1 = { nofree nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
    \\
    \\!llvm.module.flags = !{!0, !1, !2, !3}
    \\!llvm.ident = !{!4}
    \\
    \\!0 = !{i32 1, !"wchar_size", i32 4}
    \\!1 = !{i32 8, !"PIC Level", i32 2}
    \\!2 = !{i32 7, !"PIE Level", i32 2}
    \\!3 = !{i32 7, !"uwtable", i32 2}
    \\!4 = !{!"clang version 18.1.8"}
    \\!5 = distinct !{!5, !6}
    \\!6 = !{!"llvm.loop.mustprogress"}
;
const after =
    \\; ModuleID = '/home/I/projects/diff-based-analyze/challenges-a/file-content-changes/variable-rename/after.c'
    \\source_filename = "/home/I/projects/diff-based-analyze/challenges-a/file-content-changes/variable-rename/after.c"
    \\target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
    \\target triple = "x86_64-pc-linux-gnu"
    \\
    \\@.str = private unnamed_addr constant [5 x i8] c"%zu\0A\00", align 1
    \\
    \\; Function Attrs: nofree nounwind sspstrong uwtable
    \\define dso_local noundef i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
    \\  %3 = sext i32 %0 to i64
    \\  %4 = icmp ugt i32 %0, 1
    \\  br i1 %4, label %6, label %5
    \\
    \\5:                                                ; preds = %6, %2
    \\  ret i32 0
    \\
    \\6:                                                ; preds = %2, %6
    \\  %7 = phi i64 [ %9, %6 ], [ 1, %2 ]
    \\  %8 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i64 noundef %7)
    \\  %9 = add nuw i64 %7, 1
    \\  %10 = icmp eq i64 %9, %3
    \\  br i1 %10, label %5, label %6, !llvm.loop !5
    \\}
    \\
    \\; Function Attrs: nofree nounwind
    \\declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #1
    \\
    \\attributes #0 = { nofree nounwind sspstrong uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
    \\attributes #1 = { nofree nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
    \\
    \\!llvm.module.flags = !{!0, !1, !2, !3}
    \\!llvm.ident = !{!4}
    \\
    \\!0 = !{i32 1, !"wchar_size", i32 4}
    \\!1 = !{i32 8, !"PIC Level", i32 2}
    \\!2 = !{i32 7, !"PIE Level", i32 2}
    \\!3 = !{i32 7, !"uwtable", i32 2}
    \\!4 = !{!"clang version 18.1.8"}
    \\!5 = distinct !{!5, !6}
    \\!6 = !{!"llvm.loop.mustprogress"}
;

test "variable got renamed" {
    try std.testing.expect(false);
}

variables: std.ArrayList(llvm.Value) = undefined,
ctx: llvm.Context = undefined,

pub fn init(ctx: llvm.Context) @This() {}

pub fn buildInitVariableFromInitFile(mem_buf: llvm.MemoryBuffer) {
    self.mem_buf = mem_buf;
}
