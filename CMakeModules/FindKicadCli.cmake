# Find kicad-cli
# Finder module for the kicad-cli tool
#
# Variables set:
#  KICAD_CLI           - Path to kicad-cli executable
#  KICAD_CLI_FOUND     - True if kicad-cli was found
#  KICAD_CLI_VERSION   - Version string of kicad-cli (e.g. "9.0.5")
#  KICAD_CLI_VERSION_MAJOR - Major version number (9.0.5 -> 9)
#  KICAD_CLI_VERSION_MINOR - Minor version number (9.0.5 -> 0)
#  KICAD_CLI_VERSION_PATCH - Patch version number (9.0.5 -> 5)

find_program( KICAD_CLI
    NAMES kicad-cli
)

if ( KICAD_CLI )
    message( STATUS "kicad-cli found: ${KICAD_CLI}" )
else()
    message( STATUS "kicad-cli not found" )
endif()


if ( KICAD_CLI )
    # mark found
    set( KICAD_CLI_FOUND TRUE )

    execute_process(
        COMMAND "${KICAD_CLI}" version --format plain
        RESULT_VARIABLE _kicad_cli_version_result
        OUTPUT_VARIABLE _kicad_cli_version_output
        ERROR_VARIABLE _kicad_cli_version_error
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    if ( _kicad_cli_version_output )
        # try to extract semantic version X.Y.Z, then X.Y, else keep raw output
        string( REGEX MATCH "([0-9]+)\\.([0-9]+)\\.([0-9]+)" _version_match "${_kicad_cli_version_output}" )
        if ( NOT _version_match STREQUAL "" )
            set( KICAD_CLI_VERSION "${CMAKE_MATCH_0}" )
            set( KICAD_CLI_VERSION_MAJOR "${CMAKE_MATCH_1}" )
            set( KICAD_CLI_VERSION_MINOR "${CMAKE_MATCH_2}" )
            set( KICAD_CLI_VERSION_PATCH "${CMAKE_MATCH_3}" )
        endif()

        message( STATUS "kicad-cli version: ${KICAD_CLI_VERSION}" )
    else()
        message( STATUS "kicad-cli version: unknown (no output from 'version')" )
        set( KICAD_CLI_VERSION "" )
    endif()
else()
    set( KICAD_CLI_FOUND FALSE )
    set( KICAD_CLI_VERSION "" )
endif()
