cmake_minimum_required(VERSION 3.2)
project(libxmplite VERSION 4.5.0 LANGUAGES C)

include(build_pros.cmake)

# -fPIC thing
if(NOT WIN32 AND NOT EMSCRIPTEN AND NOT VITA)
    option(LIBXMP_PIC   "Build the static library as the position-independent" OFF)
else()
    set(LIBXMP_PIC OFF)
endif()
# -----------------------------------

if(EMSCRIPTEN OR VITA)
    set(BUILD_SHARED_DEFAULT OFF)
else()
    set(BUILD_SHARED_DEFAULT ON)
endif()

option(BUILD_STATIC   "Build static library of libXMP" ON)
option(BUILD_SHARED   "Build shared library of libXMP" ${BUILD_SHARED_DEFAULT})
if(NOT BUILD_STATIC AND NOT BUILD_SHARED)
    message(FATAL_ERROR "Both static and shared builds got disabled. You must enable at least one of them.")
endif()

option(LIBXMP_DISABLE_IT            "Disable IT support at libXMP-Lite" OFF)

include(build_src.cmake)


set(LIBXMP_DEFINES)
set(LIBXMP_DEFINES_PUBLIC)

list(APPEND LIBXMP_DEFINES_PUBLIC
    -DLIBXMP_CORE_PLAYER
    -DLIBXMP_NO_PROWIZARD
    -DLIBXMP_NO_DEPACKERS
)

if(LIBXMP_DISABLE_IT)
    list(APPEND LIBXMP_DEFINES_PUBLIC -DLIBXMP_CORE_DISABLE_IT)
endif()

if(MSVC)
    list(APPEND LIBXMP_DEFINES -Dinline=__inline -D_USE_MATH_DEFINES -DPATH_MAX=260)
endif()


list(APPEND LIBXMP_SRC_LITE ${LIBXMP_SRC_LIST_LITE} ${LIBXMP_SRC_COMMON})


set(XMP_INSTALLS)

# ============= LITE =============
if(BUILD_STATIC)
    add_library(xmp_lite_static STATIC ${LIBXMP_SRC_LITE})
    list(APPEND XMP_INSTALLS xmp_lite_static)

    if(WIN32 AND BUILD_SHARED)
        set_target_properties(xmp_lite_static PROPERTIES OUTPUT_NAME xmp-lite-static)
    else()
        set_target_properties(xmp_lite_static PROPERTIES OUTPUT_NAME xmp-lite)
    endif()

    target_compile_definitions(xmp_lite_static PRIVATE ${LIBXMP_DEFINES} -DBUILDING_STATIC)
    target_compile_definitions(xmp_lite_static PUBLIC ${LIBXMP_DEFINES_PUBLIC})

    if(LIBXMP_PIC)
        target_compile_options(xmp_lite_static PRIVATE -fPIC)
    endif()

    target_include_directories(xmp_lite_static PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include/libxmp-lite)
    target_include_directories(xmp_lite_static PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src
        ${CMAKE_CURRENT_SOURCE_DIR}/src/loaders
    )
endif()

if(BUILD_SHARED)
    add_library(xmp_lite_shared SHARED ${LIBXMP_SRC_LITE})
    list(APPEND XMP_INSTALLS xmp_lite_shared)
    set_target_properties(xmp_lite_shared PROPERTIES OUTPUT_NAME xmp-lite)

    if(NOT MSVC)
        target_link_libraries(xmp_lite_shared PUBLIC m)
    endif()

    target_compile_definitions(xmp_lite_shared PRIVATE ${LIBXMP_DEFINES} -DBUILDING_DLL)
    target_compile_definitions(xmp_lite_shared PUBLIC ${LIBXMP_DEFINES_PUBLIC})

    target_include_directories(xmp_lite_shared PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include/libxmp-lite)
    target_include_directories(xmp_lite_shared PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src
        ${CMAKE_CURRENT_SOURCE_DIR}/src/loaders
    )

    set_target_properties(xmp_lite_shared PROPERTIES VERSION ${libxmplite_VERSION} SOVERSION ${libxmplite_VERSION_MAJOR})
endif()


add_library(XMP_IF INTERFACE)

if(NOT BUILD_SHARED)
    target_link_libraries(XMP_IF INTERFACE xmp_lite_static)
else()
    target_link_libraries(XMP_IF INTERFACE xmp_lite_shared)
endif()

# === Unit tests ====
option(WITH_UNIT_TESTS "Enable unit testing" OFF)
if(WITH_UNIT_TESTS)
    enable_testing()
    add_subdirectory(test)
endif()

if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/build_examples.cmake")
    include(build_examples.cmake)
endif()


install(TARGETS ${XMP_INSTALLS}
        RUNTIME DESTINATION "bin"
        LIBRARY DESTINATION "lib"
        ARCHIVE DESTINATION "lib"
        INCLUDES DESTINATION "include")

install(FILES
        include/libxmp-lite/xmp.h
        DESTINATION include/libxmp-lite/)
