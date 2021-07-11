
if(POLICY CMP0079)
    cmake_policy(SET CMP0079 NEW)
endif()

include_directories(
    ${CMAKE_SOURCE_DIR}/include
    ${CMAKE_SOURCE_DIR}/src)

add_executable(libxmp-test test.c)

if(LIBXMP_DISABLE_DEPACKERS)
    target_compile_definitions(libxmp-test PRIVATE -DLIBXMP_NO_DEPACKERS)
endif()

target_link_libraries(libxmp-test XMP_IF)
add_test(NAME libxmp-test COMMAND libxmp-test WORKING_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}")
