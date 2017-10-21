# network
Estes scripts simulam uma camada de apliação com mini servidor web e uma camada físca.
A ideia é que há um *Computador A* rodando um servidor web. Este computador está conhectado há um *Computador B* através
da camada física também implementada neste repositório.

Caso o *Computador B* tente acessar o servidor web no *Computador A* sua requisição será redirecionada (através de um NAT) 
para uma aplicação local que entregará esta mensagem para a camada física, forçando a simulação das camadas.


## Como para rodar o Projeto

Assumindo que o IP do *Computador A* é 192.168.15.7 e ele será o servidor
e que o do *Computador B* é 192.168.15.18 e ele será o cliente.

1. Consiga duas máquinas Linux conectadas em rede local

2. Instale lua5.1 em ambas e baixe luasocket através do luarocks

```
sudo apt-get install lua5.1
sudo apt-get install luarocks
sudo luarocks install luasocket
```
3. Baixe a pasta server deste repositório para a máquina servidora

4. Baixe a pasta client deste repositrio para a máquina cliente

5. configure o NAT na máquina cliente de forma a interceptar toda request tcp da porta 2321 e redirecionar para localhost

```
sudo iptables -t nat -A OUTPUT -p tcp --dport 2321 -j DNAT --to-destination 127.0.0.1:2321
```
6. Na máquina servidora instancie 3 terminais e em cada um deles inicie os serviços:

```
bash cliente_fisica.sh 2322 192.168.15.18 2324
```
```
lua5.1 web_server.lua
```
```
bash servidor_fisica.sh 2320 2321 1000 
```

7. Na máquina cliente instancie 3 terminais e em cada um deles inicie os serviços:

```
bash cliente_fisica.sh 2319 192.168.15.7 2320
```
```
lua5.1 web_client.lua
```
```
bash servidor_fisica.sh 2324 2325 1000 
```
8. Na máquina cliente abra um browser e digite 192.168.15.7:2321

9. *Et voilà!* você estará acessando uma página do *Computador A* que trafegou pela camada física!
