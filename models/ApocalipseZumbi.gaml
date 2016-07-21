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
	bool contaminado <- flip(0.3);
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
	 * Se um zumbi tem algum humano como alvo, ele o segue.
	 */
	reflex seguir_humano when: alvo_percebido != nil and contaminado{
		do goto target:alvo_percebido;
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
	 * Se um zumbi encontra um humano próximo, ele passa a te-lo como alvo.
	 */
	reflex perceber_humano_proximo when:contaminado{
		ask humano at_distance(10){
			if(!self.contaminado){
				myself.alvo_percebido <- self;
			}else{
				myself.alvo_percebido <- nil;
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
				if(myself.agressividade = self.agressividade){
					self.contaminado <- true;
				}
				if(myself.agressividade > self.agressividade){
					self.vida <- self.vida - myself.agressividade;
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
				if(myself.agressividade > self.agressividade){
					self.vida <- self.vida - myself.agressividade;
					if(self.vida < 0){
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
				myself.agressividade <- myself.agressividade + 0.5;
				self.agressividade <- self.agressividade + 0.5;
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
	output {
		display myDisplay {
			species humano aspect:default ;
		}
	}
}