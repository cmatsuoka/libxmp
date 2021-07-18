cmake_minimum_required(VERSION 3.2)
project(libxmp VERSION 4.5.0 LANGUAGES C)

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

option(LIBXMP_DISABLE_DEPACKERS     "Disable archive depackers at libXMP" OFF)
option(LIBXMP_DISABLE_PROWIZARD     "Disable the ProWizard at libXMP" OFF)

include(build_src.cmake)


set(LIBXMP_DEFINES)

if(LIBXMP_DISABLE_DEPACKERS)
    list(APPEND LIBXMP_DEFINES -DLIBXMP_NO_DEPACKERS)
else()
    list(APPEND LIBXMP_SRC_LIST_FULL ${LIBXMP_SRC_LIST_DEPACKERS})
endif()

if(LIBXMP_DISABLE_PROWIZARD)
    list(APPEND LIBXMP_DEFINES -DLIBXMP_NO_PROWIZARD)
else()
    list(APPEND LIBXMP_SRC_LIST_FULL ${LIBXMP_SRC_LIST_PROWIZARD})
endif()

list(APPEND LIBXMP_SRC_FULL ${LIBXMP_SRC_LIST_LITE} ${LIBXMP_SRC_LIST_FULL} ${LIBXMP_SRC_COMMON})

if(MSVC)
    list(APPEND LIBXMP_DEFINES -Dinline=__inline -D_USE_MATH_DEFINES -DPATH_MAX=260)
endif()

set(XMP_INSTALLS)

# ============= FULL =============
if(BUILD_STATIC)
    add_library(xmp_static STATIC ${LIBXMP_SRC_FULL})
    list(APPEND XMP_INSTALLS xmp_static)
    set_target_properties(xmp_static PROPERTIES OUTPUT_NAME xmp C_STANDARD 90)

    if(WIN32 AND BUILD_SHARED)
        set_target_properties(xmp_static PROPERTIES OUTPUT_NAME xmp-static)
    else()
        set_target_properties(xmp_static PROPERTIES OUTPUT_NAME xmp)
    endif()

    target_compile_definitions(xmp_static PRIVATE ${LIBXMP_DEFINES})
    target_compile_definitions(xmp_static PUBLIC -DBUILDING_STATIC)

    if(LIBXMP_PIC)
        target_compile_options(xmp_static PRIVATE -fPIC)
    endif()

    target_include_directories(xmp_static PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)
    target_include_directories(xmp_static PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)

    if(LIBM_REQUIRED)
        target_link_libraries(xmp_static PUBLIC ${LIBM_LIBRARY})
    endif()
endif()

if(BUILD_SHARED)
    add_library(xmp_shared SHARED ${LIBXMP_SRC_FULL})
    list(APPEND XMP_INSTALLS xmp_shared)
    set_target_properties(xmp_shared PROPERTIES OUTPUT_NAME xmp C_STANDARD 90)

    if(NOT MSVC)
        target_link_libraries(xmp_shared PUBLIC m)
    endif()

    target_compile_definitions(xmp_shared PRIVATE ${LIBXMP_DEFINES} -DBUILDING_DLL)

    target_include_directories(xmp_shared PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)
    target_include_directories(xmp_shared PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)

    set_target_properties(xmp_shared PROPERTIES VERSION ${libxmp_VERSION} SOVERSION ${libxmp_VERSION_MAJOR})
endif()


add_library(XMP_IF INTERFACE)

if(NOT BUILD_SHARED)
    target_link_libraries(XMP_IF INTERFACE xmp_static)
else()
    target_link_libraries(XMP_IF INTERFACE xmp_shared)
endif()

# === Unit tests ====
option(WITH_UNIT_TESTS "Enable unit testing" OFF)
if(WITH_UNIT_TESTS)
    enable_testing()
    add_subdirectory(test)
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/test-dev/")
        add_subdirectory(test-dev)
    endif()
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
        include/xmp.h
        DESTINATION include/)
