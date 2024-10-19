project(flex)

set(BUILD_DIR ${CMAKE_CURRENT_BINARY_DIR}/../build)

add_custom_target(clean_build
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${BUILD_DIR}
    COMMENT "Cleaning build directory"
)

set(INCLUDE_TESTS TRUE)
set(RESOURCES_DIR ${CMAKE_CURRENT_SOURCE_DIR}/resources)

if(WIN32)
    set(FLEX_CMD "${RESOURCES_DIR}/win_flex.exe --wincompat")
    target_include_directories(${PROJECT_NAME} PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include_win)
else()
    set(FLEX_CMD "flex")
endif()

if(INCLUDE_TESTS)
    enable_testing()
    add_executable(test ${CMAKE_CURRENT_SOURCE_DIR}/test/test.cpp)

    target_link_libraries(
        test
        GTest::gtest_main
    )

    include(GoogleTest)
    gtest_discover_tests(test)
endif()

add_custom_target(
    generate_flexer
    COMMAND ${CMAKE_COMMAND} -E env ${FLEX_CMD} -+ --outfile="${CMAKE_CURRENT_SOURCE_DIR}/src/haskell.flex.cpp" ${RESOURCES_DIR}/haskell.flex
)

add_subdirectory(src)

add_dependencies(${PROJECT_NAME} generate_flexer)
add_dependencies(${PROJECT_NAME} clean_build)

target_include_directories(${PROJECT_NAME} PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)
