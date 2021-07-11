if(POLICY CMP0079)
    cmake_policy(SET CMP0079 NEW)
endif()

if(POLICY CMP0115)
    cmake_policy(SET CMP0115 NEW)
endif()

include_directories(
    ${CMAKE_SOURCE_DIR}/include
    ${CMAKE_SOURCE_DIR}/src)

set(DEVTEST_SRC
    util.c
    main.c
    simple_module.c
    compare_mixer_data.c
)

macro(add_devtest TESTNAME)
    list(APPEND DEVTEST_SRC ${TESTNAME})
endmacro()

set(DEV_GENERATED "${CMAKE_CURRENT_BINARY_DIR}/tests-dev-generated")
file(MAKE_DIRECTORY "${DEV_GENERATED}")
include_directories("${DEV_GENERATED}")


file(STRINGS "all_tests.txt" ALL_DEV_TESTS)
set(ALL_TESTS_C_CONTENT)

foreach(DEVTEST ${ALL_DEV_TESTS})
    add_devtest(${DEVTEST})
    set(ALL_TESTS_C_CONTENT "${ALL_TESTS_C_CONTENT}\ndeclare_test(${DEVTEST});")
endforeach()

file(WRITE "${DEV_GENERATED}/all_tests.c" "${ALL_TESTS_C_CONTENT}")

add_executable(libxmp-tests-dev ${DEVTEST_SRC})
set_property(TARGET libxmp-tests-dev PROPERTY C_STANDARD 99)

if(NOT "${CMAKE_C_COMPILER_ID}" MATCHES "^(Apple)?Clang$")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-unused-variable")
endif()

if(LIBXMP_DISABLE_DEPACKERS)
    target_compile_definitions(libxmp-tests-dev PRIVATE -DLIBXMP_NO_DEPACKERS)
endif()

option(LIBXMP_TEST_DEV_NO_FORK_TEST   "Disable the forked test at development unit tests" OFF)
if(LIBXMP_TEST_DEV_NO_FORK_TEST)
    target_compile_definitions(libxmp-tests-dev PRIVATE -DNO_FORK_TEST)
endif()

target_link_libraries(libxmp-tests-dev XMP_IF)
add_test(NAME libxmp-tests-dev COMMAND libxmp-tests-dev WORKING_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}")
