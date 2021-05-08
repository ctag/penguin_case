// Penguin Case - customizable "rugged" box
// Christopher Bero <bigbero@gmail.com>

// Only for Thingiverse Customizer
use <utils/build_plate.scad>

/* [Basic] */

part = "both"; // [top:Top Half, bottom: Bottom Half, both: Top and Bottom arranged]

// Box dimensions dictate the internal volume.

// Box's cavity height (z)
box_height = 50;
// Box's cavity width (x)
box_width = 100;
// Box's cavity depth (y)
box_depth = 40;
// Height (z) of seam between bottom and top halves
seal_height = 35;
// Number of latches
latch_num = 2; // [1, 2]
// Style of seal surface
seal_type = "flat"; // [channel_square:Square Channel,flat:Flat]

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

// Validate variables
assert(box_height > 0);
assert(box_width > 0);
assert(box_depth > 0);
assert(seal_height > 0);

// Exterior wall dimensions
ext_w = box_width + (wall*2);
ext_d = box_depth + (wall*2);
ext_h = box_height + (wall*2);

// Render Thingiverse Customizer build plate
//for display only, doesn't contribute to final object
build_plate_selector = 3; //[0:Replicator 2,1: Replicator,2:Thingomatic,3:Manual]

//when Build Plate Selector is set to "manual" this controls the build plate x dimension
build_plate_manual_x = 200; //[100:400]

//when Build Plate Selector is set to "manual" this controls the build plate y dimension
build_plate_manual_y = 180; //[100:400]

build_plate(build_plate_selector,build_plate_manual_x,build_plate_manual_y);

// Creates rounded cube for rough shape of case.
module box_core() {
	difference() {
		translate([0, 0, (ext_h/2)]) {
			minkowski() {
				cube([ext_w-(inner_radius*2), ext_d-(inner_radius*2), ext_h-(inner_radius)], center=true);
				sphere(inner_radius);
			}
		}
		translate([0, 0, -(inner_radius/2)])
			cube([ext_w*2, ext_d*2, inner_radius], center = true);
		translate([0, 0, (box_height + (wall*2)) + (inner_radius/2)])
			cube([box_width*2, box_depth*2, inner_radius], center=true);
	}
}

module box_seal() {
	c_h = 2; // cylinder height - minkowski helper variable
	union() {
		box_core();
		translate([0, 0, seal_height]) {
			hull() {
				minkowski() {
					cube([ext_w-(inner_radius*2), ext_d-(inner_radius*2), seal_thickness - c_h], center=true);
					cylinder(c_h, r=(inner_radius + wall), center=true);
				}
				minkowski() {
					cube([ext_w-(inner_radius*2), ext_d-(inner_radius*2), (seal_thickness + (wall * 2) - c_h)], center=true);
					cylinder(c_h, r=(inner_radius), center=true);
				}
			}
		}
	}
}

module box_ribs() {
	w = (box_width+(wall*2));
	h = (box_height + (wall*2));
	union() {
		box_seal();
		for (i = [-1:2:1]) {
			translate([0, (-1*i)*(box_depth/4), h/2]) {
				hull() {
					cube([w + (wall*2), wall, h - (wall*2)], center=true);
					cube([w, wall*2, h], center=true);
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
			minkowski() {
				cylinder_h = 2;
				cube([box_width-(inner_radius*2), box_depth-(inner_radius*2), seal_thickness - cylinder_h], center=true);
				cylinder(cylinder_h, r=(inner_radius + (wall*2) - 1), center=true);
			}
			minkowski() {
				cylinder_h = 2;
				cube([box_width-(inner_radius*2), box_depth-(inner_radius*2), seal_thickness - cylinder_h], center=true);
				cylinder(cylinder_h, r=(inner_radius+1), center=true);
			}
		}
	}
}

module box_top_oring() {
	union() {
		box_top();
		translate([0, 0, seal_height])
		difference() {
			minkowski() {
				cylinder_h = 1;
				cube([box_width-(inner_radius*2), box_depth-(inner_radius*2), (seal_thickness/4) - cylinder_h], center=true);
				cylinder(cylinder_h, r=(inner_radius + (wall*2) - 1.25), center=true);
			}
			minkowski() {
				cylinder_h = 2;
				cube([box_width-(inner_radius*2), box_depth-(inner_radius*2), (seal_thickness/4) - cylinder_h + 0.1], center=true);
				cylinder(cylinder_h, r=(inner_radius+1.25), center=true);
			}
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















