if(POLICY CMP0079)
    cmake_policy(SET CMP0079 NEW)
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
    message("Adding ${TESTNAME} test...")
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

add_executable(libxmp-tests ${DEVTEST_SRC})

if(LIBXMP_DISABLE_DEPACKERS)
    target_compile_definitions(libxmp-tests PRIVATE -DLIBXMP_NO_DEPACKERS)
endif()

target_link_libraries(libxmp-tests XMP_IF)
add_test(NAME libxmp-tests COMMAND libxmp-tests WORKING_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}")
