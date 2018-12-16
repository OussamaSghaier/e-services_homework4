# Homework TP4_e-services : Microservices avec Spring Boot et Spring Cloud
### Lien vers l'énoncé du TP:
### https://insatunisia.github.io/TP-eServices/tp4/

<p align="center">
  <img src="/img/microservices.png">
</p>

&nbsp; Le développement d’applications Web côté serveur a beaucoup évolué depuis les débuts de Docker. Grâce à Docker, il est maintenant plus facile de construire des applications évolutives et gérables construites à partir de microservices. <br/><br/>
&nbsp; Dans ce contexte, nous allons nus intéresser à la conteneurisation d'une application à base de microservices dont l'architecture est donnée par la figure ci-dessous : <br/> 

<p align="center">
  <img src="/img/architecture.png">
</p>

<br/>
 &nbsp; Les concepts que nous allons utiliser ici pour le déploiement sont les suivants:
<br/><br/>
&nbsp;&nbsp;&nbsp;&nbsp; 1. Dockerfile: 
Il s'agit d'un document texte contenant toutes les instructions nécessaires à la création d'une image Docker. En utilisant le jeu d'instructions d'un fichier Dockerfile, nous pouvons écrire des étapes pour copier des fichiers, effectuer l'installation, etc...
<br/><br/>
&nbsp;&nbsp;&nbsp;&nbsp; 2. Docker Compose: 
C'est un outil qui peut créer et générer plusieurs conteneurs. Il est utile pour créer l'environnement requis avec une seule commande.
<br/><br/>

## Création d'un répertoire pour les fichiers de configuration
&nbsp; Le répertoire de configuration doit être un répertoire git. Pour cela, placez-vous dans config-service\src\main\resources\myConfig et saisir les commandes ci-dessous : <br/>
- git init
- git add .
- git commit -m "First commit"
- git remote add origin [remote repository URL]
- git push origin master

## Changement au niveau du code 
&nbsp; Dans Config-service, ajouter la propriété suivante au niveau de proxy-service.properties ainsi que product-service.properties : <br/>
<code> eureka.client.serviceUrl.defaultZone=http://discovery-service:8761/eureka/ </code> <br/><br/>
&nbsp; Cette propriété permet de s'assurer que le proxy-service et product-service s'enregistrent automatiquement auprès du discovery-service en définissant la zone par défaut. <br/>
<br/> Note : discovery-service est le nom du service défini dans docker-compose.yml par la suite. <br/>


## Consturuction des images Docker
&nbsp; Créer en premier lieu un fichier Dockerfile qui permettra de construire l'image de base contenant Java.

<pre><code>
FROM alpine:edge 
LABEL maintainer="Oussama_Imen"
RUN apk add --no-cache openjdk8 
</code></pre>

&nbsp; Exécuter la commande ci-dessous pour créer l'image de base de Docker: <br/>
<code>docker build --tag=alpine-jdk:base --rm=true . </code> <br/>

&nbsp; Une fois que l'image de base est générée avec succès, il est temps de créer les images docker des différents services : <br/>
#### Config-service : <br/>
&nbsp; Créez un fichier appelé Dockerfile-configservice avec le contenu ci-dessous:
<pre><code>
FROM alpine-jdk:base
LABEL maintainer="Oussama_Imen"
COPY config-service/target/config-service-0.0.1-SNAPSHOT.jar /opt/lib/
ENV SPRING_APPLICATION_JSON='{"spring": {"cloud": {"config": {"server": {"git": {"uri": "https://github.com/OussamaSghaier/e-services_configurations"}}}}}}'
ENTRYPOINT ["/usr/bin/java"]
CMD ["-jar", "/opt/lib/config-service-0.0.1-SNAPSHOT.jar"]
EXPOSE 8888
</code></pre>

&nbsp; Ici, nous avons mentionné la construction de l'image à partir de l'image alpine-jdk créée précédemment.<br/>
Nous copierons le fichier jar nommé config-service-0.0.1-SNAPSHOT.jar à l’emplacement /opt/lib. <br/>
Lorsque le conteneur démarre, nous voulons que le serveur de configuration commence à s'exécuter. Par conséquent, ENTRYPOINT et CMD sont configurés pour exécuter la commande Java.<br/>
Le serveur de configuration doit être accessible avec le port 8888; C'est pourquoi nous avons EXPOSE 8888.
<br/><br/>

#### Discovery-service
&nbsp; De même, nous devons créer un fichier Docker pour DiscoveryService, qui s'exécutera sur le port 8761. Le fichier Dockerfile-DiscoveryService devrait être comme suit:
<pre><code>
FROM alpine-jdk:base
LABEL maintainer="Oussama_Imen"
RUN apk --no-cache add netcat-openbsd
COPY discovery-service/target/discovery-service-0.0.1-SNAPSHOT.jar /opt/lib/
COPY discoveryservice_wait-for-it.sh /opt/bin/
RUN chmod 755 /opt/bin/discoveryservice_wait-for-it.sh
EXPOSE 8761
</code></pre>

&nbsp; Nous devons nous rappeler que DiscoveryService dépend de ConfigService. Il faut donc nous assurer que, avant de démarrer le DiscoveryService, le ConfigServie est opérationnel.
<br/><br/> 
&nbsp; Pour cela, créons le script discoveryservice_wait-for-it ci-dessous :
<pre><code>
#!/bin/sh
while ! nc -z config-service 8888 ; do
&nbsp;    echo "Waiting for upcoming Config Service"
&nbsp;    sleep 2
done
java -jar /opt/lib/discovery-service-0.0.1-SNAPSHOT.jar
</code></pre>

#### Proxy-service
&nbsp; ProxyService s'exécute sur le port 9999. Le fichier Dockerfile-ProxyService sera donc comme suit : 
<pre><code>
FROM alpine-jdk:base
LABEL maintainer="Oussama_Imen"
RUN apk --no-cache add netcat-openbsd
COPY proxy-service/target/proxy-service-0.0.1-SNAPSHOT.jar /opt/lib/
COPY proxyservice_wait-for-it.sh /opt/bin/
RUN chmod 755 /opt/bin/proxyservice_wait-for-it.sh
EXPOSE 9999
</code></pre>

&nbsp; Ici, le ProxyService dépend du ConfigService ansi que le DiscoveryService. Il faut donc nous assurer que, avant de démarrer le ProxyService, les deux précédents sont opérationnels. Le script proxyservice_wait-for-it.sh sera comme suit
<pre><code>
#!/bin/sh
while ! nc -z config-service 8888 ; do
&nbsp;    echo "Waiting for upcoming Config Service"
&nbsp;    sleep 2
done
while ! nc -z discovery-service 8761 ; do
&nbsp;    echo "Waiting for the Discovery Service"
&nbsp;    sleep 2
done
java -jar /opt/lib/proxy-service-0.0.1-SNAPSHOT.jar
</code></pre>

#### Product-service
&nbsp; ProductService s'exécute sur le port 8080. Le fichier Dockerfile-ProductService sera donc comme suit : 
<pre><code>
FROM alpine-jdk:base
LABEL maintainer="Oussama_Imen"
RUN apk --no-cache add netcat-openbsd
COPY product-service/target/product-service-0.0.1-SNAPSHOT.jar /opt/lib/
COPY productservice_wait-for-it.sh /opt/bin/
RUN chmod 755 /opt/bin/productservice_wait-for-it.sh
EXPOSE 8080
</code></pre>

&nbsp; Tout comme le ProxyService, le ProductService dépend du ConfigService ansi que le DiscoveryService. Il faut donc nous assurer que, avant de le démarrer, les deux précédents sont opérationnels. Le script productservice_wait-for-it.sh sera comme suit
<pre><code>
#!/bin/sh
while ! nc -z config-service 8888 ; do
&nbsp;    echo "Waiting for the Config Service"
&nbsp;    sleep 3
done
while ! nc -z discovery-service 8761 ; do
&nbsp;    echo "Waiting for the Eureka Service"
&nbsp;    sleep 3
done
while ! nc -z proxy-service 9999 ; do
&nbsp;    echo "Waiting for the Proxy Service"
&nbsp;    sleep 3
done
java -jar /opt/lib/product-service-0.0.1-SNAPSHOT.jar
</code></pre>

#### Docker-Compose
&nbsp; Créons maintenant un fichier appelé docker-compose.yml, qui utilisera tous ces Dockerfiles pour créer notre environnement requis. Il s'assurera également que les conteneurs requis générés maintiennent le bon ordre et qu'ils sont interconnectés. 
<br/><br/>
&nbsp; Ce dernier sera comme suit : 
<pre><code>
version: '2.0'
services:
    config-service:
        container_name: config-service
        build:
            context: .
            dockerfile: Dockerfile-configservice
        image: config-service:latest
        expose:
            - 8888
        ports:
            - 8888:8888
        networks:
            - spring-cloud-network
        logging:
            driver: json-file
    discovery-service:
        container_name: discovery-service
        build:
            context: .
            dockerfile: Dockerfile-DiscoveryService
        image: discovery-service:latest
        entrypoint: /opt/bin/discoveryservice_wait-for-it.sh
        environment:
            SPRING_APPLICATION_JSON: '{"spring":{"cloud":{"config":{"uri":"http://config-service:8888"}}}}'
            EUREKA_INSTANCE_PREFER_IP_ADDRESS: "false"
        expose:
            - 8761
        ports:
            - 8761:8761
        networks:
            - spring-cloud-network
        links:
            - config-service:config-service
        depends_on:
            - config-service
        logging:
            driver: json-file
    proxy-service:
        container_name: proxy-service
        build:
            context: .
            dockerfile: Dockerfile-ProxyService
        image: proxy-service:latest
        entrypoint: /opt/bin/proxyservice_wait-for-it.sh
        environment:
            SPRING_APPLICATION_JSON: '{"spring":{"cloud":{"config":{"uri":"http://config-service:8888"}}}}'
        expose:
            - 9999
        ports:
            - 9999:9999
        networks:
            - spring-cloud-network
        links:
            - config-service:config-service
            - discovery-service:discovery-service
        depends_on:
            - config-service
            - discovery-service
        logging:
            driver: json-file
    product-service-0:
        container_name: product-service-0
        build:
            context: .
            dockerfile: Dockerfile-ProductService
        image: product-service:latest
        entrypoint: /opt/bin/productservice_wait-for-it.sh
        environment:
            SPRING_APPLICATION_JSON: '{"spring":{"cloud":{"config":{"uri":"http://config-service:8888"}}}}'
        expose:
            - 8080
        ports:
            - 8080:8080
        networks:
            - spring-cloud-network
        links:
            - config-service:config-service
            - discovery-service:discovery-service
        depends_on:
            - config-service
            - discovery-service
        logging:
            driver: json-file
    product-service-1:
        container_name: product-service-1
        build:
            context: .
            dockerfile: Dockerfile-ProductService
        image: product-service:latest
        entrypoint: /opt/bin/productservice_wait-for-it.sh
        environment:
            SPRING_APPLICATION_JSON: '{"spring":{"cloud":{"config":{"uri":"http://config-service:8888"}}}}'
        expose:
            - 8080
        ports:
            - 8081:8080
        networks:
            - spring-cloud-network
        links:
            - config-service:config-service
            - discovery-service:discovery-service
        depends_on:
            - config-service
            - discovery-service
        logging:
            driver: json-file
    product-service-2:
        container_name: product-service-2
        build:
            context: .
            dockerfile: Dockerfile-ProductService
        image: product-service:latest
        entrypoint: /opt/bin/productservice_wait-for-it.sh
        environment:
            SPRING_APPLICATION_JSON: '{"spring":{"cloud":{"config":{"uri":"http://config-service:8888"}}}}'
        expose:
            - 8080
        ports:
            - 8082:8080
        networks:
            - spring-cloud-network
        links:
            - config-service:config-service
            - discovery-service:discovery-service
        depends_on:
            - config-service
            - discovery-service
        logging:
            driver: json-file
    product-service-3:
        container_name: product-service-3
        build:
            context: .
            dockerfile: Dockerfile-ProductService
        image: product-service:latest
        entrypoint: /opt/bin/productservice_wait-for-it.sh
        environment:
            SPRING_APPLICATION_JSON: '{"spring":{"cloud":{"config":{"uri":"http://config-service:8888"}}}}'
        expose:
            - 8080
        ports:
            - 8083:8080
        networks:
            - spring-cloud-network
        links:
            - config-service:config-service
            - discovery-service:discovery-service
        depends_on:
            - config-service
            - discovery-service
        logging:
            driver: json-file
networks:
    spring-cloud-network:
        driver: bridge

</code></pre>

&nbsp; Le fichier de composition Docker ci-dessous contient quelques entrées importantes: <br/>

&nbsp;&nbsp; 1. version: un champ obligatoire dans lequel nous devons conserver la version du format Docker Compose.

&nbsp;&nbsp; 2. services: chaque entrée définit le conteneur que nous devons générer.

&nbsp;&nbsp; 3. build: si mentionné, alors Docker Compose devrait construire une image à partir du fichier Docker indiqué.

&nbsp;&nbsp; 4. image: le nom de l'image qui sera créée.

&nbsp;&nbsp; 5. network: le nom du réseau à utiliser. Ce nom devrait être présent dans la section réseaux.

&nbsp;&nbsp; 6. links: cela créera un lien interne entre le service et le service mentionné. Ici, le ProductService doit par exemple accéder au CongifService aisni qu'au DiscoveryService.

&nbsp;&nbsp; 7. depends: cela est nécessaire pour maintenir l'ordre. Le conteneur ProductService dépend de DiscoveryService et de ConfigService. Par conséquent, Docker s'assure que les conteneurs DiscoveryService et ConfigService sont créés avant le conteneur ProductService.

## Exécution
&nbsp; Après avoir créé ces différents fichiers, construisons nos images, créons les conteneurs requis et démarrons avec la seule commande: <br/>
<code>docker-compose up --build </code>
On a ainsi une architecture fonctionnelle de microservices composée des élements suivants:
* Proxy Service
* Config Service
* Discovery Service
* 3 Product Services
         
<br/>
&nbsp; Pour arrêter l'environnement complet, nous pouvons utiliser cette commande: <br/>
<code>docker-compose down </code>
