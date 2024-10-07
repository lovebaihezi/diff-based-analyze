; ModuleID = 'tests/correct_sync/tree-multi.c'
source_filename = "tests/correct_sync/tree-multi.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

%struct.Input = type { ptr, i32 }
%struct.dirent = type { i64, i64, i16, i8, [256 x i8] }

; Function Attrs: nounwind sspstrong uwtable
define dso_local noundef nonnull ptr @root_fn_wrap(ptr noundef %0) #0 {
  %2 = load ptr, ptr %0, align 8, !tbaa !5
  %3 = tail call i32 @root_fn(ptr noundef %2)
  %4 = getelementptr inbounds %struct.Input, ptr %0, i64 0, i32 1
  store i32 %3, ptr %4, align 8, !tbaa !11
  store ptr null, ptr %0, align 8, !tbaa !5
  ret ptr %4
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind sspstrong uwtable
define dso_local noundef i32 @root_fn(ptr noundef %0) local_unnamed_addr #0 {
  %2 = alloca [512 x i64], align 16
  %3 = alloca [512 x %struct.Input], align 16
  call void @llvm.lifetime.start.p0(i64 4096, ptr nonnull %2) #6
  call void @llvm.lifetime.start.p0(i64 8192, ptr nonnull %3) #6
  %4 = tail call ptr @readdir(ptr noundef %0) #6
  %5 = icmp eq ptr %4, null
  br i1 %5, label %25, label %6

6:                                                ; preds = %1, %22
  %7 = phi ptr [ %23, %22 ], [ %4, %1 ]
  %8 = getelementptr inbounds %struct.dirent, ptr %7, i64 0, i32 3
  %9 = load i8, ptr %8, align 2, !tbaa !12
  %10 = icmp eq i8 %9, 4
  %11 = getelementptr inbounds %struct.dirent, ptr %7, i64 0, i32 4
  br i1 %10, label %12, label %20

12:                                               ; preds = %6
  %13 = load i8, ptr %11, align 1, !tbaa !16
  %14 = icmp eq i8 %13, 46
  br i1 %14, label %22, label %15

15:                                               ; preds = %12
  %16 = call i32 @puts(ptr nonnull dereferenceable(1) %11)
  %17 = call noalias ptr @opendir(ptr noundef nonnull %11)
  %18 = call i32 @pthread_create(ptr noundef nonnull %2, ptr noundef null, ptr noundef nonnull @root_fn_wrap, ptr noundef nonnull %3) #6
  %19 = icmp eq i32 %18, 0
  br i1 %19, label %22, label %29

20:                                               ; preds = %6
  %21 = call i32 @puts(ptr nonnull dereferenceable(1) %11)
  br label %22

22:                                               ; preds = %20, %15, %12
  %23 = call ptr @readdir(ptr noundef %0) #6
  %24 = icmp eq ptr %23, null
  br i1 %24, label %25, label %6, !llvm.loop !17

25:                                               ; preds = %22, %1
  %26 = icmp eq ptr %0, null
  br i1 %26, label %29, label %27

27:                                               ; preds = %25
  %28 = call i32 @closedir(ptr noundef nonnull %0)
  br label %29

29:                                               ; preds = %15, %25, %27
  %30 = phi i32 [ 0, %27 ], [ 0, %25 ], [ 1, %15 ]
  call void @llvm.lifetime.end.p0(i64 8192, ptr nonnull %3) #6
  call void @llvm.lifetime.end.p0(i64 4096, ptr nonnull %2) #6
  ret i32 %30
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare ptr @readdir(ptr noundef) local_unnamed_addr #2

; Function Attrs: nofree nounwind
declare noalias noundef ptr @opendir(ptr nocapture noundef readonly) local_unnamed_addr #3

; Function Attrs: nounwind
declare i32 @pthread_create(ptr noundef, ptr noundef, ptr noundef, ptr noundef) local_unnamed_addr #4

; Function Attrs: nofree nounwind
declare noundef i32 @closedir(ptr nocapture noundef) local_unnamed_addr #3

; Function Attrs: nounwind sspstrong uwtable
define dso_local noundef i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = icmp slt i32 %0, 2
  br i1 %3, label %9, label %4

4:                                                ; preds = %2
  %5 = getelementptr inbounds ptr, ptr %1, i64 1
  %6 = load ptr, ptr %5, align 8, !tbaa !19
  %7 = tail call noalias ptr @opendir(ptr noundef %6)
  %8 = tail call i32 @root_fn(ptr noundef %7)
  br label %9

9:                                                ; preds = %2, %4
  %10 = phi i32 [ %8, %4 ], [ 1, %2 ]
  ret i32 %10
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr nocapture noundef readonly) local_unnamed_addr #5

attributes #0 = { nounwind sspstrong uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { nofree nounwind }
attributes #6 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{!"clang version 18.1.8"}
!5 = !{!6, !7, i64 0}
!6 = !{!"Input", !7, i64 0, !10, i64 8}
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!"int", !8, i64 0}
!11 = !{!6, !10, i64 8}
!12 = !{!13, !8, i64 18}
!13 = !{!"dirent", !14, i64 0, !14, i64 8, !15, i64 16, !8, i64 18, !8, i64 19}
!14 = !{!"long", !8, i64 0}
!15 = !{!"short", !8, i64 0}
!16 = !{!8, !8, i64 0}
!17 = distinct !{!17, !18}
!18 = !{!"llvm.loop.mustprogress"}
!19 = !{!7, !7, i64 0}
