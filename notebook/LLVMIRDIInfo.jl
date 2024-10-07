### A Pluto.jl notebook ###
# v0.19.46

using Markdown
using InteractiveUtils

# ╔═╡ 26290935-0321-4a85-96e8-257d5c2bbd71
using LLVM

# ╔═╡ e571be46-5d3e-478e-8960-dcaa1375c9d9
using Clang

# ╔═╡ 78a0bf62-0657-4487-9bd0-82ac8ea880dd
LLVM.version()

# ╔═╡ d4ef26ec-f047-4717-b75c-f97d86ae9819
import LibGit2

# ╔═╡ 0687ec67-276d-481b-820f-81df24ce29ab
before_change_ir = """; ModuleID = '/home/bowen/Documents/diff-based-analysis/challenges-a/src/file-content-changes/variable-rename/before.c'
source_filename = "/home/bowen/Documents/diff-based-analysis/challenges-a/src/file-content-changes/variable-rename/before.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@.str = private unnamed_addr constant [5 x i8] c"%zu\0A\00", align 1, !dbg !0

; Function Attrs: nofree nounwind sspstrong uwtable
define dso_local noundef i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 !dbg !18 {
  tail call void @llvm.dbg.value(metadata i32 %0, metadata !25, metadata !DIExpression()), !dbg !32
  tail call void @llvm.dbg.value(metadata ptr %1, metadata !26, metadata !DIExpression()), !dbg !32
  tail call void @llvm.dbg.value(metadata i64 1, metadata !27, metadata !DIExpression()), !dbg !33
  %3 = sext i32 %0 to i64
  tail call void @llvm.dbg.value(metadata i64 1, metadata !27, metadata !DIExpression()), !dbg !33
  %4 = icmp ugt i32 %0, 1, !dbg !34
  br i1 %4, label %6, label %5, !dbg !36

5:                                                ; preds = %6, %2
  ret i32 0, !dbg !37

6:                                                ; preds = %2, %6
  %7 = phi i64 [ %9, %6 ], [ 1, %2 ]
  tail call void @llvm.dbg.value(metadata i64 %7, metadata !27, metadata !DIExpression()), !dbg !33
  %8 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i64 noundef %7), !dbg !38
  %9 = add nuw i64 %7, 1, !dbg !40
  tail call void @llvm.dbg.value(metadata i64 %9, metadata !27, metadata !DIExpression()), !dbg !33
  %10 = icmp eq i64 %9, %3, !dbg !34
  br i1 %10, label %5, label %6, !dbg !36, !llvm.loop !41
}

; Function Attrs: nofree nounwind
declare !dbg !44 noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare void @llvm.dbg.value(metadata, metadata, metadata) #2

attributes #0 = { nofree nounwind sspstrong uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nofree nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }

!llvm.dbg.cu = !{!7}
!llvm.module.flags = !{!10, !11, !12, !13, !14, !15, !16}
!llvm.ident = !{!17}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(scope: null, file: !2, line: 6, type: !3, isLocal: true, isDefinition: true)
!2 = !DIFile(filename: "src/file-content-changes/variable-rename/before.c", directory: "/home/bowen/Documents/diff-based-analysis/challenges-a", checksumkind: CSK_MD5, checksum: "d98ec6f7fddf46bda445f93ade755516")
!3 = !DICompositeType(tag: DW_TAG_array_type, baseType: !4, size: 40, elements: !5)
!4 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!5 = !{!6}
!6 = !DISubrange(count: 5)
!7 = distinct !DICompileUnit(language: DW_LANG_C11, file: !8, producer: "clang version 18.1.8", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, globals: !9, splitDebugInlining: false, nameTableKind: None)
!8 = !DIFile(filename: "/home/bowen/Documents/diff-based-analysis/challenges-a/src/file-content-changes/variable-rename/before.c", directory: "/home/bowen/Documents/diff-based-analysis/challenges-a/build", checksumkind: CSK_MD5, checksum: "d98ec6f7fddf46bda445f93ade755516")
!9 = !{!0}
!10 = !{i32 7, !"Dwarf Version", i32 5}
!11 = !{i32 2, !"Debug Info Version", i32 3}
!12 = !{i32 1, !"wchar_size", i32 4}
!13 = !{i32 8, !"PIC Level", i32 2}
!14 = !{i32 7, !"PIE Level", i32 2}
!15 = !{i32 7, !"uwtable", i32 2}
!16 = !{i32 7, !"debug-info-assignment-tracking", i1 true}
!17 = !{!"clang version 18.1.8"}
!18 = distinct !DISubprogram(name: "main", scope: !2, file: !2, line: 4, type: !19, scopeLine: 4, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !24)
!19 = !DISubroutineType(types: !20)
!20 = !{!21, !21, !22}
!21 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!22 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !23, size: 64)
!23 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !4, size: 64)
!24 = !{!25, !26, !27}
!25 = !DILocalVariable(name: "argc", arg: 1, scope: !18, file: !2, line: 4, type: !21)
!26 = !DILocalVariable(name: "argv", arg: 2, scope: !18, file: !2, line: 4, type: !22)
!27 = !DILocalVariable(name: "index", scope: !28, file: !2, line: 5, type: !29)
!28 = distinct !DILexicalBlock(scope: !18, file: !2, line: 5, column: 3)
!29 = !DIDerivedType(tag: DW_TAG_typedef, name: "size_t", file: !30, line: 18, baseType: !31)
!30 = !DIFile(filename: "/usr/lib/clang/18/include/__stddef_size_t.h", directory: "", checksumkind: CSK_MD5, checksum: "2c44e821a2b1951cde2eb0fb2e656867")
!31 = !DIBasicType(name: "unsigned long", size: 64, encoding: DW_ATE_unsigned)
!32 = !DILocation(line: 0, scope: !18)
!33 = !DILocation(line: 0, scope: !28)
!34 = !DILocation(line: 5, column: 31, scope: !35)
!35 = distinct !DILexicalBlock(scope: !28, file: !2, line: 5, column: 3)
!36 = !DILocation(line: 5, column: 3, scope: !28)
!37 = !DILocation(line: 8, column: 3, scope: !18)
!38 = !DILocation(line: 6, column: 5, scope: !39)
!39 = distinct !DILexicalBlock(scope: !35, file: !2, line: 5, column: 50)
!40 = !DILocation(line: 5, column: 44, scope: !35)
!41 = distinct !{!41, !36, !42, !43}
!42 = !DILocation(line: 7, column: 3, scope: !28)
!43 = !{!"llvm.loop.mustprogress"}
!44 = !DISubprogram(name: "printf", scope: !45, file: !45, line: 363, type: !46, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!45 = !DIFile(filename: "/usr/include/stdio.h", directory: "", checksumkind: CSK_MD5, checksum: "bf878b5a7be9bd3141cebb72b92597e8")
!46 = !DISubroutineType(types: !47)
!47 = !{!21, !48, null}
!48 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !49)
!49 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !50, size: 64)
!50 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !4)

"""

# ╔═╡ 48e1a721-5cb6-4151-8f18-b4601815a466
Clang.

# ╔═╡ b0b257d4-010d-41f4-83cd-3e234150f422
@dispose ctx=Context() simple_printf_before = parse(LLVM.Module, before_change_ir) begin
	
end

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Clang = "40e3b903-d033-50b4-a0cc-940c62c95e31"
LLVM = "929cbde3-209d-540e-8aea-75f648917ca0"
LibGit2 = "76f85450-5226-5b5a-8eaa-529ad045b433"

[compat]
Clang = "~0.18.3"
LLVM = "~9.1.2"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.10.5"
manifest_format = "2.0"
project_hash = "abc6c7f91df54c7e3b6fff8a38cca64353f2b6ee"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.CEnum]]
git-tree-sha1 = "389ad5c84de1ae7cf0e28e381131c98ea87d54fc"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.5.0"

[[deps.Clang]]
deps = ["CEnum", "Clang_jll", "Downloads", "Pkg", "TOML"]
git-tree-sha1 = "2397d5da17ba4970f772a9888b208a0a1d77eb5d"
uuid = "40e3b903-d033-50b4-a0cc-940c62c95e31"
version = "0.18.3"

[[deps.Clang_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "TOML", "Zlib_jll", "libLLVM_jll"]
git-tree-sha1 = "de2204d98741f57e7ddb9a6a738db74ba8a608cb"
uuid = "0ee61d77-7f21-5576-8119-9fcc46b10100"
version = "15.0.7+10"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "f389674c99bfcde17dc57454011aa44d5a260a40"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.6.0"

[[deps.LLVM]]
deps = ["CEnum", "LLVMExtra_jll", "Libdl", "Preferences", "Printf", "Requires", "Unicode"]
git-tree-sha1 = "4ad43cb0a4bb5e5b1506e1d1f48646d7e0c80363"
uuid = "929cbde3-209d-540e-8aea-75f648917ca0"
version = "9.1.2"

    [deps.LLVM.extensions]
    BFloat16sExt = "BFloat16s"

    [deps.LLVM.weakdeps]
    BFloat16s = "ab4f0b2a-ad5b-11e8-123f-65d77653426b"

[[deps.LLVMExtra_jll]]
deps = ["Artifacts", "JLLWrappers", "LazyArtifacts", "Libdl", "TOML"]
git-tree-sha1 = "05a8bd5a42309a9ec82f700876903abce1017dd3"
uuid = "dad2f222-ce93-54a1-a47d-0025e8a3acab"
version = "0.0.34+0"

[[deps.LazyArtifacts]]
deps = ["Artifacts", "Pkg"]
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.4.0+0"

[[deps.LibGit2]]
deps = ["Base64", "LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.6.4+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.0+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.2+1"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2023.1.10"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.10.0"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "9306f6085165d270f7e3db02af26a400d580f5c6"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.3"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+1"

[[deps.libLLVM_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8f36deef-c2a5-5394-99ed-8e07531fb29a"
version = "15.0.7+10"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.52.0+1"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+2"
"""

# ╔═╡ Cell order:
# ╠═26290935-0321-4a85-96e8-257d5c2bbd71
# ╠═e571be46-5d3e-478e-8960-dcaa1375c9d9
# ╠═78a0bf62-0657-4487-9bd0-82ac8ea880dd
# ╠═d4ef26ec-f047-4717-b75c-f97d86ae9819
# ╠═0687ec67-276d-481b-820f-81df24ce29ab
# ╠═48e1a721-5cb6-4151-8f18-b4601815a466
# ╠═b0b257d4-010d-41f4-83cd-3e234150f422
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
