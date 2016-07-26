/**
* Name: ApocalipseZumbi
* Authors: bruno and guthierrez
* Description: Describe here the model and its experiments
* Tags: Tag1, Tag2, TagN
*/

model ApocalipseZumbi

global {
	int numero_de_humanos <- 100;
	int porcentagem_contaminados <- 10;
	init {
		create humano number:numero_de_humanos;
	}
	
	reflex fim_do_experimento {
		if(empty(humano.population where (each.contaminado = true)) or empty(humano.population where (each.contaminado = false))){
			do pause;
		}
	}
}

species	humano skills: [ moving ] {
	bool contaminado <- flip(porcentagem_contaminados / 100);
	float agressividade <- 10.0;
	float vida <- contaminado ? 10.0 : 50.0;
	humano alvo_percebido <- nil;
	
	/*
	 * Humanos ou zumbis sem um alvo para perseguir se movem aleatoriamente
	 */
	reflex mover_aleatoriamente when: alvo_percebido = nil or alvo_percebido = unknown {
		do wander amplitude:90;
	}
	
	/*
	 * Se um zumbi tem algum humano como alvo, ele se move o seguindo.
	 */
	reflex seguir_humano when: alvo_percebido != nil and contaminado{
		do goto target:{alvo_percebido.location.x + rnd(0, 5, 1), alvo_percebido.location.y + rnd(0, 5, 1)};
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
	 * Se um zumbi encontra um humano próximo, ele passa a tê-lo como alvo.
	 */
	reflex perceber_humano_proximo when:contaminado{
		ask humano at_distance(10){
			if(!self.contaminado){
				myself.alvo_percebido <- self;
			} else {
				myself.alvo_percebido <- nil;
			}
		}
	}
	
	/*
	 * Limita a agressividade para não ser maior do que 40.
	 */
	reflex limitar_agressividade {
		if(self.agressividade > 15.0) {
			self.agressividade <- 15.0;
		}
	}
	
	/*
	 * Comportamento de ataque para zumbi. Se a agressividade do zumbi é maior ou igual que a
	 * agressividade do humano saudável, o humano pode ser infectado ou morto.
	 */
	reflex atacar_humano when:contaminado {
		ask humano at_distance(1){
			if(!self.contaminado){
				int zumbieValue <- mod(rnd (1000), myself.agressividade);
				int humanValue <- mod(rnd (1000), self.agressividade);
				
				if(zumbieValue > humanValue){
					self.contaminado <- true;
					self.agressividade <- 10.0;
					self.vida <- 30.0;
					if(self.vida <= 0){
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
				int zumbieValue <- mod(rnd (1000), myself.agressividade);
				int humanValue <- mod(rnd (1000), self.agressividade);
				
				if(humanValue > zumbieValue){
					self.vida <- self.vida - myself.agressividade;
					myself.agressividade <- myself.agressividade * 1.05;
					if(self.vida <= 0){
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
				myself.agressividade <- myself.agressividade * 1.1;
				self.agressividade <- self.agressividade * 1.1;
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
	
	parameter "Número de humanos: " var: numero_de_humanos;
    parameter "Porcentagem de Infectados: " var: porcentagem_contaminados;
    
	output {
		display Experimento {
			species humano aspect:default ;
		}
		
		display Resultados {
			chart "Situação Populacional" type:pie {
				data "Humanos vivos" value:(length(humano.population where (each.contaminado = false))) color: #green;
				data "Zumbis vivos" value:(length(humano.population where (each.contaminado = true))) color: #brown;
				data "População dizimada" value: (numero_de_humanos - length(humano.population));
			}
			
		}
		
	}
}