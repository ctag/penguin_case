// Penguin Case - customizable "rugged" box
// Christopher Bero <bigbero@gmail.com>

// OpenSCAD settings
$fa = 6; // Min angle. Default 12.
$fs = 0.5; // Min face size. Default 2.

// User customizable variables
// Box dimensions dictate the internal volume.
box_height = 35;
box_width = 40;
box_depth = 40;
seal_height = 20;

// Static variables
rounding_radius = 5;
rounding_reduction = rounding_radius * 0.5;
rib_outset = 2;
rib_width = 2;
seal_outset = rib_outset;
seal_thickness = 10;
latch_outset = 10;
wall_thickness = 2;


// Validate variables
assert(box_height > 0);
assert(box_width > 0);
assert(box_depth > 0);
assert(seal_height > 0);

height_diff = (rounding_radius - rounding_reduction);
core_width = box_width + (wall_thickness*2) - (rounding_radius * 2);
core_depth = box_depth + (wall_thickness*2) - (rounding_radius * 2);
core_height = box_height + (wall_thickness*2) - (height_diff * 2);

// Creates rough shape of case.
module box_core() {
	difference() {
		translate([-(core_width/2), -(core_depth/2), height_diff]) {
			minkowski() {
				cube([core_width, core_depth, core_height]);
				sphere(rounding_radius);
			}
		}
		translate([0, 0, -(rounding_radius/2)])
			cube([core_width*2, core_depth*2, rounding_radius], center = true);
		translate([0, 0, (box_height + (wall_thickness*2)) + (rounding_radius/2)])
			cube([box_width*2, box_depth*2, rounding_radius], center=true);
	}
}

module box_seal() {
	seal_diff = (rounding_radius + seal_outset);
	union() {
		box_core();
		translate([0, 0, seal_height]) {
			hull() {
				minkowski() {
					cylinder_h = 2;
					cube([core_width, core_depth, seal_thickness - cylinder_h], center=true);
					cylinder(cylinder_h, r=(rounding_radius + seal_outset), center=true);
				}
				minkowski() {
					cylinder_h = 2;
					cube([core_width, core_depth, (seal_thickness + (seal_outset * 2) - cylinder_h)], center=true);
					cylinder(cylinder_h, r=(rounding_radius), center=true);
				}
			}
		}
	}
}

module box_ribs() {
	w = (box_width+(wall_thickness*2));
	h = (box_height + (wall_thickness*2));
	union() {
		box_seal();
		for (i = [-1:2:1]) {
			translate([0, (-1*i)*(box_depth/4), h/2]) {
				hull() {
					cube([w + (rib_outset*2), rib_width, h - (rib_outset*2)], center=true);
					cube([w, rib_width*2, h], center=true);
				}
			}
		}
	}
}

module box_latches() {
	h = box_height + (wall_thickness*2);
	union() {
		box_ribs();
		for (i = [0:1]) {
			translate([(20*i)-10, 0, h/2]) {
				difference() {
					hull() {
						cube([rib_width*2, box_depth + latch_outset, h], center=true);
						cube([rib_width, box_depth + (latch_outset*2), h-latch_outset], center=true);
					}
					for (r = [0:1]) {
						rotate([0, 0, 180*r])
							translate([0, ((box_depth+(latch_outset*2))/2)-((3/2)+2), seal_height-(box_height/2)])
								for (y = [-1:2:1]) {
									translate([0, 0, 10*y])
										rotate([0, 90, 0])
											cylinder(h=rib_width*3, d=3, center=true);
								}
					}
				}
			}
		}
	}
}

module box_cavity() {
	difference() {
		box_latches();
		translate([0, 0, (box_height/2)+wall_thickness]) {
			minkowski() {
				cube([box_width-(rounding_radius*2), box_depth-(rounding_radius*2), box_height-(rounding_radius*2)], center=true);
				sphere(r=rounding_radius);
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



//box_core();
//box_seal();
//box_ribs();
//box_latches();
//box_cavity();
box_bottom();
//box_top();
















