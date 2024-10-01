project(flex)

set(RESOURCES_DIR ${CMAKE_CURRENT_SOURCE_DIR}/resources)

add_custom_target(
    generate_flexer
    COMMAND ${CMAKE_COMMAND} -E env ${RESOURCES_DIR}/win_flex.exe -+ --wincompat --outfile="${CMAKE_CURRENT_SOURCE_DIR}/src/haskell.flex.cpp" ${RESOURCES_DIR}/haskell.flex 
)

add_subdirectory(src)

add_dependencies(${PROJECT_NAME} generate_flexer)

target_include_directories(${PROJECT_NAME} PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)
