# OpenEDA-PDK for RISC-V Day Tokyo 2026 Autumn MPW Hands-on
# Ubuntu 24.04 / arm64
#
# 通常ビルド:
#   docker build -t openeda-risc-v-day .
#
# 起動:
#   docker run -d --name openeda -p 5901:5901 -v $(pwd)/work:/home/ishi-kai/work openeda-risc-v-day

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Tokyo \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# 1. システムパッケージ
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo git wget curl ca-certificates build-essential \
    python3 python3-pip python3-venv python3-dev pkg-config \
    lsb-release automake autoconf \
    xterm x11-apps libx11-6 libx11-dev libxrender1 libxrender-dev \
    libxcb1 libx11-xcb-dev libcairo2 libcairo2-dev libgtk-3-dev \
    libasound2-dev tcl8.6 tcl8.6-dev tk8.6 tk8.6-dev \
    flex bison libxpm4 libxpm-dev gawk tcl-tclreadline \
    gettext libtool m4 tcsh csh mesa-common-dev libglu1-mesa-dev \
    libxaw7-dev libxmu-dev libxext-dev libxft-dev libfontconfig1-dev \
    libfreetype6-dev libreadline-dev libfftw3-dev \
    vim nano less tree unzip \
    xfce4 xfce4-terminal tightvncserver \
    xfonts-base xfonts-75dpi fonts-dejavu-core \
    gmsh \
    dbus-x11 \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 2. ユーザー作成（UID 1000 は ubuntu が使用済みのため指定しない）
RUN useradd -m -s /bin/bash ishi-kai \
    && echo "ishi-kai:ishi-kai" | chpasswd \
    && usermod -aG sudo ishi-kai \
    && echo "ishi-kai ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER ishi-kai
WORKDIR /home/ishi-kai

# 3. 公式イメージの設定ファイルをコピー (削除予定: 現在はビルドキャッシュを利用するため一時的に残している)
COPY --chown=ishi-kai:ishi-kai .bashrc .profile .magicrc .spiceinit /home/ishi-kai/
COPY --chown=ishi-kai:ishi-kai .xschem /home/ishi-kai/.xschem
COPY --chown=ishi-kai:ishi-kai .klayout /home/ishi-kai/.klayout

# 4. OpenEDA スクリプトをクローン
RUN git clone --depth 1 https://github.com/ishi-kai/OpenEDA-PDK_SetupScript.git

WORKDIR /home/ishi-kai/OpenEDA-PDK_SetupScript

# 5. スクリプトのパッチ
#    - gettext を 0.21 に合わせる
#    - PDK ブランチを RD_2611 に変更
#    - xschem-gaw の po ビルドをスキップ可能にする
RUN sed -i 's/export GETTEXT_VERSION=0.20/export GETTEXT_VERSION=0.21/' eda-setup.sh && \
    sed -i 's/WS_RUN3/RD_2611/g' pdk_gf180-setup.sh && \
    # gaw の make 失敗で全体が止まらないようにする
    sed -i 's/^make -j"\$(nproc)"$/make -j"\$(nproc)" || true/' eda-setup.sh && \
    sed -i 's/^sudo make install$/sudo make install || true/' eda-setup.sh

# 6. EDA ツールのセットアップ
RUN bash eda-setup.sh

# 7. xschem-gaw（失敗しても全体は止めない）
RUN if [ -d /home/ishi-kai/src/xschem-gaw ]; then \
      cd /home/ishi-kai/src/xschem-gaw && \
      sed -i 's/SUBDIRS = lib src po/SUBDIRS = lib src/' Makefile 2>/dev/null || true && \
      make -j$(nproc) && sudo make install || echo "gaw install skipped"; \
    fi

RUN \
    # gds2palace/gmsh の pip install をスキップ（aarch64 で失敗するため）
    sed -i '/gds2palace/s/^/# SKIP: /' pdk_gf180-setup.sh && \
    sed -i '/gmsh/s/^/# SKIP: /' pdk_gf180-setup.sh

# 8. PDK インストール（失敗したら止める）
WORKDIR /home/ishi-kai/OpenEDA-PDK_SetupScript
USER root
RUN bash pdk_gf180-setup.sh && \
    mv /root/pdk/gf180mcuD /home/ishi-kai/pdk/ && \
    chown -R ishi-kai:ishi-kai /home/ishi-kai/pdk /home/ishi-kai/src /home/ishi-kai
USER ishi-kai

# 8b. PDK のパス構造を修正（libs.tech / libs.ref を gf180mcuD 配下に移動）
#     公式イメージと同じ構造にする
RUN if [ -d /home/ishi-kai/pdk/libs.tech ] && [ ! -d /home/ishi-kai/pdk/gf180mcuD/libs.tech ]; then \
      mkdir -p /home/ishi-kai/pdk/gf180mcuD && \
      mv /home/ishi-kai/pdk/libs.tech /home/ishi-kai/pdk/gf180mcuD/ && \
      mv /home/ishi-kai/pdk/libs.ref /home/ishi-kai/pdk/gf180mcuD/ 2>/dev/null || true; \
    elif [ -d /home/ishi-kai/pdk/libs.tech/klayout ] && [ ! -d /home/ishi-kai/pdk/gf180mcuD/libs.tech/klayout ]; then \
      mkdir -p /home/ishi-kai/pdk/gf180mcuD/libs.tech && \
      mv /home/ishi-kai/pdk/libs.tech/klayout /home/ishi-kai/pdk/gf180mcuD/libs.tech/; \
    fi && \
    # 確認用（ビルドログに残る）
    ls -la /home/ishi-kai/pdk/gf180mcuD/libs.tech/xschem/xschem-menu && \
    ls -la /home/ishi-kai/pdk/gf180mcuD/libs.tech/klayout/tech/gf180mcu.lyp

# 9. テンプレートのクローン
WORKDIR /home/ishi-kai
RUN git clone --depth 1 https://github.com/ishi-kai/RISC-V-Day_MPW_template.git || true

# 10. 環境変数
ENV PATH="/home/ishi-kai/bin:/usr/local/bin:${PATH}" \
    LD_LIBRARY_PATH="/home/ishi-kai/bin/klayout" \
    PDK_ROOT="/home/ishi-kai/pdk" \
    PDK="gf180mcuD" \
    GF_PDK_OPTION="D" \
    PDKPATH="/home/ishi-kai/pdk/gf180mcuD" \
    STD_CELL_LIBRARY="gf180mcu_fd_sc_mcu7t5v0" \
    KLAYOUT_PATH="/home/ishi-kai/pdk/gf180mcuD/libs.tech/klayout" \
    SPICE_USERINIT_DIR="/home/ishi-kai/pdk/gf180mcuD/libs.tech/ngspice"

# 11. VNC 設定
USER root
RUN mkdir -p /home/ishi-kai/.vnc /home/ishi-kai/work \
    && echo "openeda" | vncpasswd -f > /home/ishi-kai/.vnc/passwd \
    && chmod 600 /home/ishi-kai/.vnc/passwd \
    && chown -R ishi-kai:ishi-kai /home/ishi-kai/.vnc /home/ishi-kai/work \
    && printf '#!/bin/bash\n\
export USER=ishi-kai\n\
export HOME=/home/ishi-kai\n\
vncserver :1 -geometry 1920x1080 -depth 24\n\
tail -f /dev/null\n' > /usr/local/bin/start-vnc.sh \
    && chmod +x /usr/local/bin/start-vnc.sh

# 12. 実行環境の設定ファイル
#     ビルドでは参照しない。ここより前の層のキャッシュを残すため最後に置く。
#     current_pdk は .bashrc が source する。pdk スクリプトは root で動くため
#     /root/current_pdk に書き、PDK_ROOT も /root/pdk になる。公式と同じ内容を置く。
COPY --chown=ishi-kai:ishi-kai .bashrc .profile .magicrc .spiceinit current_pdk /home/ishi-kai/
COPY --chown=ishi-kai:ishi-kai .xschem /home/ishi-kai/.xschem
COPY --chown=ishi-kai:ishi-kai .klayout /home/ishi-kai/.klayout

USER ishi-kai
WORKDIR /home/ishi-kai/work

EXPOSE 5901
CMD ["/usr/local/bin/start-vnc.sh"]
