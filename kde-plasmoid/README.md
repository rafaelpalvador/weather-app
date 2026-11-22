# Céu — widget para o KDE Plasma 6

O ficheiro `Ceu-KDE.plasmoid` é gerado a cada compilação (Releases).

Instalar: botão direito no ambiente de trabalho → **Adicionar widgets** → **Obter novos widgets** → **Instalar a partir de ficheiro local** → escolher `Ceu-KDE.plasmoid`.
Ou no terminal: `kpackagetool6 -t Plasma/Applet -i Ceu-KDE.plasmoid` (para atualizar: `-u` em vez de `-i`).

Precisa do módulo QtWebEngine para QML (Arch/CachyOS: `qt6-webengine`; Debian/Ubuntu: `qml6-module-qtwebengine`).
