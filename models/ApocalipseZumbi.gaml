/**
* Name: ApocalipseZumbi
* Author: bruno
* Description: Describe here the model and its experiments
* Tags: Tag1, Tag2, TagN
*/

model ApocalipseZumbi

global {
	int number_of_humans <- 100;
	int number_of_zumbi <- 1;
	init {
		create humano number:number_of_humans;
	}
}

species	humano skills: [ moving ] {
	bool contaminado <- false;
	float agressividade <- 10.0;
	
	init {
		speed <- 1.0;
	}
	
	reflex move {
		do wander amplitude:90;
	}
	
	aspect default {
		if(!contaminado) {
			draw circle(0.5) color: #green;
		} else {
			draw circle(0.5) color: #red;
		}
	}
}

experiment apocalipse type: gui{
	output {
		display myDisplay {
		species humano aspect:default ;
	}
}
}