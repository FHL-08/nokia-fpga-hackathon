###############################################################################
#               Siemens Digital Industries Software
#
#               THIS SOFTWARE AND RELATED DOCUMENTATION
#              ARE PROPRIETARY AND CONFIDENTIAL TO SIEMENS.
#                         © 2025 Siemens
###############################################################################
catch {close_project}

set xilinx_project "/home/kimagdy/Desktop/playground/dvt_nokia_hackathon/hackathon_exercise/vivado_project/FIR_FILTER_Project/FIR_FILTER_Project.xpr"
set project_dir "/home/kimagdy/Desktop/playground/dvt_nokia_hackathon/hackathon_exercise"
set project_name "fir_filter_project"
set lib_map_path ""

set VENDOR_NAME "xilinx"
set VENDOR_LIB_NAME "vivado"
set VIVADO_SUBDIR "vivado"
set EXPORTED_USER_RTL_FILE "Sources_User_Rtl.txt"
set EXPORTED_IP_FILE "Sources_IP_list.txt"

proc get_output_directory_path {project_dir project_name vivado_project_name} {
    global VIVADO_SUBDIR

    # Create the output directory path
    set output_dir_path [file join $project_dir $project_name $VIVADO_SUBDIR $vivado_project_name]
    set output_dir_path [file normalize $output_dir_path]

    # Check if the directory exists
    if {![file exists $output_dir_path]} {
        file mkdir $output_dir_path
    }

    return $output_dir_path
}

# Opens a file for writing
proc open_output_file {filepath} {
    return [open $filepath w]
}

# Closes a file
proc close_output_file {file_id} {
    close $file_id
}

# Function to print a separator line
proc print_separator {output_file} {
    puts $output_file "###############################################"
}


proc get_do_file_path {step output_dir_path ip_dir} {
    switch -exact $step {
        "compile"   { return [file join $output_dir_path $ip_dir "questa" "compile.do"] }
        "elaborate" { return [file join $output_dir_path $ip_dir "questa" "elaborate.do"] }
        "simulate"  { return [file join $output_dir_path $ip_dir "questa" "simulate.do"] }
        default     { error "Invalid type: $type. Expected: compile, elaborate, or simulate." }
    }
}

# Extract all include Dir
proc extract_include_dirs {fileset} {
    set include_dirs {}

    # Get INCLUDE_DIRS property from the fileset
    set fileset_dirs [get_property INCLUDE_DIRS [get_filesets $fileset]]

    if {[llength $fileset_dirs] > 0} {
        foreach dir $fileset_dirs {
            set norm_dir [file normalize $dir]
            if {[lsearch -exact $include_dirs $norm_dir] == -1} {
                lappend include_dirs $norm_dir
            }
        }
    }

    # Get Verilog Header files in the given fileset
    set verilog_headers [get_files -of_objects [get_filesets $fileset] -filter {FILE_TYPE == "Verilog Header"}]

    if {[llength $verilog_headers] > 0} {
        foreach vh_file $verilog_headers {
            set vh_dir [file normalize [file dirname $vh_file]]
            if {[lsearch -exact $include_dirs $vh_dir] == -1} {
                lappend include_dirs $vh_dir
            }
        }
    }

    return $include_dirs
}

# Extracts global include files from the fileset
proc extract_global_include {fileset} {
    set global_include_files {}

    # Get all files marked as global include in the fileset
    set global_include_list \
        [get_files -of_objects [get_filesets $fileset] -filter {IS_GLOBAL_INCLUDE == 1}]

    foreach global_file $global_include_list {
        set global_file_path [file normalize $global_file]
        lappend global_include_files $global_file_path
    }

    return $global_include_files
}

# Extracts and writes user_rtl sources
proc extract_user_rtl_sources {output_file} {
    set fileset_list [get_filesets -filter {FILESET_TYPE == "DesignSrcs"}]
    puts "Filesets: $fileset_list"

    foreach fileset $fileset_list {
        set include_dirs        [extract_include_dirs $fileset]
        set global_include      [extract_global_include $fileset]
        set verilog_defines     [get_property VERILOG_DEFINE [get_filesets $fileset]]
        set lib_map_file        [get_property LIB_MAP_FILE   [get_filesets $fileset]]

        set all_files [get_files -of_objects [get_filesets $fileset]]
        foreach src_file $all_files {
            # Skip unwanted file types
            if {[regexp {(PARENT_COMPOSITE_FILE|CAN_IP_GENERATE)} \
                [list_property -quiet [lindex [get_files -all [list $src_file]] 0]] tmp match] || \
                [get_property FILE_TYPE [lindex [get_files -all [list $src_file]] 0]] in {"Block Designs" "Data Files" "Verilog Header"}} {
                    continue
            }

            set file_path    [file normalize $src_file]
            set file_type    [get_property FILE_TYPE [get_files $src_file]]
            set library_name [get_property LIBRARY [get_files $src_file]]

            puts $output_file "-lib $library_name"
            puts $output_file "-location $file_path"
            puts $output_file "-type $file_type"
            puts $output_file "-include_dirs $include_dirs"
            puts $output_file "-verilog_defines $verilog_defines"
            puts $output_file "-global_include $global_include"
            puts $output_file "-lib_map_file $lib_map_file"
            puts $output_file "-fileset $fileset"
            print_separator $output_file
        }
    }
}


# Separates IP cores from composite IPs
proc separate_ips {ip_list} {
    set ip_cores [list]
    set ip_composite [list]

    foreach ip $ip_list {
        set parent_composite_file [get_property -quiet PARENT_COMPOSITE_FILE \
            [get_files -all -quiet [get_property -quiet IP_FILE [get_ips $ip]]]]

        if {$parent_composite_file == ""} {
            lappend ip_cores $ip
        } else {
            lappend ip_composite $ip
        }
    }

    return [list $ip_cores $ip_composite]
}

# Extracts only top-level (non-generated and non-nested) block designs
proc get_top_level_bds {} {
    set top_level_bds [list]
    foreach bd_file [get_files -all -quiet *.bd] {
        set is_generated [get_property -quiet IS_GENERATED $bd_file]

        if {![string equal $is_generated "1"]} {
            lappend top_level_bds $bd_file
        }
    }
    return $top_level_bds
}

# Processes Block Design (BD) files
proc process_bd_files {output_file ip_composite} {
    global output_dir_path
    global xilinx_project
    global lib_map_path

    global VENDOR_NAME
    global VENDOR_LIB_NAME

    # Use only top-level block designs
    set ip_parent_composite_files [get_top_level_bds]

    if {[llength $ip_parent_composite_files] > 0} {
        export_simulation -simulator questa -of_objects $ip_parent_composite_files \
            -lib_map_path $lib_map_path \
            -directory $output_dir_path -absolute_path -force
    }

    foreach ip_parent_composite $ip_parent_composite_files {
        set ip_parent_composite_name [file tail $ip_parent_composite]
        set ip_parent_composite_root [file rootname $ip_parent_composite_name]

        set compile_do_path   [get_do_file_path "compile" $output_dir_path $ip_parent_composite_root]
        set elaborate_do_path [get_do_file_path "elaborate" $output_dir_path $ip_parent_composite_root]
        set simulate_do_path  [get_do_file_path "simulate" $output_dir_path $ip_parent_composite_root]

        set sim_files [get_files -all -of_objects [get_files -quiet -all $ip_parent_composite] \
            -compile_order sources -used_in simulation]

        # Retrieve the last file in the simulation file list, which represents the top-level simulation file.
        set top_level_sim [expr {[llength $sim_files] > 0 ? [lindex $sim_files end] : ""}]

        set syn_files [get_files -all -of_objects [get_files -quiet -all $ip_parent_composite] \
            -compile_order sources -used_in synthesis -filter {FILE_TYPE == "VHDL" || FILE_TYPE == "Verilog" || FILE_TYPE == "SystemVerilog"}]
        set xdc_files [get_files -all -of_objects [get_files -quiet -all $ip_parent_composite] -filter {FILE_TYPE == "XDC"}]
        set dcp_files [get_files -all -of_objects [get_files -quiet -all $ip_parent_composite] -filter {FILE_TYPE == "Design Checkpoint"}]

        # Get the IP composite files that are children of the current parent IP composite file
        set ip_composite_fileList [list]
        for {set i 0} {$i < [llength $ip_composite]} {incr i} {
            set ip_composite_file [lindex $ip_composite $i]

            # Get the parent composite file for this IP composite
            set parent_composite_file [get_property -quiet PARENT_COMPOSITE_FILE [get_files -all -quiet [get_property -quiet IP_FILE [get_ips $ip_composite_file]]]]

            # Check if the parent composite file matches the given parent BD
            if {$parent_composite_file == $ip_parent_composite} {
                set sim_files [get_files -all -of_objects [get_ips $ip_composite_file] -compile_order sources -used_in simulation]
                set ip_composite_top_level_sim [expr {[llength $sim_files] > 0 ? [lindex $sim_files end] : ""}]

                lappend ip_composite_fileList $ip_composite_top_level_sim
            }
        }

        puts $output_file "-ip_name $ip_parent_composite_name"
        puts $output_file "-vendor $VENDOR_NAME"
        puts $output_file "-vendor_lib_name $VENDOR_LIB_NAME"
        puts $output_file "-vendor_project_path $xilinx_project"
        puts $output_file "-top_level_sim $top_level_sim"
        puts $output_file "-compile_do_path $compile_do_path"
        puts $output_file "-elaborate_do_path $elaborate_do_path"
        puts $output_file "-simulate_do_path $simulate_do_path"
        puts $output_file "-xdc_files $xdc_files"
        puts $output_file "-syn_files $syn_files"
        puts $output_file "-dcp_files $dcp_files"
        puts $output_file "-ip_composite_files $ip_composite_fileList"

        print_separator $output_file
    }
}

# Processes IP cores
proc process_ip_cores {output_file ip_cores} {
    global output_dir_path
    global xilinx_project
    global lib_map_path

    global VENDOR_NAME
    global VENDOR_LIB_NAME

    foreach ip $ip_cores {
        set ip_file [get_property -quiet IP_FILE [get_ips $ip]]
        if {$ip_file == ""} { continue }

        set ip_name [file tail $ip_file]
        # LOBO-6618: Incorrect compile.do Path for Some IPs
        set ip_dir  [file tail [get_property IP_DIR [get_ips $ip]]]

        set compile_do_path   [get_do_file_path "compile" $output_dir_path $ip_dir]
        set elaborate_do_path [get_do_file_path "elaborate" $output_dir_path $ip_dir]
        set simulate_do_path  [get_do_file_path "simulate" $output_dir_path $ip_dir]

        set sim_files [get_files -all -of_objects [get_ips $ip] -compile_order sources -used_in simulation]
        set top_level_sim [expr {[llength $sim_files] > 0 ? [lindex $sim_files end] : ""}]

        set syn_files [get_files -all -of_objects [get_ips $ip] \
            -compile_order sources -used_in synthesis -filter {FILE_TYPE == "VHDL" || FILE_TYPE == "Verilog" || FILE_TYPE == "SystemVerilog"}]

        set xci_file  [get_property -quiet IP_FILE [get_ips $ip]]
        set xdc_files [get_files -all -of_objects [get_ips $ip] -filter {FILE_TYPE == "XDC"}]
        set dcp_files [get_files -all -of_objects [get_ips $ip] -filter {FILE_TYPE == "Design Checkpoint"}]

        puts $output_file "-ip_name $ip_name"
        puts $output_file "-vendor $VENDOR_NAME"
        puts $output_file "-vendor_lib_name $VENDOR_LIB_NAME"
        puts $output_file "-vendor_project_path $xilinx_project"
        puts $output_file "-xci_file $xci_file"
        puts $output_file "-top_level_sim $top_level_sim"
        puts $output_file "-compile_do_path $compile_do_path"
        puts $output_file "-elaborate_do_path $elaborate_do_path"
        puts $output_file "-simulate_do_path $simulate_do_path"
        puts $output_file "-xdc_files $xdc_files"
        puts $output_file "-dcp_files $dcp_files"
        puts $output_file "-syn_files $syn_files"

        print_separator $output_file
    }

    if {[llength $ip_cores] > 0} {
        export_simulation -simulator questa -of_objects $ip_cores \
            -lib_map_path $lib_map_path \
            -directory $output_dir_path -absolute_path -force
    }
}

# ----------------------------------------------------------
# Open the existing Vivado project
# ----------------------------------------------------------
if {[catch {
    open_project -verbose $xilinx_project
    set vivado_project_name [get_property NAME [current_project]]
} err]} {
    puts "ERROR: Failed to open Vivado project: $err"
    return
}

# ----------------------------------------------------------
# Prepare the output directory path for exporting files
# ----------------------------------------------------------
if {[catch {
    set output_dir_path [get_output_directory_path $project_dir $project_name $vivado_project_name]
} err]} {
    puts "ERROR: Failed to determine output directory path: $err"
}

# ----------------------------------------------------------
# Extract and write non-IP sources to the output file
# ----------------------------------------------------------
if {[catch {
    set file_user_rtl [open_output_file [file join $output_dir_path $EXPORTED_USER_RTL_FILE]]
    extract_user_rtl_sources $file_user_rtl
    close_output_file $file_user_rtl
} err]} {
    puts "ERROR: Failed during non-IP source extraction: $err"
}

# ----------------------------------------------------------
# Get IPs and categorize them into composite and core IPs
# ----------------------------------------------------------
if {[catch {
    set ip_list [get_ips]
    lassign [separate_ips $ip_list] ip_cores ip_composite
} err]} {
    puts "ERROR: Failed to separate IPs: $err"
}

# ----------------------------------------------------------
# Process BD files and IP cores, and write to output file
# ----------------------------------------------------------
if {[catch {
    set file_ip [open_output_file [file join $output_dir_path $EXPORTED_IP_FILE]]
    process_bd_files $file_ip $ip_composite
    process_ip_cores $file_ip $ip_cores
    close_output_file $file_ip
} err]} {
    puts "ERROR: Failed during IPs/BDs processing: $err"
}
