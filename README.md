# MiniC-Compiler

MiniC-Compiler is a project in course Compiling-Practice in peking university.

In MiniC-Compiler,we implement a compiler for MINIC, which is a small language that support the basic function of C language.

the process include three parts:

1.we transform the minic language to eeyore language.(see minic.l , minic.y , minic.h)

2.we transform the eeyore language to tigger languagr.(see eeyore.l , eeyore.y ,global.h)

3.we transform the tigger language to riscv language.(see riscv.l , riscv.y)

finally we run the riscv language in qemu to check it.


