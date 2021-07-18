
option(XMP_WITH_DEMO_PLAYER_SDL1      "Build also demo player for XMP (SDL1 needed)" OFF)
if(XMP_WITH_DEMO_PLAYER_SDL1)
    add_executable(xmpsdl
        examples/player-sdl.c
    )
    add_dependencies(xmpsdl XMP_IF)

    find_package(SDL REQUIRED)
    if(TARGET SDL::SDL)
        set(SDL_LIBRARY SDL::SDLmain SDL::SDL)
    endif()

    target_compile_definitions(xmpsdl PRIVATE -DBUILDING_STATIC)
    if(WIN32)
        target_compile_definitions(xmpsdl PRIVATE -DSDL_MAIN_HANDLED)
    endif()
    target_include_directories(xmpsdl PRIVATE ${SDL_INCLUDE_DIR})
    target_link_libraries(xmpsdl XMP_IF ${SDL_LIBRARY})
endif()

option(XMP_WITH_DEMO_PLAYER_SDL2      "Build also demo player for XMP (SDL2 needed)" OFF)
if(XMP_WITH_DEMO_PLAYER)
    add_executable(xmpsdl2
        examples/player-sdl.c
    )
    add_dependencies(xmpsdl2 XMP_IF)

    find_package(SDL2 REQUIRED)
    if(TARGET SDL2::SDL2)
        set(SDL2_LIBRARIES SDL2::SDL2main SDL2::SDL2)
    endif()

    target_compile_definitions(xmpsdl2 PRIVATE -DBUILDING_STATIC)
    if(WIN32)
        target_compile_definitions(xmpsdl2 PRIVATE -DSDL_MAIN_HANDLED)
    endif()
    target_include_directories(xmpsdl2 PRIVATE ${SDL2_INCLUDE_DIRS})
    target_link_libraries(xmpsdl2 XMP_IF ${SDL2_LIBRARIES})
endif()
