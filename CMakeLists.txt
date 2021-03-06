cmake_minimum_required(VERSION 3.0)
enable_language(Fortran)

project(CommonModules
	VERSION "0.4.1")
enable_testing()

#=======================#
#= One-time Operations =#
#=======================#

find_program(EXECUTABLE_FORD "ford")
find_program(EXECUTABLE_GMSH "gmsh")

file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/media")
file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/test_files")
file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/src-gen")
file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/modules")
set(CMAKE_Fortran_MODULE_DIRECTORY "${CMAKE_BINARY_DIR}/modules")
include_directories("${CMAKE_BINARY_DIR}/modules")

set(ENABLE_PLPLOT TRUE CACHE BOOL "Use PlPlot Library")
set(ENABLE_FFTW3 TRUE CACHE BOOL "Use FFTW Library")
set(ENABLE_NETCDF TRUE CACHE BOOL "Use NetCDF Library")

#=====================#
#= Set Default Flags =#
#=====================#

if(NOT HAVE_RUN)
	set(CMAKE_Fortran_FLAGS ${CMAKE_Fortran_FLAGS}
		CACHE STRING "Fortran flags" FORCE)
	
	set(debug_flags "-Wall -Wno-tabs -Wno-maybe-uninitialized -Wno-unused-dummy-argument -fcheck=all -ffpe-trap=invalid,zero,overflow -fbacktrace -finit-real=snan")
	set(CMAKE_Fortran_FLAGS_DEBUG 
		"${CMAKE_Fortran_FLAGS_DEBUG} ${debug_flags}"
		CACHE STRING "Fortran debugging flags" FORCE)
	
	set(CMAKE_Fortran_FLAGS_RELEASE ${CMAKE_Fortran_FLAGS_RELEASE}
		CACHE STRING "Fortran release flags" FORCE)
endif(NOT HAVE_RUN)

#===============================#
#= Find Packages and Libraries =#
#===============================#

function(finder name lib)
	set(file ${ARGV2})
	
	find_library(finder_LIBRARY "${lib}" "/usr/lib")
	
	if(${file})
		find_path(finder_INCLUDE "${file}" "/usr/include")
	else(${file})
		set(finder_INCLUDE "/usr/include" CACHE PATH "")
	endif(${file})
	include_directories(${finder_INCLUDE})
	
	if(finder_LIBRARY AND finder_INCLUDE)
		set(${name}_FOUND 1 PARENT_SCOPE)
		
		set(${name}_LIBRARY ${finder_LIBRARY} CACHE FILEPATH "Path to ${name} library")
		set(${name}_INCLUDE ${finder_INCLUDE} CACHE PATH "Include path for ${name} library")
	else(finder_LIBRARY AND finder_INCLUDE)
		set(${name}_FOUND 0 PARENT_SCOPE)
		
		set(${name}_LIBRARY "" CACHE FILEPATH "Path to ${name} library")
		set(${name}_INCLUDE "" CACHE PATH "Include path for ${name} library")
	endif(finder_LIBRARY AND finder_INCLUDE)
	
	unset(finder_LIBRARY CACHE)
	unset(finder_INCLUDE CACHE)
endfunction(finder)

include(FindPkgConfig)


if(ENABLE_PLPLOT)
	pkg_search_module(PLPLOT QUIET plplot-fortran)
	include_directories(${PLPLOT_INCLUDE_DIRS})
	link_directories(${PLPLOT_LIBRARY_DIRS})
else(ENABLE_PLPLOT)
	unset(PLPLOT_INCLUDE_DIRS CACHE)
	unset(PLPLOT_LIBRARY_DIRS CACHE)
endif(ENABLE_PLPLOT)

if(ENABLE_NETCDF)
	finder(NETCDF "netcdff" "netcdf.mod")
else(ENABLE_NETCDF)
	unset(NETCDF_LIBRARY CACHE)
	unset(NETCDF_INCLUDE CACHE)
endif(ENABLE_NETCDF)

if(ENABLE_FFTW3)
	finder(FFTW3 "fftw3" "fftw3.f03")
else(ENABLE_FFTW3)
	unset(FFTW3_LIBRARY CACHE)
	unset(FFTW3_INCLUDE CACHE)
endif(ENABLE_FFTW3)

#=========================#
#= Create Symlink Target =#
#=========================#

add_custom_target(symlinks
	COMMAND ${CMAKE_COMMAND} -E create_symlink "${CMAKE_SOURCE_DIR}/input" "${CMAKE_BINARY_DIR}/test_files/input"
	COMMAND ${CMAKE_COMMAND} -E create_symlink "${CMAKE_SOURCE_DIR}/src"   "${CMAKE_BINARY_DIR}/src"
	COMMAND ${CMAKE_COMMAND} -E create_symlink "${CMAKE_SOURCE_DIR}/pages" "${CMAKE_BINARY_DIR}/pages"
	COMMAND ${CMAKE_COMMAND} -E create_symlink "${CMAKE_SOURCE_DIR}/project.md" "${CMAKE_BINARY_DIR}/project.md"
	WORKING_DIRECTORY "${CMAKE_BINARY_DIR}")

#=========================#
#= Create Library Target =#
#=========================#

add_custom_command(OUTPUT "${CMAKE_BINARY_DIR}/src-gen/unitsParameters.f90" 
	COMMAND "${CMAKE_SOURCE_DIR}/src/generate-unitsParameters.py"
	WORKING_DIRECTORY "${CMAKE_BINARY_DIR}/src-gen"
	DEPENDS "${CMAKE_SOURCE_DIR}/src/generate-unitsParameters.py")

# Source Files
set(modules_src
	"src/array.f90"
	"src/constants.f90"
	"src/iterate.f90"
	"src/kinds.f90"
	"src/optimize.f90"
	"src/spline.f90"
	"src/stats.f90"
	"src/time.f90"
	"src/units.f90"
	"${CMAKE_BINARY_DIR}/src-gen/unitsParameters.f90"
	"src/autoDiff/autoDiff.f90"
	"src/autoDiff/autoDiffArray.f90"
	"src/autoDiff/autoDiffExponential.f90"
	"src/autoDiff/autoDiffOperator.f90"
	"src/autoDiff/autoDiffTrigonometric.f90"
	"src/autoDiff/autoDiffType.f90"
	"src/autoDiff/autoDiffZ.f90"
	"src/autoDiff/autoDiffZArray.f90"
	"src/autoDiff/autoDiffZExponential.f90"
	"src/autoDiff/autoDiffZOperator.f90"
	"src/autoDiff/autoDiffZTrigonometric.f90"
	"src/autoDiff/autoDiffZType.f90"
	"src/expression/expression.f90"
	"src/expression/node.f90"
	"src/expression/treeExponential.f90"
	"src/expression/treeOperator.f90"
	"src/expression/treeTrigonometric.f90"
	"src/expression/treeValue.f90"
	"src/IO/config.f90"
	"src/IO/matIO.f90"
	"src/IO/mesh.f90"
	"src/IO/text.f90"
	"src/IO/vtkIO.f90"
	"src/matrix/basicSolvers.f90"
	"src/matrix/quaternion.f90"
	"src/matrix/solvers.f90"
	"src/matrix/sparse.f90"
	"src/matrix/tensor.f90"
	"src/matrix/basicSolversZ.f90"
	"src/matrix/sparseZ.f90")

# Conditional source files
if(ENABLE_FFTW3)
	set(modules_src ${modules_src} "src/fftw3.f90" "src/fourier.f90")
endif(ENABLE_FFTW3)

if(ENABLE_NETCDF)
	set(modules_src ${modules_src} "src/IO/netCDF.f90")
endif(ENABLE_NETCDF)

if(ENABLE_PLPLOT)
	set(modules_src ${modules_src}
		"src/plplotlib/plplotlib.f90"
		"src/plplotlib/plplotlibBase.f90"
		"src/plplotlib/plplotlibFigure.f90"
		"src/plplotlib/plplotlib1D.f90"
		"src/plplotlib/plplotlib2D.f90"
		"src/plplotlib/plplotlib3D.f90")
endif(ENABLE_PLPLOT)

# Add target
add_library(CommonModules SHARED ${modules_src})
export(TARGETS CommonModules FILE CommonModules.cmake)

# Linking directives
if(ENABLE_FFTW3)
	target_link_libraries(CommonModules ${FFTW3_LIBRARY})
endif(ENABLE_FFTW3)

if(ENABLE_NETCDF)
	target_link_libraries(CommonModules ${NETCDF_LIBRARY})
endif(ENABLE_NETCDF)

if(ENABLE_PLPLOT)
	target_link_libraries(CommonModules ${PLPLOT_LIBRARIES})
endif(ENABLE_PLPLOT)


#=======================#
#= Create Test Targets =#
#=======================#

function(addTest name)
	add_executable(${name} "src/test/${name}.f90")
	target_link_libraries(${name} CommonModules)
	set_target_properties(${name} PROPERTIES RUNTIME_OUTPUT_DIRECTORY "tests")
	
	add_test(${name} "${CMAKE_BINARY_DIR}/tests/${name}" )
	set_tests_properties(${name} PROPERTIES WORKING_DIRECTORY "${CMAKE_BINARY_DIR}/test_files")
endfunction(addTest)

addTest("testArray")
addTest("testAutoDiff")
addTest("testConfig")
addTest("testConstants")
addTest("testIterate")
addTest("testKinds")
addTest("testMatIO")
addTest("testQuaternion")
addTest("testStats")
addTest("testTensor")
addTest("testText")
addTest("testTime")
addTest("testUnits")
addTest("testVtkIO")

add_dependencies(testConfig symlinks)

if(ENABLE_FFTW3)
	addTest("testFourier")
	target_link_libraries(testFourier ${FFTW3_LIBRARY})
endif(ENABLE_FFTW3)

if(ENABLE_NETCDF)
	addTest("testNetCDF")
	target_link_libraries(testNetCDF ${NETCDF_LIBRARY})
endif(ENABLE_NETCDF)

if(ENABLE_PLPLOT)
	addTest("testExpression")
	addTest("testOptimize")
	addTest("testSparse")
	addTest("testSpline")
	
	target_link_libraries(testExpression ${PLPLOT_LIBRARIES})
	target_link_libraries(testOptimize   ${PLPLOT_LIBRARIES})
	target_link_libraries(testSparse     ${PLPLOT_LIBRARIES})
	target_link_libraries(testSpline     ${PLPLOT_LIBRARIES})
endif(ENABLE_PLPLOT)

if(EXECUTABLE_GMSH)
	addTest("testMesh")
	add_dependencies(testMesh symlinks)
endif(EXECUTABLE_GMSH)

#============================#
#= Create PlPlotLib Targets =#
#============================#

if(ENABLE_PLPLOT)
	function(addExample name)
		add_executable(${name} "src/plplotlib/${name}.f90")
		target_link_libraries(${name} CommonModules)
		target_link_libraries(${name} ${PLPLOT_LIBRARIES})
		set_target_properties(${name} PROPERTIES RUNTIME_OUTPUT_DIRECTORY "plplotlib")
	endfunction(addExample)
	
	addExample("logo")
	addExample("basic")
	addExample("animate")
	addExample("examples")
endif(ENABLE_PLPLOT)

#======================#
#= Create FORD Target =#
#======================#

add_custom_command(OUTPUT "docs/index.html"
	COMMAND basic
	COMMAND examples
	COMMAND logo
	COMMAND ${EXECUTABLE_FORD} "${CMAKE_BINARY_DIR}/project.md"
	DEPENDS logo basic examples symlinks
	WORKING_DIRECTORY "${CMAKE_BINARY_DIR}")
add_custom_target(doc DEPENDS "docs/index.html")

set(HAVE_RUN TRUE CACHE BOOL "Indicate if first run of CMake" FORCE)

#========================#
#= Create Install Files =#
#========================#

install(TARGETS CommonModules
	EXPORT CommonModules
	LIBRARY DESTINATION "lib")

install(DIRECTORY "${CMAKE_BINARY_DIR}/modules/"
	DESTINATION "include/CommonModules"
	FILES_MATCHING PATTERN "*.mod")

install(DIRECTORY "${CMAKE_BINARY_DIR}/doc/"
	DESTINATION "share/doc/CommonModules"
	OPTIONAL)

install(EXPORT CommonModules
	DESTINATION "lib/CommonModules")
