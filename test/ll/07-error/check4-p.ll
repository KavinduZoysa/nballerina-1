@_bal_stack_guard = external global i8*
declare i8 addrspace(1)* @_bal_panic_construct(i64) cold
declare void @_bal_panic(i8 addrspace(1)*) noreturn cold
declare i8 addrspace(1)* @_bal_mapping_construct(i64, i64)
declare void @_bal_mapping_init_member(i8 addrspace(1)*, i8 addrspace(1)*, i8 addrspace(1)*)
declare i8 addrspace(1)* @_bal_int_to_tagged(i64)
declare i8 addrspace(1)* @_bal_mapping_get(i8 addrspace(1)*, i8 addrspace(1)*) readonly
declare i64 @_bal_tagged_to_int(i8 addrspace(1)*) readonly
declare {i64, i1} @llvm.ssub.with.overflow.i64(i64, i64) nounwind readnone speculatable willreturn
declare void @_Bio__println(i8 addrspace(1)*)
declare i8 addrspace(1)* @_bal_error_construct(i8 addrspace(1)*, i64)
define void @_B_main() {
  %1 = alloca i8 addrspace(1)*
  %m = alloca i8 addrspace(1)*
  %2 = alloca i8 addrspace(1)*
  %3 = alloca i8 addrspace(1)*
  %4 = alloca i1
  %5 = alloca i8 addrspace(1)*
  %6 = alloca i64
  %7 = alloca i64
  %8 = alloca i8 addrspace(1)*
  %9 = alloca i8 addrspace(1)*
  %10 = alloca i8
  %11 = load i8*, i8** @_bal_stack_guard
  %12 = icmp ult i8* %10, %11
  br i1 %12, label %38, label %13
13:
  %14 = call i8 addrspace(1)* @_bal_mapping_construct(i64 128, i64 1)
  %15 = call i8 addrspace(1)* @_bal_int_to_tagged(i64 1)
  call void @_bal_mapping_init_member(i8 addrspace(1)* %14, i8 addrspace(1)* getelementptr(i8, i8 addrspace(1)* null, i64 3098476543630901112), i8 addrspace(1)* %15)
  store i8 addrspace(1)* %14, i8 addrspace(1)** %1
  %16 = load i8 addrspace(1)*, i8 addrspace(1)** %1
  store i8 addrspace(1)* %16, i8 addrspace(1)** %m
  %17 = load i8 addrspace(1)*, i8 addrspace(1)** %m
  %18 = call i8 addrspace(1)* @_bal_mapping_get(i8 addrspace(1)* %17, i8 addrspace(1)* getelementptr(i8, i8 addrspace(1)* null, i64 3098476543630901113))
  store i8 addrspace(1)* %18, i8 addrspace(1)** %2
  %19 = load i8 addrspace(1)*, i8 addrspace(1)** %2
  %20 = call i8 addrspace(1)* @_B_nonNil(i8 addrspace(1)* %19)
  store i8 addrspace(1)* %20, i8 addrspace(1)** %3
  %21 = load i8 addrspace(1)*, i8 addrspace(1)** %3
  %22 = addrspacecast i8 addrspace(1)* %21 to i8*
  %23 = ptrtoint i8* %22 to i64
  %24 = and i64 %23, 2233785415175766016
  %25 = icmp eq i64 %24, 792633534417207296
  store i1 %25, i1* %4
  %26 = load i1, i1* %4
  br i1 %26, label %33, label %27
27:
  %28 = load i8 addrspace(1)*, i8 addrspace(1)** %3
  %29 = call i64 @_bal_tagged_to_int(i8 addrspace(1)* %28)
  store i64 %29, i64* %6
  %30 = load i64, i64* %6
  %31 = call {i64, i1} @llvm.ssub.with.overflow.i64(i64 0, i64 %30)
  %32 = extractvalue {i64, i1} %31, 1
  br i1 %32, label %44, label %40
33:
  %34 = load i8 addrspace(1)*, i8 addrspace(1)** %3
  store i8 addrspace(1)* %34, i8 addrspace(1)** %5
  %35 = load i8 addrspace(1)*, i8 addrspace(1)** %5
  store i8 addrspace(1)* %35, i8 addrspace(1)** %9
  br label %36
36:
  %37 = load i8 addrspace(1)*, i8 addrspace(1)** %9
  call void @_bal_panic(i8 addrspace(1)* %37)
  unreachable
38:
  %39 = call i8 addrspace(1)* @_bal_panic_construct(i64 772)
  call void @_bal_panic(i8 addrspace(1)* %39)
  unreachable
40:
  %41 = extractvalue {i64, i1} %31, 0
  store i64 %41, i64* %7
  %42 = load i64, i64* %7
  %43 = call i8 addrspace(1)* @_bal_int_to_tagged(i64 %42)
  call void @_Bio__println(i8 addrspace(1)* %43)
  store i8 addrspace(1)* null, i8 addrspace(1)** %8
  ret void
44:
  %45 = call i8 addrspace(1)* @_bal_panic_construct(i64 1281)
  store i8 addrspace(1)* %45, i8 addrspace(1)** %9
  br label %36
}
define internal i8 addrspace(1)* @_B_nonNil(i8 addrspace(1)* %0) {
  %n = alloca i8 addrspace(1)*
  %2 = alloca i1
  %n.1 = alloca i8 addrspace(1)*
  %3 = alloca i8 addrspace(1)*
  %n.2 = alloca i64
  %4 = alloca i8
  %5 = load i8*, i8** @_bal_stack_guard
  %6 = icmp ult i8* %4, %5
  br i1 %6, label %20, label %7
7:
  store i8 addrspace(1)* %0, i8 addrspace(1)** %n
  %8 = load i8 addrspace(1)*, i8 addrspace(1)** %n
  %9 = icmp eq i8 addrspace(1)* %8, null
  store i1 %9, i1* %2
  %10 = load i1, i1* %2
  br i1 %10, label %11, label %15
11:
  %12 = load i8 addrspace(1)*, i8 addrspace(1)** %n
  store i8 addrspace(1)* %12, i8 addrspace(1)** %n.1
  %13 = call i8 addrspace(1)* @_bal_error_construct(i8 addrspace(1)* getelementptr(i8, i8 addrspace(1)* null, i64 3098476543621228910), i64 10)
  store i8 addrspace(1)* %13, i8 addrspace(1)** %3
  %14 = load i8 addrspace(1)*, i8 addrspace(1)** %3
  ret i8 addrspace(1)* %14
15:
  %16 = load i8 addrspace(1)*, i8 addrspace(1)** %n
  %17 = call i64 @_bal_tagged_to_int(i8 addrspace(1)* %16)
  store i64 %17, i64* %n.2
  %18 = load i64, i64* %n.2
  %19 = call i8 addrspace(1)* @_bal_int_to_tagged(i64 %18)
  ret i8 addrspace(1)* %19
20:
  %21 = call i8 addrspace(1)* @_bal_panic_construct(i64 2052)
  call void @_bal_panic(i8 addrspace(1)* %21)
  unreachable
}
