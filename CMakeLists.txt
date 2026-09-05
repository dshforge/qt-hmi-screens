cmake_minimum_required(VERSION 3.21)

project(hmi_screens VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Quick Gui QuickControls2)

qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(hmi_screens
    src/main.cpp
    src/vehicle.cpp
    src/vehicle.h
    src/sparklineitem.cpp
    src/sparklineitem.h
    src/framestats.cpp
    src/framestats.h
    src/typography.h
    src/wavetrace.cpp
    src/wavetrace.h
    src/waveforms.h
    src/fleetmodel.h
    src/canmodel.h
)

# The QML lives in Screens/ on disk. Without an alias, qt_add_qml_module
# would derive the module path from that subdirectory and publish the
# files as Screens/Screens/*.qml, which loadFromModule() would then miss.
set(SCREENS_QML
    Main.qml
    ClusterScreen.qml
    FleetScreen.qml
    CanScreen.qml
    Gauge.qml
    Telltale.qml
    Theme.qml
    TimingScreen.qml
    MedicalScreen.qml
    InstrumentScreen.qml
    ScadaScreen.qml
    ClimateScreen.qml
    HeavyScreen.qml
    BarChart.qml
)

set(SCREENS_QML_PATHS "")
foreach(qml_file IN LISTS SCREENS_QML)
    list(APPEND SCREENS_QML_PATHS "Screens/${qml_file}")
    set_source_files_properties("Screens/${qml_file}"
        PROPERTIES QT_RESOURCE_ALIAS "${qml_file}")
endforeach()

# Theme.qml carries `pragma Singleton`; the generated qmldir has to
# declare it as one or `import Screens` will not resolve Theme.
set_source_files_properties(Screens/Theme.qml
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(hmi_screens
    URI Screens
    VERSION 1.0
    QML_FILES ${SCREENS_QML_PATHS}
)

# The generated qmltyperegistrations.cpp includes the headers that
# declare QML_ELEMENT types by their recorded name, so src/ has to be
# on the include path or SparklineItem never resolves.
target_include_directories(hmi_screens PRIVATE src)

target_link_libraries(hmi_screens PRIVATE
    Qt6::Quick
    Qt6::Gui
    Qt6::QuickControls2
)

set_target_properties(hmi_screens PROPERTIES
    WIN32_EXECUTABLE TRUE
    MACOSX_BUNDLE TRUE
)

install(TARGETS hmi_screens
    BUNDLE  DESTINATION .
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
)
