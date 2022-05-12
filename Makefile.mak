# MIT License
#
# Copyright (C) 1964-2022 Mladen Turk
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

CC = cl.exe
LN = link.exe
AR = lib.exe
RC = rc.exe
SRCDIR = .

_CPU = x64
_LIB = lib64

!IF !DEFINED(WINVER) || "$(WINVER)" == ""
WINVER = 0x0601
!ENDIF

!IF DEFINED(_STATIC_MSVCRT)
CRT_CFLAGS = -MT
EXTRA_LIBS =
!ELSE
CRT_CFLAGS = -MD
!ENDIF

LFLAGS = /nologo /INCREMENTAL:NO /MACHINE:$(_CPU)

!IF DEFINED(_DEBUG)
CRT_CFLAGS = $(CRT_CFLAGS)d
CFLAGS = -DDEBUG -D_DEBUG
RFLAGS = /d DEBUG /d _DEBUG
BLDVER = -dbg-
!ELSE
CFLAGS = -DNDEBUG
LFLAGS = $(LFLAGS) /OPT:REF
RFLAGS = /d NDEBUG
BLDVER = -rel-
!ENDIF

CFLAGS_CLI = -I$(SRCDIR)\lib -I$(SRCDIR)\lib\common -I$(SRCDIR)\programs
CFLAGS_LIB = -I$(SRCDIR)\lib -I$(SRCDIR)\lib\common -I$(SRCDIR)\lib\compress
CFLAGS_LIB = $(CFLAGS_LIB) -I$(SRCDIR)\lib\decompress -I$(SRCDIR)\lib\dictBuild -I$(SRCDIR)\lib\legacy
CFLAGS_LIB = $(CFLAGS_LIB) -D_CRT_SECURE_NO_WARNINGS
CFLAGS = $(CFLAGS) -DWIN32 -D_WIN32_WINNT=$(WINVER) -DWINVER=$(WINVER) -D_CONSOLE
CFLAGS = $(CFLAGS) -DZSTD_MULTITHREAD=1 -DZSTD_LEGACY_SUPPORT=5
CFLAGS = $(CFLAGS) $(EXTRA_CFLAGS)

!IF DEFINED(_STATIC)
TARGET  = static
ARFLAGS = /nologo /MACHINE:$(_CPU) $(EXTRA_ARFLAGS)
LIBNAME = libzstd-static
!ELSE
TARGET  = shared
CFLAGS_LIB = $(CFLAGS_LIB) -DZSTD_DLL_EXPORT=1
CFLAGS_CLI = $(CFLAGS_CLI) -DZSTD_DLL_IMPORT=1
LIBNAME = libzstd
!ENDIF

WORKDIR = $(_CPU)$(BLDVER)$(TARGET)
ZSTDCLI = $(WORKDIR)\zstd.exe
ZFUZZER = $(WORKDIR)\fuzzer.exe
ZFBENCH = $(WORKDIR)\fullbench.exe
!IF DEFINED(_STATIC)
ZSTDLIB = $(WORKDIR)\$(LIBNAME).lib
!ELSE
ZSTDLIB = $(WORKDIR)\$(LIBNAME).dll
!ENDIF
ZSTDIMP = $(WORKDIR)\$(LIBNAME).lib

CLOPTS  = /c /nologo $(CRT_CFLAGS) -W4 -O2 -Ob2
RFLAGS  = /l 0x409 /n /i $(SRCDIR)\lib /i $(SRCDIR)\programs\windres $(RFLAGS) /d WIN32 /d WINNT /d WINVER=$(WINVER)
RFLAGS  = $(RFLAGS) /d _WIN32_WINNT=$(WINVER) $(EXTRA_RFLAGS)
LDLIBS  = kernel32.lib $(EXTRA_LIBS)

!IF DEFINED(_PDB)
CFLAGS_CLI = -Zi $(CFLAGS_CLI)
!IF !DEFINED(_STATIC)
CFLAGS_LIB = -Zi $(CFLAGS_LIB)
LIBPDB   = /pdb:$(WORKDIR)\$(LIBNAME).pdb
LIBPDBFD = -Fd$(WORKDIR)\$(LIBNAME)
!ENDIF
CLIPDBFD = -Fd$(WORKDIR)\zstd
CLIPDB   = /pdb:$(WORKDIR)\zstd.pdb
FUZPDB   = /pdb:$(WORKDIR)\fuzzer.pdb
ZFBPDB   = /pdb:$(WORKDIR)\fullbench.pdb
LFLAGS   = $(LFLAGS) /DEBUG
!ENDIF

LIBOBJECTS = \
	$(WORKDIR)\debug.obj \
	$(WORKDIR)\entropy_common.obj \
	$(WORKDIR)\error_private.obj \
	$(WORKDIR)\fse_decompress.obj \
	$(WORKDIR)\pool.obj \
	$(WORKDIR)\threading.obj \
	$(WORKDIR)\xxhash.obj \
	$(WORKDIR)\zstd_common.obj \
	$(WORKDIR)\fse_compress.obj \
	$(WORKDIR)\hist.obj \
	$(WORKDIR)\huf_compress.obj \
	$(WORKDIR)\zstd_compress.obj \
	$(WORKDIR)\zstd_compress_literals.obj \
	$(WORKDIR)\zstd_compress_sequences.obj \
	$(WORKDIR)\zstd_compress_superblock.obj \
	$(WORKDIR)\zstd_double_fast.obj \
	$(WORKDIR)\zstd_fast.obj \
	$(WORKDIR)\zstd_lazy.obj \
	$(WORKDIR)\zstd_ldm.obj \
	$(WORKDIR)\zstdmt_compress.obj \
	$(WORKDIR)\zstd_opt.obj \
	$(WORKDIR)\huf_decompress.obj \
	$(WORKDIR)\zstd_ddict.obj \
	$(WORKDIR)\zstd_decompress_block.obj \
	$(WORKDIR)\zstd_decompress.obj \
	$(WORKDIR)\cover.obj \
	$(WORKDIR)\divsufsort.obj \
	$(WORKDIR)\fastcover.obj \
	$(WORKDIR)\zdict.obj \
	$(WORKDIR)\zstd_v01.obj \
	$(WORKDIR)\zstd_v02.obj \
	$(WORKDIR)\zstd_v03.obj \
	$(WORKDIR)\zstd_v04.obj \
	$(WORKDIR)\zstd_v05.obj \
	$(WORKDIR)\zstd_v06.obj \
	$(WORKDIR)\zstd_v07.obj

!IF "$(TARGET)" == "shared"
LIBOBJECTS = $(LIBOBJECTS) $(WORKDIR)\libzstd-dll.res
!ENDIF

CLIOBJECTS = \
	$(WORKDIR)\benchfn.obj \
	$(WORKDIR)\benchzstd.obj \
	$(WORKDIR)\datagen.obj \
	$(WORKDIR)\dibio.obj \
	$(WORKDIR)\fileio_asyncio.obj \
	$(WORKDIR)\fileio.obj \
	$(WORKDIR)\timefn.obj \
	$(WORKDIR)\util.obj \
	$(WORKDIR)\zstdcli.obj \
	$(WORKDIR)\zstdcli_trace.obj \
	$(WORKDIR)\zstd.res

FUZOBJECTS = \
	$(WORKDIR)\datagen.obj \
	$(WORKDIR)\timefn.obj \
	$(WORKDIR)\util.obj \
	$(WORKDIR)\fuzzer.obj

ZFBOBJECTS = \
	$(WORKDIR)\benchfn.obj \
	$(WORKDIR)\datagen.obj \
	$(WORKDIR)\timefn.obj \
	$(WORKDIR)\util.obj \
	$(WORKDIR)\fullbench.obj

!IF "$(TARGET)" == "static"
all : $(WORKDIR) $(ZSTDLIB) $(ZSTDCLI)
!ELSE
all : $(WORKDIR) $(ZSTDLIB)
!ENDIF

$(WORKDIR):
	@-md $(WORKDIR)

{$(SRCDIR)\lib\common}.c{$(WORKDIR)}.obj:
	$(CC) $(CLOPTS) $(CFLAGS_LIB) $(CFLAGS) -Fo$(WORKDIR)\ $(LIBPDBFD) $<

{$(SRCDIR)\lib\compress}.c{$(WORKDIR)}.obj:
	$(CC) $(CLOPTS) $(CFLAGS_LIB) $(CFLAGS) -Fo$(WORKDIR)\ $(LIBPDBFD) $<

{$(SRCDIR)\lib\decompress}.c{$(WORKDIR)}.obj:
	$(CC) $(CLOPTS) $(CFLAGS_LIB) $(CFLAGS) -Fo$(WORKDIR)\ $(LIBPDBFD) $<

{$(SRCDIR)\lib\dictBuilder}.c{$(WORKDIR)}.obj:
	$(CC) $(CLOPTS) $(CFLAGS_LIB) $(CFLAGS) -Fo$(WORKDIR)\ $(LIBPDBFD) $<

{$(SRCDIR)\lib\legacy}.c{$(WORKDIR)}.obj:
	$(CC) $(CLOPTS) $(CFLAGS_LIB) $(CFLAGS) -Fo$(WORKDIR)\ $(LIBPDBFD) $<

{$(SRCDIR)\programs}.c{$(WORKDIR)}.obj:
	$(CC) $(CLOPTS) $(CFLAGS_CLI) $(CFLAGS) -Fo$(WORKDIR)\ $(CLIPDBFD) $<

{$(SRCDIR)\tests}.c{$(WORKDIR)}.obj:
	$(CC) $(CLOPTS) $(CFLAGS_CLI) $(CFLAGS) -Fo$(WORKDIR)\ $(CLIPDBFD) $<

{$(SRCDIR)\programs\windres}.rc{$(WORKDIR)}.res:
	$(RC) $(RFLAGS) /fo $@ $<

{$(SRCDIR)\build\VS2010\libzstd-dll}.rc{$(WORKDIR)}.res:
	$(RC) $(RFLAGS) /fo $@ $<

$(ZSTDLIB): $(LIBOBJECTS)
!IF "$(TARGET)" == "shared"
	$(LN) $(LFLAGS) /DLL /SUBSYSTEM:WINDOWS $(LIBOBJECTS) $(LDLIBS) $(LIBPDB) /out:$(ZSTDLIB)
!ELSE
	$(AR) $(ARFLAGS) $(LIBOBJECTS) /out:$(ZSTDLIB)
!ENDIF

$(ZSTDCLI): $(ZSTDLIB) $(CLIOBJECTS)
	$(LN) $(LFLAGS) /SUBSYSTEM:CONSOLE $(CLIOBJECTS) $(ZSTDIMP) $(LDLIBS) $(CLIPDB) /out:$(ZSTDCLI)

$(ZFUZZER): $(ZSTDLIB) $(FUZOBJECTS)
	$(LN) $(LFLAGS) /SUBSYSTEM:CONSOLE $(FUZOBJECTS) $(ZSTDIMP) $(LDLIBS) $(FUZPDB) /out:$(ZFUZZER)

$(ZFBENCH): $(ZSTDLIB) $(ZFBOBJECTS)
	$(LN) $(LFLAGS) /SUBSYSTEM:CONSOLE $(ZFBOBJECTS) $(ZSTDIMP) $(LDLIBS) $(ZFBPDB) /out:$(ZFBENCH)

!IF !DEFINED(PREFIX) || "$(PREFIX)" == ""
install:
	@echo PREFIX is not defined
	@echo Use `nmake install PREFIX=directory`
	@echo.
	@exit /B 1
!ELSE
install: all
!IF "$(TARGET)" == "shared"
	@xcopy /I /Y /Q "$(WORKDIR)\*.dll" "$(PREFIX)\bin"
!ELSE
	@xcopy /I /Y /Q "$(WORKDIR)\*.exe" "$(PREFIX)\bin"
!ENDIF
	@xcopy /I /Y /Q "$(WORKDIR)\*.lib" "$(PREFIX)\$(_LIB)"
	@xcopy /I /Y /Q "$(SRCDIR)\lib\*.h*" "$(PREFIX)\include"
!IF DEFINED(_PDB)
	@xcopy /I /Y /Q "$(WORKDIR)\*.pdb" "$(PREFIX)\bin"
!ENDIF
!ENDIF

!IF "$(TARGET)" == "static"
check: all $(ZFUZZER)
	@$(ZFUZZER) -v
	@del /Q $(WORKDIR)\fuzzer.*

!ENDIF
benchmark: $(WORKDIR) $(ZFBENCH)
	@$(ZFBENCH)
	@del /Q $(WORKDIR)\fullbench.*

clean:
	@-rd /S /Q $(WORKDIR) 2>NUL
