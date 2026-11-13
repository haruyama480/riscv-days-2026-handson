# OpenEDA-PDK for RISC-V Day Tokyo 2026 Autumn MPW Hands-on
# Ubuntu 24.04。arm64 / amd64 は同じファイル。アーキテクチャはビルド時の --platform で決める。
#
# ステージを分けている理由:
#   イメージの層は、その RUN が終わった時点の差分を持つ。
#   後の RUN でファイルを消しても、前の層に残った分はイメージから消えない。
#   builder にはコンパイラ、ヘッダ、ソース、Nix、pip、OpenEDA の作業コピーが残る。
#   runtime は新しい Ubuntu から始め、/export に集めたものだけを COPY する。
#   だから最終イメージには、消したつもりのソースやビルド依存が層として残らない。
#
# arm64:
#   docker build -t openeda-risc-v-day .
# amd64:
#   docker build --platform linux/amd64 -t openeda-risc-v-day:amd64 .
#
# 起動:
#   docker run -d --name openeda -p 5901:5901 -v $(pwd)/work:/home/ishi-kai/work openeda-risc-v-day

FROM ubuntu:24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Tokyo \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# コンパイル用。xschem、Magic、Netgen、ngspice、gaw のソースビルドに使う。
#   build-essential、autotools、flex/bison、gettext: ビルドツール
#   libx11、cairo、GTK、Xaw、fontconfig の -dev: GUI ツールのヘッダ
#   tcl/tk、fftw、readline、ALSA の -dev: Magic、ngspice、gaw
# KLayout の Qt 開発パッケージは、aarch64 のとき eda-setup.sh が入れる。
# xfce、フォント、実行時の .so はここに入れない。builder にしか無いファイルは最終イメージに入らない。
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo git wget curl ca-certificates build-essential \
    python3 python3-pip python3-venv python3-dev pkg-config \
    lsb-release automake autoconf \
    libx11-dev libxrender-dev libx11-xcb-dev libcairo2-dev libgtk-3-dev \
    libasound2-dev tcl8.6-dev tk8.6-dev \
    flex bison libxpm-dev gawk tcl-tclreadline \
    gettext libtool m4 tcsh csh mesa-common-dev libglu1-mesa-dev \
    libxaw7-dev libxmu-dev libxext-dev libxft-dev libfontconfig1-dev \
    libfreetype6-dev libreadline-dev libfftw3-dev \
    unzip \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# UID 1000 は ubuntu が使用済みのため指定しない
RUN useradd -m -s /bin/bash ishi-kai \
    && echo "ishi-kai:ishi-kai" | chpasswd \
    && usermod -aG sudo ishi-kai \
    && echo "ishi-kai ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER ishi-kai
WORKDIR /home/ishi-kai

# .git は clone と同じ RUN で消す。後の RUN で消しても、この層には残る。
RUN git clone --depth 1 https://github.com/ishi-kai/OpenEDA-PDK_SetupScript.git \
 && rm -rf OpenEDA-PDK_SetupScript/.git

WORKDIR /home/ishi-kai/OpenEDA-PDK_SetupScript

# gettext を 0.21 に合わせる。PDK ブランチは RD_2611。
# gaw の make 失敗と、aarch64 の gds2palace/gmsh で全体を止めない。
# Rosetta 上では Nix の seccomp BPF が載らない。
# aarch64 の KLayout は既定ブランチではなく、amd64 の deb と同じ v0.30.12 をビルドする。
RUN sed -i 's/export GETTEXT_VERSION=0.20/export GETTEXT_VERSION=0.21/' eda-setup.sh && \
    sed -i 's/WS_RUN3/RD_2611/g' pdk_gf180-setup.sh && \
    sed -i 's/^make -j"\$(nproc)"$/make -j"\$(nproc)" || true/' eda-setup.sh && \
    sed -i 's/^sudo make install$/sudo make install || true/' eda-setup.sh && \
    sed -i '/gds2palace/s/^/# SKIP: /' pdk_gf180-setup.sh && \
    sed -i '/gmsh/s/^/# SKIP: /' pdk_gf180-setup.sh && \
    sed -i 's/extra-experimental-features = nix-command flakes/extra-experimental-features = nix-command flakes\n      filter-syscalls = false/' pdk_gf180-setup.sh && \
    sed -i 's|git clone --depth 1 https://github.com/KLayout/klayout.git|git clone --depth 1 --branch v0.30.12 https://github.com/KLayout/klayout.git|' eda-setup.sh

# xschem、gaw、Magic、Netgen、ngspice をソースから入れる。
# KLayout は aarch64 だけここで v0.30.12 をビルドし、$HOME/bin/klayout に置く。
# amd64 はコンパイルせず、公式の klayout_0.30.12-1_amd64.deb を /usr に入れる。
# スクリプト内の git clone もこの RUN のうちに .git を消す。
RUN bash eda-setup.sh && \
    find /home/ishi-kai/src -name .git \( -type d -o -type f \) -prune -exec rm -rf {} +

# gaw の po は gettext の版ずれで失敗することがある。翻訳なしで入れ直す。失敗しても先へ進む。
RUN if [ -d /home/ishi-kai/src/xschem-gaw ]; then \
      cd /home/ishi-kai/src/xschem-gaw && \
      sed -i 's/SUBDIRS = lib src po/SUBDIRS = lib src/' Makefile 2>/dev/null || true && \
      make -j"$(nproc)" && sudo make install || echo "gaw install skipped"; \
    fi

USER root
# Nix と ciel で gf180mcuD を取得し、/home/ishi-kai/pdk へ移す。Nix 自体は /export に含めない。
# /root/src と /root/tools の clone、PDK ツリーに紛れた .git を同じ RUN で消す。
RUN bash pdk_gf180-setup.sh && \
    mv /root/pdk/gf180mcuD /home/ishi-kai/pdk/ && \
    for d in /root/src /root/tools /root/pdk /home/ishi-kai/pdk; do \
      if [ -d "$d" ]; then \
        find "$d" -name .git \( -type d -o -type f \) -prune -exec rm -rf {} +; \
      fi; \
    done && \
    chown -R ishi-kai:ishi-kai /home/ishi-kai

USER ishi-kai
# 公式イメージと同じく libs.tech / libs.ref を gf180mcuD 配下に置く
RUN if [ -d /home/ishi-kai/pdk/libs.tech ] && [ ! -d /home/ishi-kai/pdk/gf180mcuD/libs.tech ]; then \
      mkdir -p /home/ishi-kai/pdk/gf180mcuD && \
      mv /home/ishi-kai/pdk/libs.tech /home/ishi-kai/pdk/gf180mcuD/ && \
      mv /home/ishi-kai/pdk/libs.ref /home/ishi-kai/pdk/gf180mcuD/ 2>/dev/null || true; \
    elif [ -d /home/ishi-kai/pdk/libs.tech/klayout ] && [ ! -d /home/ishi-kai/pdk/gf180mcuD/libs.tech/klayout ]; then \
      mkdir -p /home/ishi-kai/pdk/gf180mcuD/libs.tech && \
      mv /home/ishi-kai/pdk/libs.tech/klayout /home/ishi-kai/pdk/gf180mcuD/libs.tech/; \
    fi && \
    ls -la /home/ishi-kai/pdk/gf180mcuD/libs.tech/xschem/xschem-menu && \
    ls -la /home/ishi-kai/pdk/gf180mcuD/libs.tech/klayout/tech/gf180mcu.lyp

WORKDIR /home/ishi-kai
# ハンズオンの GDS テンプレート。clone と同じ RUN で .git を消す。
RUN git clone --depth 1 https://github.com/ishi-kai/RISC-V-Day_MPW_template.git || true; \
    rm -rf RISC-V-Day_MPW_template/.git

# builder と runtime の境界。この RUN で /export に置いたものだけが最終イメージに入る。
# 渡すもの: xschem、ngspice、Magic、Netgen、gaw、それらの実行用データ、PDK、テンプレート、KLayout。
# 渡さないもの: コンパイラ、*-dev、ソースツリー、Nix、pip、OpenEDA の作業コピー。
USER root
RUN set -eux; \
    root=/export; \
    mkdir -p "$root/usr/local/bin" "$root/usr/local/lib" "$root/usr/local/share" "$root/home/ishi-kai"; \
    for b in ext2sim ext2spice gaw magic netgen ngspice rawtovcd xschem; do \
      if [ -e "/usr/local/bin/$b" ]; then cp -a "/usr/local/bin/$b" "$root/usr/local/bin/"; fi; \
    done; \
    for d in magic netgen ngspice; do \
      if [ -d "/usr/local/lib/$d" ]; then cp -a "/usr/local/lib/$d" "$root/usr/local/lib/"; fi; \
    done; \
    for d in xschem ngspice gaw; do \
      if [ -d "/usr/local/share/$d" ]; then cp -a "/usr/local/share/$d" "$root/usr/local/share/"; fi; \
    done; \
    cp -a /home/ishi-kai/pdk "$root/home/ishi-kai/pdk"; \
    if [ -d /home/ishi-kai/RISC-V-Day_MPW_template ]; then \
      mkdir -p "$root/home/ishi-kai/RISC-V-Day_MPW_template"; \
      cp -a /home/ishi-kai/RISC-V-Day_MPW_template/. "$root/home/ishi-kai/RISC-V-Day_MPW_template/"; \
      rm -rf "$root/home/ishi-kai/RISC-V-Day_MPW_template/.git"; \
    fi; \
    if [ -d /home/ishi-kai/bin/klayout ]; then \
      mkdir -p "$root/home/ishi-kai/bin"; \
      cp -a /home/ishi-kai/bin/klayout "$root/home/ishi-kai/bin/klayout"; \
    fi; \
    if [ -x /usr/bin/klayout ]; then \
      mkdir -p "$root/usr/bin" "$root/usr/lib"; \
      cp -a /usr/bin/klayout "$root/usr/bin/klayout"; \
      if [ -d /usr/lib/klayout ]; then cp -a /usr/lib/klayout "$root/usr/lib/"; fi; \
    fi

# runtime は新しい Ubuntu。builder の層は引き継がない。
# 共有ライブラリ、フォント、デスクトップはここに入れる。builder だけに入れると最終イメージに無い。
FROM ubuntu:24.04 AS runtime

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Tokyo \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# 実行時ライブラリとデスクトップ。ヘッダとコンパイラは入れない。行のまとまりは上から次のとおり。
#   sudo、git: 基本コマンド
#   python3、ruby: KLayout のスクリプト
#   jpeg、fftw、readline、ALSA、Xaw、GLU: ngspice、gaw、Magic が読む .so
#   Qt5、libgit2: KLayout が読む .so
#   tcl、tk、gawk、csh: Magic
#   xterm、vim、nano、less、tree、unzip: ハンズオン中の操作
#   xfce、tightvnc: デスクトップと VNC
#   xfonts、dejavu: GUI の文字
#   dbus: xfce のセッション
# KLayout のパッケージは入れない。Ubuntu 24 では 0.28.16 になる。
# 本体は /export から来る。arm64 は v0.30.12 のソースビルド、amd64 は同じ版の公式 deb。
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo ca-certificates git \
    python3 ruby \
    libjpeg-turbo8 libfftw3-double3 libreadline8t64 libasound2t64 libxaw7 libxss1 libglu1-mesa \
    libqt5widgets5t64 libqt5xml5t64 libqt5network5t64 libqt5svg5 libqt5multimedia5 \
    libqt5multimediawidgets5 libqt5printsupport5t64 libqt5xmlpatterns5 libqt5sql5t64 \
    libqt5designer5 libgit2-1.7 \
    tcl8.6 tk8.6 tcl-tclreadline gawk tcsh csh \
    xterm \
    vim nano less tree unzip \
    xfce4 xfce4-terminal tightvncserver \
    xfonts-base xfonts-75dpi fonts-dejavu-core \
    dbus-x11 \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN useradd -m -s /bin/bash ishi-kai \
    && echo "ishi-kai:ishi-kai" | chpasswd \
    && usermod -aG sudo ishi-kai \
    && echo "ishi-kai ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# builder から渡るのは /export だけ。
COPY --from=builder /export/ /
RUN chown -R ishi-kai:ishi-kai /home/ishi-kai

# VNC から起動する GUI は .bashrc を読まない。PDK と KLayout の変数はここで渡す。
# PATH の先頭は arm64 のソースビルド。amd64 の deb は /usr/bin/klayout にあり、通常の PATH で見つかる。
ENV PATH="/home/ishi-kai/bin/klayout:/home/ishi-kai/bin:/usr/local/bin:${PATH}" \
    LD_LIBRARY_PATH="/home/ishi-kai/bin/klayout" \
    PDK_ROOT="/home/ishi-kai/pdk" \
    PDK="gf180mcuD" \
    GF_PDK_OPTION="D" \
    PDKPATH="/home/ishi-kai/pdk/gf180mcuD" \
    STD_CELL_LIBRARY="gf180mcu_fd_sc_mcu7t5v0" \
    KLAYOUT_PATH="/home/ishi-kai/pdk/gf180mcuD/libs.tech/klayout" \
    SPICE_USERINIT_DIR="/home/ishi-kai/pdk/gf180mcuD/libs.tech/ngspice"

# 設定ファイルは最後に置く。ここを編集しても、上のビルド層のキャッシュは無効にならない。
COPY --chown=ishi-kai:ishi-kai .bashrc .magicrc .spiceinit /home/ishi-kai/
COPY --chown=ishi-kai:ishi-kai .xschem /home/ishi-kai/.xschem
COPY --chown=ishi-kai:ishi-kai .klayout /home/ishi-kai/.klayout
# KLayout の DRC / LVS / PEX は gnome-terminal を起動する。中身は xfce4-terminal へ渡す。
COPY --chmod=755 bin/gnome-terminal /usr/local/bin/gnome-terminal

# VNC はディスプレイ :1。ホストへは 5901 を出す。パスワードは ishi-kai。
RUN mkdir -p /home/ishi-kai/.vnc /home/ishi-kai/work \
    && echo "ishi-kai" | vncpasswd -f > /home/ishi-kai/.vnc/passwd \
    && chmod 600 /home/ishi-kai/.vnc/passwd \
    && chown -R ishi-kai:ishi-kai /home/ishi-kai/.vnc /home/ishi-kai/work \
    && printf '#!/bin/bash\n\
export USER=ishi-kai\n\
export HOME=/home/ishi-kai\n\
vncserver :1 -geometry 1920x1080 -depth 24\n\
tail -f /dev/null\n' > /usr/local/bin/start-vnc.sh \
    && chmod +x /usr/local/bin/start-vnc.sh

USER ishi-kai
WORKDIR /home/ishi-kai/work

EXPOSE 5901
CMD ["/usr/local/bin/start-vnc.sh"]
