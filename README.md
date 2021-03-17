Utilizando o circuito mostrado na Figura 2, elabore um programa em linguagem de montagem que faça
com que o LED incorporado à placa de desenvolvimento (conectado ao pino 13) pisque a uma frequência
de 0,5Hz (1s aceso e 1s apagado).

![alt text](https://github.com/AlefeTiago/machine-language/blob/main/Montagem.PNG)


Quando o botão é pressionado, o LED incorporado deve instantaneamente piscar três vezes de acordo com
a sequência: apagado, aceso, apagado, aceso, apagado, aceso, apagado, em que cada estado, apagado ou
aceso, dura 100ms. Note que a sequência se inicia e se encerra com o LED apagado, ou seja, há quatro
estados em que o LED se apaga e três em que ele se acende. Após essa sequência, o acionamento do LED
deve retomar o ponto em que havia sido interrompido antes do botão ser pressionado. A Figura 3 mostra o
nível lógico do pino 13 em um exemplo de acionamento do LED. Note que a sequência inserida tem
duração de 700ms.
A detecção do estado do botão deve ser feita através da interrupção externa associada ao terminal 3 (INT1).

![alt text](https://github.com/AlefeTiago/machine-language/blob/main/Onda.PNG)

Os atrasos necessários para a temporização do acionamento do LED devem ser obtidos através de laços que
executam uma sequência de instruções com o objetivo exclusivamente de consumir tempo (processador em
espera ativa), estratégia equivalente à usada na função _delay_ms(.). O uso de programação em Assembly
neste cenário é particularmente pertinente pelo fato de podermos controlar de forma direta o número total
de ciclos de relógio relacionados à execução do laço, alcançando, assim, uma boa precisão com respeito ao
tempo consumido por ele. Os laços para consumo de tempo podem ser implementados usando-se
chamadas de sub-rotina (veja as instruções CALL e RET).

O transitório do botão pode gerar rajadas indesejadas e o ideal seria usarmos um circuito de debounce para
filtrá-lo. Como os componentes necessários para montar tal circuito não estão disponíveis no kit didático,
use sua criatividade para mitigar o efeito do transitório por software. Uma medida simples é limpar o flag
associado a INT1 no final da Rotina de Serviço de Interrupção (RSI). Um pulso espúrio pode ativar o flag
durante a execução da RSI de modo que uma nova interrupção fique pendente. A limpeza do flag impede
que a interrupção espúria ocorra, evitando duas rajadas consecutivas e garantindo que apenas uma única
ocorra a cada pressionamento do botão.
