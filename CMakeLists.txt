cmake_minimum_required( VERSION 3.10 FATAL_ERROR )

project( kicad-symbols NONE )

set(CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/CMakeModules")

find_package(KicadCli)

#================================================
# Locations for install targets.
#================================================
if( APPLE )
    # Like all variables, CMAKE_INSTALL_PREFIX can be over-ridden on the command line.
    set( CMAKE_INSTALL_PREFIX "/Library/Application Support/kicad/" CACHE PATH "" )

    # Everything without leading / is relative to CMAKE_INSTALL_PREFIX.
    set( KICAD_LIBRARY symbols )
    set( KICAD_TEMPLATE template )
else()
    # Everything without leading / is relative to CMAKE_INSTALL_PREFIX.
    set( KICAD_DATA share/kicad
         CACHE PATH "Location of KiCad data files." )
    set( KICAD_LIBRARY ${KICAD_DATA}/symbols )
    set( KICAD_TEMPLATE ${KICAD_DATA}/template )
endif()

mark_as_advanced( KICAD_DATA KICAD_LIBRARY )


option(KICAD_PACK_SYM_LIBRARIES "Pack symbol libraries before installation" ON)


#================================================
# "make uninstall" rules
#================================================
configure_file(
    "${PROJECT_SOURCE_DIR}/CMakeModules/cmake_uninstall.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
    IMMEDIATE @ONLY
)

add_custom_target( uninstall
    "${CMAKE_COMMAND}" -P "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
)


#================================================
# Functions to pack symbol libraries.
#================================================

# Pack a single library
#
# Arguments:
#   input_lib  - Input library file to pack
#   output_lib - Packed library file to write
function( pack_library input_lib output_lib )
    add_custom_command(
        OUTPUT ${output_lib}
        COMMAND ${KICAD_CLI} sym upgrade --force --output ${output_lib} ${input_lib}
        DEPENDS ${input_lib}
        COMMENT "Packing symbol library ${input_lib} to ${output_lib}"
        VERBATIM
    )
endfunction()


# Pack all libraries in a list
#
# Arguments:
#   input_libs       - List of input library files to pack
#   output_dir       - Directory to place packed library files
#   packed_lib_files - Output variable to receive list of packed library files
#
function( pack_all_libraries input_libs output_dir packed_lib_files )

    set( local_packed_lib_files "" )

    foreach( lib_file ${input_libs} )
        get_filename_component( lib_filename ${lib_file} NAME_WE )
        set( packed_lib_file "${output_dir}/${lib_filename}.kicad_sym" )

        pack_library( ${lib_file} ${packed_lib_file} )
        list( APPEND local_packed_lib_files ${packed_lib_file} )
    endforeach()

    set( ${packed_lib_files} ${local_packed_lib_files} PARENT_SCOPE )
endfunction()

#================================================
# Library pre-flighting - e.g. packing
#================================================

# Install all of the symbol library (.kicad_sym) and simulation model (.sp)
# files in this folder.
file( GLOB sym_lib_files "*.kicad_symdir" )
file( GLOB sym_sim_files "*.sp" )

if( KICAD_PACK_SYM_LIBRARIES )
    message( STATUS "Packing libraries before installation")

    set( packed_lib_dir "${CMAKE_CURRENT_BINARY_DIR}/packed" )

    if( NOT KICAD_CLI )
        message( FATAL_ERROR "kicad-cli not found. Cannot pack symbol libraries." )
    endif()
    message( STATUS "Using kicad-cli: ${KICAD_CLI}" )

    # Pack all symbol libraries before installation.
    set( packed_sym_lib_files "" )
    pack_all_libraries( "${sym_lib_files}" "${packed_lib_dir}" packed_sym_lib_files )

    # The pack target depends on all packed libraries.
    add_custom_target( pack_symbols
        ALL # make pack_symbols part of the default build
        DEPENDS ${packed_sym_lib_files}
    )

    # Create the output dir as a dependency of the pack target.
    add_custom_target(
        make_packed_dir
        COMMAND ${CMAKE_COMMAND} -E make_directory ${packed_lib_dir}
    )

    add_dependencies(pack_symbols make_packed_dir)

    set( installed_sym_lib_files ${packed_sym_lib_files} )
else()
    message( STATUS "Not packing libraries before installation" )
    set( installed_sym_lib_files ${sym_lib_files} )
endif()

#================================================
# Installed files.
#================================================

install(
    FILES
        ${installed_sym_lib_files}
        ${sym_sim_files}
    DESTINATION ${KICAD_LIBRARY}
    COMPONENT resources
)

# Install the default global symbol library table in the template folder.
install(
    FILES sym-lib-table
    DESTINATION ${KICAD_TEMPLATE}
    COMPONENT resources
)
