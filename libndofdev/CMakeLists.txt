# -*- cmake -*-

cmake_minimum_required(VERSION 3.18)

project(libndofdev)

find_package(SDL3 CONFIG REQUIRED)

add_compile_definitions(USE_SDL3=1)

set(libndofdev_SOURCE_FILES
    ndofdev.c
    ndofdev_external.h
)

if(${CMAKE_SYSTEM_NAME} MATCHES "Windows")
    message(FATAL_ERROR "Windows configuration not implemented. Use the 3DConnexion library located at http://bitbucket.org/lindenlab/3p-libndofdev  ")
elseif(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    message(FATAL_ERROR "Darwin configuration not implemented. Use the 3DConnexion library located at http://bitbucket.org/lindenlab/3p-libndofdev ")
endif()

add_library (ndofdev STATIC ${libndofdev_SOURCE_FILES})

target_link_libraries(ndofdev
    PUBLIC
    SDL3::SDL3
)

install(TARGETS ndofdev)
install(FILES ndofdev_external.h TYPE INCLUDE)