# Twitter bot: Cada esquina do Brasil <img align="right" src="https://www.urbandemographics.org/img/package_logo/esquinadobrasil_logo.png" alt="logo" width="250">

[![Passing check](https://github.com/rafapereirabr/todos_setores/actions/workflows/bot-schedule.yaml/badge.svg)](https://github.com/rafapereirabr/todos_setores/actions)
[![versao](https://img.shields.io/badge/V.-0.2.0-yellow)](https://img.shields.io/badge/V.-0.2.0-yellow)

<p align="left">
<a href="https://twitter.com/esquinadobrasil"><img src="https://img.shields.io/badge/%40esquinadobrasil-blue?style=flat&labelColor=1DA1F2&color=1DA1F2&logo=twitter&logoColor=white" alt=“Follow me" height=22 ></a>
</p>

Twitter bot :robot: que posta imagens de satélite de todos setores censitários do Brasil. Um novo setor a cada 15 minutos. A ordem dos setores foi sorteada aleatoriamente. O objetivo com esse bot é ~procrastinar~  levar as pessoas a "visitar" cada esquina desse imenso Brasil, em toda sua beleza e também desigualdade. O propósito também é educacional para despertar a curiosidade e interesse sobre ciências de dados espaciais e programação em R.

Bot criado por [Rafael H. M. Pereira](https://www.urbandemographics.org/about/) ([@UrbanDemog](https://twitter.com/UrbanDemog)).

# Dados:
- Setores censitários (geometria, estimativas de população e bairro): Censo Demográfico de 2010, IBGE
- Imagens de Satélite: Microsoft VirtualEarth, via GDAL Web Map Services



# Código e automação

O bot foi escrito em R usando os seguintes pacotes / ferramentas:

- [{geobr}](https://ipeagit.github.io/geobr/) para baixar dados de setores censitários 
- [{gdalio}](https://github.com/hypertidy/gdalio) para baixar imagens de satélite 
- [{sf}](https://r-spatial.github.io/sf/index.html) para operações em dados espaciais
- [{terra}](https://rspatial.github.io/terra/index.html) para visualizar os dados 
- [{rtweet}](https://docs.ropensci.org/rtweet/) para postagens no Twitter
- [Github Actions](https://github.com/features/actions) para automação



# Inspirado em outros bots:

- [@everytract](https://twitter.com/everytract)
- [@italiancomuni](https://twitter.com/italiancomuni)
- [@londonmapbot](https://twitter.com/londonmapbot)
- [@spainmunic](https://twitter.com/spainmunic)


