#!/usr/bin/env bash
# Busca o cérebro da Iris (regras, habilidades e ferramenta) no GitHub do suporte, em .nucleo/.
# O cérebro nunca é guardado na casa (.gitignore). Sem acesso ativo, apaga o que tiver sobrado e avisa.
cd "$(dirname "$0")" || exit 0
DONO="ERICO-PROJETO"
NOME="iris-nucleo"

# 1º jeito: o mesmo endereço (e a mesma credencial) que trouxe a casa, trocando só o repositório.
# É o que funciona por trás do intermediário de GitHub da nuvem do Claude.
ORIGEM=$(git remote get-url origin 2>/dev/null)
DERIVADO=$(printf '%s' "$ORIGEM" | sed -E "s#[^/:]+/[^/]+(\.git)?/?\$#$DONO/$NOME#")

tentar() {
  rm -rf .nucleo.novo
  GIT_TERMINAL_PROMPT=0 timeout 90 git clone -q --depth 1 "$1" .nucleo.novo 2>>.nucleo.erro
}

rm -f .nucleo.erro
if { [ -n "$DERIVADO" ] && [ "$DERIVADO" != "$ORIGEM" ] && tentar "$DERIVADO"; } \
   || tentar "https://github.com/$DONO/$NOME.git"; then
  rm -rf .nucleo && mv .nucleo.novo .nucleo && rm -f .nucleo.erro
  echo "NUCLEO_OK versão $(cat .nucleo/VERSAO 2>/dev/null)"
  exit 0
fi

ERRO=$(tr '\n' ' ' < .nucleo.erro 2>/dev/null | cut -c1-300)
rm -rf .nucleo.novo .nucleo.erro
if printf '%s' "$ERRO" | grep -qiE "resolve host|failed to connect|timed out|connection (refused|reset)|network is unreachable"; then
  echo "NUCLEO_SEM_REDE (detalhe: $ERRO)"
else
  rm -rf .nucleo
  echo "NUCLEO_SEM_ACESSO (detalhe: $ERRO)"
fi
exit 0
