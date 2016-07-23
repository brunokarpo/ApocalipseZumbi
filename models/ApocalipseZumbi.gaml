/**
* Name: ApocalipseZumbi
* Authors: bruno and guthierrez
* Description: Describe here the model and its experiments
* Tags: Tag1, Tag2, TagN
*/

model ApocalipseZumbi

global {
	int number_of_humans <- 50;
	init {
		create humano number:number_of_humans;
	}
}

species	humano skills: [ moving ] {
	bool contaminado <- flip(0.1);
	float agressividade <- 10.0;
	float vida <- 50.0;
	humano alvo_percebido <- nil;
	
	/*
	 * Humanos ou zumbis sem um alvo para perseguir se movem aleatoriamente
	 */
	reflex mover_aleatoriamente when: alvo_percebido = nil {
		do wander amplitude:90;
	}
	
	/*
	 * Se um zumbi tem algum humano como alvo, ele se move o seguindo.
	 */
	reflex seguir_humano when: alvo_percebido != nil and contaminado{
		do goto target:{alvo_percebido.location.x + rnd(0, 15, 1), alvo_percebido.location.y + rnd(0, 15, 1)};
	}
	
	/*
	 * Atualiza a velocidade de locomoção do agente de acordo com sua situação.
	 */
	reflex atualizar_velocidade {
		if(contaminado){
			speed <- 0.7;
		}else{
			speed <- 1.0;
		}
	}
	
	/*
	 * Atualiza a vida do agente contaminado, deixando ele sempre com 10 de vida, fazendo com que ele seja eliminado caso perca um combate contra um agente humano.
	 */
	reflex atualizar_vida_zumbi when:contaminado {
		vida <- 10.0;
	}
	
	/*
	 * Se um zumbi encontra um humano próximo, ele passa a tê-lo como alvo.
	 */
	reflex perceber_humano_proximo when:contaminado{
		ask humano at_distance(10){
			if(!self.contaminado){
				myself.alvo_percebido <- self;
			}
		}
	}
	
	/*
	 * Comportamento de ataque para zumbi. Se a agressividade do zumbi é maior ou igual que a
	 * agressividade do humano saudável, o humano pode ser infectado ou morto.
	 */
	reflex atacar_humano when:contaminado {
		ask humano at_distance(1){
			if(!self.contaminado){
				int randomico <- rnd (1000);
				int zumbieValue <- mod(randomico, myself.agressividade);
				int humanValue <- mod(randomico, self.agressividade);
				
				if(zumbieValue >= humanValue){
					self.contaminado <- true;
					self.agressividade <- 10.0;
					self.vida <- self.vida - myself.agressividade;
					myself.agressividade <- myself.agressividade * 1.1;
					if(self.vida < 0){
						do die;
					}
				}
			}
		}
	}
	
	/*
	 * Comportamento de ataque para um humano. Se a agressividade do humano é maior que a
	 * agressividade do zumbi, o zumbi pode ser morto.
	 */
	reflex atacar_zumbi when:!contaminado {
		ask humano at_distance(1){
			if(self.contaminado){
				int randomico <- rnd (1000);
				int zumbieValue <- mod(randomico, myself.agressividade);
				int humanValue <- mod(randomico, self.agressividade);
				
				if(humanValue > zumbieValue){
					self.vida <- self.vida - myself.agressividade;
					myself.agressividade <- myself.agressividade * 1.05;
					if(self.vida < 0){
						myself.agressividade <- myself.agressividade * 1.1;
						do die;
					}
				}
			}
		}
	}
	
	/*
	 * Quando dois humanos se encontram ambos aumentam sua agressividade.
	 */
	reflex trocar_experiencias when:!contaminado {
		ask humano at_distance(1){
			if(!self.contaminado){
				myself.agressividade <- myself.agressividade * 1.05;
				self.agressividade <- self.agressividade * 1.05;
			}
		}
	}
	
	aspect default {
		if(!contaminado) {
			draw circle(1) color: #green;
		} else {
			draw circle(1) color: #red;
		}
		draw string((alvo_percebido = nil ? 'N' : 'S') + '-' + agressividade + '-' + vida) color: #black;
	}
}

experiment apocalipse type: gui{
	float minimum_cycle_duration <- 0.5#second;
	output {
		display myDisplay {
			graphics "Ambiente" {
				draw square(200) at:{0,0} color:rgb(235, 235, 235);
			}
			
			species humano aspect:default ;
		}
		
	}
}