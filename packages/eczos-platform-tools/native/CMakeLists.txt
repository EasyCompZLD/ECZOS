cmake_minimum_required(VERSION 3.16)

project(eczos-system-settings VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(ECM 6.13 REQUIRED NO_MODULE)
list(APPEND CMAKE_MODULE_PATH ${ECM_MODULE_PATH})
include(KDEInstallDirs)

find_package(Qt6 6.8 REQUIRED COMPONENTS Widgets Qml QuickWidgets LinguistTools)
find_package(KF6 6.13 REQUIRED COMPONENTS Auth Config CoreAddons KCMUtils)

add_executable(eczos-system-settings main.cpp)
qt_add_translations(eczos-system-settings
    TS_FILES
        ${CMAKE_CURRENT_SOURCE_DIR}/i18n/eczos-system-settings_nl.ts
        ${CMAKE_CURRENT_SOURCE_DIR}/i18n/eczos-system-settings_de.ts
        ${CMAKE_CURRENT_SOURCE_DIR}/i18n/eczos-system-settings_fr.ts
)
target_link_libraries(eczos-system-settings PRIVATE
    Qt6::Widgets
    Qt6::Qml
    Qt6::QuickWidgets
    KF6::AuthCore
    KF6::ConfigCore
    KF6::CoreAddons
    KF6::KCMUtils
)

install(TARGETS eczos-system-settings DESTINATION ${KDE_INSTALL_BINDIR})
install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/ DESTINATION /usr/share/eczos/translations
        FILES_MATCHING PATTERN "eczos-system-settings_*.qm")
