# - Find python libraries
# This module finds if Python is installed and determines where the
# include files and libraries are. It also determines what the name of
# the library is. This code sets the following variables:
#
#  PYTHONLIBS_FOUND           - have the Python libs been found
#  PYTHON_LIBRARIES           - path to the python library
#  PYTHON_INCLUDE_PATH        - path to where Python.h is found (deprecated)
#  PYTHON_INCLUDE_DIRS        - path to where Python.h is found
#  PYTHON_DEBUG_LIBRARIES     - path to the debug library
#  Python_ADDITIONAL_VERSIONS - list of additional Python versions to search for

#=============================================================================
# Copyright 2001-2009 Kitware, Inc.
#
# Distributed under the OSI-approved BSD License (the "License");
# see accompanying file Copyright.txt for details.
#
# This software is distributed WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the License for more information.
#=============================================================================
# (To distribute this file outside of CMake, substitute the full
#  License text for the above reference.)

set( PYTHON_STATIC_BUILD FALSE CACHE BOOL
"Build static instead." )
mark_as_advanced( PYTHON_STATIC_BUILD )

INCLUDE(CMakeFindFrameworks)
# Search for the python framework on Apple.
CMAKE_FIND_FRAMEWORKS(Python)

# Set up the versions we know about, in the order we will search. Always add
# the user supplied additional versions to the front.
set(_Python_VERSIONS
  ${Python_ADDITIONAL_VERSIONS}
  2.7 2.6 2.5 2.4 2.3 2.2 2.1 2.0 1.6 1.5)

FOREACH(_CURRENT_VERSION ${_Python_VERSIONS})
  STRING(REPLACE "." "" _CURRENT_VERSION_NO_DOTS ${_CURRENT_VERSION})
  IF(WIN32)
	#message(STATUS "Find Python1: [HKEY_LOCAL_MACHINE\\SOFTWARE\\Python\\PythonCore\\${_CURRENT_VERSION}\\InstallPath]")
    FIND_LIBRARY(PYTHON_DEBUG_LIBRARY
      NAMES python${_CURRENT_VERSION_NO_DOTS}_d python
      PATHS
      [HKEY_LOCAL_MACHINE\\SOFTWARE\\Python\\PythonCore\\${_CURRENT_VERSION}\\InstallPath]/libs/Debug
      [HKEY_LOCAL_MACHINE\\SOFTWARE\\Python\\PythonCore\\${_CURRENT_VERSION}\\InstallPath]/libs 
	  C:/Python${_CURRENT_VERSION_NO_DOTS}/libs/Debug
	  C:/Python${_CURRENT_VERSION_NO_DOTS}/libs)
	#message(STATUS ${PYTHON_DEBUG_LIBRARY})
  ENDIF(WIN32)

  FIND_LIBRARY(PYTHON_LIBRARY
    NAMES python${_CURRENT_VERSION_NO_DOTS} python${_CURRENT_VERSION}
    PATHS
      [HKEY_LOCAL_MACHINE\\SOFTWARE\\Python\\PythonCore\\${_CURRENT_VERSION}\\InstallPath]/libs
	  C:/Python${_CURRENT_VERSION_NO_DOTS}/libs
	 # C:/Windows/System32
    # Avoid finding the .dll in the PATH.  We want the .lib.
      NO_SYSTEM_ENVIRONMENT_PATH
  )
  # Look for the static library in the Python config directory
  FIND_LIBRARY(PYTHON_LIBRARY
    NAMES python${_CURRENT_VERSION_NO_DOTS} python${_CURRENT_VERSION}
    # Avoid finding the .dll in the PATH.  We want the .lib.
    NO_SYSTEM_ENVIRONMENT_PATH
    # This is where the static library is usually located
    PATH_SUFFIXES python${_CURRENT_VERSION}/config
  )
  #message(STATUS ${PYTHON_LIBRARY})

  # For backward compatibility, honour value of PYTHON_INCLUDE_PATH, if
  # PYTHON_INCLUDE_DIR is not set.
  IF(DEFINED PYTHON_INCLUDE_PATH AND NOT DEFINED PYTHON_INCLUDE_DIR)
    SET(PYTHON_INCLUDE_DIR "${PYTHON_INCLUDE_PATH}" CACHE PATH
      "Path to where Python.h is found" FORCE)
  ENDIF(DEFINED PYTHON_INCLUDE_PATH AND NOT DEFINED PYTHON_INCLUDE_DIR)

  SET(PYTHON_FRAMEWORK_INCLUDES)
  IF(Python_FRAMEWORKS AND NOT PYTHON_INCLUDE_DIR)
    FOREACH(dir ${Python_FRAMEWORKS})
      SET(PYTHON_FRAMEWORK_INCLUDES ${PYTHON_FRAMEWORK_INCLUDES}
        ${dir}/Versions/${_CURRENT_VERSION}/include/python${_CURRENT_VERSION})
    ENDFOREACH(dir)
  ENDIF(Python_FRAMEWORKS AND NOT PYTHON_INCLUDE_DIR)

  FIND_PATH(PYTHON_INCLUDE_DIR
    NAMES Python.h
    PATHS
      ${PYTHON_FRAMEWORK_INCLUDES}
      [HKEY_LOCAL_MACHINE\\SOFTWARE\\Python\\PythonCore\\${_CURRENT_VERSION}\\InstallPath]/include
	  C:/Python${_CURRENT_VERSION_NO_DOTS}/include
    PATH_SUFFIXES
      python${_CURRENT_VERSION}
  )

  # For backward compatibility, set PYTHON_INCLUDE_PATH, but make it internal.
  SET(PYTHON_INCLUDE_PATH "${PYTHON_INCLUDE_DIR}" CACHE INTERNAL
    "Path to where Python.h is found (deprecated)")

ENDFOREACH(_CURRENT_VERSION)

MARK_AS_ADVANCED(
  PYTHON_DEBUG_LIBRARY
  PYTHON_LIBRARY
  PYTHON_INCLUDE_DIR
)

# We use PYTHON_INCLUDE_DIR, PYTHON_LIBRARY and PYTHON_DEBUG_LIBRARY for the
# cache entries because they are meant to specify the location of a single
# library. We now set the variables listed by the documentation for this
# module.
SET(PYTHON_INCLUDE_DIRS "${PYTHON_INCLUDE_DIR}")
SET(PYTHON_LIBRARIES "${PYTHON_LIBRARY}")
SET(PYTHON_DEBUG_LIBRARIES "${PYTHON_DEBUG_LIBRARY}")

# TESTING by jo&jp 
#message(STATUS "${PYTHON_LIBRARIES}")
#message(STATUS "${PYTHON_INCLUDE_DIRS}") 

#GET_FILENAME_COMPONENT(SDK_ROOT_PATH  "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Python\\PythonCore\\${_CURRENT_VERSION}\\InstallPath;(Default)]" ABSOLUTE )
#message(STATUS "${SDK_ROOT_PATH}")
# TESTING

INCLUDE(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(PythonLibs DEFAULT_MSG PYTHON_LIBRARIES PYTHON_INCLUDE_DIRS)


# PYTHON_ADD_MODULE(<name> src1 src2 ... srcN) is used to build modules for python.
# PYTHON_WRITE_MODULES_HEADER(<filename>) writes a header file you can include
# in your sources to initialize the static python modules
FUNCTION(PYTHON_ADD_MODULE _NAME )
  GET_PROPERTY(_TARGET_SUPPORTS_SHARED_LIBS
    GLOBAL PROPERTY TARGET_SUPPORTS_SHARED_LIBS)
  OPTION(PYTHON_ENABLE_MODULE_${_NAME} "Add module ${_NAME}" TRUE)
  
  if( PYTHON_STATIC_BUILD )
    #message( "Static build" )
    OPTION(PYTHON_MODULE_${_NAME}_BUILD_SHARED
      "Add module ${_NAME} shared" FALSE)
  else( PYTHON_STATIC_BUILD )
    #message( "Shared build" )
    OPTION(PYTHON_MODULE_${_NAME}_BUILD_SHARED
      "Add module ${_NAME} shared" ${_TARGET_SUPPORTS_SHARED_LIBS})
  endif( PYTHON_STATIC_BUILD )

  # Mark these options as advanced
  MARK_AS_ADVANCED(PYTHON_ENABLE_MODULE_${_NAME}
    PYTHON_MODULE_${_NAME}_BUILD_SHARED)

  IF(PYTHON_ENABLE_MODULE_${_NAME})
    IF(PYTHON_MODULE_${_NAME}_BUILD_SHARED)
#      message( "Shared build" )
      SET(PY_MODULE_TYPE SHARED)
    ELSE(PYTHON_MODULE_${_NAME}_BUILD_SHARED)
#      message( "Static build" )
      SET(PY_MODULE_TYPE STATIC)
      SET_PROPERTY(GLOBAL  APPEND  PROPERTY  PY_STATIC_MODULES_LIST ${_NAME})
    ENDIF(PYTHON_MODULE_${_NAME}_BUILD_SHARED)

    SET_PROPERTY(GLOBAL  APPEND  PROPERTY  PY_MODULES_LIST ${_NAME})
    ADD_LIBRARY(${_NAME} ${PY_MODULE_TYPE} ${ARGN})
    #if(CMAKE_BUILD_TYPE STREQUAL Debug)
    #  TARGET_LINK_LIBRARIES(${_NAME} ${PYTHON_DEBUG_LIBRARIES})  
    #else()
    TARGET_LINK_LIBRARIES(${_NAME} ${PYTHON_LIBRARIES})
    #endif()

    IF(PYTHON_MODULE_${_NAME}_BUILD_SHARED)
      #message(STATUS "${_NAME} prefix. ${PYTHON_MODULE_PREFIX}")
      SET_TARGET_PROPERTIES(${_NAME} PROPERTIES PREFIX "${PYTHON_MODULE_PREFIX}")
      IF(WIN32 AND NOT CYGWIN)
        SET_TARGET_PROPERTIES(${_NAME} PROPERTIES SUFFIX ".pyd")
      ENDIF(WIN32 AND NOT CYGWIN)
    ENDIF(PYTHON_MODULE_${_NAME}_BUILD_SHARED)

  ENDIF(PYTHON_ENABLE_MODULE_${_NAME})
ENDFUNCTION(PYTHON_ADD_MODULE)

FUNCTION(PYTHON_WRITE_MODULES_HEADER _filename)

  GET_PROPERTY(PY_STATIC_MODULES_LIST  GLOBAL  PROPERTY PY_STATIC_MODULES_LIST)

  GET_FILENAME_COMPONENT(_name "${_filename}" NAME)
  STRING(REPLACE "." "_" _name "${_name}")
  STRING(TOUPPER ${_name} _nameUpper)
  SET(_filename ${CMAKE_CURRENT_BINARY_DIR}/${_filename})

  SET(_filenameTmp "${_filename}.in")
  FILE(WRITE ${_filenameTmp} "/*Created by cmake, do not edit, changes will be lost*/\n")
  FILE(APPEND ${_filenameTmp}
"#ifndef ${_nameUpper}
#define ${_nameUpper}

#include <Python.h>

#ifdef __cplusplus
extern \"C\" {
#endif /* __cplusplus */

")

  FOREACH(_currentModule ${PY_STATIC_MODULES_LIST})
    FILE(APPEND ${_filenameTmp} "extern void init${PYTHON_MODULE_PREFIX}${_currentModule}(void);\n\n")
  ENDFOREACH(_currentModule ${PY_STATIC_MODULES_LIST})

  FILE(APPEND ${_filenameTmp}
"#ifdef __cplusplus
}
#endif /* __cplusplus */

")


  FOREACH(_currentModule ${PY_STATIC_MODULES_LIST})
    FILE(APPEND ${_filenameTmp} "int ${_name}_${_currentModule}(void) \n{\n  static char name[]=\"${PYTHON_MODULE_PREFIX}${_currentModule}\"; return PyImport_AppendInittab(name, init${PYTHON_MODULE_PREFIX}${_currentModule});\n}\n\n")
  ENDFOREACH(_currentModule ${PY_STATIC_MODULES_LIST})

  FILE(APPEND ${_filenameTmp} "void ${_name}_LoadAllPythonModules(void)\n{\n")
  FOREACH(_currentModule ${PY_STATIC_MODULES_LIST})
    FILE(APPEND ${_filenameTmp} "  ${_name}_${_currentModule}();\n")
  ENDFOREACH(_currentModule ${PY_STATIC_MODULES_LIST})
  FILE(APPEND ${_filenameTmp} "}\n\n")
  FILE(APPEND ${_filenameTmp} "#ifndef EXCLUDE_LOAD_ALL_FUNCTION\nvoid CMakeLoadAllPythonModules(void)\n{\n  ${_name}_LoadAllPythonModules();\n}\n#endif\n\n#endif\n")

# with CONFIGURE_FILE() cmake complains that you may not use a file created using FILE(WRITE) as input file for CONFIGURE_FILE()
  EXECUTE_PROCESS(COMMAND ${CMAKE_COMMAND} -E copy_if_different "${_filenameTmp}" "${_filename}" OUTPUT_QUIET ERROR_QUIET)

ENDFUNCTION(PYTHON_WRITE_MODULES_HEADER)
