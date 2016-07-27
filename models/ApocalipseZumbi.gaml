/**
* Name: ApocalipseZumbi
* Authors: bruno and guthierrez
* Description: Describe here the model and its experiments
* Tags: Tag1, Tag2, TagN
*/

model ApocalipseZumbi

global {
	int numero_de_humanos <- 100;
	int porcentagem_contaminados <- 20;
	
	int fator_de_combate <- 1000;
	
	float velocidade_zumbi <- 0.7;
	float velocidade_humano <- 1.0;
	
	float agressividade_inicial <- 10.0;
	float limite_de_agressividade <- 15.0;
	
	float vida_inicial <- 50.0;
	float vida_de_zumbi <- 30.0;
	float morto <- 0.0;
	
	geometry shape <- square(1000#m);
	
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
	float agressividade <- agressividade_inicial;
	float vida <- contaminado ? vida_de_zumbi : vida_inicial;
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
			speed <- velocidade_zumbi;
		}else{
			speed <- velocidade_humano;
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
	 * Quando um agente humano é atacado por um agente zumbi e sua vida fica igual ou abaixo de 30, ele se torna um zumbi
	 */
	reflex ser_contaminado when:!contaminado{
		if(vida <= vida_de_zumbi) {
			self.contaminado <- true;
			self.agressividade <- agressividade_inicial;
		}
	}
	
	/*
	 * Limita a agressividade para não ser maior do que 40.
	 */
	reflex limitar_agressividade {
		if(self.agressividade > limite_de_agressividade) {
			self.agressividade <- limite_de_agressividade;
		}
	}
	
	/*
	 * Comportamento de ataque para zumbi. Se a agressividade do zumbi é maior ou igual que a
	 * agressividade do humano saudável, o humano pode ser infectado ou morto.
	 */
	reflex atacar_humano when:contaminado {
		ask humano at_distance(1){
			if(!self.contaminado){
				int taxa_de_sucesso_do_ataque <- mod(rnd (fator_de_combate), myself.agressividade);
				int taxa_de_escape <- mod(rnd (fator_de_combate), self.agressividade);
				int dano <- taxa_de_sucesso_do_ataque - taxa_de_escape;
				
				if(taxa_de_sucesso_do_ataque >= taxa_de_escape){
					self.vida <- self.vida - dano;
					if(self.vida <= morto){
						myself.agressividade <- myself.agressividade * 1.2;
						do die;
					} else {
						myself.agressividade <- myself.agressividade * 1.1;
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
				int taxa_de_sucesso_do_ataque <- mod(rnd (fator_de_combate), myself.agressividade);
				int taxa_de_escape <- mod(rnd (fator_de_combate), self.agressividade);
				int dano <- taxa_de_sucesso_do_ataque - taxa_de_escape;
				
				if(taxa_de_sucesso_do_ataque > taxa_de_escape){
					self.vida <- self.vida - dano;
					if(self.vida <= morto){
						myself.agressividade <- myself.agressividade * 1.2;
						do die;
					} else {
						myself.agressividade <- myself.agressividade * 1.1;
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
				myself.agressividade <- myself.agressividade * 1.01;
				self.agressividade <- self.agressividade * 1.01;
			}
		}
	}
	
	aspect default {
		if(!contaminado) {
			draw circle(1) color: #green;
		} else {
			draw circle(1) color: #red;
		}
	}
}

experiment apocalipse type: gui{
	
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