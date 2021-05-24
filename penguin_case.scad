// Penguin Case - customizable "rugged" box
// Christopher Bero <bigbero@gmail.com>

// Used to show a fake "printbed"
use <utils/build_plate.scad>

/* [Basic] */

part = "both"; // [top:Top Half,bottom:Bottom Half,both:Top and Bottom arranged]

// Box's internal height (z)
box_height = 50; // [50:200]
// Box's internal width (x)
box_width = 100; // [24:200]
// Box's internal depth (y)
box_depth = 60; // [24:200]
// Height (z) of seam between bottom and top halves
seal_height = 35; // [200]
// Number of latches
latch_num = 2; // [1, 2]
// Style of seal surface
seal_type = "flat"; // [channel_square:Square Channel,flat:Flat]
// Show or hide the preview printbed
show_printbed = "on"; // [on:On,off:Off]

/* [Advanced] */

//
// OpenSCAD settings
//

// Min angle. OpenSCAD default is 12.
$fa = 6;
// Min face size. OpenSCAD default is 2.
$fs = 0.5;

// Inside radius of box edges
inner_radius = 5;
// Height (z) of seal
seal_thickness = 10;
// Distance latch protrudes from exterior of box
latch_outset = 10;
// Wall thickness
wall = 2;
// Distance between latch mounting holes. 1 inch matches existing clasp designs.
latch_height = 25.4;
// Inner latch width, matches existing designs.
latch_width = 12.7;

/* [Print Bed] */

//for display only, doesn't contribute to final object
build_plate_selector = 3; //[0:Replicator 2,1: Replicator,2:Thingomatic,3:Manual]

//when Build Plate Selector is set to "manual" this controls the build plate x dimension
build_plate_manual_x = 200; //[100:400]

//when Build Plate Selector is set to "manual" this controls the build plate y dimension
build_plate_manual_y = 180; //[100:400]

// Validate variables
assert(box_height > 0);
assert(box_width > 0);
assert(box_depth > 0);
assert(seal_height > 0);

// Exterior wall dimensions
ext_w = box_width + (wall*2);
ext_d = box_depth + (wall*2);
ext_h = box_height + (wall*2);

core_w = box_width - (inner_radius*2);
core_d = box_depth - (inner_radius*2);
core_h = box_height - (inner_radius*2);

// Render Thingiverse Customizer build plate
if (show_printbed == "on") {
	build_plate(build_plate_selector,build_plate_manual_x,build_plate_manual_y);
}

// Create a cube with rounded vertical edges
module cube_rvert(size=[0, 0, 0], cyl_r=0, mod_center=true) {
	translate([0, 0, mod_center ? (size.z*-0.5) : 0]) {
		linear_extrude(size.z)
			offset(r=cyl_r)
				square([size.x, size.y], center=mod_center);
	}
}

// Creates rounded cube for rough shape of case.
module box_core() {
	ext_r = inner_radius + wall;
	difference() {
		translate([0, 0, (ext_h/2)]) {
			minkowski() {
				cube([core_w, core_d, core_h+ext_r], center=true);
				sphere(ext_r);
			}
		}
		translate([0, 0, -(ext_r/2)])
			cube([ext_w*2, ext_d*2, ext_r], center = true);
		translate([0, 0, (box_height + (wall*2)) + (ext_r/2)])
			cube([box_width*2, box_depth*2, ext_r], center=true);
	}
}

module box_seal() {
	union() {
		box_core();
		translate([0, 0, seal_height]) {
			hull() {
				cube_rvert([core_w, core_d, seal_thickness], inner_radius+(wall*2));
				cube_rvert([core_w, core_d, seal_thickness + (wall*2)], inner_radius+wall);
			}
		}
	}
}

module box_ribs() {
	union() {
		box_seal();
		for (i = [-1:2:1]) {
			translate([0, (-1*i)*(box_depth/4), ext_h/2]) {
				hull() {
					cube([ext_w + (wall*2), wall, ext_h - (wall*3)], center=true);
					cube([ext_w - (wall), wall*2, ext_h], center=true);
				}
			}
		}
	}
}

module latch(x_offset = 0) {
	h = box_height + (wall*2);
	translate([x_offset, 0, 0]) {
		for (i = [-1:2:1]) {
		translate([((latch_width/2)+(wall+0.5))*i, 0, 0]) { // mirror left/right
			difference() {
				translate([0 ,0, h/2])
					hull() { // Latch rib
						cube([wall*2, box_depth + latch_outset, h], center=true);
						cube([wall, box_depth + (latch_outset*2), h-latch_outset], center=true);
					}
				for (r = [0:1]) { // Latch mounting holes
					rotate([0, 0, 180*r]) // mirror front/back of case
						translate([0, ((box_depth+(latch_outset*2))/2)-((3/2)+2), seal_height])
							for (y = [-1:2:1]) {
								translate([0, 0, (latch_height/2)*y]) // mirror bottom/top
									rotate([0, 90, 0])
										cylinder(h=wall*3, d=3, center=true);
							}
				}
				for (d = [-1:2:1]) { // Latch hinge cutouts
					translate([0, ((box_depth+latch_outset*2)/2)*d, seal_height])
						rotate([45, 0, 0])
							cube([wall*4, wall, wall], center=true);
				}
			}
		}
		}
	}
}

module box_latches() {
	union() {
		box_ribs();
		if (latch_num == 1) {
			latch(0);
		}
		else {
			latch(-(box_width/4));
			latch(box_width/4);
		}
	}
}

module box_cavity() {
	difference() {
		box_latches();
		translate([0, 0, (box_height/2)+wall]) {
			minkowski() {
				cube([box_width-(inner_radius*2), box_depth-(inner_radius*2), box_height-(inner_radius*2)], center=true);
				sphere(r=inner_radius);
			}
		}
	}
}


module box_bottom() {
	difference() {
		box_cavity();
		translate([0, 0, (box_height/2)+seal_height])
			cube([box_width*2, box_depth*2, box_height], center=true);
	}
}


module box_top() {
	difference() {
		box_cavity();
		translate([0, 0, -(box_height/2)+seal_height])
			cube([box_width*2, box_depth*2, box_height], center=true);
	}
}

module box_bottom_oring() {
	difference() {
		box_bottom();
		translate([0, 0, seal_height + (seal_thickness/4)])
		difference() {
			cube_rvert([core_w, core_d, seal_thickness], inner_radius+(wall)+0.75);
			cube_rvert([core_w, core_d, seal_thickness+0.2], inner_radius+(wall)-0.75);
		}
	}
}

module box_top_oring() {
	gap = 0.2;
	ridge_h = (seal_thickness/4) + gap;
	union() {
		box_top();
		translate([0, 0, seal_height])
			difference() {
				cube_rvert([core_w, core_d, ridge_h], inner_radius+(wall)+0.75-gap);
				cube_rvert([core_w, core_d, ridge_h + 1], inner_radius+(wall)-0.75+gap);
			}
	}
}

module box_top_printable() {
		rotate([180, 0, 0]) {
			translate([0, 0, -ext_h])
				children();
		}
}

module box_arrangement() {
	translate([-((box_width/2)+10), 0, 0]) {
		if (seal_type == "flat") {
			box_bottom();
		}
		if (seal_type == "channel_square") {
			box_bottom_oring();
		}
	}
	translate([(box_width/2)+10, 0, 0]) {
		box_top_printable() {
			if (seal_type == "flat") {
				box_top();
			}
			if (seal_type == "channel_square") {
				box_top_oring();
			}
		}
	}
}

module box_customizer() {
	if (part == "top") {
		box_top_printable() {
			if (seal_type == "flat") {
				box_top();
			}
			if (seal_type == "channel_square") {
				box_top_oring();
			}
		}
	}
	if (part == "bottom") {
		if (seal_type == "flat") {
			box_bottom();
		}
		if (seal_type == "channel_square") {
			box_bottom_oring();
		}
	}
	if (part == "both") {
		box_arrangement();
	}
}

//box_core();
//box_seal();
//box_ribs();
//box_latches();
//box_cavity();
//box_bottom();
//box_top();
//box_bottom_oring();
//box_top_oring();
//box_arrangement();
box_customizer();













