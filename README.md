# RHEL7に新しいglib,gccを入れて、VSCode1.86以降のバージョンのリモート拡張機能を使えるようにする方法

## 1. 概要

この記事はダウンロード環境とターゲットの RHEL7計算機が別の計算機である想定で、RHEL7 に新しい glib,gcc を入れて、VSCode1.86以降のバージョンのリモート拡張機能を使えるようにする方法を記載する。

> 古いLinuxでVSCodeのリモート機能がサポート対象外になったので、それの回避策の覚え書き。

詳細は[こちら](https://code.visualstudio.com/docs/remote/linux)を参照。

平たく言うと、__古い linuxディストリビューションは glib,libstdc++ のバージョンが古いので対象外だよ__ ということ。

対策は __glib,libstdc++ の tarball をビルドして、システムへの影響の無いようにカスタムのインストール先にインストール__ してしまえば良い。

ちなみに、`glibc` や `libstdc++` をシステムのパスの通ったところにインストールしたり、環境変数 `LD_LIBRARY_PATH` にパスを追加するとシステムが壊れる。基本コマンドも使えなくなる。絶対にやらないこと。

- この記事の動作確認をした環境は以下のとおり

  - Windows11 に CentOS7.5 の WSL2 ディストリビューションを作成
  - VSCode1.109.5 の拡張機能WSLでリモート接続

- tarballをビルドしてカスタムインストールするパッケージは以下のとおり

  | コンポーネント | カスタムのインストール先 |
  | --- | --- |
  | glib2.29 | /opt/glibc-2.29 |
  | gcc12.2 | /opt/gcc-12.2 |
  | patchelf0.18 | /opt/patchelf0.18 |
  | openssl-1.1.1w | /opt/openssl-1.1.1 |
  | Python-3.7.17 | /opt/python-3.7 |

- ビルドのためのパッケージは以下のとおり

  | コンポーネント | インストール方法 |
  | --- | --- |
  | binutils | OSのISOファイルまたは書庫リポジトリからインストールする |
  | bison | OSのISOファイルまたは書庫リポジトリからインストールする |
  | boost | OSのISOファイルまたは書庫リポジトリからインストールする |
  | bzip2-devel | OSのISOファイルまたは書庫リポジトリからインストールする |
  | flex | OSのISOファイルまたは書庫リポジトリからインストールする |
  | g++ | OSのISOファイルまたは書庫リポジトリからインストールする |
  | gcc | OSのISOファイルまたは書庫リポジトリからインストールする |
  | gdbm-devel | OSのISOファイルまたは書庫リポジトリからインストールする |
  | glibc-devel | OSのISOファイルまたは書庫リポジトリからインストールする |
  | glibc-headers | OSのISOファイルまたは書庫リポジトリからインストールする |
  | gmp-devel | OSのISOファイルまたは書庫リポジトリからインストールする |
  | iso-codes | OSのISOファイルまたは書庫リポジトリからインストールする |
  | kernel-headers | OSのISOファイルまたは書庫リポジトリからインストールする |
  | libavahi | OSのISOファイルまたは書庫リポジトリからインストールする |
  | libffi | OSのISOファイルまたは書庫リポジトリからインストールする |
  | libffi-devel | OSのISOファイルまたは書庫リポジトリからインストールする |
  | libmpc-devel | OSのISOファイルまたは書庫リポジトリからインストールする |
  | libquadmath | OSのISOファイルまたは書庫リポジトリからインストールする |
  | make | OSのISOファイルまたは書庫リポジトリからインストールする |
  | mokutil | OSのISOファイルまたは書庫リポジトリからインストールする |
  | mpfr-devel | OSのISOファイルまたは書庫リポジトリからインストールする |
  | ncurses-devel | OSのISOファイルまたは書庫リポジトリからインストールする |
  | openssh-clients | OSのISOファイルまたは書庫リポジトリからインストールする |
  | perl-IPC-Cmd | OSのISOファイルまたは書庫リポジトリからインストールする |
  | perl-Time-Piece | OSのISOファイルまたは書庫リポジトリからインストールする |
  | policycoreutils | OSのISOファイルまたは書庫リポジトリからインストールする |
  | policycoreutils-python | OSのISOファイルまたは書庫リポジトリからインストールする |
  | readline-devel | OSのISOファイルまたは書庫リポジトリからインストールする |
  | redhat-rpm-config | OSのISOファイルまたは書庫リポジトリからインストールする |
  | source-highlight | OSのISOファイルまたは書庫リポジトリからインストールする |
  | sqlite-devel | OSのISOファイルまたは書庫リポジトリからインストールする |
  | tar | OSのISOファイルまたは書庫リポジトリからインストールする |
  | tk-devel | OSのISOファイルまたは書庫リポジトリからインストールする |
  | uuid-devel | OSのISOファイルまたは書庫リポジトリからインストールする |
  | wget | OSのISOファイルまたは書庫リポジトリからインストールする |
  | tar | OSのISOファイルまたは書庫リポジトリからインストールする |
  | unzip | OSのISOファイルまたは書庫リポジトリからインストールする |
  | xz | OSのISOファイルまたは書庫リポジトリからインストールする |
  | xz-devel | OSのISOファイルまたは書庫リポジトリからインストールする |
  | zlib | OSのISOファイルまたは書庫リポジトリからインストールする |
  | zlib-devel | OSのISOファイルまたは書庫リポジトリからインストールする |
  | devtoolset-11 | rpmファイルをダウンロードしインストールする |
  | scl-utils | rpmファイルをダウンロードしインストールする |
  | libgfortran5 | rpmファイルをダウンロードしインストールする |

## 2. ダウンロード

必要な資材のダウンロードの手順を以下にまとめる

Windows11で資材をダウンロードする場合は[こちら](https://github.com/fangface-hub/devtoolset_glib_gcc_patchelf_download_script)をクローンしてスクリプトを使う。

### 2.1. 予めターゲットのRHEL7計算機にカスタムビルドに必要な追加パッケージをインストールする

ターゲットのRHEL7計算機で以下のコマンドを実行する

```bash
# sudo を入れてなかったら個別にインストールする
su 
yum install -y sudo
exit
sudo yum install -y \
    avahi binutils bison \
    boost bzip2-devel elfutils-devel \
    flex g++ gcc gdbm-devel \
    glibc-devel glibc-headers \
    gmp-devel iso-codes json-c \
    kernel-devel-uname-r \
    kernel-headers libavahi \
    libffi libffi-devel \
    libmpc-devel libquadmath \
    make mokutil mpfr-devel \
    ncurses-devel openssh-clients \
    perl-IPC-Cmd perl-Time-Piece \
    policycoreutils policycoreutils-python \
    readline-devel redhat-rpm-config \
    source-highlight sqlite-devel \
    tar tk-devel unzip \
    uuid-devel wget which \
    xz xz-devel zlib zlib-devel
```

- OS が EOL(End-Of-Life) でリポジトリが無効の場合、URLをvaultに変更する

  - CentOS7.5の場合

    - ターゲット計算機がオンラインに接続可能の場合

      ```bash
      su
      sed -i 's|mirrorlist=|#mirrorlist=|g' /etc/yum.repos.d/CentOS-*.repo
      sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*.repo
  
      yum clean all
      yum makecache
      exit
      ```

    - ターゲット計算機がオンラインに接続不可の場合
      1. ISOファイルをダウンロードする

          [CentOS-7-x86_64-Everything-1804.iso](http://vault.centos.org/7.5.1804/isos/x86_64/CentOS-7-x86_64-Everything-1804.iso)

      1. ISOファイルをマウント＆ローカルリポジトリを構築する

          ```bash
          su
          # マウントポイントを作成
          mkdir -p /mnt/centos7
          # マウントする
          mount -o loop \
              CentOS-7-x86_64-Everything-1804.iso \
              /mnt/centos7
          mkdir -p /opt/localrepo/centos7
          cp -a /mnt/centos7/* /opt/localrepo/centos7/
          umount /mnt/centos7
          rm -rf /mnt/centos7
          # ISOが用なしであれば削除
          rm -f CentOS-7-x86_64-Everything-1804.iso
          # リポジトリファイルの作成
          {
              echo '[local-centos7]'
              echo 'name=Local CentOS 7.5 Everything Repo'
              echo 'baseurl=file:///opt/localrepo/centos7'
              echo 'enabled=1'
              echo 'gpgcheck=0'
              echo 'exclude=*.i686'
          } > /etc/yum.repos.d/local-centos7.repo
          # 他のリポジトリを無効にする
          yum-config-manager --disable \*
          # local-centos7を有効にする
          yum-config-manager --enable local-centos7 
          yum clean all
          yum makecache
          exit
          ```

### 2.2. オンライン端末で Python-3.7.17 と OpenSSL 1.1.1 のtarballをダウンロードする

- オンライン端末がRHEL7の場合

  1. curlでダウンロードする

      ```bash
      mkdir python3.7_tarball
      cd python3.7_tarball
      curl -O https://www.python.org/ftp/python/3.7.17/Python-3.7.17.tgz
      curl -O https://github.com/openssl/openssl/releases/download/OpenSSL_1_1_1w/openssl-1.1.1w.tar.gz
      ```

      1. ターゲットのRHEL7計算機に `python3.7_tarball` ディレクトリを移動する

- オンライン端末がWindowsの場合

  1. ダウンロードスクリプト `python3.7download.ps1` を右クリックしPowershellで実行する

  1. ターゲットのRHEL7計算機に `python3.7_tarball` ディレクトリを移動する

### 2.3. オンライン端末で devtoolset-11 と関連パッケージをダウンロードする

> crosstool-ng を使う方法もあるが、必要な資材が多いので devtoolset-11 が安全で最短。

- オンライン端末がRHEL7の場合

  1. yum でダウンロードする

     ```bash
     sudo yum install --downloadonly --downloaddir=./devtoolset11_rpms \
         devtoolset-11 devtoolset-11-gcc devtoolset-11-gcc-c++ devtoolset-11-binutils \
         scl-utils-20130529-19 scl-utils-build-20130529-19
     ```

  1. ターゲットのRHEL7計算機に `devtoolset11_rpms` ディレクトリを移動する

- オンライン端末がWindowsの場合

  1. ダウンロードスクリプト `devtoolset11download.ps1` を右クリックしPowershellで実行する

  1. ターゲットのRHEL7計算機に `devtoolset11_rpms` ディレクトリを移動する

### 2.4. glib2.29をダウンロードする

- オンライン端末がRHEL7の場合

  1. curlでダウンロードする

      ```bash
      mkdir glib2.29_tarball
      cd glib2.29_tarball
      curl -O https://ftp.gnu.org/gnu/glibc/glibc-2.29.tar.gz
      ```

  1. ターゲットのRHEL7計算機に `glib2.29_tarball` ディレクトリを移動する

- オンライン端末がWindowsの場合

  1. ダウンロードスクリプト `glib2.29download.ps1` を右クリックしPowershellで実行する
  
  1. ターゲットのRHEL7計算機に `glib2.29_tarball` ディレクトリを移動する

### 2.5. gcc12.2 をダウンロードする

- オンライン端末がRHEL7の場合

  1. curlでダウンロードする

      ```bash
      mkdir gcc12.2_tarball
      cd gcc12.2_tarball
      # GCC本体
      curl -O https://ftp.gnu.org/gnu/gcc/gcc-12.2.0/gcc-12.2.0.tar.xz
      # GMP（GNU Multiple Precision Arithmetic Library）
      curl -O https://ftp.gnu.org/gnu/gmp/gmp-6.2.1.tar.xz
      # MPFR（Multiple Precision Floating-Point Reliably）
      curl -O https://www.mpfr.org/mpfr-4.1.0/mpfr-4.1.0.tar.xz
      # MPC（Multiple Precision Complex）
      curl -O https://ftp.gnu.org/gnu/mpc/mpc-1.2.1.tar.gz
      ```

  1. ターゲットのRHEL7計算機に `gcc12.2_tarball` ディレクトリを移動する

- オンライン端末がWindowsの場合

  1. ダウンロードスクリプト `gcc12.2download.ps1` を右クリックしPowerShellで実行する

  1. ターゲットのRHEL7計算機に `gcc12.2_tarball` ディレクトリを移動する

### 2.6. patchelf-0.18 のダウンロード

- オンライン端末がRHEL7の場合

  1. curlでダウンロードする
  
      ```bash
      mkdir patchelf0.18_tarball
      curl -LO https://github.com/NixOS/patchelf/releases/download/0.18.0/patchelf-0.18.0.tar.gz
      ```

  1. ターゲットのRHEL7計算機に `patchelf0.18_tarball` ディレクトリを移動する

- オンライン端末がWindowsの場合

  1. ダウンロードスクリプト `patchelf0.18download.ps1` を右クリックしPowerShellで実行する

  1. ターゲットのRHEL7計算機に `patchelf0.18_tarball` ディレクトリを移動する

## 3. インストール

インストール手順を3章にまとめる

### 3.1. Python-3.7.17 と OpenSSL 1.1.1 をインストールする（ssl 解決）

1. ターゲットのRHEL7計算機で以下のコマンド

  ```bash
  cd python3.7_tarball
  # ssl モジュールを有効化するため OpenSSL を先にビルドする
  # 事前に openssl-1.1.1w.tar.gz を python3.7_tarball に配置しておく
  tar xf openssl-1.1.1w.tar.gz
  cd openssl-1.1.1w
  ./Configure linux-x86_64 --prefix=/opt/openssl-1.1.1 --openssldir=/opt/openssl-1.1.1 shared zlib
  make -j"$(nproc)"
  sudo make install_sw

  # ランタイムリンカに OpenSSL のライブラリパスを登録
  {
      echo "/opt/openssl-1.1.1/lib64"
      echo "/opt/openssl-1.1.1/lib"
  } | sudo tee /etc/ld.so.conf.d/openssl-1.1.1.conf
  sudo ldconfig

  cd ..
  # Python3.7 を /opt/openssl-1.1.1 にリンクしてビルドする
  export CPPFLAGS="-I/opt/openssl-1.1.1/include"
  export LDFLAGS="-Wl,-rpath,/opt/openssl-1.1.1/lib64 -Wl,-rpath,/opt/openssl-1.1.1/lib -L/opt/openssl-1.1.1/lib64 -L/opt/openssl-1.1.1/lib"
  export PKG_CONFIG_PATH="/opt/openssl-1.1.1/lib64/pkgconfig:/opt/openssl-1.1.1/lib/pkgconfig"
  # Python test_socket がハングアップするのでこのセッションだけIPv6を無効にしておく
  export GAI_CONF=/dev/null
  export GAI_IGNORE_IPV6=1

  tar xf Python-3.7.17.tgz
  cd Python-3.7.17
  # .configure の注意
  # 最適化 --enable-optimizations オプション(PGO) 
  # は非常に時間がかかるので注意(30～60分以上かかる)
  ./configure \
      --prefix=/opt/python-3.7 \
      --with-openssl=/opt/openssl-1.1.1 \
      --with-openssl-rpath=auto
  make -j"$(nproc)"
  sudo make install

  # ssl の確認
  /opt/python-3.7/bin/python3 -c "import ssl; print(ssl.OPENSSL_VERSION)"

  # alternatives 設定
  sudo update-alternatives \
      --install /usr/bin/python3 python3 /opt/python-3.7/bin/python3 50 \
      --slave /usr/bin/pip3 pip3 /opt/python-3.7/bin/pip3 \
      --slave /usr/bin/idle3 idle3 /opt/python-3.7/bin/idle3 \
      --slave /usr/bin/pydoc3 pydoc3 /opt/python-3.7/bin/pydoc3
  ```

- ビルドが途中で失敗したら

  ソースのディレクトリで以下のコマンドを実行し、ビルドを初期化する

  ```bash
  make distclean
  make clean
  rm -f python Programs/_testembed
  rm -f pybuilddir.txt
  rm -rf build
  ```

### 3.2. devtoolset-11をインストールする

1. ターゲットのRHEL7計算機で以下のコマンド

    ```bash
    cd devtoolset11_rpms
    sudo rpm -Uvh --force \
        libgfortran5*.rpm \
        scl-utils-*.rpm \
        devtoolset-11*.rpm
    ```

    > エラーになったら `devtoolset11_rpms` の中から必要な依存パッケージを追加する。依存パッケージを全てダウンロードしているはず。

### 3.3. glib2.29 をビルド、インストールする

1. devtoolset-11 を有効にする

    ```bash
    scl enable devtoolset-11 bash
    ```

1. そのまま同じ端末で glib2.29 をビルドする

    ```bash
    cd glib2.29_tarball # 格納したディレクトリへ移動
    tar xf glibc-2.29.tar.gz # 圧縮ファイルを展開
    # in-tree build は RPATH を埋め込んでしまうので
    # 別ディレクトリを作成し移動する
    mkdir build # ビルドディレクトリ作成
    cd build # ビルドへ移動
    
    # configure
    ../glibc-2.29/configure \
        --prefix=/opt/glibc-2.29 \
        --disable-werror
    make -j$(nproc) # make
    sudo make install # make install
    ```

    - glibビルドの確認

      - 以下のコマンドの結果が何もないこと

        ```bash
        readelf -d /opt/glibc-2.29/lib/ld-linux-x86-64.so.2 | grep RPATH
        ```

      - 以下のコマンドの結果が `ok` であること

        ```bash
        /opt/glibc-2.29/lib/ld-linux-x86-64.so.2 \
          --library-path /opt/glibc-2.29/lib \
          /bin/echo ok
        ```

### 3.4. gcc12.2をビルド、インストールする

1. devtoolset-11 を有効にする

    ```bash
    scl enable devtoolset-11 bash
    ```

1. そのまま同じ端末で gcc12.2 をビルドする

    ```bash
    cd gcc12.2_tarball
    tar xf gcc-12.2.0.tar.xz
    tar xf gmp-6.2.1.tar.xz
    tar xf mpfr-4.1.0.tar.xz
    tar xf mpc-1.2.1.tar.gz
    cd gcc-12.2.0
    
    # 必要なライブラリを GCC ソースツリーに配置
    ln -s ../gmp-6.2.1 gmp
    ln -s ../mpfr-4.1.0 mpfr
    ln -s ../mpc-1.2.1 mpc
    
    mkdir build
    cd build

    ../configure \
      --prefix=/opt/gcc-12.2 \
      --disable-bootstrap \
      --disable-multilib \
      --enable-languages=c,c++

    make -j$(nproc) 
    sudo make install
    ```

### 3.5. patchelf0.18 をビルド、インストールする

1. devtoolset-11 を有効にする

    ```bash
    scl enable devtoolset-11 bash
    ```

1. そのまま同じ端末で patchelf0.18 をビルドする

    ```bash
    tar xf patchelf-0.18.0.tar.gz
    cd patchelf-0.18.0
    ./configure --prefix=/opt/patchelf0.18
    make -j$(nproc)
    sudo make install
    ```

## 4. ターゲットのRHEL7計算機の環境変数を設定する

システムの環境変数を変更すると古いVSCodeを使っているユーザにも影響してしまうので、なるべく個人のプロファイルを設定する。

`~.bashrc` と `~/.vscode-server/server-env-setup` に以下の環境変数を追加する

```bash
# 省略(既存の行は変更しない)
GCC12_2_LIB=/opt/gcc-12.2/lib64
GLIBC2_29_LIB=/opt/glibc-2.29/lib
PATCHELF0_18=/opt/patchelf0.18
export VSCODE_LD_LIBRARY_PATH=${GCC12_2_LIB}:${GLIBC2_29_LIB}
export VSCODE_SERVER_CUSTOM_GLIBC_LINKER=${GLIBC2_29_LIB}/ld-linux-x86-64.so.2
export VSCODE_SERVER_CUSTOM_GLIBC_PATH=${VSCODE_LD_LIBRARY_PATH}
export VSCODE_SERVER_PATCHELF_PATH=${PATCHELF0_18}/bin/patchelf
```
