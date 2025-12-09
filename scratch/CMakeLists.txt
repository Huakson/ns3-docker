# Automatically detect and compile all .cc files in the scratch directory
file(GLOB scripts "*.cc")

foreach(script ${scripts})
    # Get the filename without extension (e.g., "my-sim.cc" -> "my-sim")
    get_filename_component(name ${script} NAME_WE)
    
    # Create executable target
    add_executable(${name} ${script})
    
    # Link with all NS-3 libraries
    target_link_libraries(${name} ${ns3-libs})
    
    # Optional: Copy the executable to the main build directory for easier access
    # (NS-3 wrapper script might expect this or a specific naming convention)
endforeach()
