F/A-18C SEAD/DEAD Loadout Extension - v0.1 (draft)
====================================================

O QUE FAZ
---------
Adiciona ao F/A-18C dois novos racks multi-municao, reaproveitando a
mesma arquitetura de adaptador ja usada pelo TALD (BRU-42A) e pelo
JSOW (BRU-55) no jogo original:

  - BRU-55 com 2x AGM-88 HARM   ("{BRU55_2xAGM88}")
  - BRU-42A com 3x AGM-65E Mav  ("{BRU42A_x3_AGM65E}")

Essas opcoes ficam disponiveis livremente nas estacoes de asa
2, 3, 7 e 8 no editor de carga do DCS (Mission Editor e tela de
carregamento em campanha), permitindo ao jogador escolher
livremente posicao e combinacao:

  - 4 estacoes com HARM  -> 8x AGM-88
  - 4 estacoes com Mav   -> 12x AGM-65E
  - qualquer mistura entre as duas (ex: 2+2 HARM / 2+2 Mav = 4 HARM + 6 Mav)

Alem disso, dois PRESETS aparecem no menu de Rearm/Refuel (F8 -> Ground
Crew -> Request Loadout) e no dropdown do Mission Editor:

  [26] "[SEAD] AGM-88*8, FUEL*1"
  [27] "[SEAD+DEAD] AGM-88*4, AGM-65E*6, FUEL*1"

COMO INSTALAR (teste local)
----------------------------
1. Fechar o DCS completamente.
2. Copiar a pasta "Mods" deste pacote para dentro de:
     %USERPROFILE%\Saved Games\DCS\               (versao estavel)
   ou
     %USERPROFILE%\Saved Games\DCS.openbeta\       (versao OpenBeta)
   Resultado esperado:
     Saved Games\DCS\Mods\aircraft\FA-18C\FA-18C_hornet.lua
     Saved Games\DCS\Mods\aircraft\FA-18C\CustomWeapons\dead_sead_racks.lua
     Saved Games\DCS\Mods\aircraft\FA-18C\UnitPayloads\FA-18C_hornet.lua
3. Abrir o DCS, ir no Mission Editor, colocar um F/A-18C e conferir
   se as opcoes aparecem no editor de carga (categoria de mísseis,
   nas estacoes 2/3/7/8).
4. Checar o log em %USERPROFILE%\Saved Games\DCS\Logs\dcs.log caso
   algo nao apareca (procurar por "LUA" ou "error" perto da hora
   que o ME carregou o avio).

AVISOS IMPORTANTES
-------------------
- Isto e um mod de GAMEPLAY, nao um combo real do Hornet. HARM e
  Maverick nunca sao montados em racks multi-munição na aeronave
  real; aqui reaproveitamos a geometria 3D do TALD/JSOW so pra fins
  de jogo. Visualmente pode ficar com pouco espaco entre os misseis.
- Quebra o Integrity Check (IC). Servidores multiplayer com IC
  ativado vao rejeitar ou expulsar o cliente. Use apenas offline/
  campanha solo ou em servidores que aceitem mods de terceiros.
- Faca backup antes de testar em cima de uma instalacao com outros
  mods de F/A-18C ja instalados (ex.: pacotes que tambem sobrescrevem
  FA-18C_hornet.lua) - pode haver conflito de "ultimo a escrever
  vence" dependendo da ordem de instalacao.
- Massas (Weight) dos racks sao estimativas; ajustar depois de testar
  o comportamento de voo/consumo de combustivel se necessario.

PROXIMOS PASSOS (para publicacao no DCS User Files)
-----------------------------------------------------
- Trocar Picture/placeholder pelos icones corretos do rack.
- Testar em multiplayer sem IC pra confirmar que nao ha crash.
- Escrever changelog e capturas de tela para a pagina de upload.
- Definir nome/versionamento definitivos antes do primeiro upload.
