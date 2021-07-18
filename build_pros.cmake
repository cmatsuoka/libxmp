include(CheckSymbolExists)
include(CheckFunctionExists)
include(CheckIncludeFile)
include(TestBigEndian)


if(POLICY CMP0075) # Include file check macros honor CMAKE_REQUIRED_LIBRARIES, CMake >= 3.12
    cmake_policy(SET CMP0075 NEW)
endif()

if(POLICY CMP0077) # Cache variables override since 3.12
    cmake_policy(SET CMP0077 NEW)
endif()


# If platform is Emscripten
if(${CMAKE_SYSTEM_NAME} STREQUAL "Emscripten")
    set(EMSCRIPTEN 1)
endif()


# Strip garbage
if(APPLE)
    string(REGEX REPLACE "-O3" ""
        CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE}")
    set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -O2")
    set(LINK_FLAGS_RELEASE  "${LINK_FLAGS_RELEASE} -dead_strip")

    # Unify visibility to meet llvm's default.
    include(CheckCCompilerFlag)
    check_c_compiler_flag("-fvisibility-inlines-hidden" SUPPORTS_FVISIBILITY_INLINES_HIDDEN_FLAG)
    if(SUPPORTS_FVISIBILITY_INLINES_HIDDEN_FLAG)
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fvisibility-inlines-hidden")
    endif()
elseif(NOT MSVC)
    if(EMSCRIPTEN)
        set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -Os -fdata-sections -ffunction-sections")
        if("${CMAKE_C_COMPILER_ID}" STREQUAL "Clang")
            set(LINK_FLAGS_RELEASE  "${LINK_FLAGS_RELEASE} -dead_strip")
        else()
            set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -Wl,--gc-sections -Wl,-s")
            set(LINK_FLAGS_RELEASE  "${LINK_FLAGS_RELEASE} -Wl,--gc-sections -Wl,-s")
        endif()
    else()
        string(REGEX REPLACE "-O3" ""
            CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE}")
        set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -O2 -fdata-sections -ffunction-sections")
        if(ANDROID)
            set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -funwind-tables")
        elseif(NOT "${CMAKE_C_COMPILER_ID}" STREQUAL "Clang")
            set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -s -Wl,--gc-sections -Wl,-s")
            set(LINK_FLAGS_RELEASE  "${LINK_FLAGS_RELEASE} -Wl,--gc-sections -Wl,-s")
        else()
            set(LINK_FLAGS_RELEASE  "${LINK_FLAGS_RELEASE} -dead_strip")
        endif()
    endif()
endif()

# Global optimization flags
if(NOT MSVC)
    set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -fno-omit-frame-pointer")
endif()

string(TOLOWER "${CMAKE_BUILD_TYPE}" CMAKE_BUILD_TYPE_LOWER)

set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -DNDEBUG")
set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -DDEBUG -D_DEBUG")

if(MSVC)
    # Force to always compile with W4
    if(CMAKE_C_FLAGS MATCHES "/W[0-4]")
        string(REGEX REPLACE "/W[0-4]" "/W4" CMAKE_C_FLAGS "${CMAKE_C_FLAGS}")
    else()
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /W4")
    endif()
elseif(CMAKE_COMPILER_IS_GNUCC OR CMAKE_COMPILER_IS_GNUCXX)
    # Update if necessary
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall")
endif()

# Disable bogus MSVC warnings
if(MSVC)
    add_definitions(-D_CRT_SECURE_NO_WARNINGS)
endif()

if("${CMAKE_C_COMPILER_ID}" MATCHES "^(Apple)?Clang$")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-shift-negative-value")
endif()

if(MSVC)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /wd4244 /wd4018 /wd4996 /wd4048 /wd4267 /wd4127")
    # set(CMAKE_LINK_LIBRARY_FLAG "${CMAKE_LINK_LIBRARY_FLAG} /wd4273")
elseif(NOT "${CMAKE_C_COMPILER_ID}" MATCHES "^(Apple)?Clang$")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-unused-but-set-variable -Wno-stringop-truncation")
endif()


# ======== Checks ========

TEST_BIG_ENDIAN(WORDS_BIGENDIAN)
if(WORDS_BIGENDIAN)
    add_definitions(-DWORDS_BIGENDIAN=1)
endif()

check_include_file(alloca.h HAVE_ALLOCA_H)
if(HAVE_ALLOCA_H)
    add_definitions(-DHAVE_ALLOCA_H=1)
endif()

check_symbol_exists(powf "math.h" HAVE_POWF_FUNCTION)
if(HAVE_POWF_FUNCTION)
    add_definitions(-DHAVE_POWF=1)
endif()

check_function_exists(popen HAVE_POPEN_F)
check_symbol_exists(popen "stdio.h" HAVE_POPEN)
if(HAVE_POPEN AND HAVE_POPEN_F)
    add_definitions(-DHAVE_POPEN=1)
endif()

check_function_exists(fnmatch HAVE_FNMATCH_F)
check_symbol_exists(fnmatch "fnmatch.h" HAVE_FNMATCH)
if(HAVE_FNMATCH AND HAVE_FNMATCH_F)
    add_definitions(-DHAVE_FNMATCH=1)
endif()

check_function_exists(umask HAVE_UMASK_F)
check_symbol_exists(umask "sys/stat.h" HAVE_UMASK)
if(HAVE_UMASK AND HAVE_UMASK_F)
    add_definitions(-DHAVE_UMASK=1)
endif()

check_function_exists(wait HAVE_WAIT_F)
check_symbol_exists(wait "sys/wait.h" HAVE_WAIT)
if(HAVE_WAIT AND HAVE_WAIT_F)
    add_definitions(-DHAVE_WAIT=1)
endif()

check_function_exists(pipe HAVE_PIPE_F)
check_symbol_exists(pipe "unistd.h" HAVE_PIPE)
if(HAVE_PIPE AND HAVE_PIPE_F)
    add_definitions(-DHAVE_PIPE=1)
endif()

check_function_exists(fork HAVE_FORK_F)
check_symbol_exists(fork "unistd.h" HAVE_FORK)
if(HAVE_FORK AND HAVE_FORK_F)
    add_definitions(-DHAVE_FORK=1)
endif()

check_function_exists(execvp HAVE_EXECVP_F)
check_symbol_exists(execvp "unistd.h" HAVE_EXECVP)
if(HAVE_EXECVP AND HAVE_EXECVP_F)
    add_definitions(-DHAVE_EXECVP=1)
endif()

check_function_exists(dup2 HAVE_DUP2_F)
check_symbol_exists(dup2 "unistd.h" HAVE_DUP2)
if(HAVE_DUP2 AND HAVE_DUP2_F)
    add_definitions(-DHAVE_DUP2=1)
endif()

check_function_exists(mkstemp HAVE_MKSTEMP_F)
check_symbol_exists(mkstemp "stdlib.h" HAVE_MKSTEMP)
if(HAVE_MKSTEMP AND HAVE_MKSTEMP_F)
    add_definitions(-DHAVE_MKSTEMP=1)
endif()

check_symbol_exists(opendir "dirent.h" HAVE_DIRENT)
check_function_exists(opendir HAVE_OPENDIR)
check_function_exists(readdir HAVE_READDIR)
if(HAVE_DIRENT AND HAVE_OPENDIR AND HAVE_READDIR)
    add_definitions(-DHAVE_DIRENT=1)
endif()

if(UNIX AND NOT (WIN32 OR APPLE OR HAIKU OR EMSCRIPTEN OR BEOS))
    find_library(LIBM_LIBRARY m)
    if(LIBM_LIBRARY) # No need to link it by an absolute path
        set(LIBM_REQUIRED 1)
        set(LIBM_LIBRARY m)
        list(APPEND CMAKE_REQUIRED_LIBRARIES m)
    endif()
    mark_as_advanced(LIBM_LIBRARY)
endif()
