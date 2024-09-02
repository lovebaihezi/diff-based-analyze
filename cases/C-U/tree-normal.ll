; ModuleID = 'tests/correct_sync/tree-normal.c'
source_filename = "tests/correct_sync/tree-normal.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

%struct.dirent = type { i64, i64, i16, i8, [256 x i8] }

; Function Attrs: nounwind sspstrong uwtable
define dso_local noundef i32 @root_fn(ptr noundef %0) local_unnamed_addr #0 {
  %2 = tail call ptr @readdir(ptr noundef %0) #4
  %3 = icmp eq ptr %2, null
  br i1 %3, label %22, label %4

4:                                                ; preds = %1, %19
  %5 = phi ptr [ %20, %19 ], [ %2, %1 ]
  %6 = getelementptr inbounds %struct.dirent, ptr %5, i64 0, i32 3
  %7 = load i8, ptr %6, align 2, !tbaa !5
  %8 = icmp eq i8 %7, 4
  %9 = getelementptr inbounds %struct.dirent, ptr %5, i64 0, i32 4
  br i1 %8, label %10, label %17

10:                                               ; preds = %4
  %11 = load i8, ptr %9, align 1, !tbaa !11
  %12 = icmp eq i8 %11, 46
  br i1 %12, label %19, label %13

13:                                               ; preds = %10
  %14 = tail call i32 @puts(ptr nonnull dereferenceable(1) %9)
  %15 = tail call noalias ptr @opendir(ptr noundef nonnull %9)
  %16 = tail call i32 @root_fn(ptr noundef %15)
  br label %19

17:                                               ; preds = %4
  %18 = tail call i32 @puts(ptr nonnull dereferenceable(1) %9)
  br label %19

19:                                               ; preds = %13, %17, %10
  %20 = tail call ptr @readdir(ptr noundef %0) #4
  %21 = icmp eq ptr %20, null
  br i1 %21, label %22, label %4, !llvm.loop !12

22:                                               ; preds = %19, %1
  %23 = icmp eq ptr %0, null
  br i1 %23, label %26, label %24

24:                                               ; preds = %22
  %25 = tail call i32 @closedir(ptr noundef nonnull %0)
  br label %26

26:                                               ; preds = %24, %22
  ret i32 0
}

declare ptr @readdir(ptr noundef) local_unnamed_addr #1

; Function Attrs: nofree nounwind
declare noalias noundef ptr @opendir(ptr nocapture noundef readonly) local_unnamed_addr #2

; Function Attrs: nofree nounwind
declare noundef i32 @closedir(ptr nocapture noundef) local_unnamed_addr #2

; Function Attrs: nounwind sspstrong uwtable
define dso_local noundef i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = icmp slt i32 %0, 2
  br i1 %3, label %9, label %4

4:                                                ; preds = %2
  %5 = getelementptr inbounds ptr, ptr %1, i64 1
  %6 = load ptr, ptr %5, align 8, !tbaa !14
  %7 = tail call noalias ptr @opendir(ptr noundef %6)
  %8 = tail call i32 @root_fn(ptr noundef %7)
  br label %9

9:                                                ; preds = %2, %4
  %10 = phi i32 [ 0, %4 ], [ 1, %2 ]
  ret i32 %10
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr nocapture noundef readonly) local_unnamed_addr #3

attributes #0 = { nounwind sspstrong uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree nounwind }
attributes #4 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{!"clang version 18.1.8"}
!5 = !{!6, !8, i64 18}
!6 = !{!"dirent", !7, i64 0, !7, i64 8, !10, i64 16, !8, i64 18, !8, i64 19}
!7 = !{!"long", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!"short", !8, i64 0}
!11 = !{!8, !8, i64 0}
!12 = distinct !{!12, !13}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!15, !15, i64 0}
!15 = !{!"any pointer", !8, i64 0}
