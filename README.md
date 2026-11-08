# Céu — previsão do tempo pessoal

App de tempo para Android (e Windows), feito com o mesmo esquema do Marginália Notes.

## Stack
- **Tauri 2 + Rust**: o mesmo código serve para o APK de Android e o instalador de Windows.
- **Frontend sem build** (`src/index.html`, HTML + JS puro): é aqui que se mexe no visual e nas secções.
- **Rust** (`src-tauri/src/lib.rs`): faz os pedidos à internet (sem limites de CORS) e usa o GPS do telemóvel (plugin `geolocation`).

## Fontes de dados (todas gratuitas, sem chave)
| O quê | Fonte |
|---|---|
| Previsão principal (automática ou ECMWF IFS 9 km) | Open-Meteo |
| Comparação de modelos (ECMWF, ICON, GFS, Météo-France) | Open-Meteo |
| Chuva a cada 15 min, próximas 2 h | Open-Meteo (`minutely_15`) |
| Qualidade do ar e pólen | Open-Meteo Air Quality |
| Avisos amarelo/laranja/vermelho | IPMA (distrito mais próximo) |
| Nome da cidade a partir do GPS | BigDataCloud (reserva: OpenStreetMap Nominatim) |
| Pesquisa de cidades | Open-Meteo Geocoding |

## Como funciona a compilação
Cada `push` para `main` corre o GitHub Actions (`.github/workflows/compilar.yml`):
1. Compila o APK (assinado com `android-assinatura/ceu-teste.jks`, para as atualizações instalarem por cima) e o instalador de Windows.
2. Publica tudo em **Releases** com a versão `0.1.N` e apaga as versões antigas.

Links fixos (sempre a versão mais nova):
- `https://github.com/rafaelpalvador/weather-app/releases/latest/download/Ceu-Android.apk`
- `https://github.com/rafaelpalvador/weather-app/releases/latest/download/Ceu-Windows-instalador.exe`

No telemóvel, adiciona o endereço do repositório no **Obtainium** para receber as atualizações sozinho.

## Estrutura
```
src/index.html                 # todo o app (visual, gráficos, lógica)
src-tauri/
  tauri.conf.json              # nome, identificador, janela
  Cargo.toml                   # dependências Rust
  src/lib.rs                   # http_get + GPS
  capabilities/                # permissões (mobile.json = GPS)
  icons/icon.png               # ícone base (os outros são gerados no Actions)
android-assinatura/            # chave de teste do APK
```

## Testar no computador
1. Instala Rust e os pré-requisitos do Tauri 2.
2. `npm install`
3. `npx tauri icon src-tauri/icons/icon.png`
4. `npm run dev`
