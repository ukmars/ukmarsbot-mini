// Simple Micromouse wheel that uses a 0.3 Mod 44:11 gear plugged into it
//
use <pd-gears/pd-gears.scad>

show_tyre = true;
show_gear = true;
show_wheel = true;
enable_holes_in_gear = true;    // Currently hardcoded, not calculated based on size.

faces = 200;
//faces = 50;

epsilon = 0.001;        // small constant to avoid coincident walls on union, difference or intersection


function module_to_circular_pitch(module_val) = module_val * PI;


// mini_UKMARS constants
// =====================
type_expansion = 2;     // expand rhe rim and tyre to we don't run on the gear teeth
m_RIM_depth = 4.5;
m_RIM_outside_radius = (11+type_expansion)/2;
m_RIM_inside_radius = m_RIM_outside_radius-1;
RIM_back_depth = 1;

// this is the gear that fits onto the wheel
m_gear_thickness = 1;
m_gear_teeth = 44;
m_gear_module = 0.3;
m_axle_collar_length = 0.3;
m_axle_collar_diameter = 4;
m_subgear_thickness = 4.55 - (m_gear_thickness + m_axle_collar_length);
m_subgear_teeth = 11;
m_axle_diameter = 1.5;        // usually this is smaller, but we widen to 2mm
m_gear_offset = m_axle_collar_length;

m_tyre_OD = 13.8+type_expansion;
m_tyre_thickness = m_tyre_OD/2 - m_RIM_outside_radius;

// common constants
defined_pressure_angle = 20;

// gear holder
RIM_gear_holder_depth = m_subgear_thickness;
RIM_gear_holder_thickness = 1;
gear_pinch_radius = -0.2;       // negative = give it a bit of extra clearence, positive = make it tighter
RIM_gear_holder_inside_radius = outer_radius(module_to_circular_pitch(m_gear_module), m_subgear_teeth) - gear_pinch_radius;
RIM_gear_holder_outside_radius = RIM_gear_holder_inside_radius + 1;


//////////////////////////////////////////////////////////////////////////////////////////////
//             ____                          
//  ___  ___  / ___\   ____  _____  _______  
//  \  \/  / / /_/  >_/ __ \ \__  \ \_  __ \ 
//   >    <  \___  / \  ___/  / __ \_|  | \/ 
//  /__/\_ \/_____/   \___  >(____  /|__|    
//        \/              \/      \/         
//   
// Saves generating full gears when prototyping
//////////////////////////////////////////////////////////////////////////////////////////////
replace_cylinder = false;
cylinder_segments = 100;

module xgear(mm_per_tooth, teeth, thickness, hole_diameter, center = false)
{
    if (replace_cylinder) {
        difference() {
            cylinder(thickness, outer_radius(mm_per_tooth, teeth, 0), outer_radius(mm_per_tooth, teeth, 0), center, $fn = cylinder_segments);
        translate([0,0, (center ? 0 : -0.1)])
            cylinder(h=thickness+0.2, r=hole_diameter/2, center=center, $fn=cylinder_segments);
        }
    }
    else
        gear(mm_per_tooth, teeth, thickness, hole_diameter, center, pressure_angle = defined_pressure_angle);
}

//////////////////////////////////////////////////////////////////////////////////////////////
//
// make wheels lighter
//


module hole_circles(RIM_depth, gear_thickness, gear_offset) {
    number_of_circles = 9;
    hole_size = 0.9;
    hole_depth = 1 + RIM_depth + gear_thickness + gear_offset;
    hole_orbit_radius = 3.8-gear_pinch_radius;
    hole_faces = 50;
    
    for(i = [0 : number_of_circles]) {
        rotate([0, 0, i * (360 / number_of_circles)]) translate([0, hole_orbit_radius, 0])
            cylinder(hole_depth, hole_size, hole_size, $fn=hole_faces);
    }
}

//////////////////////////////////////////////////////////////////////////////////////////////
//
// zwheel
//
module simple_wheel(RIM_depth, gear_thickness, gear_offset, RIM_outside_radius, RIM_inside_radius, axle_collar_diameter, axle_collar_length, axle_diameter, gear_teeth, gear_module)
{
    /*color("white", 1.0) */ {
        difference() {
            union() {
                if(show_wheel) /*color("yellow", 1.0)*/ {
                    // main RIM
                    translate([0, 0, gear_thickness+gear_offset]) { 
                        difference() {
                            cylinder(RIM_depth, RIM_outside_radius, RIM_outside_radius, $fn=faces);
                            translate([0,0,-0.05]) cylinder(RIM_depth+0.1, RIM_inside_radius, RIM_inside_radius, $fn=faces);
                        }
                        // RIM back
                        cylinder(RIM_back_depth, RIM_outside_radius, RIM_outside_radius, $fn=faces);
                        // Gear holder on RIM
                        difference() {
                            cylinder(RIM_gear_holder_depth, RIM_gear_holder_outside_radius, RIM_gear_holder_outside_radius, $fn=faces);
                            translate([0,0,-0.05-RIM_gear_holder_thickness]) cylinder(RIM_gear_holder_thickness+RIM_gear_holder_depth+0.1, RIM_gear_holder_inside_radius, RIM_gear_holder_inside_radius, $fn=faces);
                        }
                        
                    }
                }
            }
            union() {
                // axle  actually as wide as gear holder
                //translate([0, 0, -RIM_depth/2]) cylinder(RIM_depth*2, axle_diameter/2, axle_diameter/2, $fn=faces);
                translate([0, 0, -RIM_depth/2]) cylinder(RIM_depth*2, RIM_gear_holder_inside_radius, RIM_gear_holder_inside_radius, $fn=faces);

                if(enable_holes_in_gear) {
                    hole_circles(RIM_depth, gear_thickness, gear_offset);
                }
            }
            
        }
        
        if(show_gear) color("white", 1.0) difference() { 
            union() {
            // axel collar
            cylinder(axle_collar_length, axle_collar_diameter/2, axle_collar_diameter/2, $fn=faces);
            translate([0,0,gear_offset-epsilon]) xgear(module_to_circular_pitch(gear_module), gear_teeth, gear_thickness, axle_diameter, center=true);
            translate([0,0,gear_offset+gear_thickness-epsilon*2]) xgear(module_to_circular_pitch(gear_module), m_subgear_teeth, m_subgear_thickness, axle_diameter, center=true);
            }
            // axle for gear
            translate([0, 0, -RIM_depth/2]) cylinder(RIM_depth*2, axle_diameter/2, axle_diameter/2, $fn=faces);
            
        }


    }
}
//////////////////////////////////////////////////////////////////////////////////////////////

module simple_tyre_core(diameter, thickness, hole_diameter, center = false)
{
    r = diameter/2;
    difference() {
        cylinder(thickness, r, r, center, $fn = cylinder_segments);
        translate([0, 0, (center ? 0 : -0.1)])
            cylinder(h=thickness+0.2, r=hole_diameter/2, center=center, $fn=cylinder_segments);
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////

module simple_tyre(RIM_outside_radius, RIM_depth, gear_thickness, gear_offset, tyre_thickness)
{
    wheel_diameter = RIM_outside_radius*2;
    wheel_thickness = RIM_depth;
    wheel_gear_thickness = -(RIM_depth+gear_thickness+gear_offset);

    angle=0; offset=0; offsety=0;
    rotate([0, angle, 0]) translate([offset,  offsety, 0])
        rotate([90,90,0]) 
            {
            translate([0,0,wheel_gear_thickness-epsilon]) color([0.3, 0.3, 0.3, 0.5]) simple_tyre_core(wheel_diameter+2*tyre_thickness, wheel_thickness-epsilon*2, wheel_diameter, center = false);
            }
}
//
//
//


simple_wheel(m_RIM_depth, m_gear_thickness, m_gear_offset, m_RIM_outside_radius, m_RIM_inside_radius, m_axle_collar_diameter, m_axle_collar_length, m_axle_diameter, m_gear_teeth, m_gear_module);


if(m_tyre_thickness != 0 && show_tyre)
{
    rotate([90,0,0]) simple_tyre(m_RIM_outside_radius, m_RIM_depth, m_gear_thickness, m_gear_offset, m_tyre_thickness);
}

